import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/utils/enums.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'subscription_badge_state.dart';

/// Maps pubkeys to their YakiHonne subscription plan (NIP-58 badge award by
/// the gateway pubkey), so the badge can be shown anywhere a user is
/// rendered instead of only on the profile view.
class SubscriptionBadgeCubit extends Cubit<SubscriptionBadgeState> {
  SubscriptionBadgeCubit() : super(const SubscriptionBadgeState());

  final Set<String> _pending = {};

  Future<void> fetchPlan(String pubkey) async {
    if (pubkey.isEmpty ||
        state.plans.containsKey(pubkey) ||
        _pending.contains(pubkey)) {
      return;
    }

    _pending.add(pubkey);

    try {
      final gatewayPubkey = dotenv.env['YAKI_GATEWAY_PUBKEY'] ?? '';
      if (gatewayPubkey.isEmpty) {
        _mark(pubkey, '', '');
        return;
      }

      final awardEvents = await NostrFunctionsRepository.getEventsAsync(
        kinds: [EventKind.BADGE_AWARD],
        pubkeys: [gatewayPubkey],
        pTags: [pubkey],
        limit: 1,
        relays: constantRelays.toList(),
        source: EventsSource.all,
      );

      if (awardEvents.isEmpty) {
        _mark(pubkey, '', '');
        return;
      }

      // "a" tag format per NIP-58: "30009:<gateway_pubkey>:<d-tag>"
      final aTag = awardEvents.first.tags
          .firstWhere((t) => t.isNotEmpty && t[0] == 'a', orElse: () => []);
      final parts = aTag.length >= 2 ? aTag[1].split(':') : <String>[];
      if (parts.length < 3) {
        _mark(pubkey, '', '');
        return;
      }

      final plan = parts[2];

      final definitionEvents = await NostrFunctionsRepository.getEventsAsync(
        kinds: [EventKind.BADGE_DEFINITION],
        pubkeys: [gatewayPubkey],
        dTags: [plan],
        limit: 1,
        relays: constantRelays.toList(),
        source: EventsSource.all,
      );

      String badgeImageUrl = '';
      if (definitionEvents.isNotEmpty) {
        final imageTag = definitionEvents.first.tags.firstWhere(
          (t) => t.isNotEmpty && t[0] == 'image',
          orElse: () => [],
        );
        if (imageTag.length >= 2) {
          badgeImageUrl = imageTag[1];
        }
      }

      _mark(pubkey, plan, badgeImageUrl);
    } catch (e) {
      lg.i('SubscriptionBadgeCubit.fetchPlan: $e');
      _mark(pubkey, '', '');
    } finally {
      _pending.remove(pubkey);
    }
  }

  void _mark(String pubkey, String plan, String imageUrl) {
    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        plans: {...state.plans, pubkey: plan},
        badgeImages: {...state.badgeImages, pubkey: imageUrl},
      ),
    );
  }
}
