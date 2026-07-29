// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../logic/subscription_cubit/subscription_cubit.dart';
import '../../../models/points_system_models.dart';
import '../../../models/subscription_models.dart';
import '../../../models/wallet_model.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/modal_sheet_container.dart';

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
  static const _kPurple = Color(0xFF697BD8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg, fg;
    if (plan == 'premium') {
      bg = _kOrange.withValues(alpha: 0.15);
      fg = _kOrange;
    } else if (plan == 'business') {
      bg = _kPurple.withValues(alpha: 0.15);
      fg = _kPurple;
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
  String? _changingPlan;
  bool _cancellingChange = false;

  List<PointsRedeemCode> _redeemCodes = [];
  bool _codesLoading = false;
  bool _requesting = false;
  String? _redeemingCode;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _codesLoading = true);
    try {
      final codes = await HttpFunctionsRepository.getRedeemCodes();
      if (mounted) {
        setState(() => _redeemCodes = codes);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _codesLoading = false);
      }
    }
  }

  Future<void> _requestCode() async {
    setState(() => _requesting = true);
    try {
      await HttpFunctionsRepository.requestRedeemCode();
      if (mounted) {
        BotToastUtils.showSuccess(context.t.points_request_success);
      }
      await _loadCodes();
    } on DioException catch (e) {
      if (mounted) {
        BotToastUtils.showError(
          (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
              context.t.points_request_error,
        );
      }
    } catch (_) {
      if (mounted) {
        BotToastUtils.showError(context.t.points_request_error);
      }
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }

  Future<void> _redeemCode(PointsRedeemCode code) async {
    final lightningAddress = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RedeemCodeSheet(code: code),
    );
    if (lightningAddress == null || lightningAddress.isEmpty) {
      return;
    }
    setState(() => _redeemingCode = code.code);
    try {
      await HttpFunctionsRepository.redeemPointsCode(
        code: code.code,
        lightningAddress: lightningAddress,
      );
      if (mounted) {
        BotToastUtils.showSuccess(context.t.points_redeem_success);
      }
      await _loadCodes();
    } on DioException catch (e) {
      if (mounted) {
        BotToastUtils.showError(
          (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
              context.t.points_redeem_error,
        );
      }
    } catch (_) {
      if (mounted) {
        BotToastUtils.showError(context.t.points_redeem_error);
      }
    } finally {
      if (mounted) {
        setState(() => _redeemingCode = null);
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
            if (s.inTrial || showStripeControls) ...[
              _SectionLabel(context.t.sub_actions),
              _SubActionsGroup(
                status: s,
                cancelling: _cancelling,
                resuming: _resuming,
                onCancel: () => _showCancelConfirm(context, s),
                onResume: _resume,
                onUpgrade: widget.onUpgrade,
              ),
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
            if (s.active && !s.inTrial) ...[
              _SectionLabel(context.t.points_redeem_codes),
              _RedeemCodesSection(
                codes: _redeemCodes,
                loading: _codesLoading,
                requesting: _requesting,
                redeemingCode: _redeemingCode,
                onRequest: _requestCode,
                onRedeem: _redeemCode,
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
                              Container(
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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(_kGroupRadius),
                border: Border.all(color: theme.dividerColor, width: 0.5),
              ),
              child: Text(
                s.lastPaymentMethod == 'lightning'
                    ? context.t.sub_note_lightning
                    : context.t.sub_note_stripe,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
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
  const _SubActionsGroup({
    required this.status,
    required this.cancelling,
    required this.resuming,
    required this.onCancel,
    required this.onResume,
    required this.onUpgrade,
  });

  final SubscriptionStatus status;
  final bool cancelling;
  final bool resuming;
  final VoidCallback onCancel;
  final VoidCallback onResume;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = status;
    final isStripeActive = s.lastPaymentMethod == 'stripe' && s.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.inTrial)
            TextButton(
                onPressed: onUpgrade, child: Text(context.t.sub_upgrade_now)),
          if (isStripeActive) ...[
            if (s.inTrial) const SizedBox(height: kDefaultPadding / 2 - 2),
            if (s.cancelAtPeriodEnd) ...[
              OutlinedButton(
                onPressed: resuming ? null : onResume,
                child: resuming
                    ? SpinKitCircle(color: theme.primaryColor, size: 16)
                    : Text(context.t.sub_resume),
              ),
            ] else ...[
              OutlinedButton(
                onPressed: cancelling ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: cancelling
                    ? const SpinKitCircle(color: Colors.red, size: 16)
                    : Text(context.t.sub_cancel),
              ),
            ],
          ],
        ],
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

class _PaymentHistoryGroup extends StatelessWidget {
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

    return _GroupCard(
      children: history.reversed.map((entry) {
        return _Row(
          label: fmtSubDate(entry.lastSubscription),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            PaymentMethodLabel(method: entry.lastPaymentMethod),
            const SizedBox(width: kDefaultPadding / 2),
            PlanBadge(plan: entry.plan),
          ]),
        );
      }).toList(),
    );
  }
}

// ── Redeem Codes Section ─────────────────────────────────────────────────────

// ── Redeem Code Sheet ────────────────────────────────────────────────────────

class _RedeemCodeSheet extends StatefulWidget {
  const _RedeemCodeSheet({required this.code});
  final PointsRedeemCode code;

  @override
  State<_RedeemCodeSheet> createState() => _RedeemCodeSheetState();
}

class _RedeemCodeSheetState extends State<_RedeemCodeSheet> {
  final _controller = TextEditingController();
  WalletModel? _selectedWallet;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectWallet(WalletModel wallet) {
    setState(() {
      if (_selectedWallet?.id == wallet.id) {
        _selectedWallet = null;
        _controller.clear();
      } else {
        _selectedWallet = wallet;
        _controller.text = wallet.lud16;
      }
    });
  }

  void _confirm() {
    final address = _controller.text.trim();
    if (address.isEmpty) {
      return;
    }
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final wallets = walletManagerCubit.state.wallets.values
        .where((w) => w.lud16.isNotEmpty)
        .toList();

    return ModalSheetContainer(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: kDefaultPadding / 2),
              child: Center(child: ModalBottomSheetHandle()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kDefaultPadding,
                kDefaultPadding / 2,
                kDefaultPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.points_redeem_action,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding / 4),
                  Text(
                    context.t.points_enter_lightning,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            if (wallets.isNotEmpty) ...[
              const SizedBox(height: kDefaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                child: Text(
                  context.t.lightningAddress.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding / 4),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < wallets.length; i++) ...[
                        _WalletTile(
                          wallet: wallets[i],
                          isSelected: _selectedWallet?.id == wallets[i].id,
                          onTap: () => _selectWallet(wallets[i]),
                        ),
                        if (i < wallets.length - 1)
                          Divider(
                            height: 0.5,
                            thickness: 0.5,
                            indent: kDefaultPadding,
                            color: theme.dividerColor,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 2,
                  horizontal: kDefaultPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: theme.dividerColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      child: Text(
                        context.t.or,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: theme.dividerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: kDefaultPadding),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) {
                  if (_selectedWallet != null &&
                      _controller.text != _selectedWallet!.lud16) {
                    setState(() => _selectedWallet = null);
                  }
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'user@wallet.com',
                  prefixIcon: Icon(
                    LucideIcons.zap,
                    color: theme.hintColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kDefaultPadding,
                kDefaultPadding,
                kDefaultPadding,
                kDefaultPadding,
              ),
              child: Row(
                spacing: kDefaultPadding / 2,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.t.cancel.capitalizeFirst()),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: _confirm,
                      child: Text(context.t.points_redeem_action),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.isSelected,
    required this.onTap,
  });

  final WalletModel wallet;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding * 0.75,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.12)
                    : theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.5)
                      : theme.dividerColor,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Icon(
                LucideIcons.wallet,
                size: 18,
                color: isSelected ? theme.primaryColor : theme.hintColor,
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    wallet.lud16,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.circleCheck,
                size: 18,
                color: theme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Redeem Codes Section ─────────────────────────────────────────────────────

class _RedeemCodesSection extends StatelessWidget {
  const _RedeemCodesSection({
    required this.codes,
    required this.loading,
    required this.requesting,
    required this.redeemingCode,
    required this.onRequest,
    required this.onRedeem,
  });

  final List<PointsRedeemCode> codes;
  final bool loading;
  final bool requesting;
  final String? redeemingCode;
  final VoidCallback onRequest;
  final ValueChanged<PointsRedeemCode> onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: requesting ? null : onRequest,
              icon: requesting
                  ? SpinKitCircle(color: theme.primaryColor, size: 14)
                  : const Icon(LucideIcons.plus, size: 18),
              label: Text(context.t.points_request_code),
            ),
          ),
          if (loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
              child: Center(child: SpinKitCircle(color: theme.primaryColorDark, size: 32)),
            )
          else if (codes.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
              child: Text(
                context.t.points_no_codes,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: kDefaultPadding / 2),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(_kGroupRadius),
                border: Border.all(color: theme.dividerColor, width: 0.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < codes.length; i++) ...[
                    _RedeemCodeRow(
                      code: codes[i],
                      isRedeeming: redeemingCode == codes[i].code,
                      onRedeem: () => onRedeem(codes[i]),
                    ),
                    if (i < codes.length - 1)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: kDefaultPadding,
                        color: theme.dividerColor,
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: kDefaultPadding / 2),
        ],
      ),
    );
  }
}

class _RedeemCodeRow extends StatelessWidget {
  const _RedeemCodeRow({
    required this.code,
    required this.isRedeeming,
    required this.onRedeem,
  });

  final PointsRedeemCode code;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRedeemed = code.status;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding * 0.75,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code.code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${code.amount} sats · ${isRedeemed ? context.t.points_code_redeemed : context.t.points_code_pending}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isRedeemed ? Colors.green : theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isRedeemed)
            isRedeeming
                ? SpinKitCircle(color: theme.primaryColor, size: 16)
                : TextButton(
                    onPressed: onRedeem,
                    child: Text(context.t.points_redeem_action),
                  ),
        ],
      ),
    );
  }
}
