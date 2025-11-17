// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../../logic/properties_cubit/update_relays_cubit/update_relays_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import 'relay_info_view.dart';

class RelaysList extends HookWidget {
  const RelaysList({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final searchController = useState('');

    return BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.60,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Scrollbar(
              controller: scrollController,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Center(
                        child: ModalBottomSheetHandle(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          kDefaultPadding / 2,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: context.t.searchRelay.capitalizeFirst(),
                          ),
                          onChanged: (text) {
                            searchController.value = text;
                          },
                        ),
                      ),
                    ),
                    _relaysList(state, searchController),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  SliverList _relaysList(
      UpdateRelaysState state, ValueNotifier<String> searchController) {
    return SliverList.builder(
      itemBuilder: (context, i) {
        final relay = state.onlineRelays[i];
        final isDisplayed = (searchController.value.trim().isNotEmpty &&
                !relay.contains(searchController.value.trim())) ||
            constantRelays.contains(relay);

        if (isDisplayed) {
          return const SizedBox.shrink();
        } else {
          final isAvailable = index == 0
              ? state.relays.keys.contains(relay) ||
                  state.pendingRelays.keys.contains(relay)
              : index == 1
                  ? state.dmRelays.contains(relay)
                  : state.searchRelays.contains(relay);

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 8,
            ),
            child: RelayListTile(
              relay: relay,
              isAvailable: isAvailable,
              canRemove: false,
              setAction: () {
                if (index == 1) {
                  context.read<UpdateRelaysCubit>().updateDmRelay(
                        relay: relay,
                        isAdding: !isAvailable,
                      );
                } else if (index == 2) {
                  context.read<UpdateRelaysCubit>().updateSearchRelay(
                        relay: relay,
                        isAdding: !isAvailable,
                      );
                } else {
                  context.read<UpdateRelaysCubit>().setRelay(
                        relay,
                        textfield: true,
                      );
                }
              },
            ),
          );
        }
      },
      itemCount: state.onlineRelays.length,
    );
  }
}

class AvailableRelaysList extends HookWidget {
  const AvailableRelaysList({
    super.key,
    required this.onlineRelays,
    required this.setRelay,
    required this.remoteRelay,
    this.excludeContantRelays = true,
  });

  final List<String> onlineRelays;
  final Function(String) setRelay;
  final Function(String) remoteRelay;
  final bool excludeContantRelays;

  @override
  Widget build(BuildContext context) {
    final searchController = useState('');
    final activeRelays = useState(onlineRelays);

    // Use useFuture instead of FutureBuilder
    final relaysFuture = useMemoized(() => nostrRepository.fetchRelays());
    final relaysSnapshot = useFuture(relaysFuture);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Scrollbar(
            controller: scrollController,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  _header(context, searchController),
                  // Use the snapshot directly instead of FutureBuilder
                  if (relaysSnapshot.connectionState == ConnectionState.waiting)
                    _loading(context)
                  else if (relaysSnapshot.hasData)
                    _relaysList(relaysSnapshot, searchController, activeRelays)
                  else
                    SliverToBoxAdapter(
                      child: EmptyList(
                        description: context.t.relaysNotReached,
                        icon: FeatureIcons.relays,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Builder _relaysList(
    AsyncSnapshot<List<String>> relaysSnapshot,
    ValueNotifier<String> searchController,
    ValueNotifier<List<String>> activeRelays,
  ) {
    return Builder(
      builder: (context) {
        final relays = relaysSnapshot.data!
            .where(
              (relay) => !((searchController.value.trim().isNotEmpty &&
                      !relay.contains(searchController.value.trim())) ||
                  (excludeContantRelays && constantRelays.contains(relay))),
            )
            .toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
          sliver: SliverList.separated(
            separatorBuilder: (context, index) => const Divider(
              thickness: 0.5,
              indent: kDefaultPadding / 2,
              endIndent: kDefaultPadding / 2,
            ),
            itemBuilder: (context, index) {
              final relay = relays[index];

              final isAvailable = activeRelays.value.contains(relay);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 8,
                ),
                child: RelayListTile(
                  relay: relay,
                  canRemove: true,
                  isAvailable: isAvailable,
                  setAction: () {
                    if (!isAvailable) {
                      setRelay(relay);
                      activeRelays.value = List<String>.from(
                        activeRelays.value,
                      )..add(relay);
                    } else {
                      activeRelays.value = List<String>.from(
                        activeRelays.value,
                      )..remove(relay);
                    }
                  },
                ),
              );
            },
            itemCount: relays.length,
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _loading(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 20,
        width: 20,
        margin: const EdgeInsets.symmetric(
          vertical: kDefaultPadding,
        ),
        alignment: Alignment.center,
        child: SpinKitCircle(
          color: Theme.of(context).primaryColorDark,
          size: 20,
        ),
      ),
    );
  }

  SliverFloatingHeader _header(
      BuildContext context, ValueNotifier<String> searchController) {
    return SliverFloatingHeader(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        child: Column(
          children: [
            const ModalBottomSheetHandle(),
            TextField(
              decoration: InputDecoration(
                hintText: context.t.searchRelay.capitalizeFirst(),
              ),
              onChanged: (text) {
                searchController.value = text;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RelayListTile extends HookWidget {
  const RelayListTile({
    super.key,
    required this.relay,
    required this.isAvailable,
    required this.setAction,
    required this.canRemove,
  });

  final String relay;
  final bool isAvailable;
  final Function() setAction;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final expandRelayInfo = useState(false);

    return RelayInfoProvider(
      relay: relay,
      child: (relayInfo) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 4,
          vertical: kDefaultPadding / 4,
        ),
        child: Column(
          children: [
            _relayRow(relayInfo, context, expandRelayInfo),
            _relayInfo(expandRelayInfo, relayInfo),
          ],
        ),
      ),
    );
  }

  AnimatedCrossFade _relayInfo(
      ValueNotifier<bool> expandRelayInfo, RelayInfo? relayInfo) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(
        height: 0,
        width: double.infinity,
      ),
      secondChild: GestureDetector(
        onTap: () {
          expandRelayInfo.value = !expandRelayInfo.value;
        },
        child: SizedBox(
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
                    ),
                  ),
            crossFadeState: expandRelayInfo.value
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ),
      ),
      crossFadeState: relayInfo != null
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  Row _relayRow(RelayInfo? relayInfo, BuildContext context,
      ValueNotifier<bool> expandRelayInfo) {
    return Row(
      children: [
        RelayImage(
          relay: relay,
          relayInfo: relayInfo,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relay.split('wss://').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                relay,
                maxLines: 2,
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
        if (!isAvailable || (isAvailable && canRemove))
          _addDeleteButton(context),
        if (relayInfo != null) ...[
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          _expandButton(expandRelayInfo, context),
        ]
      ],
    );
  }

  GestureDetector _expandButton(
      ValueNotifier<bool> expandRelayInfo, BuildContext context) {
    return GestureDetector(
      onTap: () {
        expandRelayInfo.value = !expandRelayInfo.value;
      },
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(kDefaultPadding / 2),
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
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _addDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: setAction,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(kDefaultPadding / 2),
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
        child: SvgPicture.asset(
          isAvailable ? FeatureIcons.trash : FeatureIcons.addRaw,
          width: 17,
          height: 17,
          colorFilter: ColorFilter.mode(
            isAvailable ? kRed : Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class RelayImage extends StatelessWidget {
  const RelayImage({
    super.key,
    required this.relay,
    required this.relayInfo,
    this.backgroundColor,
  });

  final String relay;
  final RelayInfo? relayInfo;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: backgroundColor ?? Theme.of(context).cardColor,
      ),
      alignment: Alignment.center,
      child: relayInfo != null && relayInfo!.icon.isNotEmpty
          ? CommonThumbnail(
              image: relayInfo!.icon,
              placeholder: getRandomPlaceholder(input: relay, isPfp: false),
              width: 35,
              height: 35,
              isRound: true,
              radius: kDefaultPadding / 2,
            )
          : Text(
              relay.split('wss://').last.characters.first.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
    );
  }
}
