import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../logic/checkout_cubit/checkout_cubit.dart';
import '../../../../models/app_models/pricing_plan_model.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/buttons_containers_widgets.dart';
import '../../../widgets/fluid_scaffold.dart';
import '../../../widgets/fluid_sheet.dart';
import 'lightning_invoice_sheet.dart';
import 'subscription_success_view.dart';

/// Renders one plan purchase end to end: the in-flight and error states (no
/// toasts — everything renders here) and the success screen. [CheckoutCubit]
/// owns the payment itself.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    super.key,
    required this.plan,
    required this.method,
    this.accountSession,
  });

  final PricingPlan plan;
  final CheckoutMethod method;

  /// The pricing screen's in-flight backend login, awaited before charging.
  final Future<void>? accountSession;

  static Route<bool> route({
    required PricingPlan plan,
    required CheckoutMethod method,
    Future<void>? accountSession,
  }) =>
      MaterialPageRoute<bool>(
        builder: (_) => CheckoutScreen(
          plan: plan,
          method: method,
          accountSession: accountSession,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckoutCubit(
        plan: plan,
        method: method,
        accountSession: accountSession,
      )..start(),
      child: const _CheckoutBody(),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody();

  String _methodLabel(CheckoutMethod method) => switch (method) {
        CheckoutMethod.iap => t.checkout_method_iap,
        CheckoutMethod.stripe => t.checkout_method_stripe,
        CheckoutMethod.lightning => t.checkout_method_ln,
      };

  Future<void> _showInvoiceSheet(
    BuildContext context,
    CheckoutCubit cubit,
    String invoice,
  ) async {
    cubit.invoiceShown();
    await showAppModalSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LightningInvoiceSheet(
        invoice: invoice,
        planName: cubit.plan.name,
        sats: cubit.plan.sats,
        pubkey: cubit.pubkey,
        onPaid: () {
          Navigator.of(sheetContext).pop();
          cubit.lightningPaid();
        },
      ),
    );
    cubit.lightningDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CheckoutCubit>();
    final plan = cubit.plan;
    final method = _methodLabel(cubit.method);

    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (prev, next) =>
          prev.phase != next.phase || prev.invoice != next.invoice,
      listener: (context, state) {
        if (state.phase == CheckoutPhase.cancelled) {
          Navigator.of(context).pop(false);
        }
        // `_showInvoiceSheet` clears the invoice from state before opening, so
        // a later phase-only emit can't land here and reopen the sheet.
        final invoice = state.invoice;
        if (invoice != null) {
          _showInvoiceSheet(context, cubit, invoice);
        }
      },
      builder: (context, state) {
        // The success screen owns its own scaffold and hands off to identity
        // onboarding on its own — it replaces this route's body wholesale.
        if (state.phase == CheckoutPhase.success) {
          // Paid: backing out here would skip identity onboarding, and the
          // hidden leading button only removes the tap target, not the gesture.
          return PopScope(
            canPop: false,
            child: SubscriptionSuccessView(
              planName: plan.name,
              price: '${plan.price}${plan.period}',
            ),
          );
        }

        // Only the store purchase genuinely can't be abandoned mid-flight —
        // every other phase must offer a way out.
        final canLeave = state.phase != CheckoutPhase.paying ||
            cubit.method != CheckoutMethod.iap;

        return PopScope(
          canPop: canLeave,
          child: FluidScaffold(
            title: context.t.checkout_title,
            actions: const [],
            leading: canLeave
                ? AppIconButton(
                    icon: LucideIcons.x,
                    onClicked: () => Navigator.of(context).pop(false),
                  )
                : const SizedBox.shrink(),
            body: SafeArea(
              top: false,
              child: Padding(
                // These bodies are Columns, not scroll views, so the fluid
                // bar's inset has to be reserved here or the summary card
                // sits under it.
                padding: EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  fluidScaffoldTopInset(context),
                  kDefaultPadding,
                  kDefaultPadding,
                ),
                child: switch (state.phase) {
                  CheckoutPhase.paying => _PayingBody(
                      plan: plan,
                      method: method,
                      notice: state.notice,
                    ),
                  CheckoutPhase.handedOff => _HandedOffBody(
                      plan: plan,
                      method: method,
                      onDone: () => Navigator.of(context).pop(true),
                    ),
                  CheckoutPhase.failed => _FailedBody(
                      error: state.error,
                      onRetry: cubit.start,
                      onCancel: () => Navigator.of(context).pop(false),
                    ),
                  CheckoutPhase.success ||
                  CheckoutPhase.cancelled =>
                    const SizedBox.shrink(),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Order summary shown while the payment settles, so the user sees exactly
/// what they're paying for.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.plan, required this.method});

  final PricingPlan plan;
  final String method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: kDefaultPadding / 2,
            bottom: kDefaultPadding / 2 - 2,
          ),
          child: Text(
            context.t.checkout_order_summary.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            child: Column(
              children: [
                _row(context, context.t.checkout_plan, plan.name),
                _divider(theme),
                _row(context, context.t.checkout_method, method),
                _divider(theme),
                // Total last and tinted — it's the figure being charged.
                _row(
                  context,
                  context.t.checkout_total,
                  '${plan.price} ${plan.period}',
                  strong: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(ThemeData theme) => Divider(
        height: 0.5,
        thickness: 0.5,
        indent: kDefaultPadding,
        color: theme.dividerColor,
      );

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2 + 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: strong ? theme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayingBody extends StatelessWidget {
  const _PayingBody({
    required this.plan,
    required this.method,
    required this.notice,
  });

  final PricingPlan plan;
  final String method;
  final String notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        OrderSummaryCard(plan: plan, method: method),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: kDefaultPadding,
            children: [
              SpinKitCircle(color: theme.primaryColorDark, size: 42),
              Column(
                spacing: kDefaultPadding / 4,
                children: [
                  Text(
                    context.t.checkout_processing,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    notice.isNotEmpty
                        ? notice
                        : context.t.checkout_processing_hint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Terminal state for Stripe: checkout continues in the browser, so all this
/// screen can do is explain that and get out of the way.
class _HandedOffBody extends StatelessWidget {
  const _HandedOffBody({
    required this.plan,
    required this.method,
    required this.onDone,
  });

  final PricingPlan plan;
  final String method;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        OrderSummaryCard(plan: plan, method: method),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: kDefaultPadding,
            children: [
              AppIcon(
                LucideIcons.externalLink,
                size: 40,
                color: theme.primaryColorDark,
              ),
              Text(
                context.t.checkout_stripe_opened,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(onPressed: onDone, child: Text(context.t.ok)),
        ),
      ],
    );
  }
}

class _FailedBody extends StatelessWidget {
  const _FailedBody({
    required this.error,
    required this.onRetry,
    required this.onCancel,
  });

  final String error;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: kDefaultPadding,
            children: [
              const AppIcon(
                LucideIcons.circleAlert,
                size: 44,
                color: kRed,
              ),
              Column(
                spacing: kDefaultPadding / 4,
                children: [
                  Text(
                    context.t.checkout_failed,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onRetry,
            child: Text(context.t.checkout_retry),
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        GestureDetector(
          onTap: onCancel,
          behavior: HitTestBehavior.translucent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              context.t.cancel,
              style: theme.textTheme.labelLarge!.copyWith(
                color: theme.primaryColorDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
