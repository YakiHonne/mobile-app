import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  void emitOnlineStats(UserOnlineStats stats) {
    emit(state.copyWith(subscriptionStatus: stats.subscriptionStatus));
  }

  /// Called on login and app start — loads subscription status for feature gating.
  Future<void> refreshStatus() async {
    emit(state.copyWith(refreshing: true));
    try {
      final data = await HttpFunctionsRepository.getUserOnlineStats();
      if (data != null) {
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
      HttpFunctionsRepository.getUserOnlineStats(),
      HttpFunctionsRepository.subscriptionGetUsage(),
    ]);

    final onlineStats = results[0] as UserOnlineStats?;
    final usageData = results[1] as UsageData?;

    emit(state.copyWith(
      subscriptionStatus: onlineStats?.subscriptionStatus,
      usageData: usageData,
      refreshing: false,
      usageRefreshing: false,
    ));
  }

  void reset() {
    emit(const SubscriptionState());
  }
}
