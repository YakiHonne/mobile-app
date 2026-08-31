// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/checkout_cubit/checkout_cubit.dart';
import '../../../logic/metadata_cubit/metadata_cubit.dart';
import '../../../models/app_models/pricing_plan_model.dart';
import '../../../models/points_system_models.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import 'widgets/checkout_screen.dart';
import 'widgets/plan_card.dart';
import 'widgets/pricing_hero.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isLn = false;
  bool _isPoints = false;

  /// Points only. Store/Stripe/Lightning run inside [CheckoutScreen], which
  /// renders its own progress — this screen never spins for them.
  String? _loadingPlanId;
  PointsEligibility? _eligibility;
  List<PricingPlan> _plans = [];
  bool _plansLoading = true;
  late final PageController _pageCtrl;
  int _page = 1;

  bool get _useIap => kIapEnabled;

  late final Future<void> _accountSessionFuture;

  @override
  void initState() {
    super.initState();
    // Slightly under a full page so the neighbouring cards peek in on both
    // sides, making the horizontal swipe discoverable. Page 1 (the first
    // fetched plan) is the entry point — the hard-coded free card sits on the
    // left edge.
    _pageCtrl = PageController(viewportFraction: 0.88, initialPage: 1)
      ..addListener(() {
        final p = _pageCtrl.page?.round() ?? 1;
        if (p != _page) {
          setState(() => _page = p);
        }
      });
    _fetchPlans();
    _fetchEligibility();
    _accountSessionFuture = _ensureAccountSession();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureAccountSession() async {
    if (currentSigner?.canSign() ?? false) {
      await HttpFunctionsRepository.loginToAppSystem();
    }
  }

  Future<void> _fetchPlans() async {
    final result = await HttpFunctionsRepository.getSubscriptionPlans();
    if (mounted) {
      setState(() {
        _plans = result;
        _plansLoading = false;
      });
    }
  }

  Future<void> _fetchEligibility() async {
    try {
      final result = await HttpFunctionsRepository.getSubscriptionEligibility();
      if (mounted) {
        setState(() => _eligibility = result);
      }
    } catch (_) {}
  }

  /// Points redeem here — it's a plain REST call with no store queue behind it.
  /// Everything else is handed to [CheckoutScreen], which owns the purchase
  /// stream for exactly as long as that one purchase is in flight.
  Future<void> _checkout(PricingPlan plan) async {
    if (_isPoints) {
      setState(() => _loadingPlanId = plan.plan);
      try {
        await _accountSessionFuture;
        await _checkoutPoints(plan);
      } catch (e) {
        lg.i('[Points] checkout failed: $e');
        if (mounted) {
          setState(() => _loadingPlanId = null);
          BotToastUtils.showError(e.toString());
        }
      }
      return;
    }

    await Navigator.of(context).push(
      CheckoutScreen.route(
        plan: plan,
        method: _useIap
            ? CheckoutMethod.iap
            : _isLn
                ? CheckoutMethod.lightning
                : CheckoutMethod.stripe,
        accountSession: _accountSessionFuture,
      ),
    );
    if (mounted) {
      // The plan cards read subscription status, which the purchase may have
      // just changed.
      setState(() {});
    }
  }

  Future<void> _checkoutPoints(PricingPlan plan) async {
    try {
      final redeemed =
          await HttpFunctionsRepository.redeemSubscriptionWithPoints(plan.plan);
      if (!redeemed) {
        if (mounted) {
          setState(() => _loadingPlanId = null);
          BotToastUtils.showError(context.t.points_insufficient);
        }
        return;
      }
      await subscriptionCubit.refreshStatus();
      unawaited(pointsManagementCubit.getCurrenUserStats());
      _fetchEligibility();
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showSuccess(context.t.pricing_points_success);
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showError(
          (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
              context.t.pricing_error_checkout,
        );
      }
    }
  }

  /// Hard-coded free tier, always shown ahead of the backend-paid plans. It has
  /// no checkout path — a free user sees "Current Plan", a paid one sees a
  /// disabled "Downgrade" CTA (cancelling a sub reverts to this tier).
  PricingPlan _freePlan(BuildContext context) => (
        id: 'free',
        plan: 'free',
        priceId: '',
        productId: '',
        iapProductId: '',
        yakiproIapProductId: '',
        paymentProvider: 'free',
        name: context.t.pricing_free_name,
        price: context.t.pricing_free_price,
        satsRaw: 0,
        sats: '0',
        period: kPricingPeriod,
        desc: '',
        highlighted: false,
        features: [
          (text: context.t.pricing_free_feature_publishing, dim: false),
          (text: context.t.pricing_free_feature_nostr_identity, dim: false),
          (text: context.t.pricing_free_feature_classic_editor, dim: false),
          (text: context.t.pricing_free_feature_storage, dim: false),
          (text: context.t.pricing_free_feature_wallet, dim: false),
          (text: context.t.pricing_free_feature_translations, dim: false),
          (text: context.t.pricing_free_feature_points, dim: false),
        ],
      );

  Widget _planCard(
    PricingPlan plan,
    bool isActivePaidSub,
    String userPlan,
    bool isWebManaged, {
    bool scrollable = false,
  }) {
    final isFree = plan.plan == 'free';
    final pointsEligible =
        !isFree && _isPoints && (_eligibility?.eligibleFor(plan.plan) ?? false);
    return PlanCard(
      plan: plan,
      isLn: !isFree && !_useIap && _isLn,
      isPoints: !isFree && _isPoints,
      pointsCost: isFree ? 0 : (_eligibility?.costFor(plan.plan) ?? 0),
      pointsEligible: pointsEligible,
      isLoading: !isFree && _loadingPlanId == plan.plan,
      anyLoading: _loadingPlanId != null,
      isCurrent:
          isFree ? !isActivePaidSub : isActivePaidSub && userPlan == plan.plan,
      isUpgrade: !isFree &&
          isActivePaidSub &&
          plan.plan == 'premium' &&
          userPlan == 'basic',
      showButton: !isFree,
      showApprox: !isFree,
      scrollable: scrollable,
      onCheckout: isFree || (isWebManaged || (_isPoints && !pointsEligible))
          ? null
          : () => _checkout(plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final pubkey = currentSigner?.getPublicKey() ?? '';
    final plans = [_freePlan(context), ..._plans];
    final userPlan = subscriptionCubit.state.subscriptionStatus?.plan ?? '';
    final lastPaymentMethod =
        subscriptionCubit.state.subscriptionStatus?.lastPaymentMethod ?? '';
    final isActivePaidSub =
        subscriptionCubit.state.subscriptionStatus?.isActivePaidSub ?? false;
    final isWebManaged = _useIap &&
        isActivePaidSub &&
        lastPaymentMethod != 'iap' &&
        lastPaymentMethod != 'points';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BlocBuilder<MetadataCubit, MetadataState>(
                bloc: metadataCubit,
                builder: (context, metaState) {
                  final meta = metaState.metadataCache[pubkey];
                  final picture = meta?.picture ?? '';
                  final displayName = meta?.displayName ?? '';
                  final name =
                      (displayName.isNotEmpty ? displayName : meta?.name) ?? '';
                  return PricingHeroHeader(
                    picture: picture,
                    name: name,
                    pubkey: pubkey,
                    isLn: _isLn,
                    isPoints: _isPoints,
                    onToggleLn: _useIap
                        ? null
                        : (v) => setState(() {
                              _isLn = v;
                              if (v) {
                                _isPoints = false;
                              }
                            }),
                    onTogglePoints: (!_useIap && _eligibility != null)
                        ? (v) => setState(() {
                              _isPoints = v;
                              if (v) {
                                _isLn = false;
                              }
                            })
                        : null,
                    onClose: () => Navigator.of(context).pop(),
                  );
                },
              ),
            ),
            if (isWebManaged)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    kDefaultPadding,
                    kDefaultPadding,
                    kDefaultPadding,
                    0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  ),
                  child: Text(
                    context.t.pricing_web_managed,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.primaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (_plansLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding * 2),
                  child: Center(
                      child: SpinKitCircle(
                          color: theme.primaryColorDark, size: 32)),
                ),
              )
            else if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    kDefaultPadding, kDefaultPadding, kDefaultPadding, 0),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          (constraints.maxWidth - kDefaultPadding / 2) / 2;
                      return Wrap(
                        spacing: kDefaultPadding / 2,
                        runSpacing: kDefaultPadding / 2,
                        children: [
                          for (final plan in plans)
                            SizedBox(
                              width: itemWidth,
                              child: _planCard(plan, isActivePaidSub, userPlan,
                                  isWebManaged),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 500,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    // Default padEnds keeps the focused card centred, so the
                    // previous and next cards both peek in around it.
                    itemCount: plans.length,
                    itemBuilder: (context, i) {
                      final plan = plans[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          kDefaultPadding / 2,
                          kDefaultPadding,
                          kDefaultPadding / 2,
                          kDefaultPadding / 2,
                        ),
                        child: _planCard(
                          plan,
                          isActivePaidSub,
                          userPlan,
                          isWebManaged,
                          scrollable: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (plans.length > 1)
                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < plans.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: i == _page ? 18 : 6,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? theme.primaryColor
                                : theme.dividerColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  kDefaultPadding,
                  kDefaultPadding,
                  bottomPad + kDefaultPadding,
                ),
                child: Column(
                  spacing: kDefaultPadding / 4,
                  children: [
                    const _PaywallLegalLinks(),
                    Text(
                      context.t.pricing_footer,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Terms of Use and Privacy Policy links, mandatory on any auto-renewable
/// subscription paywall (App Store guideline 3.1.2).
///
/// ponytail: plain TextButtons over a rich-text span — the strings already
/// exist in every locale and a span would need a per-locale split point.
class _PaywallLegalLinks extends StatelessWidget {
  const _PaywallLegalLinks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.hintColor,
      decoration: TextDecoration.underline,
      decorationColor: theme.hintColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kDefaultPadding / 4,
      children: [
        TextButton(
          onPressed: () => openWebPage(url: termsUrl, openInternal: false),
          child: Text(context.t.termsAndConditions, style: style),
        ),
        TextButton(
          onPressed: () => openWebPage(url: privacyUrl, openInternal: false),
          child: Text(context.t.privacyPolicies, style: style),
        ),
      ],
    );
  }
}
