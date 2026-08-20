import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/points_system_models.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/app_cycle.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'points_management_state.dart';

class PointsManagementCubit extends Cubit<PointsManagementState> {
  PointsManagementCubit()
      : super(
          const PointsManagementState(
            isUpdated: true,
            isNew: false,
            currentXp: 0,
            standards: [],
            additionalXp: 0,
            currentLevel: 0,
            currentLevelXp: 0,
            nextLevelXp: 0,
            percentage: 0,
            consumablePoints: 0,
          ),
        ) {
    setZapsToPointsSubscription();
  }

  final _appLifecycleNotifier = AppLifecycleNotifier();
  StreamSubscription? _appLifeCycle;
  List<ZapsToPoints> zapsToPointsList = [];
  String? id;

  Future<void> login({
    required Function() onSuccess,
  }) async {
    if (!isClosed) {
      emit(
        state.copyWith(
          isUpdated: !state.isUpdated,
        ),
      );
    }

    final res = await HttpFunctionsRepository.loginToAppSystem();

    if (res != null) {
      BotToastUtils.showSuccess(
        t.loggedToYakiChest.capitalizeFirst(),
      );

      if (!isClosed) {
        emit(state.copyWith(isSystemLoggedIn: true));
      }

      getRecentStats();
      subscriptionCubit.refreshStatus();

      final isNew = (res['isNew'] as bool?) ?? false;
      final actions = (res['actions'] as List?) ?? <PointAction>[];

      if (isNew && actions.isNotEmpty) {
        final int currentXp = res['xp'] ?? 0;

        final currentLevel = getCurrentLevel(currentXp);
        final currentLevelXp = getRemainingXp(currentLevel);
        final additionalXp = currentXp - currentLevelXp;
        final nextLevelXp = getRemainingXp(currentLevel + 1);

        if (!isClosed) {
          emit(
            state.copyWith(
              currentXp: currentXp,
              percentage: additionalXp / (nextLevelXp - currentLevelXp),
              currentLevel: currentLevel,
              userGlobalStats: state.userGlobalStats,
              isNew: true,
            ),
          );
        }
      } else {
        onSuccess.call();
      }
    } else {
      BotToastUtils.showError(
        t.errorLoggingYakiChest.capitalizeFirst(),
      );
    }
  }

  void setZapsToPointsSubscription() {
    _appLifeCycle = _appLifecycleNotifier.lifecycleStream.listen(
      (appState) {
        if (appState == AppLifecycleState.resumed) {
          checkZapsToPoints();
        }
      },
    );
  }

  void checkZapsToPoints({List<ZapsToPoints>? zapsToPoints}) {
    if (state.userGlobalStats != null) {
      if (zapsToPoints != null) {
        zapsToPointsList.addAll(zapsToPoints);
      }

      for (int i = 0; i < zapsToPointsList.length; i++) {
        if (zapsToPointsList[i].shouldBeDeleted()) {
          zapsToPointsList.removeAt(i);
        }
      }

      if (zapsToPointsList.isNotEmpty) {
        NostrFunctionsRepository.sendZapsToPoints(
          zapsToPointsList: zapsToPointsList,
          id: id,
        );
      }
    }
  }

  void sendZapsPoints(num sats) {
    try {
      String zapCode = '';
      if (sats >= 1 && sats <= 20) {
        zapCode = PointsActions.ZAP1;
      } else if (sats >= 21 && sats <= 60) {
        zapCode = PointsActions.ZAP20;
      } else if (sats >= 61 && sats <= 100) {
        zapCode = PointsActions.ZAP60;
      } else {
        zapCode = PointsActions.ZAP100;
      }

      HttpFunctionsRepository.sendAction(zapCode);
    } catch (e) {
      lg.i(e);
    }
  }

  Future<void> logout() async {
    try {
      await HttpFunctionsRepository.logoutAppSystem().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {}

    _appLifeCycle?.cancel();
    zapsToPointsList.clear();

    if (id != null) {
      nc.closeRequests([id!]);
    }
    if (!isClosed) {
      emit(
        const PointsManagementState(
          isUpdated: true,
          isNew: false,
          currentXp: 0,
          standards: [],
          additionalXp: 0,
          currentLevel: 0,
          currentLevelXp: 0,
          nextLevelXp: 0,
          percentage: 0,
          consumablePoints: 0,
        ),
      );
    }
  }

  void setUserStats(UserGlobalStats? userStats) {
    if (userStats != null) {
      final currentLevel = userStats.currentLevel();
      final currentXp = userStats.xp;
      final currentLevelXp = getRemainingXp(currentLevel);
      final additionalXp = currentXp - currentLevelXp;
      final nextLevelXp = getRemainingXp(currentLevel + 1);
      final points = userStats.currentPoints;
      if (!isClosed) {
        emit(
          state.copyWith(
            isUpdated: !state.isUpdated,
            userGlobalStats: userStats,
            currentXp: currentXp.toInt(),
            currentLevel: currentLevel,
            additionalXp: additionalXp.toInt(),
            currentLevelXp: currentLevelXp,
            nextLevelXp: nextLevelXp,
            percentage: additionalXp / (nextLevelXp - currentLevelXp),
            consumablePoints: points.toInt(),
            isSystemLoggedIn: true,
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            isUpdated: !state.isUpdated,
            userGlobalStats: userStats,
          ),
        );
      }
    }
  }

  Future<void> getRecentStats() async {
    try {
      final online = await HttpFunctionsRepository.getUserOnlineStats();
      if (online != null) {
        subscriptionCubit.emitOnlineStats(online);
        if (!isClosed) {
          emit(state.copyWith(
            consumablePoints: online.consumablePoints.toInt(),
            currentXp: online.xp.toInt(),
          ));
        }
      }
      final userStats = await HttpFunctionsRepository.getUserStats();
      setUserStats(userStats);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _appLifeCycle?.cancel();
    return super.close();
  }
}
