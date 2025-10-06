import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../logic/relay_info_cubit/relay_info_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../profile_view/widgets/profile_fast_access.dart';
import '../relay_feed_view/relay_feed_view.dart';
import '../settings_view/widgets/properties_relay_list.dart';
import '../settings_view/widgets/relay_info_view.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/data_providers.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/tag_container.dart';

class ExploreRelaysView extends HookWidget {
  const ExploreRelaysView({super.key});

  @override
  Widget build(BuildContext context) {
    final types = useMemoized(() {
      relayInfoCubit.init();

      return [
        context.t.network,
        context.t.following,
        context.t.collections,
        context.t.global,
      ];
    });

    final selectedType = useState(types.first);
    final search = useState('');

    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.relayOrbits.capitalizeFirst(),
        description: context.t.relayOrbitsDesc,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        child: CustomScrollView(
          slivers: [
            _appbar(context, types, selectedType, search),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding / 2,
              ),
            ),
            if (selectedType.value == types[2]) ...[
              const RelaysCollections()
            ] else ...[
              if (selectedType.value == types[3] || canSign()) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: kDefaultPadding / 2,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: context.t.searchRelay.capitalizeFirst(),
                      ),
                      onChanged: (value) => search.value = value,
                    ),
                  ),
                ),
                RelaysList(
                  selectedType: selectedType.value,
                  types: types,
                  search: search.value,
                ),
              ] else ...[
                const SliverToBoxAdapter(
                  child: RelayLoginHorizontalViewModeWidget(),
                )
              ],
            ],
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kBottomNavigationBarHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _appbar(BuildContext context, List<String> types,
      ValueNotifier<String> selectedType, ValueNotifier<String> search) {
    return SliverAppBar(
      leading: const SizedBox.shrink(),
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      titleSpacing: 0,
      floating: true,
      title: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(
              width: kDefaultPadding / 4,
            ),
            itemBuilder: (context, index) {
              final type = types[index];

              return TagContainer(
                title: type.capitalizeFirst(),
                isActive: selectedType.value == type,
                style: Theme.of(context).textTheme.labelLarge,
                onClick: () {
                  search.value = '';
                  selectedType.value = type;
                  HapticFeedback.lightImpact();
                },
              );
            },
            itemCount: types.length,
          ),
        ),
      ),
    );
  }
}

class ShowEngagementMessageBox extends StatelessWidget {
  const ShowEngagementMessageBox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: Column(
        children: [
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding,
          ),
          SvgPicture.asset(
            FeatureIcons.globe,
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            context.t.engageWithUsers,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            context.t.engageWithUsersDesc,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding,
          ),
        ],
      ),
    );
  }
}

class RelaysCollections extends StatelessWidget {
  const RelaysCollections({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelayInfoCubit, RelayInfoState>(
      builder: (context, state) {
        return SliverMainAxisGroup(
          slivers: [
            ...state.collections.map(
              (e) {
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        bottom: kDefaultPadding / 2,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          e.name,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        bottom: kDefaultPadding,
                      ),
                      sliver: SliverList.separated(
                        separatorBuilder: (context, index) => const SizedBox(
                          height: kDefaultPadding / 4,
                        ),
                        itemBuilder: (context, index) {
                          final relay = e.relays[index];

                          return RelayBox(
                            relay: relay,
                          );
                        },
                        itemCount: e.relays.length,
                      ),
                    ),
                  ],
                );
              },
            )
          ],
        );
      },
    );
  }
}

class RelaysList extends StatelessWidget {
  const RelaysList({
    super.key,
    required this.selectedType,
    required this.types,
    required this.search,
  });

  final String selectedType;
  final List<String> types;
  final String search;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelayInfoCubit, RelayInfoState>(
      builder: (context, state) {
        final relays = (selectedType == types[3]
            ? state.globalRelays
            : selectedType == types[0]
                ? state.networkRelays
                : state.relayFavored.keys.toList());

        if (relays.isEmpty) {
          return const SliverToBoxAdapter(child: ShowEngagementMessageBox());
        }

        final filtered = search.isEmpty
            ? relays
            : relays
                .where(
                  (e) => e.contains(search),
                )
                .toList();

        return SliverList.separated(
          separatorBuilder: (context, index) => const SizedBox(
            height: kDefaultPadding / 4,
          ),
          itemBuilder: (context, index) {
            final relay = filtered[index];

            return RelayBox(
              relay: relay,
            );
          },
          itemCount: filtered.length,
        );
      },
    );
  }
}

class RelayBox extends HookWidget {
  const RelayBox({
    super.key,
    required this.relay,
    this.enableBrowse = true,
  });

  final String relay;
  final bool enableBrowse;

  @override
  Widget build(BuildContext context) {
    final expandRelayInfo = useState(false);

    return RelayInfoProvider(
      key: ValueKey(relay),
      relay: relay,
      child: (relayInfo) => Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            _relayHeader(relayInfo, context, expandRelayInfo),
            _relayInfo(relayInfo, expandRelayInfo),
            if (enableBrowse) ...[
              const Divider(
                thickness: 0.5,
              ),
              _browseRelay(context),
            ]
          ],
        ),
      ),
    );
  }

  GestureDetector _browseRelay(BuildContext context) {
    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) => RelayFeedView(relay: relay),
        );
      },
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        child: Row(
          spacing: kDefaultPadding / 4,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.t.browseRelay,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
            ),
            SvgPicture.asset(
              FeatureIcons.shareExternal,
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedCrossFade _relayInfo(
      RelayInfo? relayInfo, ValueNotifier<bool> expandRelayInfo) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(
        height: 0,
        width: double.infinity,
      ),
      secondChild: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: AnimatedCrossFade(
              firstChild: const SizedBox(
                height: 0,
                width: double.infinity,
              ),
              secondChild: relayInfo == null
                  ? const SizedBox()
                  : Container(
                      margin: const EdgeInsets.only(
                        top: kDefaultPadding / 2,
                      ),
                      child: RelayGeneralInfo(
                        relayInfo: relayInfo,
                        isCard: true,
                      ),
                    ),
              crossFadeState: expandRelayInfo.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ),
          if (relayInfo != null) ...[
            RelayStatus(relayInfo: relayInfo),
          ]
        ],
      ),
      crossFadeState: relayInfo != null
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  Row _relayHeader(RelayInfo? relayInfo, BuildContext context,
      ValueNotifier<bool> expandRelayInfo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RelayImage(
          relay: relay,
          relayInfo: relayInfo,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: kDefaultPadding / 3,
                children: [
                  Flexible(
                    child: Text(
                      relay.split('wss://').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusContainer(relayInfo),
                ],
              ),
              if (relayInfo?.description != null &&
                  relayInfo!.description.isNotEmpty)
                Text(
                  relayInfo.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        if (relayInfo != null && relayInfo.hasInfos()) ...[
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          _buildExpandButton(expandRelayInfo, context),
        ]
      ],
    );
  }

  GestureDetector _buildExpandButton(
      ValueNotifier<bool> expandRelayInfo, BuildContext context) {
    return GestureDetector(
      onTap: () {
        expandRelayInfo.value = !expandRelayInfo.value;
      },
      child: Container(
        width: 30,
        height: 30,
        padding: const EdgeInsets.all(kDefaultPadding / 3),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: RotatedBox(
          quarterTurns: expandRelayInfo.value ? 2 : 4,
          child: SvgPicture.asset(
            FeatureIcons.arrowDown,
            width: 17,
            height: 17,
            colorFilter: ColorFilter.mode(
              Theme.of(context).highlightColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Builder _buildStatusContainer(RelayInfo? relayInfo) {
    return Builder(
      builder: (context) {
        final lat = relayInfo?.latency ?? '';
        final isOnline = lat.isNotEmpty && lat != '0';

        if (!isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 4,
            vertical: kDefaultPadding / 6,
          ),
          decoration: BoxDecoration(
            color: isOnline
                ? kGreen.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(300),
            border: Border.all(
              color: isOnline ? kGreen : Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Row(
            spacing: kDefaultPadding / 4,
            children: [
              DotContainer(
                color: isOnline
                    ? kGreen
                    : Theme.of(context).scaffoldBackgroundColor,
                isNotMarging: true,
              ),
              Text(
                isOnline ? context.t.online : context.t.offline,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color:
                          isOnline ? kGreen : Theme.of(context).highlightColor,
                      height: 1,
                    ),
              )
            ],
          ),
        );
      },
    );
  }
}

class RelayStatus extends HookWidget {
  const RelayStatus({super.key, required this.relayInfo});

  final RelayInfo relayInfo;

  @override
  Widget build(BuildContext context) {
    final loc = relayInfo.location;
    final lat = relayInfo.latency;
    final isPaid = relayInfo.isPaid;
    final isAuth = relayInfo.isAuth;

    final relaysFuture =
        useMemoized(() => relayInfoCubit.getRelayContacts(relayInfo.url));
    final relaysSnapshot = useFuture(relaysFuture);
    final data = relaysSnapshot.hasData ? relaysSnapshot.data! : <String>[];
    final fr = relayInfoCubit.getFavoredRelayUsers(relayInfo.url);

    if (data.isNotEmpty || relayInfo.hasStats() || fr.isNotEmpty) {
      final widgets = <Widget>[];

      if (isPaid) {
        widgets.add(
          ImageTooltip(
            message: context.t.paid.capitalizeFirst(),
            icon: FeatureIcons.sats,
          ),
        );
      }

      if (isAuth) {
        widgets.add(
          ImageTooltip(
            message: context.t.requiredAuthentication.capitalizeFirst(),
            icon: FeatureIcons.protected,
          ),
        );
      }

      if (data.isNotEmpty) {
        widgets.add(
          Row(
            spacing: kDefaultPadding / 4,
            children: [
              Text(
                context.t.followedBy(number: data.length).capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
              CommonUsersRow(
                commonPubkeys: data.toSet(),
                compact: true,
              ),
            ],
          ),
        );
      }

      if (fr.isNotEmpty) {
        widgets.add(
          Row(
            spacing: kDefaultPadding / 4,
            children: [
              Text(
                context.t.favoredBy(number: fr.length).capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
              CommonUsersRow(
                commonPubkeys: fr.toSet(),
                compact: true,
              ),
            ],
          ),
        );
      }

      if ((lat.isNotEmpty && lat != '0') || loc.isNotEmpty) {
        widgets.add(
          Row(
            spacing: kDefaultPadding / 2,
            children: [
              if (lat.isNotEmpty && lat != '0')
                Text(
                  '$lat ms',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: getLatColor(context: context, lat: lat),
                      ),
                ),
              if (loc.isNotEmpty)
                Builder(
                  builder: (context) {
                    final code = loc;
                    final flag = getCountryFlag(code);

                    return Text(
                      flag == null ? code : '$flag $code',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    );
                  },
                )
            ],
          ),
        );
      }

      return Column(
        children: [
          const Divider(
            thickness: 0.5,
          ),
          ScrollShadow(
            color: Theme.of(context).cardColor,
            size: 10,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _withDividers(widgets),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _withDividers(List<Widget> widgets) {
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(const VerticalDivider(width: 16)); // adjust spacing
      }
    }
    return result;
  }

  Color getLatColor({required BuildContext context, required String lat}) {
    final latVal = int.tryParse(lat);

    if (latVal != null) {
      if (latVal < 500) {
        return kGreen;
      } else if (latVal < 1000) {
        return kMainColor;
      } else {
        return kRed;
      }
    }

    return Theme.of(context).primaryColorDark;
  }
}

class ImageTooltip extends StatelessWidget {
  const ImageTooltip({
    super.key,
    required this.message,
    required this.icon,
  });

  final String message;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: Theme.of(context).primaryColorDark,
          ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 4),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 2,
          )
        ],
      ),
      child: SvgPicture.asset(
        icon,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
