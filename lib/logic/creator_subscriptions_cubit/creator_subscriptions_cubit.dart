import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/creator_subscription_models.dart';
import '../../repositories/http_functions_repository.dart';

part 'creator_subscriptions_state.dart';

/// The current user's subscriptions to other creators (as opposed to
/// [SubscriptionCubit], which tracks the user's own YakiHonne app plan).
/// Global so any view can check subscription status without refetching.
class CreatorSubscriptionsCubit extends Cubit<CreatorSubscriptionsState> {
  CreatorSubscriptionsCubit() : super(const CreatorSubscriptionsState());

  Future<void> fetch({bool force = false}) async {
    if (state.isLoading || (state.hasFetched && !force)) {
      return;
    }

    emit(state.copyWith(isLoading: true));

    final res = await HttpFunctionsRepository.getSubscriberSubscriptions();

    if (isClosed) {
      return;
    }

    emit(state.copyWith(
      subscriptions: res.subscriptions,
      isLoading: false,
      hasFetched: true,
    ));
  }

  bool isSubscribedTo(String creatorPubkey) {
    return state.subscriptions
        .any((s) => s.creatorPubkey == creatorPubkey && s.isActive);
  }

  /// Drops the cached list on disconnect/account switch — the next [fetch]
  /// (post-login) repopulates it for whoever signs in next.
  void clear() {
    if (!isClosed) {
      emit(const CreatorSubscriptionsState());
    }
  }
}
