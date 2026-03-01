import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/core/nostr_core_repository.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/dvm_pending_pages_result.dart';
import '../../../models/dvm_schedule_state.dart';
import '../../../models/schedule_dvm.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'dashboard_scheduled_state.dart';

class DashboardScheduledCubit extends Cubit<DashboardScheduledState> {
  DashboardScheduledCubit() : super(const DashboardScheduledState());

  DvmMasterResponse? dvmMasterResponse;

  Future<void> initDvmMasterResponse() async {
    dvmMasterResponse ??= await NostrFunctionsRepository.getDvmMasterResponse();
  }

  Future<DvmScheduleState?> getScheduleState() async {
    try {
      await initDvmMasterResponse();

      if (dvmMasterResponse == null) {
        return null;
      }

      final events = await NostrFunctionsRepository.getEventsAsync(
        kinds: [EventKind.APP_CUSTOM],
        pubkeys: [DEFAULT_SCHEDULE_DVM_PUBKEY],
        dTags: ['pidgeon:v3:mb:${dvmMasterResponse!.mb}:index'],
        includeIds: false,
        compareById: false,
      );

      if (events.isEmpty) {
        return null;
      }

      final decryptedContent = await Nip44v2.decrypt(
        events.first.content,
        dvmMasterResponse!.mailboxKey,
      );

      return DvmScheduleState.fromJson(decryptedContent);
    } catch (e) {
      lg.e(e);
      return null;
    }
  }

  Future<void> getScheduledNotes() async {
    emit(state.copyWith(isLoading: true));

    final scheduleState = await getScheduleState();

    if (scheduleState == null || scheduleState.pendingPages.isEmpty) {
      emit(state.copyWith(notes: [], isLoading: false));
      return;
    }

    final dTags = scheduleState.pendingPages.map((e) => e.d).toList();

    if (dTags.isEmpty) {
      emit(state.copyWith(notes: [], isLoading: false));
      return;
    }

    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [EventKind.APP_CUSTOM],
      dTags: dTags,
      pubkeys: [DEFAULT_SCHEDULE_DVM_PUBKEY],
      compareById: false,
      includeIds: false,
    );

    final notes = <DvmPendingItem>[];

    if (events.isNotEmpty) {
      try {
        final decryptedContent = await Nip44v2.decrypt(
          events.first.content,
          dvmMasterResponse!.mailboxKey,
        );

        final result = DvmPendingPagesResult.fromJson(decryptedContent);

        if (result.rev == scheduleState.rev) {
          for (final item in result.pending) {
            if (item.jobType == 'note') {
              notes.add(item);
            }
          }
        }
      } catch (err) {
        lg.e('Decryption failed for bucket event: $err');
      }
    }

    emit(state.copyWith(notes: notes, isLoading: false));
  }

  Future<bool> deleteNote(String jobId) async {
    final cancel = BotToastUtils.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: jobId,
      pTag: DEFAULT_SCHEDULE_DVM_PUBKEY,
    );

    cancel.call();

    if (isSuccessful) {
      _updateScheduledNotes();

      return true;
    } else {
      BotToastUtils.showError(
        t.errorDeletingContent.capitalizeFirst(),
      );
      return false;
    }
  }

  Future<void> publishNote(DvmPendingItem item) async {
    final cancel = BotToastUtils.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: item.jobId,
      pTag: DEFAULT_SCHEDULE_DVM_PUBKEY,
    );

    if (isSuccessful) {
      final event = await Event.genEvent(
        kind: EventKind.TEXT_NOTE,
        tags: item.notePreview.tags,
        content: item.notePreview.content,
        signer: currentSigner,
      );

      if (event == null) {
        BotToastUtils.showError(
          t.errorSendingEvent.capitalizeFirst(),
        );

        cancel.call();
        return;
      }

      final sent = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
        relays: item.relays,
      );

      cancel.call();

      if (sent) {
        BotToastUtils.showSuccess(t.notePublished.capitalizeFirst());
        _updateScheduledNotes();
      } else {
        BotToastUtils.showError(
          t.errorSendingEvent.capitalizeFirst(),
        );
      }
    } else {
      BotToastUtils.showError(
        t.errorDeletingContent.capitalizeFirst(),
      );
    }
  }

  Future<void> rescheduleNote(DvmPendingItem item, DateTime newDate) async {
    final cancel = BotToastUtils.showLoading();

    try {
      final isSuccessful = await NostrFunctionsRepository.deleteEvent(
        eventId: item.jobId,
        pTag: DEFAULT_SCHEDULE_DVM_PUBKEY,
      );

      if (isSuccessful) {
        final event = await Event.genEvent(
          kind: EventKind.TEXT_NOTE,
          tags: item.notePreview.tags,
          content: item.notePreview.content,
          signer: currentSigner,
          createdAt: newDate.toSecondsSinceEpoch(),
        );

        if (event == null) {
          BotToastUtils.showError(
            t.errorSendingEvent.capitalizeFirst(),
          );

          return;
        }

        final giftWrap = await dvmMasterResponse!.generateScheduleEvent(
          relays: item.relays,
          event: event,
          dvmPubkey: DEFAULT_SCHEDULE_DVM_PUBKEY,
          signer: currentSigner!,
        );

        if (giftWrap == null) {
          BotToastUtils.showError(
            t.errorSendingEvent.capitalizeFirst(),
          );

          return;
        }

        final sent = await NostrFunctionsRepository.sendEvent(
          event: giftWrap,
          relays: dvmMasterResponse!.relays,
          setProgress: true,
        );

        if (sent) {
          BotToastUtils.showSuccess(t.noteScheduled.capitalizeFirst());
          _updateScheduledNotes();
        } else {
          BotToastUtils.showError(
            t.errorSendingEvent.capitalizeFirst(),
          );
        }
      } else {
        BotToastUtils.showError(
          t.errorDeletingContent.capitalizeFirst(),
        );
      }
    } finally {
      cancel.call();
    }
  }

  Future<void> _updateScheduledNotes() async {
    Future.delayed(const Duration(seconds: 2)).then(
      (_) {
        getScheduledNotes();
      },
    );
  }

  // Future<void> getBucket(String bucket) async {
  //   lg.i(bucket);
  //   final events = await NostrFunctionsRepository.getEventsAsync(
  //     kinds: [EventKind.APP_CUSTOM],
  //     pubkeys: [DEFAULT_SCHEDULE_DVM_PUBKEY],
  //     dTags: ['pidgeon:v3:mb:${dvmMasterResponse!.mb}:bucket:$bucket'],
  //     includeIds: false,
  //   );

  //   for (final e in events) {
  //     try {
  //       final decryptedContent = await Nip44v2.decrypt(
  //         e.content,
  //         dvmMasterResponse!.mailboxKey,
  //       );

  //       lg.i(jsonDecode(decryptedContent));
  //     } catch (err) {
  //       lg.e('Decryption failed for bucket event: $err');
  //     }
  //   }
  // }
}
