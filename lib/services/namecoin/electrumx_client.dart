/// Lightweight, query-only ElectrumX client for Namecoin name resolution.
///
/// Connects over TCP/TLS to a Namecoin ElectrumX server and resolves
/// Namecoin names to their current values using the standard Electrum
/// protocol (scripthash-based lookups).
///
/// Ported from Amethyst's ElectrumXClient.kt (MIT License, Vitor Pamplona).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'electrumx_server.dart';

class ElectrumXClient {
  final Duration connectTimeout;
  final Duration readTimeout;

  static const String _protocolVersion = '1.4';

  /// Namecoin names expire this many blocks after their last update.
  /// From chainparams.cpp: consensus.nNameExpirationDepth = 36000
  static const int nameExpireDepth = 36000;

  // Namecoin script opcodes
  static const int _opNameUpdate = 0x53; // OP_3 repurposed by Namecoin
  static const int _op2Drop = 0x6d;
  static const int _opDrop = 0x75;
  static const int _opReturn = 0x6a;
  static const int _opPushData1 = 0x4c;
  static const int _opPushData2 = 0x4d;

  int _requestId = 0;

  ElectrumXClient({
    this.connectTimeout = const Duration(seconds: 10),
    this.readTimeout = const Duration(seconds: 15),
  });

  /// Perform a name_show lookup against the given ElectrumX server.
  Future<NameShowResult?> nameShow(
    String identifier, {
    ElectrumxServer? server,
  }) async {
    server ??= defaultElectrumxServers.first;
    try {
      return await _connectAndQuery(identifier, server);
    } on NamecoinLookupException {
      rethrow;
    } catch (e) {
      return null;
    }
  }

  /// Try each server in order until one succeeds.
  Future<NameShowResult?> nameShowWithFallback(
    String identifier,
    List<ElectrumxServer> servers,
  ) async {
    Object? lastError;
    for (final server in servers) {
      try {
        final result = await nameShow(identifier, server: server);
        if (result != null) return result;
      } on NamecoinNameNotFoundException {
        rethrow; // Definitive answer
      } on NamecoinNameExpiredException {
        rethrow; // Definitive answer
      } catch (e) {
        lastError = e; // Server error — try next server
      }
    }
    throw NamecoinServersUnreachableException(lastError);
  }

  // ── internals ──────────────────────────────────────────────────────

  Future<NameShowResult?> _connectAndQuery(
    String identifier,
    ElectrumxServer server,
  ) async {
    Socket socket;

    // Connect with timeout
    if (server.useSsl) {
      socket = await SecureSocket.connect(
        server.host,
        server.port,
        timeout: connectTimeout,
        onBadCertificate:
            server.trustAllCerts ? (_) => true : null,
      );
    } else {
      socket = await Socket.connect(
        server.host,
        server.port,
        timeout: connectTimeout,
      );
    }

    _LineReader? lineReader;
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);

      lineReader = _LineReader(socket, readTimeout);

      // 1. Negotiate protocol version
      final versionReq = _buildRpcRequest(
        'server.version',
        ['YakiHonneNMC/0.1', _protocolVersion],
      );
      lineReader.send(versionReq);
      await lineReader.readLine(); // consume version response

      // 2. Compute the canonical name index scripthash
      final nameScript =
          _buildNameIndexScript(utf8.encode(identifier));
      final scriptHash = _electrumScriptHash(nameScript);

      // 3. Get transaction history for this name
      final historyReq = _buildRpcRequest(
        'blockchain.scripthash.get_history',
        [scriptHash],
      );
      lineReader.send(historyReq);
      final historyResponse = await lineReader.readLine();
      if (historyResponse == null) return null;
      final historyEntries = _parseHistoryResponse(historyResponse);
      if (historyEntries == null) return null;
      if (historyEntries.isEmpty) {
        throw NamecoinNameNotFoundException(identifier);
      }

      // 4. Get the latest transaction
      final latestEntry = historyEntries.last;
      final txHash = latestEntry.txHash;
      final height = latestEntry.height;

      final txReq = _buildRpcRequest(
        'blockchain.transaction.get',
        [txHash, true],
      );
      lineReader.send(txReq);
      final txResponse = await lineReader.readLine();

      // 5. Get current block height to check name expiry
      final headersReq = _buildRpcRequest(
        'blockchain.headers.subscribe',
        [],
      );
      lineReader.send(headersReq);
      final headersResponse = await lineReader.readLine();
      final currentHeight = _parseBlockHeight(headersResponse);

      // 6. Check if the name has expired
      if (currentHeight != null && height > 0) {
        final blocksSinceUpdate = currentHeight - height;
        if (blocksSinceUpdate >= nameExpireDepth) {
          throw NamecoinNameExpiredException(identifier);
        }
      }

      // 7. Parse the name value from the transaction
      var result = _parseNameFromTransaction(
        identifier,
        txHash,
        height,
        txResponse,
      );
      if (result != null && currentHeight != null && height > 0) {
        result = result.copyWith(
          expiresIn: nameExpireDepth - (currentHeight - height),
        );
      }
      return result;
    } finally {
      await lineReader?.close();
      await socket.close();
    }
  }

  /// Build the canonical script used by ElectrumX to index Namecoin names.
  ///
  /// Format: OP_NAME_UPDATE <push(name)> <push(empty)> OP_2DROP OP_DROP OP_RETURN
  Uint8List _buildNameIndexScript(List<int> nameBytes) {
    final result = <int>[];
    result.add(_opNameUpdate);
    result.addAll(_pushData(Uint8List.fromList(nameBytes)));
    result.addAll(_pushData(Uint8List(0))); // empty value
    result.add(_op2Drop);
    result.add(_opDrop);
    result.add(_opReturn);
    return Uint8List.fromList(result);
  }

  /// Bitcoin-style push data encoding.
  Uint8List _pushData(Uint8List data) {
    final len = data.length;
    if (len < 0x4c) {
      return Uint8List.fromList([len, ...data]);
    } else if (len <= 0xff) {
      return Uint8List.fromList([_opPushData1, len, ...data]);
    } else {
      return Uint8List.fromList([
        _opPushData2,
        len & 0xff,
        (len >> 8) & 0xff,
        ...data,
      ]);
    }
  }

  /// Electrum protocol scripthash: SHA-256 of the script, byte-reversed, hex-encoded.
  String _electrumScriptHash(Uint8List script) {
    final digest = sha256.convert(script).bytes;
    return _bytesToHex(Uint8List.fromList(digest.reversed.toList()));
  }

  /// Parse the block height from a `blockchain.headers.subscribe` response.
  int? _parseBlockHeight(String? raw) {
    if (raw == null) return null;
    try {
      final envelope = json.decode(raw) as Map<String, dynamic>;
      final result = envelope['result'] as Map<String, dynamic>?;
      return result?['height'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// Parse the history response into a list of (txHash, height) pairs.
  List<_HistoryEntry>? _parseHistoryResponse(String raw) {
    try {
      final envelope = json.decode(raw) as Map<String, dynamic>;
      final error = envelope['error'];
      if (error != null) return null;

      final result = envelope['result'] as List<dynamic>?;
      if (result == null) return null;

      return result
          .map((entry) {
            final obj = entry as Map<String, dynamic>;
            final txHash = obj['tx_hash'] as String?;
            final height = obj['height'] as int?;
            if (txHash == null || height == null) return null;
            return _HistoryEntry(txHash: txHash, height: height);
          })
          .whereType<_HistoryEntry>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Parse a Namecoin name and value from a verbose transaction response.
  NameShowResult? _parseNameFromTransaction(
    String identifier,
    String txHash,
    int height,
    String? raw,
  ) {
    if (raw == null) return null;
    try {
      final envelope = json.decode(raw) as Map<String, dynamic>;
      final error = envelope['error'];
      if (error != null) return null;

      final result = envelope['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final vouts = result['vout'] as List<dynamic>?;
      if (vouts == null) return null;

      for (final vout in vouts) {
        final scriptPubKey =
            (vout as Map<String, dynamic>)['scriptPubKey']
                as Map<String, dynamic>?;
        final scriptHex = scriptPubKey?['hex'] as String?;
        if (scriptHex == null) continue;

        // NAME_UPDATE scripts start with OP_3 (0x53)
        if (!scriptHex.startsWith('53')) continue;

        final scriptBytes = _hexToBytes(scriptHex);
        final parsed = _parseNameScript(scriptBytes);
        if (parsed == null) continue;

        // Verify this is the name we're looking for
        if (parsed.name == identifier) {
          return NameShowResult(
            name: parsed.name,
            value: parsed.value,
            txid: txHash,
            height: height,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parse a NAME_UPDATE script to extract the name and value.
  _NameValuePair? _parseNameScript(Uint8List script) {
    if (script.isEmpty || script[0] != _opNameUpdate) return null;

    var pos = 1;

    // Read name
    final nameResult = _readPushData(script, pos);
    if (nameResult == null) return null;
    pos = nameResult.nextPos;

    // Read value
    final valueResult = _readPushData(script, pos);
    if (valueResult == null) return null;

    final name = utf8.decode(nameResult.data, allowMalformed: true);
    final value = utf8.decode(valueResult.data, allowMalformed: true);
    return _NameValuePair(name: name, value: value);
  }

  /// Read a push-data encoded byte sequence from the script at the given position.
  _PushDataResult? _readPushData(Uint8List script, int pos) {
    if (pos >= script.length) return null;

    final opcode = script[pos];
    if (opcode == 0) {
      return _PushDataResult(data: Uint8List(0), nextPos: pos + 1);
    } else if (opcode < 0x4c) {
      final end = pos + 1 + opcode;
      if (end > script.length) return null;
      return _PushDataResult(
        data: script.sublist(pos + 1, end),
        nextPos: end,
      );
    } else if (opcode == 0x4c) {
      if (pos + 2 > script.length) return null;
      final len = script[pos + 1];
      final end = pos + 2 + len;
      if (end > script.length) return null;
      return _PushDataResult(
        data: script.sublist(pos + 2, end),
        nextPos: end,
      );
    } else if (opcode == 0x4d) {
      if (pos + 3 > script.length) return null;
      final len = script[pos + 1] | (script[pos + 2] << 8);
      final end = pos + 3 + len;
      if (end > script.length) return null;
      return _PushDataResult(
        data: script.sublist(pos + 3, end),
        nextPos: end,
      );
    }
    return null;
  }

  String _buildRpcRequest(String method, List<dynamic> params) {
    final id = ++_requestId;
    final obj = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };
    return json.encode(obj);
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final len = hex.length;
    final data = Uint8List(len ~/ 2);
    for (var i = 0; i < len; i += 2) {
      data[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return data;
  }
}

/// Simple line-oriented reader for ElectrumX socket communication.
class _LineReader {
  final Socket _socket;
  final Duration _timeout;
  final StringBuffer _buffer = StringBuffer();
  final List<String> _lines = [];
  StreamSubscription? _subscription;
  Completer<void>? _dataCompleter;

  _LineReader(this._socket, this._timeout) {
    _subscription = _socket.listen(
      (data) {
        _buffer.write(utf8.decode(data));
        _processBuffer();
        _dataCompleter?.complete();
        _dataCompleter = null;
      },
      onError: (e) {
        _dataCompleter?.completeError(e);
        _dataCompleter = null;
      },
      onDone: () {
        // Socket closed — unblock any pending readLine()
        _processBuffer();
        if (_dataCompleter != null && !_dataCompleter!.isCompleted) {
          _dataCompleter!.completeError(
            NamecoinServersUnreachableException(),
          );
          _dataCompleter = null;
        }
      },
    );
  }

  void _processBuffer() {
    final s = _buffer.toString();
    final parts = s.split('\n');
    if (parts.length > 1) {
      for (var i = 0; i < parts.length - 1; i++) {
        if (parts[i].isNotEmpty) {
          _lines.add(parts[i]);
        }
      }
      _buffer.clear();
      _buffer.write(parts.last);
    }
  }

  void send(String request) {
    _socket.add(utf8.encode('$request\n'));
  }

  Future<String?> readLine() async {
    // Return immediately if we already have a buffered line
    if (_lines.isNotEmpty) {
      return _lines.removeAt(0);
    }

    // Wait for data until we get a complete line or timeout
    final deadline = DateTime.now().add(_timeout);
    while (_lines.isEmpty) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) return null;

      _dataCompleter = Completer<void>();
      try {
        await _dataCompleter!.future.timeout(remaining);
      } on TimeoutException {
        return null;
      } catch (_) {
        return null;
      }

      // Process buffer in case the listener callback didn't produce
      // a complete line yet
      _processBuffer();
    }

    return _lines.removeAt(0);
  }

  Future<void> close() async {
    await _subscription?.cancel();
  }
}

class _HistoryEntry {
  final String txHash;
  final int height;
  _HistoryEntry({required this.txHash, required this.height});
}

class _NameValuePair {
  final String name;
  final String value;
  _NameValuePair({required this.name, required this.value});
}

class _PushDataResult {
  final Uint8List data;
  final int nextPos;
  _PushDataResult({required this.data, required this.nextPos});
}
