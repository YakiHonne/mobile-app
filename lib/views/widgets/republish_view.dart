// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/relay_info.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import 'common_thumbnail.dart';
import 'content_manager/add_discover_filter.dart';
import 'data_providers.dart';
import 'dotted_container.dart';

class RepublishView extends HookWidget {
  const RepublishView({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final selectedRelays = useState<Set<String>>({});
    final isLoading = useState(false);

    final favoriteRelays = useMemoized(
      () => appSettingsManagerCubit.state.favoriteRelays,
    );

    final allRelays = useMemoized(
      () => nc.activeRelays(),
    );

    final orderedRelays = useMemoized(
      () {
        final favSet = favoriteRelays.toSet();
        final relays = [...allRelays];

        relays.sort((a, b) {
          final aFav = favSet.contains(a);
          final bFav = favSet.contains(b);

          if (aFav && !bFav) {
            return -1; // a comes first
          }
          if (!aFav && bFav) {
            return 1; // b comes first
          }
          return 0; // keep original order among same group
        });

        return relays;
      },
      [allRelays, favoriteRelays],
    );

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
        initialChildSize: 0.95,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: Column(
            children: [
              ModalBottomSheetAppbar(
                title: context.t.republish.capitalizeFirst(),
                isBack: false,
              ),
              if (event.canBeRepublished(currentSigner)) ...[
                _buildRelayList(
                  scrollController,
                  orderedRelays,
                  selectedRelays,
                  favoriteRelays,
                ),
                _buildRepublishButton(context, isLoading, selectedRelays),
              ] else ...[
                _buildProtectedEvent(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildProtectedEvent(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: kDefaultPadding,
        children: [
          SvgPicture.asset(
            FeatureIcons.protected,
            width: 20.w,
            height: 20.w,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          Text(
            context.t.protectedEvent,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            context.t.protectedEventDesc,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Container _buildRepublishButton(
      BuildContext context,
      ValueNotifier<bool> isLoading,
      ValueNotifier<Set<String>> selectedRelays) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom / 2,
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: RegularLoadingButton(
              title: context.t.republish.capitalizeFirst(),
              isLoading: isLoading.value,
              onClicked: () async {
                isLoading.value = true;
                final isSuccess = await appSettingsManagerCubit.republishEvent(
                  event: event,
                  relays: selectedRelays.value,
                );

                isLoading.value = false;

                if (isSuccess) {
                  YNavigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Expanded _buildRelayList(
      ScrollController scrollController,
      List<String> orderedRelays,
      ValueNotifier<Set<String>> selectedRelays,
      List<String> favoriteRelays) {
    return Expanded(
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.only(
          top: kDefaultPadding / 2,
          bottom: kBottomNavigationBarHeight,
        ),
        itemCount: orderedRelays.length,
        separatorBuilder: (context, index) => const SizedBox(
          height: kDefaultPadding / 4,
        ),
        itemBuilder: (context, index) {
          final r = orderedRelays[index];

          return RelayInfoProvider(
            relay: r,
            child: (relayInfo) {
              return _relayRow(
                  selectedRelays, r, context, relayInfo, favoriteRelays);
            },
          );
        },
      ),
    );
  }

  GestureDetector _relayRow(ValueNotifier<Set<String>> selectedRelays, String r,
      BuildContext context, RelayInfo? relayInfo, List<String> favoriteRelays) {
    return GestureDetector(
      onTap: () {
        if (!selectedRelays.value.contains(r)) {
          selectedRelays.value = {...selectedRelays.value..add(r)};
        } else {
          selectedRelays.value = {...selectedRelays.value..remove(r)};
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Stack(
            children: [
              const SizedBox(
                width: 50,
                height: 50,
              ),
              _thumbnail(context, relayInfo, r),
              if (favoriteRelays.contains(r))
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SvgPicture.asset(
                    FeatureIcons.favoriteFilled,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      kMainColor,
                      BlendMode.srcIn,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.split('wss://').last,
                ),
                Text(
                  r,
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
          Checkbox(
            value: selectedRelays.value.contains(r),
            activeColor: kMainColor,
            checkColor: kWhite,
            onChanged: (status) {
              if (status ?? false) {
                selectedRelays.value = {...selectedRelays.value..add(r)};
              } else {
                selectedRelays.value = {...selectedRelays.value..remove(r)};
              }
            },
          ),
        ],
      ),
    );
  }

  Positioned _thumbnail(BuildContext context, RelayInfo? relayInfo, String r) {
    return Positioned.fill(
      child: Align(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
            color: Theme.of(context).cardColor,
          ),
          alignment: Alignment.center,
          child: relayInfo != null && relayInfo.icon.isNotEmpty
              ? CommonThumbnail(
                  image: relayInfo.icon,
                  placeholder: getRandomPlaceholder(
                    input: r,
                    isPfp: false,
                  ),
                  width: 40,
                  height: 40,
                  isRound: true,
                  radius: kDefaultPadding / 2,
                )
              : Text(
                  r.split('wss://').last.characters.first.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
        ),
      ),
    );
  }
}
