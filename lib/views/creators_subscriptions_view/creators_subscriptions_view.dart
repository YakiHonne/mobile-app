import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/creator_subscription_models.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../widgets/data_providers.dart';
import '../widgets/dotted_container.dart';
import '../widgets/fluid_scaffold.dart';
import '../widgets/fluid_sheet.dart';
import '../widgets/modal_sheet_container.dart';
import '../widgets/profile_picture.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class CreatorsSubscriptionsView extends HookWidget {
  const CreatorsSubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptions = useState(<SubscriberSubscription>[]);
    final payments = useState(<SubscriptionPayment>[]);
    final isLoading = useState(true);

    Future<void> fetch() async {
      final res = await HttpFunctionsRepository.getSubscriberSubscriptions();
      subscriptions.value = res.subscriptions;
      payments.value = res.payments;
      isLoading.value = false;
    }

    useEffect(() {
      fetch();
      return null;
    }, []);

    // Cancelling in the Stripe portal lands by webhook a moment later, so the
    // list is refetched whenever we come back to the app.
    useOnAppLifecycleStateChange((_, current) {
      if (current == AppLifecycleState.resumed) {
        fetch();
      }
    });

    final isEmpty = subscriptions.value.isEmpty && payments.value.isEmpty;

    return FluidScaffold(
      title: context.t.creatorsSubscriptions.capitalizeFirst(),
      body: Padding(
        padding: EdgeInsets.only(top: fluidScaffoldTopInset(context)),
        child: SafeArea(
          top: false,
          child: isLoading.value
              ? Center(
                  child: SpinKitCircle(
                    color: Theme.of(context).primaryColorDark,
                    size: 32,
                  ),
                )
              : isEmpty
                  ? const _Hero()
                  : RefreshIndicator.adaptive(
                      onRefresh: fetch,
                      child: ListView(
                        padding: const EdgeInsets.all(kDefaultPadding),
                        children: [
                          // The hero is the empty state — once there is something
                          // to show, the list speaks for itself.
                          ...[
                            if (subscriptions.value.isNotEmpty) ...[
                              _SectionTitle(
                                context.t.subscribedCreators.capitalizeFirst(),
                              ),
                              ...subscriptions.value.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: kDefaultPadding / 2,
                                  ),
                                  child: _SubscriptionRow(subscription: s),
                                ),
                              ),
                              const SizedBox(height: kDefaultPadding / 2),
                            ],
                            if (payments.value.isNotEmpty) ...[
                              _SectionTitle(
                                context.t.paidInvoices.capitalizeFirst(),
                              ),
                              ...payments.value.map((p) {
                                // A flat payment can reference a creator no longer
                                // in `subscriptions[]` — leave those untappable.
                                final match = subscriptions.value
                                    .where(
                                      (s) => s.creatorPubkey == p.creatorPubkey,
                                    )
                                    .firstOrNull;

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: kDefaultPadding / 2,
                                  ),
                                  child: _InvoiceCard(
                                    payment: p,
                                    showCreator: true,
                                    onTap: match == null
                                        ? null
                                        : () => _SubscriptionSheet.show(
                                              context,
                                              match,
                                            ),
                                  ),
                                );
                              }),
                            ],
                          ],
                          const SizedBox(height: kDefaultPadding * 2),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.crown,
            size: 40,
            color: theme.primaryColorDark,
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.creatorsSubscriptions.capitalizeFirst(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 4),
          Text(
            context.t.creatorsSubscriptionsDesc.capitalizeFirst(),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rows & cards
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kDefaultPadding),
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 1.5),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: child,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Colour + label for `display_status`. A `canceling` subscription is still
/// live, so it shows as active with an end date rather than greyed out.
({String label, Color color}) _statusOf(
  BuildContext context,
  SubscriberSubscription s,
) {
  if (s.hasPaymentIssue) {
    return (
      label: switch (s.displayStatus) {
        'past_due' => context.t.pastDue.capitalizeFirst(),
        'unpaid' => context.t.unpaid.capitalizeFirst(),
        _ => context.t.incomplete.capitalizeFirst(),
      },
      color: kMainColor2,
    );
  }
  if (s.isActive) {
    return (label: context.t.active.capitalizeFirst(), color: kMainColor);
  }
  return (
    label: switch (s.displayStatus) {
      'expired' => context.t.expired.capitalizeFirst(),
      'canceled' => context.t.canceled.capitalizeFirst(),
      // Unknown future status — better the raw value than a blank chip.
      _ => s.displayStatus.replaceAll('_', ' ').capitalizeFirst(),
    },
    color: Theme.of(context).hintColor,
  );
}

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({required this.subscription});

  final SubscriberSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusOf(context, subscription);

    final showsEndDate = subscription.isCanceling && subscription.endsAt != 0;

    return _Card(
      onTap: () => _SubscriptionSheet.show(context, subscription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity and status only — the date and the action get their own
          // row so nothing squeezes the creator's name out of the card.
          Row(
            children: [
              Expanded(
                child: _CreatorIdentity(pubkey: subscription.creatorPubkey),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              _Chip(label: status.label, color: status.color),
            ],
          ),
          if (showsEndDate || subscription.hasStripe) ...[
            const Divider(height: kDefaultPadding),
            Row(
              children: [
                if (showsEndDate)
                  Expanded(
                    child: Text(
                      context.t.endsOn(
                        date: dateFormat2.format(
                          DateTime.fromMillisecondsSinceEpoch(
                            subscription.endsAt * 1000,
                          ),
                        ),
                      ),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  )
                else
                  const Spacer(),
                if (subscription.hasStripe)
                  _ManageBillingButton(
                    creatorPubkey: subscription.creatorPubkey,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatorIdentity extends StatelessWidget {
  const _CreatorIdentity({required this.pubkey});

  final String pubkey;
  static const size = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, _) => Row(
        children: [
          ProfilePicture2(
            size: size,
            image: metadata.picture,
            pubkey: pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () {},
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.getName(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${metadata.getName(prioritizeDisplayName: false)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.payment,
    this.showCreator = false,
    this.onTap,
  });

  final SubscriptionPayment payment;
  final bool showCreator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFooter = (showCreator && payment.creatorPubkey.isNotEmpty) ||
        payment.hostedInvoiceUrl.isNotEmpty;

    return _Card(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // At most two things per line: amount/outcome, then date/method.
          Row(
            children: [
              Expanded(
                child: Text(
                  payment.formattedAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              _Chip(
                label: payment.isPaid
                    ? context.t.paid.capitalizeFirst()
                    : context.t.failed.capitalizeFirst(),
                color: payment.isPaid ? kMainColor3 : kMainColor2,
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  payment.subscribedAt == 0
                      ? ''
                      : dateFormat2.format(
                          DateTime.fromMillisecondsSinceEpoch(
                            payment.subscribedAt * 1000,
                          ),
                        ),
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ),
              if (payment.paymentMethod.isNotEmpty) ...[
                const SizedBox(width: kDefaultPadding / 2),
                _Chip(
                  label: payment.paymentMethod,
                  color:
                      payment.provider == 'lightning' ? kMainColor : kMainColor5,
                ),
              ],
            ],
          ),
          if (hasFooter) ...[
            const Divider(height: kDefaultPadding),
            Row(
              children: [
                if (showCreator && payment.creatorPubkey.isNotEmpty)
                  Expanded(
                    child: MetadataProvider(
                      pubkey: payment.creatorPubkey,
                      child: (metadata, _) => Row(
                        children: [
                          Text(
                            context.t.paidTo.capitalizeFirst(),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(width: kDefaultPadding / 3),
                          ProfilePicture2(
                            size: 20,
                            image: metadata.picture,
                            pubkey: payment.creatorPubkey,
                            padding: 0,
                            strokeWidth: 0,
                            strokeColor: kTransparent,
                            onClicked: () {},
                          ),
                          const SizedBox(width: kDefaultPadding / 4),
                          Flexible(
                            child: Text(
                              metadata.getName(),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (payment.hostedInvoiceUrl.isNotEmpty)
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(payment.hostedInvoiceUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(context.t.view.capitalizeFirst()),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens a fresh, single-use Stripe portal session. Only rendered when
/// `has_stripe` is true — lightning-only subscriptions have nothing to manage.
class _ManageBillingButton extends HookWidget {
  const _ManageBillingButton({
    required this.creatorPubkey,
    this.expanded = false,
    this.onLaunched,
  });

  final String creatorPubkey;
  final bool expanded;

  /// Fired just before leaving for the browser. The sheet uses it to close
  /// itself, so the user doesn't come back to a stale snapshot of the
  /// subscription it was built from.
  final VoidCallback? onLaunched;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    if (isLoading.value) {
      return SpinKitCircle(
        color: Theme.of(context).primaryColorDark,
        size: 20,
      );
    }

    final button = TextButton(
      onPressed: () async {
        isLoading.value = true;
        final url = await HttpFunctionsRepository.getSubscriberBillingPortal(
          creatorPubkey,
        );
        isLoading.value = false;

        if (url == null) {
          if (context.mounted) {
            BotToastUtils.showError(
              context.t.creatorBillingPortalError.capitalizeFirst(),
            );
          }
          return;
        }

        onLaunched?.call();
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Text(context.t.manageBilling.capitalizeFirst()),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ---------------------------------------------------------------------------
// Per-creator sheet
// ---------------------------------------------------------------------------

class _SubscriptionSheet extends StatelessWidget {
  const _SubscriptionSheet({required this.subscription});

  final SubscriberSubscription subscription;

  static void show(BuildContext context, SubscriberSubscription subscription) {
    showAppModalSheet(
      context: context,
      builder: (_) => _SubscriptionSheet(subscription: subscription),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusOf(context, subscription);
    final lastPayment = subscription.history.firstOrNull;

    return ModalSheetContainer(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            kDefaultPadding, 0, kDefaultPadding, kDefaultPadding),
        children: [
          const Center(child: ModalBottomSheetHandle()),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          MetadataProvider(
            pubkey: subscription.creatorPubkey,
            child: (metadata, _) => Column(
              children: [
                ProfilePicture2(
                  size: 70,
                  image: metadata.picture,
                  pubkey: subscription.creatorPubkey,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {},
                ),
                const SizedBox(height: kDefaultPadding / 2),
                Text(
                  metadata.getName(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Center(child: _Chip(label: status.label, color: status.color)),
          const SizedBox(height: kDefaultPadding),
          _DetailRow(
            label: context.t.amount.capitalizeFirst(),
            value: Text(
              subscription.formattedAmount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (lastPayment != null && lastPayment.subscribedAt != 0)
            _DetailRow(
              label: context.t.subscriptionDate.capitalizeFirst(),
              value: Text(
                dateFormat2.format(
                  DateTime.fromMillisecondsSinceEpoch(
                    lastPayment.subscribedAt * 1000,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (subscription.isCanceling && subscription.endsAt != 0)
            _DetailRow(
              label: context.t.status.capitalizeFirst(),
              value: Text(
                context.t.endsOn(
                  date: dateFormat2.format(
                    DateTime.fromMillisecondsSinceEpoch(
                      subscription.endsAt * 1000,
                    ),
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (lastPayment != null && lastPayment.paymentMethod.isNotEmpty)
            _DetailRow(
              label: context.t.paymentMethod.capitalizeFirst(),
              value: _Chip(
                label: lastPayment.paymentMethod,
                color: lastPayment.provider == 'lightning'
                    ? kMainColor
                    : kMainColor5,
              ),
            ),
          if (subscription.hasStripe) ...[
            const SizedBox(height: kDefaultPadding),
            _ManageBillingButton(
              creatorPubkey: subscription.creatorPubkey,
              expanded: true,
              onLaunched: () => Navigator.pop(context),
            ),
          ],
          if (subscription.history.isNotEmpty) ...[
            const SizedBox(height: kDefaultPadding),
            _SectionTitle(context.t.paidInvoices.capitalizeFirst()),
            ...subscription.history.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
                child: _InvoiceCard(payment: p),
              ),
            ),
          ],
          const SizedBox(height: kDefaultPadding),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Flexible(child: value),
        ],
      ),
    );
  }
}
