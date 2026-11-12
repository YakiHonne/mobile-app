import '../../models/subscription_models.dart';

/// Desktop uses the existing external checkout even in store-enabled builds.
bool usesNativeSubscriptionStore({
  required bool desktop,
  required bool iapEnabled,
}) =>
    iapEnabled && !desktop;

/// Existing recurring subscriptions must be managed before starting another.
bool blocksDesktopCardCheckout(SubscriptionStatus? status) =>
    status != null &&
    status.active &&
    (status.lastPaymentMethod == 'iap' || status.lastPaymentMethod == 'stripe');
