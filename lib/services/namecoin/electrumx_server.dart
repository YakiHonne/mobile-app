/// ElectrumX server model and constants for Namecoin name resolution.
///
/// Ported from Amethyst's ElectrumXServer.kt (MIT License, Vitor Pamplona).

/// Result of an ElectrumX name_show query.
///
/// Maps to the JSON fields returned by Namecoin Core / Electrum-NMC:
///   { "name": "d/example", "value": "{...}", "txid": "abc...", "height": 12345, ... }
class NameShowResult {
  final String name;
  final String value;
  final String? txid;
  final int? height;
  final int? expiresIn;

  const NameShowResult({
    required this.name,
    required this.value,
    this.txid,
    this.height,
    this.expiresIn,
  });

  NameShowResult copyWith({
    String? name,
    String? value,
    String? txid,
    int? height,
    int? expiresIn,
  }) {
    return NameShowResult(
      name: name ?? this.name,
      value: value ?? this.value,
      txid: txid ?? this.txid,
      height: height ?? this.height,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }
}

/// Represents a single ElectrumX server endpoint.
class ElectrumxServer {
  final String host;
  final int port;
  final bool useSsl;

  /// If true, accept any certificate (self-signed, expired, etc.)
  final bool trustAllCerts;

  const ElectrumxServer({
    required this.host,
    required this.port,
    this.useSsl = true,
    this.trustAllCerts = false,
  });
}

/// Specific exception types for Namecoin resolution failures.
abstract class NamecoinLookupException implements Exception {
  final String message;
  NamecoinLookupException(this.message);

  @override
  String toString() => message;
}

/// The name was queried successfully but does not exist on the blockchain.
class NamecoinNameNotFoundException extends NamecoinLookupException {
  final String name;
  NamecoinNameNotFoundException(this.name) : super('Name not found: $name');
}

/// The name has expired (>36000 blocks since last update).
class NamecoinNameExpiredException extends NamecoinLookupException {
  final String name;
  NamecoinNameExpiredException(this.name) : super('Name expired: $name');
}

/// All ElectrumX servers were unreachable or returned errors.
class NamecoinServersUnreachableException extends NamecoinLookupException {
  final Object? lastError;
  NamecoinServersUnreachableException([this.lastError])
      : super('All ElectrumX servers unreachable');
}

/// Well-known public Namecoin ElectrumX servers (clearnet).
const List<ElectrumxServer> defaultElectrumxServers = [
  ElectrumxServer(
    host: 'electrumx.testls.space',
    port: 50002,
    useSsl: true,
    trustAllCerts: true,
  ),
  ElectrumxServer(
    host: 'nmc2.bitcoins.sk',
    port: 57002,
    useSsl: true,
    trustAllCerts: true,
  ),
  ElectrumxServer(
    host: '46.229.238.187',
    port: 57002,
    useSsl: true,
    trustAllCerts: true,
  ),
];

/// Tor-preferred server list: onion primary, clearnet fallback.
const List<ElectrumxServer> torElectrumxServers = [
  ElectrumxServer(
    host:
        'i665jpwsq46zlsdbnj4axgzd3s56uzey5uhotsnxzsknzbn36jaddsid.onion',
    port: 50002,
    useSsl: true,
    trustAllCerts: true,
  ),
  ElectrumxServer(
    host: 'electrumx.testls.space',
    port: 50002,
    useSsl: true,
    trustAllCerts: true,
  ),
  ElectrumxServer(
    host: 'nmc2.bitcoins.sk',
    port: 57002,
    useSsl: true,
    trustAllCerts: true,
  ),
];
