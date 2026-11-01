import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'light_gbm_spam_model.dart';
import 'nspam_feature_extractor.dart';

/// Owns a background isolate that loads the model once and scores local posts.
class NSpamModelWorker {
  NSpamModelWorker._();

  static final NSpamModelWorker instance = NSpamModelWorker._();

  final Map<int, Completer<Map<String, double>>> _pending =
      <int, Completer<Map<String, double>>>{};
  final Completer<SendPort> _ready = Completer<SendPort>();
  int _nextRequestId = 0;
  Future<void>? _startFuture;
  late final ReceivePort _responsePort;
  late SendPort _workerPort;

  /// Scores author histories in a worker isolate so feature extraction stays
  /// off Flutter's UI isolate.
  Future<Map<String, double>> scoreAuthors(
    Map<String, List<NSpamNoteInput>> notesByAuthor,
  ) async {
    if (notesByAuthor.isEmpty) {
      return const <String, double>{};
    }
    await (_startFuture ??= _start());
    final workerPort = await _ready.future;
    final requestId = ++_nextRequestId;
    final result = Completer<Map<String, double>>();
    _pending[requestId] = result;
    workerPort.send(<String, Object>{
      'requestId': requestId,
      'notesByAuthor': <String, List<Map<String, Object>>>{
        for (final entry in notesByAuthor.entries)
          entry.key: entry.value
              .map((note) => <String, Object>{
                    'content': note.content,
                    'tags': note.tags,
                    'createdAt': note.createdAt,
                  })
              .toList(),
      },
    });

    try {
      return await result.future.timeout(const Duration(seconds: 45));
    } finally {
      _pending.remove(requestId);
    }
  }

  Future<void> _start() async {
    final modelData = await rootBundle.load('assets/nspam/model.txt');
    final modelBytes = modelData.buffer.asUint8List(
      modelData.offsetInBytes,
      modelData.lengthInBytes,
    );
    final calibrationJson =
        await rootBundle.loadString('assets/nspam/calibration.json');
    _responsePort = ReceivePort();
    _responsePort.listen(_handleResponse);

    await Isolate.spawn<Map<String, Object>>(
      _nspamWorkerMain,
      <String, Object>{
        'mainPort': _responsePort.sendPort,
        'modelBytes': TransferableTypedData.fromList(<TypedData>[modelBytes]),
        'calibrationJson': calibrationJson,
      },
      debugName: 'yaki-nspam-model',
    );
    await _ready.future.timeout(const Duration(seconds: 60));
  }

  void _handleResponse(Object? message) {
    if (message is! Map<Object?, Object?>) {
      return;
    }
    if (message['type'] == 'ready') {
      _workerPort = message['sendPort']! as SendPort;
      if (!_ready.isCompleted) {
        _ready.complete(_workerPort);
      }
      return;
    }
    if (message['type'] == 'startupError') {
      if (!_ready.isCompleted) {
        _ready.completeError(StateError(message['error'].toString()));
      }
      return;
    }

    final requestId = message['requestId'];
    if (requestId is! int) {
      return;
    }
    final completer = _pending[requestId];
    if (completer == null || completer.isCompleted) {
      return;
    }
    final rawScores = message['scores'];
    if (rawScores is! Map<Object?, Object?>) {
      completer.completeError(
        StateError('The nspam worker returned an invalid response.'),
      );
      return;
    }
    completer.complete(<String, double>{
      for (final entry in rawScores.entries)
        entry.key.toString(): (entry.value! as num).toDouble(),
    });
  }
}

void _nspamWorkerMain(Map<String, Object> bootstrap) {
  final mainPort = bootstrap['mainPort']! as SendPort;
  final requestPort = ReceivePort();
  late final LightGbmSpamModel model;
  try {
    final transferable = bootstrap['modelBytes']! as TransferableTypedData;
    final modelBytes = transferable.materialize().asUint8List();
    final modelText = utf8.decode(modelBytes);
    final calibrationJson = bootstrap['calibrationJson']! as String;
    model = LightGbmSpamModel.parse(modelText, calibrationJson);
  } catch (error) {
    mainPort.send(<String, Object>{
      'type': 'startupError',
      'error': error.toString(),
    });
    requestPort.close();
    return;
  }

  mainPort.send(<String, Object>{
    'type': 'ready',
    'sendPort': requestPort.sendPort,
  });
  requestPort.listen((Object? message) {
    if (message is! Map<Object?, Object?>) {
      return;
    }
    final requestId = message['requestId'];
    final rawNotesByAuthor = message['notesByAuthor'];
    if (requestId is! int || rawNotesByAuthor is! Map<Object?, Object?>) {
      return;
    }

    try {
      final scores = <String, double>{};
      for (final entry in rawNotesByAuthor.entries) {
        final notes = (entry.value! as List<Object?>).map((rawNote) {
          final note = rawNote! as Map<Object?, Object?>;
          final rawTags = note['tags']! as List<Object?>;
          return NSpamNoteInput(
            content: note['content']! as String,
            tags: rawTags
                .map(
                  (tag) => (tag! as List<Object?>)
                      .map((value) => value! as String)
                      .toList(),
                )
                .toList(),
            createdAt: note['createdAt']! as int,
          );
        }).toList();
        scores[entry.key.toString()] = model.score(notes);
      }
      mainPort.send(<String, Object>{
        'requestId': requestId,
        'scores': scores,
      });
    } catch (error) {
      mainPort.send(<String, Object>{
        'requestId': requestId,
        'scores': <String, double>{},
      });
    }
  });
}
