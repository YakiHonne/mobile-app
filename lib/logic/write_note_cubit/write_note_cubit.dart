// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:aescryptojs/aescryptojs.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/write_note_view/write_note_view.dart';

part 'write_note_state.dart';

class WriteNoteCubit extends Cubit<WriteNoteState> {
  WriteNoteCubit(
    BaseEventModel? quotedNote, {
    required bool isMention,
  }) : super(
          WriteNoteState(
            medias: const [],
            isQuotedContentAvailable: quotedNote != null,
            quotedContent: quotedNote,
            isMention: isMention,
          ),
        );

  Event? toBeSubmittedEvent;
  String? relay;

  void addImage(List<String> link) {
    if (!isClosed) {
      emit(
        state.copyWith(
          medias: List.from(state.medias)..addAll(link),
        ),
      );
    }
  }

  void removeImage(int index) {
    if (!isClosed) {
      emit(
        state.copyWith(
          medias: List.from(state.medias)..removeAt(index),
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
  }) async {
    toBeSubmittedEvent = null;

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

    if (state.isQuotedContentAvailable) {
      qTag = getBaseEventModelId(state.quotedContent!);

      String? addr;

      if (state.quotedContent is DetailedNoteModel) {
        qTag = state.quotedContent!.id;
        addr = Nip19.encodeNote(state.quotedContent!.id);
      } else {
        addr = naddr(state.quotedContent!);
      }

      if (addr != null) {
        updatedContent = '$updatedContent nostr:$addr';
      }

      if (!pTags.contains(state.quotedContent!.pubkey)) {
        pTags.add(state.quotedContent!.pubkey);
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

    final cancel = BotToast.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.TEXT_NOTE,
      tags: tags,
      content: updatedContent,
      signer: signer,
    );

    if (event == null) {
      BotToastUtils.showError(
        t.errorGeneratingEvent.capitalizeFirst(),
      );
      return;
    }

    if (!isPaid) {
      await sendEventAndVerify(
        event: event,
        onSuccess: onSuccess,
        replyContent: replyContent,
        relay: relay,
      );
    } else {
      toBeSubmittedEvent = event;
      this.relay = relay;
      onPaymentProcess.call();
    }

    cancel.call();
  }

  Future<void> sendEventAndVerify({
    required Event event,
    required Function(Event) onSuccess,
    Map<String, dynamic>? replyContent,
    String? relay,
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

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: relays,
      setProgress: true,
      destinationPubkey: pubkey,
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess(
        t.notePublished.capitalizeFirst(),
      );
      resetDraft(replyContent);
      onSuccess.call(event);
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
    final cancel = BotToast.showLoading();

    final isChecked = await NostrFunctionsRepository.checkPayment(
      toBeSubmittedEvent!.id,
    );

    if (isChecked) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: toBeSubmittedEvent!,
        relays: relay != null ? [relay!] : currentUserRelayList.writes,
        setProgress: true,
      );

      if (isSuccessful) {
        BotToastUtils.showSuccess(
          t.paidNotePublished.capitalizeFirst(),
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
}
