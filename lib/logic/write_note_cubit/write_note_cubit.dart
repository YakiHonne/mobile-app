// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:aescryptojs/aescryptojs.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/unpaid_note.dart';
import '../../models/video_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/write_note_view/write_note_view.dart';

part 'write_note_state.dart';

class WriteNoteCubit extends Cubit<WriteNoteState> {
  WriteNoteCubit(
    BaseEventModel? quotedNote, {
    required bool isMention,
    required bool isQuote,
  }) : super(
          WriteNoteState(
            medias: const [],
            imetas: const [],
            isQuotedContentAvailable: quotedNote != null,
            quotedContent: quotedNote,
            isMention: isMention,
            isQuote: isQuote,
          ),
        );

  Event? toBeSubmittedEvent;
  DateTime? scheduledPaid;
  List<String>? relays;

  void addImage(List<Map<String, String>> mediaData) {
    if (!isClosed) {
      final links = mediaData.map((e) => e['url'] ?? '').toList();
      emit(
        state.copyWith(
          medias: List.from(state.medias)..addAll(links),
          imetas: List.from(state.imetas)..addAll(mediaData),
        ),
      );
    }
  }

  void removeImage(int index) {
    if (!isClosed) {
      emit(
        state.copyWith(
          medias: List.from(state.medias)..removeAt(index),
          imetas: List.from(state.imetas)..removeAt(index),
        ),
      );
    }
  }

  void removeQuotedNote() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isQuotedContentAvailable: false,
        ),
      );
    }
  }

  Future<void> postNote({
    required String content,
    required Function(Event) onSuccess,
    required bool isPaid,
    required bool useSourceRelay,
    required EventSigner signer,
    required Function() onPaymentProcess,
    Map<String, dynamic>? replyContent,
    String? selectedExternalRelay,
    DateTime? scheduled,
  }) async {
    toBeSubmittedEvent = null;
    final ae = state.quotedContent;

    if (content.trim().isEmpty && !state.isQuotedContentAvailable) {
      BotToastUtils.showError(
        t.writeValidNote.capitalizeFirst(),
      );
      return;
    }

    final relay = selectedExternalRelay ??
        (useSourceRelay ? appSettingsManagerCubit.getNoteSourceRelay() : null);

    String updatedContent = content;
    final pTags = getPtags(content);

    List<List<String>>? replyData;
    final int? createdAt;

    if (replyContent != null) {
      if (replyContent['pTags'] != null) {
        pTags.addAll(
          (replyContent['pTags'] as List<String>?)?.where(
                (element) => element.isNotEmpty,
              ) ??
              [],
        );
      }

      final rPubkey = replyContent['pubkey'];

      if (rPubkey != null &&
          (rPubkey as String).isNotEmpty &&
          rPubkey != signer.getPublicKey()) {
        pTags.add(rPubkey);
      }

      if (replyContent['replyData'] != null) {
        replyData = replyContent['replyData'];
      }
    }

    String? qTag;

    if (state.isQuotedContentAvailable && state.isQuote) {
      qTag = getBaseEventModelId(ae!);

      updatedContent = '$updatedContent \nnostr:${ae.getScheme()}';

      if (!pTags.contains(ae.pubkey)) {
        pTags.add(ae.pubkey);
      }
    }

    updatedContent = sanitizeContent(updatedContent);

    final hashtags = getTtags(content);

    final nadresses = getNaddr(content);

    bool hasSmartWidget = false;

    for (final naddr in nadresses) {
      if (naddr.pubkey.isNotEmpty) {
        pTags.add(naddr.pubkey);
      }

      if (naddr.kind == EventKind.SMART_WIDGET_ENH) {
        hasSmartWidget = true;
      }
    }

    final tags = [
      if (relay != null && useSourceRelay) ['-'],
      if (qTag != null) ['q', qTag],
      if (hasSmartWidget) ['l', 'smart-widget'],
      if (pTags.isNotEmpty) ...pTags.map((p) => ['p', p, '', 'mention']),
      if (hashtags.isNotEmpty) ...hashtags.map((t) => ['t', t.split('#')[1]]),
      if (nadresses.isNotEmpty)
        ...Nip33.coordinatesToTagsWithMentions(nadresses),
      if (replyData != null) ...replyData,
    ];

    if (isPaid) {
      createdAt = currentUnixTimestampSeconds();
      final encryptedMessage = encryptAESCryptoJS(
        createdAt.toString(),
        dotenv.env['FN_KEY']!,
      );

      tags.addAll(
        [
          ['l', FN_SEARCH_VALUE],
          [
            FN_ENCRYPTION,
            encryptedMessage,
          ],
        ],
      );
    }

    for (final imeta in state.imetas) {
      if (imeta['url'] != null &&
          (state.medias.contains(imeta['url']) ||
              updatedContent.contains(imeta['url']!))) {
        final imetaTag = <String>['imeta'];

        imeta.forEach((key, value) {
          if (value.isNotEmpty) {
            if (key == 'url' ||
                key == 'm' ||
                key == 'x' ||
                key == 'size' ||
                key == 'dim' ||
                key == 'blurhash' ||
                key == 'duration') {
              imetaTag.add('$key $value');
            }
          }
        });

        tags.add(imetaTag);
      }
    }

    int kind = EventKind.TEXT_NOTE;
    if (replyContent != null && replyContent['parentKind'] != null) {
      final pKind = replyContent['parentKind'] as int;
      if (pKind == EventKind.LONG_FORM ||
          pKind == EventKind.VIDEO_HORIZONTAL ||
          pKind == EventKind.VIDEO_VERTICAL ||
          pKind == EventKind.VIDEO_VIEW ||
          pKind == EventKind.LEGACY_VIDEO_HORIZONTAL ||
          pKind == EventKind.LEGACY_VIDEO_VERTICAL ||
          pKind == EventKind.COMMENT) {
        kind = EventKind.COMMENT;
        tags.add(['k', pKind.toString()]);
      }
    }

    final cancel = BotToastUtils.showLoading();

    final event = await Event.genEvent(
      kind: kind,
      tags: tags,
      content: updatedContent,
      signer: signer,
      createdAt: scheduled?.toSecondsSinceEpoch() ?? 0,
    );

    if (event == null) {
      BotToastUtils.showError(
        t.errorGeneratingEvent.capitalizeFirst(),
      );
      return;
    }

    if (!isPaid || subscriptionCubit.isPremium) {
      await sendEventAndVerify(
        event: event,
        onSuccess: onSuccess,
        replyContent: replyContent,
        relay: relay,
        scheduled: scheduled,
      );
    } else {
      toBeSubmittedEvent = event;
      scheduledPaid = scheduled;
      relays = relay != null ? [relay] : null;

      localDatabaseRepository.saveUnpaidNote(
        signer.getPublicKey(),
        UnpaidNote(event: event, relays: relays),
      );

      onPaymentProcess.call();
    }

    cancel.call();
  }

  Future<void> sendEventAndVerify({
    required Event event,
    Function(Event)? onSuccess,
    Map<String, dynamic>? replyContent,
    String? relay,
    DateTime? scheduled,
  }) async {
    String? pubkey;
    if (state.isQuotedContentAvailable) {
      pubkey = state.quotedContent!.pubkey;
    }

    if (replyContent != null) {
      pubkey = replyContent['pubkey'];
    }

    final relays = relay != null
        ? [relay]
        : pubkey != null
            ? await broadcastRelays(pubkey)
            : currentUserRelayList.writes;

    if (relays.isEmpty) {
      BotToastUtils.showError(
        t.setOutboxRelays.capitalizeFirst(),
      );
      return;
    }

    bool isSuccessful;

    if (scheduled != null) {
      isSuccessful = await submitEventScheduled(
        event: event,
        relays: relays,
      );
    } else {
      isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        relays: relays,
        setProgress: true,
        destinationPubkey: pubkey,
      );
    }

    if (isSuccessful) {
      BotToastUtils.showSuccess(
        scheduled != null
            ? t.noteScheduled.capitalizeFirst()
            : t.notePublished.capitalizeFirst(),
      );
      resetDraft(replyContent);
      onSuccess?.call(event);
    } else {
      BotToastUtils.showError(
        t.errorSendingEvent.capitalizeFirst(),
      );
    }
  }

  void resetDraft(Map<String, dynamic>? replyContent) {
    if (replyContent != null) {
      final replyId = getReplyId(replyContent);
      if (replyId != null) {
        nostrRepository.deleteNoteReplyDraft(id: replyId);
      }
    } else {
      nostrRepository.deleteNoteDraft();
    }
  }

  Future<void> submitEvent(Function() onSuccess) async {
    final cancel = BotToastUtils.showLoading();

    final isChecked = await NostrFunctionsRepository.checkPayment(
      toBeSubmittedEvent!.id,
    );

    if (isChecked) {
      bool isSuccessful;
      final rs = relays ?? currentUserRelayList.writes;

      if (scheduledPaid != null) {
        isSuccessful = await submitEventScheduled(
          event: toBeSubmittedEvent!,
          relays: rs,
        );
      } else {
        isSuccessful = await NostrFunctionsRepository.sendEvent(
          event: toBeSubmittedEvent!,
          relays: rs,
          setProgress: true,
        );
      }

      if (isSuccessful) {
        BotToastUtils.showSuccess(
          scheduledPaid != null
              ? t.paidNoteScheduled.capitalizeFirst()
              : t.paidNotePublished.capitalizeFirst(),
        );

        localDatabaseRepository.removeUnpaidNote(
          currentSigner!.getPublicKey(),
          toBeSubmittedEvent!.id,
        );

        resetDraft(null);
        onSuccess.call();
      } else {
        BotToastUtils.showError(
          t.errorSendingEvent.capitalizeFirst(),
        );
      }

      cancel.call();
    } else {
      cancel.call();
      BotToastUtils.showError(
        t.invoiceNotPayed.capitalizeFirst(),
      );
    }
  }

  // Redeems points then publishes — no invoice check needed.
  Future<void> redeemPointsAndPublish(
    Function() onSuccess,
    Function(String) onError,
  ) async {
    if (toBeSubmittedEvent == null) {
      return;
    }
    final cancel = BotToastUtils.showLoading();
    try {
      final redeemed =
          await HttpFunctionsRepository.publishPaidNoteWithPoints();

      if (!redeemed) {
        onError(t.points_insufficient);
        return;
      }

      unawaited(pointsManagementCubit.getRecentStats());

      final rs = relays ?? currentUserRelayList.writes;
      bool isSuccessful;
      if (scheduledPaid != null) {
        isSuccessful = await submitEventScheduled(
          event: toBeSubmittedEvent!,
          relays: rs,
        );
      } else {
        isSuccessful = await NostrFunctionsRepository.sendEvent(
          event: toBeSubmittedEvent!,
          relays: rs,
          setProgress: true,
        );
      }

      if (isSuccessful) {
        BotToastUtils.showSuccess(
          scheduledPaid != null
              ? t.paidNoteScheduled.capitalizeFirst()
              : t.paidNotePublished.capitalizeFirst(),
        );
        localDatabaseRepository.removeUnpaidNote(
          currentSigner!.getPublicKey(),
          toBeSubmittedEvent!.id,
        );
        resetDraft(null);
        onSuccess.call();
      } else {
        BotToastUtils.showError(t.errorSendingEvent.capitalizeFirst());
      }
    } on DioException catch (e) {
      onError(
        (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
            t.points_insufficient,
      );
    } finally {
      cancel.call();
    }
  }

  Future<bool> submitEventScheduled({
    required Event event,
    required List<String> relays,
  }) async {
    final dvmMaster = await NostrFunctionsRepository.getDvmMasterResponse();

    if (dvmMaster == null) {
      BotToastUtils.showError(
        t.errorSendingEvent.capitalizeFirst(),
      );

      return false;
    }

    final giftWrap = await dvmMaster.generateScheduleEvent(
      relays: relays,
      event: event,
      dvmPubkey: DEFAULT_SCHEDULE_DVM_PUBKEY,
      signer: currentSigner!,
    );

    if (giftWrap == null) {
      BotToastUtils.showError(
        t.errorSendingEvent.capitalizeFirst(),
      );
      return false;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: giftWrap,
      relays: dvmMaster.relays,
      setProgress: true,
    );

    return isSuccessful;
  }

  Future<void> postComment({
    required String content,
    required EventSigner signer,
    Map<String, dynamic>? replyContent,
    String? relay,
    DateTime? scheduled,
    Function(Event)? onSuccess,
  }) async {
    final t = nostrRepository.currentContext().t;
    final ae = state.quotedContent;
    if (ae == null) {
      return;
    }

    final updatedContent = sanitizeContent(content);

    final tags = <List<String>>[];

    // NIP-22 tags
    String? rootId;
    String? rootAddress;
    int? rootKind;
    String? rootPubkey;

    String? parentId;
    String? parentAddress;
    int? parentKind;
    String? parentPubkey;

    if (ae is DetailedNoteModel) {
      rootId = ae.rootId;
      rootAddress = ae.rootAddress;
      rootKind = ae.rootKind;
      rootPubkey = ae.rootPubkey;

      parentId = ae.id;
      parentKind = ae.kind;
      parentPubkey = ae.pubkey;
    } else {
      rootId = ae.id;
      rootPubkey = ae.pubkey;

      if (ae is Article) {
        rootKind = EventKind.LONG_FORM;
        rootAddress = '$rootKind:${ae.pubkey}:${ae.identifier}';
      } else if (ae is VideoModel) {
        rootKind = ae.kind;
        rootAddress = '${ae.kind}:${ae.pubkey}:${ae.identifier}';
      } else if (ae is Curation) {
        rootKind = ae.kind;
        rootAddress = '${ae.kind}:${ae.pubkey}:${ae.identifier}';
      } else if (ae is SmartWidget) {
        rootKind = EventKind.SMART_WIDGET_ENH;
        rootAddress = ae.aTag();
      }

      parentAddress = rootAddress;
      parentId = rootId;
      parentKind = rootKind;
      parentPubkey = rootPubkey;
    }

    if (rootAddress != null) {
      tags.add(['A', rootAddress, '']);
    } else if (rootId != null) {
      tags.add(['E', rootId, '', rootPubkey ?? '']);
    }

    if (rootKind != null) {
      tags.add(['K', rootKind.toString()]);
    }
    if (rootPubkey != null) {
      tags.add(['P', rootPubkey, '']);
    }

    if (parentAddress != null) {
      tags.add(['a', parentAddress, '']);
    }

    tags.add(['e', parentId, '', parentPubkey]);

    if (parentKind != null) {
      tags.add(['k', parentKind.toString()]);
    }

    tags.add(['p', parentPubkey, '']);

    final hashtags = getTtags(content);
    final nadresses = getNaddr(content);
    String? qTag;
    bool hasSmartWidget = false;

    if (state.isQuotedContentAvailable) {
      qTag = getBaseEventModelId(ae);
    }

    for (final naddr in nadresses) {
      if (naddr.kind == EventKind.SMART_WIDGET_ENH) {
        hasSmartWidget = true;
      }
    }

    // Only add q tag if it's NOT the article/video or parent comment we are replying to
    // (since they are already in NIP-22 tags)
    if (qTag != null &&
        qTag != rootAddress &&
        qTag != rootId &&
        qTag != parentAddress &&
        qTag != parentId) {
      tags.add(['q', qTag]);
    }

    if (hasSmartWidget) {
      tags.add(['l', 'smart-widget']);
    }

    if (hashtags.isNotEmpty) {
      tags.addAll(hashtags.map((t) => ['t', t.split('#')[1]]));
    }

    if (nadresses.isNotEmpty) {
      tags.addAll(Nip33.coordinatesToTagsWithMentions(nadresses));
    }

    if (replyContent != null && replyContent['pTags'] != null) {
      final pTags = (replyContent['pTags'] as List<String>?)
              ?.where((e) => e.isNotEmpty) ??
          [];
      tags.addAll(pTags
          .where((p) => p != signer.getPublicKey())
          .map((p) => ['p', p, '', 'mention']));
    }

    // Add imeta
    for (final imeta in state.imetas) {
      if (imeta['url'] != null &&
          (state.medias.contains(imeta['url']) ||
              updatedContent.contains(imeta['url']!))) {
        final imetaTag = <String>['imeta'];
        imeta.forEach((key, value) {
          if (value.isNotEmpty &&
              (key == 'url' ||
                  key == 'm' ||
                  key == 'x' ||
                  key == 'size' ||
                  key == 'dim' ||
                  key == 'blurhash' ||
                  key == 'duration')) {
            imetaTag.add('$key $value');
          }
        });
        tags.add(imetaTag);
      }
    }

    final cancel = BotToastUtils.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.COMMENT,
      tags: tags,
      content: updatedContent,
      signer: signer,
      createdAt: scheduled?.toSecondsSinceEpoch() ?? 0,
    );

    if (event == null) {
      BotToastUtils.showError(t.errorGeneratingEvent.capitalizeFirst());
      cancel.call();
      return;
    }

    lg.i(event.toJson());

    await sendEventAndVerify(
      event: event,
      onSuccess: onSuccess,
      replyContent: replyContent,
      relay: relay,
      scheduled: scheduled,
    );

    cancel.call();
  }
}
