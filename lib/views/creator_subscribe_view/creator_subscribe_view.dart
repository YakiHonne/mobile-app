// ignore_for_file: sort_constructors_first, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/creator_subscription_models.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../widgets/fluid_blur_container.dart';
import '../widgets/fluid_glass_tab_bar.dart';
import '../widgets/fluid_scaffold.dart';
import '../widgets/fluid_sheet.dart';
import '../widgets/modal_sheet_container.dart';
import '../widgets/profile_picture.dart';

// ---------------------------------------------------------------------------
// Providers bottom sheet
// ---------------------------------------------------------------------------

class CreatorProvidersSheet extends HookWidget {
  const CreatorProvidersSheet({
    super.key,
    required this.providers,
    required this.creatorMetadata,
  });

  final List<CreatorProvider> providers;
  final Metadata creatorMetadata;

  static void show(
    BuildContext context, {
    required List<CreatorProvider> providers,
    required Metadata creatorMetadata,
  }) {
    showAppModalSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => CreatorProvidersSheet(
        providers: providers,
        creatorMetadata: creatorMetadata,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding,
              kDefaultPadding,
              kDefaultPadding,
              kDefaultPadding,
            ),
            child: Column(
              children: [
                Text(
                  context.t.creator_payment_providers.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding / 4),
                Text(
                  context.t.creator_choose_gateway.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Row(
              children: providers
                  .map(
                    (p) => Padding(
                      padding:
                          const EdgeInsets.only(right: kDefaultPadding / 2),
                      child: _ProviderCard(
                        provider: p,
                        creatorMetadata: creatorMetadata,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: kDefaultPadding * 1.5),
        ],
      ),
    );
  }
}

class _ProviderCard extends HookWidget {
  const _ProviderCard({
    required this.provider,
    required this.creatorMetadata,
  });

  final CreatorProvider provider;
  final Metadata creatorMetadata;

  bool get _isOurGateway => provider.url.contains(baseUrl3);

  @override
  Widget build(BuildContext context) {
    final gatewayMetadata = useState<Metadata?>(null);

    useEffect(() {
      metadataCubit.getAvailableMetadata(provider.pubkey).then((m) {
        gatewayMetadata.value = m;
      });
      metadataCubit.getFutureMetadata(provider.pubkey).then((m) {
        if (m != null) {
          gatewayMetadata.value = m;
        }
      });
      return null;
    }, [provider.pubkey]);

    final theme = Theme.of(context);
    final m = gatewayMetadata.value;

    return FluidCardContainer(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfilePicture2(
            size: 44,
            image: m?.picture ?? '',
            pubkey: provider.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
            onClicked: () {},
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            m?.getName() ?? '',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (m?.about.isNotEmpty ?? false) ...[
            const SizedBox(height: kDefaultPadding / 4),
            Text(
              m!.about,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: kDefaultPadding / 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: kIapEnabled || provider.url.isEmpty
                  ? null
                  : () => _onSubscribe(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.t.creator_subscribe.capitalizeFirst()),
                  const SizedBox(width: 4),
                  Icon(
                    _isOurGateway
                        ? LucideIcons.arrowRight
                        : LucideIcons.externalLink,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubscribe(BuildContext context) {
    if (_isOurGateway) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => CreatorSubscribePlansView(
            creatorMetadata: creatorMetadata,
            gatewayPubkey: provider.pubkey,
          ),
        ),
      );
    } else {
      openWebPage(url: provider.url);
    }
  }
}

// ---------------------------------------------------------------------------
// Internal plans screen
// ---------------------------------------------------------------------------

class CreatorSubscribePlansView extends HookWidget {
  const CreatorSubscribePlansView({
    super.key,
    required this.creatorMetadata,
    required this.gatewayPubkey,
  });

  final Metadata creatorMetadata;
  final String gatewayPubkey;

  @override
  Widget build(BuildContext context) {
    final subscriptionData = useState<CreatorSubscriptionData?>(null);
    final isLoading = useState(true);

    useEffect(() {
      _fetchPlans(subscriptionData, isLoading);
      return null;
    }, []);

    final methods = subscriptionData.value?.methods ?? [];

    return FluidScaffold(
      title: context.t.creator_subscription_plans.capitalizeFirst(),
      body: Padding(
        padding: EdgeInsets.only(top: fluidScaffoldTopInset(context)),
        // top: false — the inset already includes the status bar.
        child: SafeArea(
          top: false,
          child: isLoading.value
              ? Center(
                  child: SpinKitCircle(
                    color: Theme.of(context).primaryColorDark,
                    size: 32,
                  ),
                )
              : methods.isEmpty
                  ? Center(
                      child: Text(
                        context.t.creator_no_plans.capitalizeFirst(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    )
                  : _PlansTabView(
                      creatorMetadata: creatorMetadata,
                      gatewayPubkey: gatewayPubkey,
                      methods: methods,
                    ),
        ),
      ),
    );
  }

  Future<void> _fetchPlans(
    ValueNotifier<CreatorSubscriptionData?> subscriptionData,
    ValueNotifier<bool> isLoading,
  ) async {
    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [30164],
      pubkeys: [creatorMetadata.pubkey],
      dTags: [gatewayPubkey],
      limit: 1,
      source: EventsSource.all,
    );

    subscriptionData.value = events.isNotEmpty
        ? CreatorSubscriptionData.fromKind30164Tags(events.first.tags)
        : const CreatorSubscriptionData(gatewayPubkey: '', methods: []);

    isLoading.value = false;
  }
}

class _PlansTabView extends HookWidget {
  const _PlansTabView({
    required this.creatorMetadata,
    required this.gatewayPubkey,
    required this.methods,
  });

  final Metadata creatorMetadata;
  final String gatewayPubkey;
  final List<CreatorMethod> methods;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: methods.length);

    return Column(
      children: [
        const SizedBox(height: kDefaultPadding),
        _CreatorHeader(metadata: creatorMetadata),
        const SizedBox(height: kDefaultPadding),
        if (methods.length > 1)
          _MethodTabBar(tabController: tabController, methods: methods),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: methods
                .map(
                  (method) => _PlansList(
                    plans: method.plans,
                    creatorMetadata: creatorMetadata,
                    gatewayPubkey: gatewayPubkey,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MethodTabBar extends StatelessWidget {
  const _MethodTabBar({
    required this.tabController,
    required this.methods,
  });

  final TabController tabController;
  final List<CreatorMethod> methods;

  @override
  Widget build(BuildContext context) {
    final tabs = methods
        .map((m) => Tab(height: 28, text: m.displayName.capitalizeFirst()))
        .toList();

    if (isFluid()) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: FluidGlassTabBar(
          controller: tabController,
          tabs: methods
              .map(
                (m) => GlassTab(label: m.displayName.capitalizeFirst()),
              )
              .toList(),
        ),
      );
    }

    return ScrollShadow(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: EdgeInsets.zero,
        labelStyle: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(fontWeight: FontWeight.w500),
        tabs: tabs,
      ),
    );
  }
}

class _CreatorHeader extends StatelessWidget {
  const _CreatorHeader({required this.metadata});

  final Metadata metadata;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Row(
        children: [
          ProfilePicture2(
            size: 48,
            image: metadata.picture,
            pubkey: metadata.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
            onClicked: () {},
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (metadata.about.isNotEmpty)
                  Text(
                    metadata.about,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                    maxLines: 2,
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

class _PlansList extends StatelessWidget {
  const _PlansList({
    required this.plans,
    required this.creatorMetadata,
    required this.gatewayPubkey,
  });

  final List<CreatorPlan> plans;
  final Metadata creatorMetadata;
  final String gatewayPubkey;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(kDefaultPadding),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: kDefaultPadding / 2),
      itemBuilder: (context, index) => _PlanCard(
        plan: plans[index],
        creatorMetadata: creatorMetadata,
        gatewayPubkey: gatewayPubkey,
      ),
    );
  }
}

class _PlanCard extends HookWidget {
  const _PlanCard({
    required this.plan,
    required this.creatorMetadata,
    required this.gatewayPubkey,
  });

  final CreatorPlan plan;
  final Metadata creatorMetadata;
  final String gatewayPubkey;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final theme = Theme.of(context);
    final isLightning = plan.method == 'lightning';
    final lnAddr = creatorMetadata.lud16.isNotEmpty
        ? creatorMetadata.lud16
        : creatorMetadata.lud06.isNotEmpty
            ? creatorMetadata.lud06
            : null;
    final lightningDisabled = isLightning && lnAddr == null;

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2 + 4),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 4),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: '${plan.currency} ${plan.amount}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text:
                            '  ${context.t.creator_subscribe_per_interval(interval: plan.interval)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          if (lightningDisabled)
            Text(
              '—',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            )
          else
            isLoading.value
                ? SpinKitCircle(
                    color: theme.primaryColorDark,
                    size: 20,
                  )
                : TextButton(
                    onPressed: kIapEnabled
                        ? null
                        : () => _onSubscribe(context, isLoading),
                    child: Text(
                      context.t.creator_subscribe_now.capitalizeFirst(),
                    ),
                  ),
        ],
      ),
    );
  }

  Future<void> _onSubscribe(
    BuildContext context,
    ValueNotifier<bool> isLoading,
  ) async {
    if (plan.method == 'lightning') {
      _openLightningZap(context);
      return;
    }
    await _openFiatLink(context, isLoading);
  }

  void _openLightningZap(BuildContext context) {
    final amountSats = int.tryParse(plan.amount) ?? 0;
    showAppModalSheet(
      context: context,
      builder: (_) => SendZapsView(
        metadata: creatorMetadata,
        isZapSplit: false,
        zapSplits: const [],
        initialVal: amountSats > 0 ? amountSats : null,
        extraTags: [
          ['P', gatewayPubkey],
          ['interval', plan.interval],
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Future<void> _openFiatLink(
    BuildContext context,
    ValueNotifier<bool> isLoading,
  ) async {
    final subscriberPubkey = currentSigner?.getPublicKey() ?? '';
    if (subscriberPubkey.isEmpty) {
      return;
    }

    isLoading.value = true;
    final url = await HttpFunctionsRepository.creatorGetSubscriptionLink(
      creatorPubkey: creatorMetadata.pubkey,
      subscriberPubkey: subscriberPubkey,
      priceId: plan.id,
    );
    isLoading.value = false;

    if (!context.mounted) {
      return;
    }

    if (url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      BotToastUtils.showError(
        context.t.creator_subscribe_error.capitalizeFirst(),
      );
    }
  }
}
