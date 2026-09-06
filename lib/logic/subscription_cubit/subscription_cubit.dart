import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/points_system_models.dart';
import '../../models/subscription_models.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/utils.dart';

part 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit() : super(const SubscriptionState());

  bool get isPremium =>
      state.subscriptionStatus?.plan == 'premium' &&
      (state.subscriptionStatus?.active ?? false);

  bool get isBasic =>
      state.subscriptionStatus?.plan == 'basic' &&
      (state.subscriptionStatus?.active ?? false);

  bool get isPaid => isBasic || isPremium;

  void emitOnlineStats(SubscriptionStatus status) {
    emit(state.copyWith(subscriptionStatus: status));
  }

  /// Called on login and app start — loads subscription status for feature gating.
  Future<void> refreshStatus() async {
    emit(state.copyWith(refreshing: true));
    try {
      final data = await HttpFunctionsRepository.getUserStats();
      if (data != null) {
        pointsManagementCubit.setUserStats(data);

        emit(state.copyWith(
          subscriptionStatus: data.subscriptionStatus,
          refreshing: false,
        ));
      } else {
        emit(state.copyWith(refreshing: false));
      }
    } catch (e) {
      lg.i('SubscriptionCubit.refreshStatus: $e');
      emit(state.copyWith(refreshing: false));
    }
  }

  /// Called when the user opens SubscriptionView — loads both status and usage in parallel.
  Future<void> loadViewData() async {
    emit(state.copyWith(refreshing: true, usageRefreshing: true));
    final results = await Future.wait([
      HttpFunctionsRepository.getUserStats(),
      HttpFunctionsRepository.subscriptionGetUsage(),
    ]);

    final userStats = results[0] as UserGlobalStats?;
    final usageData = results[1] as UsageData?;

    emit(state.copyWith(
      subscriptionStatus: userStats?.subscriptionStatus,
      usageData: usageData,
      refreshing: false,
      usageRefreshing: false,
    ));
  }

  Future<void> refreshUsage() async {
    emit(state.copyWith(usageRefreshing: true));
    try {
      final data = await HttpFunctionsRepository.subscriptionGetUsage();
      emit(state.copyWith(usageData: data, usageRefreshing: false));
    } catch (e) {
      lg.i('SubscriptionCubit.refreshUsage: $e');
      emit(state.copyWith(usageRefreshing: false));
    }
  }

  void setUsageData(UsageData data) {
    emit(state.copyWith(usageData: data));
  }

  void reset() {
    emit(const SubscriptionState());
  }
}
