// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/uncensored_notes_models.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../uncensored_notes_cubit/uncensored_notes_cubit.dart';

part 'rewards_state.dart';

class RewardsCubit extends Cubit<RewardsState> {
  RewardsCubit({
    required this.uncensoredNotesCubit,
  }) : super(
          RewardsState(
            rewards: const [],
            updatingState: UpdatingState.progress,
            refresh: false,
            loadingClaims: const {},
            initNotePrice: nostrRepository.initNotePrice,
            initRatingPrice: nostrRepository.initRatingPrice,
            sealedNotePrice: nostrRepository.sealedNotePrice,
            sealedRatingPrice: nostrRepository.sealedRatingPrice,
          ),
        );

  final UncensoredNotesCubit uncensoredNotesCubit;

  Future<void> initView() async {
    try {
      if (!isClosed) {
        emit(
          state.copyWith(
            updatingState: UpdatingState.progress,
          ),
        );
      }

      final results = await HttpFunctionsRepository.getRewards(
        currentSigner!.getPublicKey(),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            rewards: results,
            updatingState: UpdatingState.success,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            updatingState: UpdatingState.failure,
          ),
        );
      }
    }
  }

  Future<void> claimReward({
    required String eventId,
    required int kind,
  }) async {
    try {
      if (!isClosed) {
        emit(
          state.copyWith(
            loadingClaims: Set.from(state.loadingClaims)..add(eventId),
          ),
        );
      }

      String encoredData = '';
      final data = {
        'pubkey': currentSigner!.getPublicKey(),
        'event_id': eventId,
        'kind': kind,
      };

      if (nostrRepository.isUsingExternalSigner) {
        final nip04 = await Amberflutter().nip04Encrypt(
          plaintext: jsonEncode(data),
          currentUser: currentSigner!.getPublicKey(),
          pubKey: yakihonneHex,
        );

        final encryptedText = nip04['signature'] as String?;

        if (encryptedText != null && encryptedText.isNotEmpty) {
          encoredData = encryptedText;
        }
      } else {
        encoredData = await currentSigner!.encrypt04(
              jsonEncode(data),
              yakihonneHex,
            ) ??
            '';
      }

      if (encoredData.isEmpty) {
        BotToastUtils.showError(
          t.errorClaimingReward.capitalizeFirst(),
        );
        if (!isClosed) {
          emit(
            state.copyWith(
              loadingClaims: Set.from(state.loadingClaims)..remove(eventId),
            ),
          );
        }

        return;
      }

      final result = await HttpFunctionsRepository.claimReward(
        pubkey: currentSigner!.getPublicKey(),
        encodedMessage: encoredData,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            loadingClaims: Set.from(state.loadingClaims)..remove(eventId),
          ),
        );
      }

      if (result) {
        initView();
        uncensoredNotesCubit.getBalance();
      } else {
        BotToastUtils.showError(t.errorClaimingReward.capitalizeFirst());
      }
    } on DioException catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loadingClaims: Set.from(state.loadingClaims)..remove(eventId),
          ),
        );
      }

      BotToastUtils.showError(
        t.errorClaimingReward.capitalizeFirst(),
      );
    }
  }
}
