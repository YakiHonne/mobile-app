// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../logic/checkout_cubit/checkout_cubit.dart';
import '../../../logic/subscription_cubit/subscription_cubit.dart';
import '../../../models/subscription_models.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/theme/custom/buttons_theme.dart';
import '../../../utils/utils.dart';

// ── Date helpers ──────────────────────────────────────────────────────────────

const _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String fmtSubDate(int ts) {
  if (ts == 0) {
    return '—';
  }
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return '${_kMonths[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ── Local primitives ──────────────────────────────────────────────────────────

const double _kGroupRadius = 12.0;
const int _kPaymentsPerPage = 5;

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding,
          kDefaultPadding, kDefaultPadding / 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.hintColor,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(_kGroupRadius),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: kDefaultPadding,
                  color: theme.dividerColor),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing});
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding, vertical: kDefaultPadding / 2 + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          trailing,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Plan badge ────────────────────────────────────────────────────────────────

class PlanBadge extends StatelessWidget {
  const PlanBadge({super.key, required this.plan});
  final String plan;

  static const _kOrange = Color(0xFFf97316);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg, fg;
    if (plan == 'premium') {
      bg = _kOrange.withValues(alpha: 0.15);
      fg = _kOrange;
    } else {
      bg = theme.cardColor;
      fg = theme.hintColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Text(
        plan[0].toUpperCase() + plan.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Payment method label ──────────────────────────────────────────────────────

class PaymentMethodLabel extends StatelessWidget {
  const PaymentMethodLabel({super.key, required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (method == 'lightning') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.zap, size: 14, color: theme.hintColor),
        const SizedBox(width: kDefaultPadding / 4),
        Text(context.t.settings_payment_method_lightning,
            style: theme.textTheme.bodySmall),
      ]);
    }
    if (method == 'stripe') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.creditCard, size: 14, color: theme.hintColor),
        const SizedBox(width: kDefaultPadding / 4),
        Text(context.t.settings_payment_method_card,
            style: theme.textTheme.bodySmall),
      ]);
    }
    if (method == 'iap') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Platform.isIOS ? Icons.apple : Icons.android,
            size: 14, color: theme.hintColor),
        const SizedBox(width: kDefaultPadding / 4),
        Text(Platform.isIOS ? 'App Store' : 'Google Play',
            style: theme.textTheme.bodySmall),
      ]);
    }
    if (method == 'points') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.trophy, size: 14, color: theme.hintColor),
        const SizedBox(width: kDefaultPadding / 4),
        Text(context.t.settings_payment_method_points,
            style: theme.textTheme.bodySmall),
      ]);
    }
    return Text('—',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor));
  }
}

// ── Main section ──────────────────────────────────────────────────────────────

class SubscriptionSection extends StatefulWidget {
  const SubscriptionSection({super.key, required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  State<SubscriptionSection> createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<SubscriptionSection> {
  bool _cancelling = false;
  bool _resuming = false;
  bool _managingBilling = false;
  String? _changingPlan;
  bool _cancellingChange = false;
  bool _restoringPurchases = false;
  bool _restoreValidatedAny = false;
  bool _restoreOwnedByOtherAccount = false;
  bool _restoreAnotherActive = false;

  // Restore purchases re-delivers store transactions through the purchase
  // stream, so a listener is subscribed only for the duration of an explicit
  // restore — never persistently — to avoid double-processing transactions
  // with CheckoutScreen's CheckoutCubit listener when both routes are mounted.
  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  Future<void> _handleRestoreUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          switch (await validateIapPurchase(purchase)) {
            case IapValidation.valid:
              _restoreValidatedAny = true;
            case IapValidation.otherAccount:
              _restoreOwnedByOtherAccount = true;
            case IapValidation.anotherActive:
              // Already subscribed via the companion app — the account is
              // entitled, so the "already active" branch below covers it.
              _restoreAnotherActive = true;
            case IapValidation.invalid:
              break;
          }

        case PurchaseStatus.pending:
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  /// Re-reads status from the backend (not the cached state, which predates
  /// the restore) and reports whether the account is already entitled.
  Future<bool> _hasActiveSubscription() async {
    await subscriptionCubit.refreshStatus();
    final status = subscriptionCubit.state.subscriptionStatus;
    return status != null && status.active;
  }

  Future<void> _restorePurchases() async {
    setState(() => _restoringPurchases = true);
    _restoreValidatedAny = false;
    _restoreOwnedByOtherAccount = false;
    _restoreAnotherActive = false;
    _iapSub = InAppPurchase.instance.purchaseStream.listen(
      _handleRestoreUpdate,
      onError: (_) {},
    );
    var restoreThrew = false;
    try {
      await InAppPurchase.instance.restorePurchases();
      // The store may deliver transactions slightly after the restore future
      // resolves — keep listening briefly so late events are still handled.
      await Future<void>.delayed(const Duration(seconds: 2));
    } catch (e) {
      restoreThrew = true;
      lg.i('[IAP] restorePurchases error: $e');
    } finally {
      await _iapSub?.cancel();
      _iapSub = null;

      // Entitlement lives on the account, not on this app's store queue: a
      // subscription bought in the companion app never appears in this app's
      // receipts, so an empty queue is not proof the user isn't subscribed.
      // Re-check the backend before reporting failure.
      // A "another subscription is active" rejection is itself proof of
      // entitlement, so it needs no extra status round-trip.
      final alreadyEntitled = !_restoreValidatedAny &&
          !_restoreOwnedByOtherAccount &&
          (_restoreAnotherActive || await _hasActiveSubscription());

      if (mounted) {
        setState(() => _restoringPurchases = false);
        if (_restoreValidatedAny) {
          subscriptionCubit.refreshStatus();
        } else if (alreadyEntitled) {
          BotToastUtils.showSuccess(context.t.pricing_restore_already_active);
        } else if (_restoreOwnedByOtherAccount) {
          // The store had a valid purchase but the backend has it bound to a
          // different pubkey. Retrying can never succeed, so say why rather
          // than showing the "nothing found" message.
          BotToastUtils.showError(context.t.pricing_restore_other_account);
        } else {
          // A store failure and an empty queue are different outcomes: the
          // first is worth retrying, the second means there is nothing to find.
          BotToastUtils.showError(
            restoreThrew
                ? context.t.pricing_error_restore_failed
                : context.t.pricing_restore_nothing,
          );
        }
      }
    }
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    final ok = await HttpFunctionsRepository.subscriptionCancel();
    if (ok) {
      BotToastUtils.showSuccess(context.t.sub_cancel_success);
      subscriptionCubit.refreshStatus();
    } else {
      BotToastUtils.showError(context.t.sub_action_failed);
    }
    if (mounted) {
      setState(() => _cancelling = false);
    }
  }

  Future<void> _resume() async {
    setState(() => _resuming = true);
    final ok = await HttpFunctionsRepository.subscriptionResume();
    if (ok) {
      BotToastUtils.showSuccess(context.t.sub_resume_success);
      subscriptionCubit.refreshStatus();
    } else {
      BotToastUtils.showError(context.t.sub_action_failed);
    }
    if (mounted) {
      setState(() => _resuming = false);
    }
  }

  Future<void> _manageBilling() async {
    setState(() => _managingBilling = true);
    final url = await HttpFunctionsRepository.subscriptionGetBillingPortal();
    if (mounted) {
      setState(() => _managingBilling = false);
    }
    if (url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      BotToastUtils.showError(context.t.sub_action_failed);
    }
  }

  Future<void> _changePlan(String planId, String priceId) async {
    setState(() => _changingPlan = planId);
    final ok = await HttpFunctionsRepository.subscriptionChangePlan(
      newPlan: planId,
      newPriceId: priceId,
    );
    if (ok) {
      BotToastUtils.showSuccess(context.t.sub_change_success);
      subscriptionCubit.refreshStatus();
    } else {
      BotToastUtils.showError(context.t.sub_action_failed);
    }
    if (mounted) {
      setState(() => _changingPlan = null);
    }
  }

  Future<void> _cancelChange() async {
    setState(() => _cancellingChange = true);
    final ok = await HttpFunctionsRepository.subscriptionCancelPendingChange();
    if (ok) {
      BotToastUtils.showSuccess(context.t.sub_change_success);
      subscriptionCubit.refreshStatus();
    } else {
      BotToastUtils.showError(context.t.sub_action_failed);
    }
    if (mounted) {
      setState(() => _cancellingChange = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      buildWhen: (p, c) =>
          p.subscriptionStatus != c.subscriptionStatus ||
          p.refreshing != c.refreshing,
      builder: (context, state) {
        final theme = Theme.of(context);

        if (state.refreshing && state.subscriptionStatus == null) {
          return Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 2),
            child: Center(
                child: SpinKitCircle(color: theme.primaryColor, size: 32)),
          );
        }

        if (state.subscriptionStatus == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(kDefaultPadding,
                kDefaultPadding * 2, kDefaultPadding, kDefaultPadding),
            child: Column(
              children: [
                Icon(LucideIcons.wifiOff, size: 36, color: theme.hintColor),
                const SizedBox(height: kDefaultPadding / 2 + 2),
                Text(
                  context.t.sub_load_error,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding / 2 + 2),
                OutlinedButton(
                  onPressed: subscriptionCubit.refreshStatus,
                  child: Text(context.t.sub_retry),
                ),
              ],
            ),
          );
        }

        final s = state.subscriptionStatus!;
        final isStripeActive = s.lastPaymentMethod == 'stripe' && s.active;
        final isIapActive = s.lastPaymentMethod == 'iap' && s.active;
        final showStripeControls = isStripeActive && !kIapEnabled;
        final isPointsActive = s.lastPaymentMethod == 'points' && s.active;
        final showWebManagedBanner = kIapEnabled &&
            s.active &&
            !isIapActive &&
            !isPointsActive &&
            !s.inTrial &&
            s.lastPaymentMethod.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(context.t.sub_current_plan),
            _CurrentPlanGroup(status: s),
            if (s.inTrial || s.cancelAtPeriodEnd) ...[
              const SizedBox(height: kDefaultPadding / 2 - 2),
              _SubStatusBanner(status: s),
            ],
            if (!(s.inTrial || showStripeControls)) ...[
              const SizedBox(height: kDefaultPadding / 2 - 2),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: widget.onUpgrade,
                    child: Text(s.active
                        ? context.t.sub_manage_subscription
                        : context.t.pricing_cta_subscribe),
                  ),
                ),
              ),
            ],
            if (s.active &&
                (s.nextSubscription > 0 ||
                    s.lastPaymentMethod.isNotEmpty ||
                    s.lastSubscription > 0)) ...[
              _SectionLabel(context.t.sub_billing_details),
              _GroupCard(
                children: [
                  if (!s.cancelAtPeriodEnd && s.nextSubscription > 0)
                    _Row(
                        label: context.t.sub_next_renewal,
                        trailing: Text(fmtSubDate(s.nextSubscription),
                            style: theme.textTheme.bodySmall)),
                  if (s.lastPaymentMethod.isNotEmpty)
                    _Row(
                        label: context.t.sub_payment_method,
                        trailing:
                            PaymentMethodLabel(method: s.lastPaymentMethod)),
                  if (s.lastSubscription > 0)
                    _Row(
                        label: context.t.sub_last_payment,
                        trailing: Text(fmtSubDate(s.lastSubscription),
                            style: theme.textTheme.bodySmall)),
                  if (showStripeControls)
                    _BillingActionsGroup(
                      status: s,
                      cancelling: _cancelling,
                      resuming: _resuming,
                      managingBilling: _managingBilling,
                      onCancel: () => _showCancelConfirm(context, s),
                      onResume: _resume,
                      onManageBilling: _manageBilling,
                    ),
                ],
              ),
            ],
            if (s.hasPendingChange) ...[
              _SectionLabel(context.t.sub_pending_change),
              _PendingChangeGroup(
                  status: s,
                  cancellingChange: _cancellingChange,
                  onCancelChange: _cancelChange),
            ],
            if (showStripeControls) ...[
              _SectionLabel(context.t.sub_manage_plans),
              _PlanSwitcherGroup(
                  status: s,
                  changingPlan: _changingPlan,
                  onChangePlan: _changePlan),
            ],
            if (s.inTrial) ...[
              _SectionLabel(context.t.sub_actions),
              _SubActionsGroup(onUpgrade: widget.onUpgrade),
            ],
            if (kIapEnabled && isIapActive) ...[
              _SectionLabel(context.t.pricing_manage_on_store),
              const _ManageOnStoreButton(),
            ],
            if (showWebManagedBanner) ...[
              _SectionLabel(context.t.pricing_manage_on_store),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(_kGroupRadius),
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                  ),
                  child: Text(
                    context.t.sub_managed_via_web,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ),
              ),
            ],
            if (kIapEnabled) ...[
              _SectionLabel(context.t.pricing_restore_purchases),
              _RestorePurchasesButton(
                restoring: _restoringPurchases,
                onRestore: _restorePurchases,
              ),
            ],
            _SectionLabel(context.t.sub_payment_history),
            _PaymentHistoryGroup(history: s.history),
            const SizedBox(height: kDefaultPadding * 2),
          ],
        );
      },
    );
  }

  void _showCancelConfirm(BuildContext context, SubscriptionStatus s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.sub_cancel),
        content: Text(context.t.sub_cancel_confirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(context.t.keep)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancel();
            },
            child: Text(context.t.sub_cancel_confirm,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Current plan group ────────────────────────────────────────────────────────

class _CurrentPlanGroup extends StatelessWidget {
  const _CurrentPlanGroup({required this.status});
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    String statusLabel;
    Color statusColor;
    if (!s.active) {
      statusLabel = context.t.sub_status_inactive;
      statusColor = Colors.red;
    } else if (s.inTrial) {
      statusLabel = context.t.sub_status_trial;
      statusColor = const Color(0xFF697BD8);
    } else if (s.cancelAtPeriodEnd) {
      statusLabel = context.t.sub_status_cancelling;
      statusColor = const Color(0xFFf97316);
    } else {
      statusLabel = context.t.sub_status_active;
      statusColor = Colors.green;
    }

    return _GroupCard(children: [
      _Row(label: context.t.sub_plan_label, trailing: PlanBadge(plan: s.plan)),
      _Row(
          label: context.t.sub_status_label,
          trailing: _StatusBadge(label: statusLabel, color: statusColor)),
    ]);
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _SubStatusBanner extends StatelessWidget {
  const _SubStatusBanner({required this.status});
  final SubscriptionStatus status;

  static const _kOrange = Color(0xFFf97316);
  static const _kPurple = Color(0xFF697BD8);

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s.inTrial) {
      return _Banner(
          color: _kPurple,
          text: context.t.sub_trial_active(date: fmtSubDate(s.trialEndsAt)));
    }
    if (s.cancelAtPeriodEnd) {
      return _Banner(
          color: _kOrange,
          text: context.t.sub_ending_on(date: fmtSubDate(s.nextSubscription)));
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2 + 4, vertical: kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(_kGroupRadius),
      ),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ── Pending change group ──────────────────────────────────────────────────────

class _PendingChangeGroup extends StatelessWidget {
  const _PendingChangeGroup({
    required this.status,
    required this.cancellingChange,
    required this.onCancelChange,
  });

  final SubscriptionStatus status;
  final bool cancellingChange;
  final VoidCallback onCancelChange;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final theme = Theme.of(context);

    return Column(
      children: [
        _GroupCard(children: [
          _Row(
            label: context.t.sub_change_label,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              PlanBadge(plan: s.plan),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
                child: Text('→',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ),
              PlanBadge(plan: s.pendingPlan),
            ]),
          ),
          _Row(
            label: context.t.sub_takes_effect,
            trailing: Text(fmtSubDate(s.nextSubscription),
                style: theme.textTheme.bodySmall),
          ),
          if (s.pendingPlanSince > 0)
            _Row(
              label: context.t.sub_scheduled_on,
              trailing: Text(fmtSubDate(s.pendingPlanSince),
                  style: theme.textTheme.bodySmall),
            ),
        ]),
        const SizedBox(height: kDefaultPadding / 2 - 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cancellingChange ? null : onCancelChange,
              child: cancellingChange
                  ? SpinKitCircle(color: theme.primaryColor, size: 16)
                  : Text(context.t.sub_cancel_change),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Plan switcher group ───────────────────────────────────────────────────────

class _PlanSwitcherGroup extends StatelessWidget {
  const _PlanSwitcherGroup({
    required this.status,
    required this.changingPlan,
    required this.onChangePlan,
  });

  final SubscriptionStatus status;
  final String? changingPlan;
  final void Function(String planId, String priceId) onChangePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = status;
    final hasPending = s.hasPendingChange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        children: [
          Row(
            children: kSubPlans.map((plan) {
              final isCurrent = plan.id == s.plan;
              final isLoading = changingPlan == plan.id;
              final isDisabled = isCurrent || hasPending || isLoading;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: plan.id == kSubPlans.first.id
                        ? 0
                        : kDefaultPadding / 2 - 2,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(kDefaultPadding / 2 + 4),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? theme.primaryColor.withValues(alpha: 0.05)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(_kGroupRadius),
                      border: Border.all(
                        color:
                            isCurrent ? theme.primaryColor : theme.dividerColor,
                        width: isCurrent ? 1.5 : 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(plan.name,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            if (isCurrent)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: kDefaultPadding / 4,
                                      vertical: 1),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(kDefaultPadding),
                                  ),
                                  child: Text(
                                    context.t.sub_current,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: kDefaultPadding / 4),
                        Text(plan.price,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text(context.t.settings_plan_period,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor)),
                        const SizedBox(height: kDefaultPadding / 2 + 2),
                        SizedBox(
                          width: double.infinity,
                          child: isCurrent
                              ? OutlinedButton(
                                  onPressed: null,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.primaryColor,
                                    side: BorderSide(
                                        color: theme.primaryColor
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(context.t.sub_current),
                                )
                              : TextButton(
                                  onPressed: isDisabled
                                      ? null
                                      : () =>
                                          onChangePlan(plan.id, plan.priceId),
                                  child: isLoading
                                      ? const SpinKitCircle(
                                          color: kWhite, size: 14)
                                      : Text(context.t.sub_switch),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (s.lastPaymentMethod.isNotEmpty) ...[
            const SizedBox(height: kDefaultPadding / 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2 + 4,
                  vertical: kDefaultPadding / 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(_kGroupRadius),
                border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.lightbulb,
                      size: 18, color: theme.primaryColor),
                  const SizedBox(width: kDefaultPadding / 2),
                  Expanded(
                    child: Text(
                      s.lastPaymentMethod == 'lightning'
                          ? context.t.sub_note_lightning
                          : context.t.sub_note_stripe,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sub actions group ─────────────────────────────────────────────────────────

class _SubActionsGroup extends StatelessWidget {
  const _SubActionsGroup({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onUpgrade,
          child: Text(context.t.sub_upgrade_now),
        ),
      ),
    );
  }
}

// ── Billing actions group ─────────────────────────────────────────────────────

class _BillingActionsGroup extends StatelessWidget {
  const _BillingActionsGroup({
    required this.status,
    required this.cancelling,
    required this.resuming,
    required this.managingBilling,
    required this.onCancel,
    required this.onResume,
    required this.onManageBilling,
  });

  final SubscriptionStatus status;
  final bool cancelling;
  final bool resuming;
  final bool managingBilling;
  final VoidCallback onCancel;
  final VoidCallback onResume;
  final VoidCallback onManageBilling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = status;

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2 + 2),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: managingBilling ? null : onManageBilling,
              style: TbuttonsTheme.solidTextButtonStyle(theme.primaryColor),
              child: managingBilling
                  ? const SpinKitCircle(color: kWhite, size: 16)
                  : Text(context.t.sub_manage_billing),
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2 - 2),
          Expanded(
            child: s.cancelAtPeriodEnd
                ? TextButton(
                    onPressed: resuming ? null : onResume,
                    style:
                        TbuttonsTheme.solidTextButtonStyle(theme.primaryColor),
                    child: resuming
                        ? const SpinKitCircle(color: kWhite, size: 16)
                        : Text(context.t.sub_resume),
                  )
                : TextButton(
                    onPressed: cancelling ? null : onCancel,
                    style: TbuttonsTheme.solidTextButtonStyle(
                      Colors.red,
                      borderColor: Colors.red,
                    ),
                    child: cancelling
                        ? const SpinKitCircle(color: kWhite, size: 16)
                        : Text(context.t.cancel.capitalizeFirst()),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Restore purchases button ─────────────────────────────────────────────────

class _RestorePurchasesButton extends StatelessWidget {
  const _RestorePurchasesButton({
    required this.restoring,
    required this.onRestore,
  });

  final bool restoring;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: restoring ? null : onRestore,
          icon: restoring
              ? SpinKitCircle(color: theme.primaryColor, size: 14)
              : const Icon(LucideIcons.rotateCcw, size: 18),
          label: Text(context.t.pricing_restore_purchases),
        ),
      ),
    );
  }
}

// ── Manage on store button ────────────────────────────────────────────────────

class _ManageOnStoreButton extends StatelessWidget {
  const _ManageOnStoreButton();

  static const _kIosUrl = 'https://apps.apple.com/account/subscriptions';
  static const _kAndroidUrl =
      'https://play.google.com/store/account/subscriptions';

  @override
  Widget build(BuildContext context) {
    final url = Platform.isIOS ? _kIosUrl : _kAndroidUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(Platform.isIOS ? Icons.apple : Icons.android, size: 18),
          label: Text(
              Platform.isIOS ? 'Manage on App Store' : 'Manage on Google Play'),
          onPressed: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
      ),
    );
  }
}

// ── Payment history group ─────────────────────────────────────────────────────

class _PaymentHistoryGroup extends HookWidget {
  const _PaymentHistoryGroup({required this.history});
  final List<SubscriptionPaymentRecord> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(_kGroupRadius),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Text(
            context.t.sub_no_payments,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final records = history.reversed.toList();
    final totalPages = (records.length / _kPaymentsPerPage).ceil();
    final page = useState(0);
    final currentPage = page.value >= totalPages ? totalPages - 1 : page.value;

    return _GroupCard(
      children: [
        for (final entry in records
            .skip(currentPage * _kPaymentsPerPage)
            .take(_kPaymentsPerPage))
          _Row(
            label: fmtSubDate(entry.lastSubscription),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              PaymentMethodLabel(method: entry.lastPaymentMethod),
              const SizedBox(width: kDefaultPadding / 2),
              PlanBadge(plan: entry.plan),
            ]),
          ),
        if (totalPages > 1)
          _PaginationBar(
            page: currentPage,
            totalPages: totalPages,
            onPrevious:
                currentPage > 0 ? () => page.value = currentPage - 1 : null,
            onNext: currentPage < totalPages - 1
                ? () => page.value = currentPage + 1
                : null,
          ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });
  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
            tooltip: 'Previous',
          ),
          Text(
            '${page + 1} / $totalPages',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(LucideIcons.chevronRight, size: 18),
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
}
