import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../models/blossom_media.dart';
import '../../repositories/blossom_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import 'blossom_state.dart';

class BlossomCubit extends Cubit<BlossomState> {
  BlossomCubit({
    required BlossomRepository repository,
    required this.blossomServers,
    required this.pubkey,
  })  : _repository = repository,
        super(BlossomState.initial()) {
    _updateState(servers: blossomServers);
    loadMedia();
  }
  final BlossomRepository _repository;
  final List<String> blossomServers;
  final String pubkey;

  void _updateState({
    List<BlossomAggregatedMedia>? allMedia,
    List<BlossomAggregatedMedia>? filteredMedia,
    List<String>? servers,
    int? selectedServerIndex,
    bool? isGridView,
    bool? isLoading,
  }) {
    if (!isClosed) {
      emit(state.copyWith(
        allMedia: allMedia,
        filteredMedia: filteredMedia,
        servers: servers,
        selectedServerIndex: selectedServerIndex,
        isGridView: isGridView,
        isLoading: isLoading,
      ));
    }
  }

  Future<void> loadMedia({String? targetServer}) async {
    _updateState(isLoading: true);

    try {
      final Map<String, BlossomAggregatedMedia> aggregatedMap = {};
      final serversToFetch =
          targetServer != null ? [targetServer] : blossomServers;

      for (final server in serversToFetch) {
        final authEvent = await _createAuthEvent('list');
        if (authEvent == null) {
          continue;
        }

        final mediaList = await _repository.fetchMediaList(
          serverUrl: server,
          pubkey: pubkey,
          authEvent: authEvent,
        );

        for (final media in mediaList) {
          if (aggregatedMap.containsKey(media.sha256)) {
            final existing = aggregatedMap[media.sha256]!;
            if (!existing.serverUrls.contains(server)) {
              aggregatedMap[media.sha256] = BlossomAggregatedMedia(
                media: existing.media,
                serverUrls: [...existing.serverUrls, server],
              );
            }
          } else {
            aggregatedMap[media.sha256] = BlossomAggregatedMedia(
              media: media,
              serverUrls: [server],
            );
          }
        }
      }

      final allMediaList = aggregatedMap.values.toList();
      allMediaList.sort((a, b) => b.media.uploaded.compareTo(a.media.uploaded));

      _updateState(
        allMedia: allMediaList,
        isLoading: false,
      );
      _applyFilter();
    } catch (e) {
      lg.e('Error loading Blossom media: $e');
      _updateState(isLoading: false);
    }
  }

  void _applyFilter() {
    if (state.selectedServerIndex == -1) {
      _updateState(filteredMedia: state.allMedia);
    } else {
      final selectedServer = state.servers[state.selectedServerIndex];
      // Since loadMedia(targetServer) already filters, state.allMedia
      // should already be restricted to this server if it was just refreshed.
      // But we still apply filter for consistency if called after full load.
      final filtered = state.allMedia
          .where((m) => m.serverUrls.contains(selectedServer))
          .toList();
      _updateState(filteredMedia: filtered);
    }
  }

  void selectFilter(int index) {
    _updateState(selectedServerIndex: index);
    if (index == -1) {
      loadMedia();
    } else {
      loadMedia(targetServer: state.servers[index]);
    }
  }

  void toggleViewMode() {
    _updateState(isGridView: !state.isGridView);
  }

  Future<void> deleteMedia(String hash) async {
    final authEvent = await _createAuthEvent('delete', hash: hash);
    if (authEvent == null) {
      BotToastUtils.showError(t.encryptionFailed);
      return;
    }

    // Determine which servers to delete from
    List<String> targetServers;
    if (state.selectedServerIndex == -1) {
      // If "All servers", delete from all servers it's hosted on
      targetServers =
          state.allMedia.firstWhere((m) => m.media.sha256 == hash).serverUrls;
    } else {
      targetServers = [state.servers[state.selectedServerIndex]];
    }

    bool anySuccess = false;
    for (final server in targetServers) {
      final success = await _repository.deleteMedia(
        serverUrl: server,
        hash: hash,
        authEvent: authEvent,
      );
      if (success) {
        anySuccess = true;
      }
    }

    if (anySuccess) {
      BotToastUtils.showSuccess(t.deleteSuccessful);
      loadMedia(); // Refresh
    } else {
      BotToastUtils.showError(t.deleteFailed);
    }
  }

  Future<void> mirrorMedia(BlossomAggregatedMedia item) async {
    if (currentSigner == null) {
      return;
    }

    final targetServers =
        state.servers.where((s) => !item.serverUrls.contains(s)).toList();

    if (targetServers.isEmpty) {
      BotToastUtils.showInformation(t.mirrorSuccessful);
      return;
    }

    botUtilsLoadingProgressCubit.emitStatus(t.mirroring);
    final cancel = BotToastUtils.showLoading();

    bool anySuccess = false;

    try {
      final authEvent = await _createAuthEvent(
        'upload',
        hash: item.media.sha256,
      );
      if (authEvent == null) {
        cancel();
        BotToastUtils.showError(t.encryptionFailed);
        return;
      }

      for (final server in targetServers) {
        final success = await _repository.mirrorMedia(
          serverUrl: server,
          sourceUrl: item.media.url,
          authEvent: authEvent,
        );

        lg.i(server);

        if (success) {
          anySuccess = true;
        }
      }

      cancel();

      if (anySuccess) {
        BotToastUtils.showSuccess(t.mirrorSuccessful);
        loadMedia();
      } else {
        BotToastUtils.showError(t.mirrorFailed);
      }
    } catch (e) {
      cancel();
      BotToastUtils.showError(t.mirrorFailed);
    }
  }

  Future<Event?> _createAuthEvent(String type, {String? hash}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tags = [
      ['t', type],
      ['expiration', (now + 3600).toString()]
    ];
    if (hash != null) {
      tags.add(['x', hash]);
    }

    return Event.genEvent(
      kind: EventKind.BLOSSOM_HTTP_AUTH,
      tags: tags,
      content: '',
      signer: currentSigner,
    );
  }

  Future<void> uploadMedia({
    required List<int> fileBytes,
    required String filePath,
    required String mimeType,
    required List<String> targetServers,
  }) async {
    if (targetServers.isEmpty) {
      return;
    }

    final cancel = BotToastUtils.showLoading();
    bool anySuccess = false;

    try {
      final fileName = filePath.split('/').last;
      final hash = sha256.convert(fileBytes).toString();

      for (final server in targetServers) {
        final authEvent = await _createAuthEvent('upload', hash: hash);
        if (authEvent == null) {
          continue;
        }

        final success = await _repository.uploadMedia(
          serverUrl: server,
          fileBytes: fileBytes,
          fileName: fileName,
          mimeType: mimeType,
          authEvent: authEvent,
        );

        if (success) {
          anySuccess = true;
        }
      }

      cancel();

      if (anySuccess) {
        BotToastUtils.showSuccess(t.uploadSuccessful);
        loadMedia();
      } else {
        BotToastUtils.showError(t.uploadFailed);
      }
    } catch (e) {
      cancel();
      lg.e('Error during Blossom upload: $e');
      BotToastUtils.showError(t.uploadFailed);
    }
  }
}
