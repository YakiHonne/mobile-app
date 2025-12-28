import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_033.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../../logic/relay_info_cubit/relay_info_cubit.dart';
import '../../../../models/app_models/diverse_functions.dart';
import '../../../../models/relays_feed.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../relay_feed_view/relay_feed_view.dart';
import '../../../settings_view/widgets/properties_relay_list.dart';
import '../../../settings_view/widgets/relays_update.dart';
import '../../common_thumbnail.dart';
import '../../custom_icon_buttons.dart';
import '../../data_providers.dart';
import '../../dotted_container.dart';
import '../../empty_list.dart';
import '../../toggle_container.dart';
import '../add_discover_filter.dart';
import 'browse_relay_sets.dart';
import 'set_relay_set.dart';

class RelaySettingsView extends HookWidget {
  const RelaySettingsView({
    super.key,
    required this.controller,
  });

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    final formkey = useMemoized(() => GlobalKey<FormState>());
    final addRelayController = useTextEditingController();
    final connect = useState<RelayConnectivity>(RelayConnectivity.idle);
    final addRelayState = useState('');

    final favoriteRelays = useState(
      relayInfoCubit.state.relayFeeds.favoriteRelays,
    );

    final favoriteRelaySets = useState(
      relayInfoCubit.state.relayFeeds.events,
    );

    final isLoading = useState(false);
    final isSingle = useState(true);

    final addRelay = useCallback(() {
      final r = getProperRelayUrl(addRelayState.value);
      favoriteRelays.value = List<String>.from(favoriteRelays.value)
        ..insert(0, r);
      connect.value = RelayConnectivity.idle;
      addRelayController.clear();
    });

    void setFavoriteOrder(int oldIndex, int newIndex) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final options = List<String>.from(favoriteRelays.value);
      final r = options.removeAt(oldIndex);
      options.insert(newIndex, r);
      favoriteRelays.value = options;
    }

    void setRelaySetOrder(int oldIndex, int newIndex) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final options = List<EventCoordinates>.from(favoriteRelaySets.value);
      final r = options.removeAt(oldIndex);
      options.insert(newIndex, r);
      favoriteRelaySets.value = options;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: controller,
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding,
                  ),
                ),
                _toggle(context, isSingle),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kDefaultPadding / 2),
                ),
                if (isSingle.value)
                  _singleRelayList(
                    formkey,
                    addRelayController,
                    connect,
                    addRelay,
                    addRelayState,
                    context,
                    favoriteRelays,
                    setFavoriteOrder,
                  )
                else
                  _relaySetListWidget(
                    context,
                    favoriteRelaySets,
                    setRelaySetOrder,
                  ),
                if (isSingle.value) ...[] else ...[],
              ],
            ),
          ),
          _update(
            context,
            isLoading,
            favoriteRelays.value,
            favoriteRelaySets.value,
          ),
        ],
      ),
    );
  }

  SliverList _relaySetListWidget(
      BuildContext context,
      ValueNotifier<List<EventCoordinates>> favoriteRelaySets,
      void Function(int oldIndex, int newIndex) setRelaySetOrder) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Column(
            spacing: kDefaultPadding / 2,
            children: [
              const SizedBox(height: 0),
              Row(
                spacing: kDefaultPadding / 4,
                children: [
                  Expanded(
                    child: Text(
                      context.t.savedRelaySets,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                  ),
                  CustomIconButton(
                    onClicked: () {
                      showModalBottomSheet(
                        context: context,
                        elevation: 0,
                        builder: (_) {
                          return const BrowseRelaySets();
                        },
                        isScrollControlled: true,
                        useRootNavigator: true,
                        useSafeArea: true,
                        enableDrag: false,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                      );
                    },
                    icon: FeatureIcons.settings,
                    size: 20,
                    backgroundColor: kTransparent,
                    vd: -4,
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: BlocBuilder<RelayInfoCubit, RelayInfoState>(
                  builder: (context, state) {
                    final list = state.userRelaySets.entries.toList();

                    if (list.isEmpty) {
                      return Column(
                        spacing: kDefaultPadding / 2,
                        children: [
                          Text(
                            context.t.relaySetListEmpty,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            context.t.relaySetListEmptyDesc,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                                  color: Theme.of(context).highlightColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                doIfCanSign(
                                  func: () {
                                    YNavigator.pushPage(
                                      context,
                                      (context) => const SetRelaySet(),
                                    );
                                  },
                                  context: context,
                                );
                              },
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.comfortable,
                              ),
                              child: Text(
                                context.t.addRelaySet,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return SizedBox(
                      height: 20.h,
                      child: ListView.separated(
                        separatorBuilder: (context, index) {
                          return const SizedBox(
                            height: kDefaultPadding / 3,
                          );
                        },
                        itemBuilder: (context, index) {
                          final relaySet = list[index].value;

                          final isFavorite = favoriteRelaySets.value.any(
                              (element) =>
                                  element.identifier == relaySet.identifier);

                          return RelaySetContainer(
                            relaySet: relaySet,
                            onFavorite: () {
                              if (isFavorite) {
                                favoriteRelaySets.value =
                                    List.from(favoriteRelaySets.value)
                                      ..removeWhere((element) =>
                                          element.identifier ==
                                          relaySet.identifier);
                              } else {
                                favoriteRelaySets
                                    .value = List.from(favoriteRelaySets.value)
                                  ..insert(0, relaySet.toEventCoordinates());
                              }
                            },
                            isFavorite: isFavorite,
                            isSelected: true,
                            removeContainer: true,
                          );
                        },
                        itemCount: list.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          Text(
            context.t.favoriteRelaySets,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          if (favoriteRelaySets.value.isNotEmpty)
            BlocBuilder<RelayInfoCubit, RelayInfoState>(
              builder: (context, state) {
                return _relaySetList(
                  setRelaySetOrder,
                  favoriteRelaySets,
                );
              },
            )
          else
            EmptyList(
              description: context.t.relayFeedListEmpty,
              icon: FeatureIcons.relays,
            ),
        ],
      ),
    );
  }

  SliverList _singleRelayList(
      GlobalKey<FormState> formkey,
      TextEditingController addRelayController,
      ValueNotifier<RelayConnectivity> connect,
      Null Function() addRelay,
      ValueNotifier<String> addRelayState,
      BuildContext context,
      ValueNotifier<List<String>> favoriteRelays,
      void Function(int oldIndex, int newIndex) setFavoriteOrder) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _searchAvailableRelays(
          formkey,
          addRelayController,
          connect,
          addRelay,
          addRelayState,
          context,
          favoriteRelays,
        ),
        if (favoriteRelays.value.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          Text(
            context.t.favoriteRelays,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _relaysList(setFavoriteOrder, favoriteRelays),
        ],
      ]),
    );
  }

  SliverToBoxAdapter _toggle(
      BuildContext context, ValueNotifier<bool> isSingle) {
    return SliverToBoxAdapter(
      child: Center(
        child: ToggleContainer(
          string1: context.t.single,
          string2: context.t.sets,
          onToggle: () {
            isSingle.value = !isSingle.value;
          },
          isFirst: isSingle.value,
          width: 200,
        ),
      ),
    );
  }

  Container _update(
    BuildContext context,
    ValueNotifier<bool> isLoading,
    List<String> favoriteRelays,
    List<EventCoordinates> favoriteRelaySets,
  ) {
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
              title: context.t.update.capitalizeFirst(),
              isLoading: isLoading.value,
              onClicked: () async {
                isLoading.value = true;
                await relayInfoCubit.updateFavouriteRelays(
                  relays: favoriteRelays,
                  userRelaySets: favoriteRelaySets,
                );
                isLoading.value = false;

                if (context.mounted) {
                  YNavigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _relaysList(
    Function(int, int) setFavoriteOrder,
    ValueNotifier<List<String>> favoriteRelays,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      primary: false,
      itemBuilder: (context, index) {
        final url = favoriteRelays.value[index];

        return RelayContainer(
          key: ValueKey(url + index.toString()),
          url: url,
          reorderable: true,
          isSelected: true,
          onDelete: () {
            favoriteRelays.value = List<String>.from(favoriteRelays.value)
              ..remove(url);
          },
        );
      },
      itemCount: favoriteRelays.value.length,
      onReorder: (oldIndex, newIndex) => setFavoriteOrder(oldIndex, newIndex),
    );
  }

  Widget _relaySetList(
    Function(int, int) setFavoriteOrder,
    ValueNotifier<List<EventCoordinates>> favoriteRelaySets,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      primary: false,
      itemBuilder: (context, index) {
        final event = favoriteRelaySets.value[index];
        final relaySet =
            relayInfoCubit.getUpdatedFavoriteRelaySet(event.identifier);

        return RelaySetContainer(
          key: ValueKey(event.identifier + index.toString()),
          relaySet: relaySet,
          reorderable: true,
          isSelected: true,
          onDelete: () {
            favoriteRelaySets.value = List<EventCoordinates>.from(
              favoriteRelaySets.value,
            )..remove(event);
          },
        );
      },
      itemCount: favoriteRelaySets.value.length,
      onReorder: (oldIndex, newIndex) => setFavoriteOrder(oldIndex, newIndex),
    );
  }

  Widget _searchAvailableRelays(
    GlobalKey<FormState> formkey,
    TextEditingController addRelayController,
    ValueNotifier<RelayConnectivity> connect,
    Function() addRelay,
    ValueNotifier<String> addRelayState,
    BuildContext context,
    ValueNotifier<List<String>> favoriteRelays,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: Form(
            key: formkey,
            child: RelaySearchTextfield(
              addRelayController: addRelayController,
              connect: connect,
              formkey: formkey,
              addRelay: () => addRelay(),
              addRelayState: addRelayState,
              isAdd: true,
            ),
          ),
        ),
        SquareIconButton(
          onClicked: () {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return AvailableRelaysList(
                  onlineRelays: favoriteRelays.value,
                  excludeContantRelays: false,
                  setRelay: (relay) {
                    favoriteRelays.value =
                        List<String>.from(favoriteRelays.value)
                          ..insert(0, relay);
                  },
                  removeRelay: (relay) {
                    favoriteRelays.value =
                        List<String>.from(favoriteRelays.value)..remove(relay);
                  },
                );
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
            );
          },
        ),
      ],
    );
  }
}

class RelaySetContainer extends HookWidget {
  const RelaySetContainer({
    super.key,
    required this.relaySet,
    this.isSelected = false,
    this.onDelete,
    this.onClick,
    this.onFavorite,
    this.onEdit,
    this.onShareRelay,
    this.reorderable = false,
    this.removeContainer = false,
    this.isFavorite = false,
  });

  final UserRelaySet? relaySet;
  final bool isSelected;
  final Function()? onClick;
  final Function()? onDelete;
  final Function()? onFavorite;
  final Function()? onEdit;
  final Function()? onShareRelay;
  final bool? isFavorite;
  final bool removeContainer;
  final bool reorderable;

  @override
  Widget build(BuildContext context) {
    return removeContainer
        ? _infoRow(relaySet, context)
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: isSelected
                  ? Theme.of(context).cardColor
                  : Theme.of(context).scaffoldBackgroundColor,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    )
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 3,
              vertical: isSelected ? kDefaultPadding / 3 : 0,
            ),
            margin: reorderable
                ? const EdgeInsets.only(bottom: kDefaultPadding / 4)
                : null,
            child: _infoRow(relaySet, context),
          );
  }

  GestureDetector _infoRow(UserRelaySet? relaySet, BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          if (relaySet != null) ...[
            RelaySetImage(
              isSelected: isSelected,
              url: relaySet.image,
              title: relaySet.getTitle(),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relaySet.getTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    relaySet.getDescription(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ],
              ),
            ),
            if (relaySet.relays.isNotEmpty) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              PullDownButton(
                animationBuilder: (context, state, child) => child,
                routeTheme: PullDownMenuRouteTheme(
                  backgroundColor: Theme.of(context).cardColor,
                ),
                itemBuilder: (context) => [
                  ...relaySet.relays.map(
                    (e) => PullDownMenuItem(
                      onTap: () {},
                      title: e,
                      itemTheme: PullDownMenuItemTheme(
                        textStyle:
                            Theme.of(context).textTheme.labelLarge!.copyWith(
                                  color: Theme.of(context).highlightColor,
                                ),
                      ),
                      iconWidget: RelayInfoProvider(
                        relay: e,
                        child: (relayInfo) => RelayImage(
                          isSelected: true,
                          url: e,
                          relayInfo: relayInfo,
                        ),
                      ),
                    ),
                  ),
                ],
                buttonBuilder: (context, showMenu) => GestureDetector(
                  onTap: showMenu,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                      color: isSelected
                          ? Theme.of(context).scaffoldBackgroundColor
                          : Theme.of(context).cardColor,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.3,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 6,
                      horizontal: kDefaultPadding / 2,
                    ),
                    child: Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        Text(
                          context.t
                              .relaysNumber(number: relaySet.relays.length),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        SvgPicture.asset(
                          FeatureIcons.arrowDown,
                          width: 15,
                          height: 15,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).highlightColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.relaySetNotFound,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.t.relaySetNotFoundDesc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          if (onFavorite != null)
            CustomIconButton(
              onClicked: onFavorite!,
              backgroundColor: Theme.of(context).cardColor,
              icon: (isFavorite ?? false)
                  ? FeatureIcons.favoriteFilled
                  : FeatureIcons.favorite,
              size: 20,
              vd: -1,
            ),
          if (onEdit != null)
            CustomIconButton(
              onClicked: onEdit!,
              backgroundColor: Theme.of(context).cardColor,
              icon: FeatureIcons.editArticle,
              size: 20,
              vd: -1,
            ),
          if (onDelete != null)
            CustomIconButton(
              onClicked: onDelete!,
              backgroundColor: Theme.of(context).cardColor,
              icon: FeatureIcons.trash,
              size: 20,
              vd: -1,
            ),
          if (onShareRelay != null)
            CustomIconButton(
              onClicked: onShareRelay!,
              backgroundColor: kTransparent,
              icon: FeatureIcons.shareExternal,
              size: 17,
              vd: -4,
            ),
          if (reorderable)
            const Icon(
              Icons.drag_indicator_rounded,
              size: 20,
            ),
          const SizedBox(
            width: 0,
          ),
        ],
      ),
    );
  }
}

class RelayContainer extends HookWidget {
  const RelayContainer({
    super.key,
    required this.url,
    this.isSelected = false,
    this.onDelete,
    this.onClick,
    this.onShareRelay,
    this.reorderable = false,
  });

  final String url;
  final bool isSelected;
  final Function()? onClick;
  final Function()? onDelete;
  final Function()? onShareRelay;
  final bool reorderable;

  @override
  Widget build(BuildContext context) {
    return RelayInfoProvider(
      relay: url,
      child: (relayInfo) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: isSelected
              ? Theme.of(context).cardColor
              : Theme.of(context).scaffoldBackgroundColor,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                )
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 3,
          vertical: isSelected ? kDefaultPadding / 3 : 0,
        ),
        margin: reorderable
            ? const EdgeInsets.only(bottom: kDefaultPadding / 4)
            : null,
        child: _infoRow(relayInfo, context),
      ),
    );
  }

  GestureDetector _infoRow(RelayInfo? relayInfo, BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          RelayImage(
            isSelected: isSelected,
            url: url,
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
                  url.split('wss://').last,
                ),
                Text(
                  url,
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
          if (onDelete != null)
            CustomIconButton(
              onClicked: onDelete!,
              backgroundColor: Theme.of(context).cardColor,
              icon: FeatureIcons.trash,
              size: 20,
              vd: -1,
            ),
          if (onShareRelay != null)
            CustomIconButton(
              onClicked: onShareRelay!,
              backgroundColor: kTransparent,
              icon: FeatureIcons.shareExternal,
              size: 17,
              vd: -4,
            ),
          if (reorderable)
            const Icon(
              Icons.drag_indicator_rounded,
              size: 20,
            ),
          const SizedBox(
            width: 0,
          ),
        ],
      ),
    );
  }
}

class RelaySetImage extends StatelessWidget {
  const RelaySetImage({
    super.key,
    required this.isSelected,
    required this.title,
    required this.url,
    this.size,
  });

  final bool isSelected;
  final String title;
  final String url;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 40,
      height: size ?? 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: isSelected
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      alignment: Alignment.center,
      child: url.isNotEmpty
          ? CommonThumbnail(
              image: url,
              width: size ?? 40,
              height: size ?? 40,
              isRound: true,
              radius: kDefaultPadding / 2,
            )
          : Text(
              title.characters.first,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
    );
  }
}

class RelayImage extends StatelessWidget {
  const RelayImage({
    super.key,
    required this.isSelected,
    required this.url,
    required this.relayInfo,
    this.size,
  });

  final bool isSelected;
  final String url;
  final RelayInfo? relayInfo;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 40,
      height: size ?? 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: isSelected
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      alignment: Alignment.center,
      child: relayInfo != null && relayInfo!.icon.isNotEmpty
          ? CommonThumbnail(
              image: relayInfo!.icon,
              width: size ?? 40,
              height: size ?? 40,
              isRound: true,
              radius: kDefaultPadding / 2,
            )
          : Text(
              getChar(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
    );
  }

  String getChar() {
    final cleanUrl = url.startsWith('wss://') ? url.split('wss://').last : url;

    if (cleanUrl == '') {
      return 'W';
    } else {
      return cleanUrl.characters.first;
    }
  }
}

class ShareRelayFeed extends StatelessWidget {
  const ShareRelayFeed({
    super.key,
    required this.relay,
    required this.viewType,
  });

  final String relay;
  final ViewDataTypes viewType;

  @override
  Widget build(BuildContext context) {
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
        initialChildSize: 0.60,
        minChildSize: 0.60,
        maxChildSize: 0.60,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: Builder(
            builder: (context) {
              final feedUrl =
                  'https://www.yakihonne.com/r/${viewType == ViewDataTypes.articles ? 'discover' : viewType == ViewDataTypes.notes ? 'notes' : 'media'}?r=$relay';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kDefaultPadding / 2,
                children: [
                  ModalBottomSheetAppbar(
                    title: Relay.removeSocket(relay) ?? relay,
                    isBack: false,
                  ),
                  _relayInfo(scrollController, context, feedUrl),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Expanded _relayInfo(
      ScrollController scrollController, BuildContext context, String feedUrl) {
    return Expanded(
      child: ListView(
        controller: scrollController,
        children: [
          relaySharedContainer(
            context: context,
            onCopy: () {
              shareContent(text: feedUrl);
            },
            text: feedUrl,
            title: context.t.shareRelayContent,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          relaySharedContainer(
            context: context,
            onCopy: () {
              shareContent(text: relay);
            },
            text: relay,
            title: context.t.shareRelayUrl,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          TextButton(
            onPressed: () {
              YNavigator.pushPage(
                context,
                (context) => RelayFeedView(relay: relay),
              );
            },
            child: Text(context.t.browseRelay),
          ),
        ],
      ),
    );
  }

  Widget relaySharedContainer({
    required BuildContext context,
    required String title,
    required String text,
    required Function() onCopy,
  }) {
    return GestureDetector(
      onTap: onCopy,
      behavior: HitTestBehavior.translucent,
      child: DottedBorder(
        color: Theme.of(context).dividerColor,
        radius: const Radius.circular(kDefaultPadding / 2),
        borderType: BorderType.rRect,
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Row(
            spacing: kDefaultPadding / 2,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                    Text(text),
                  ],
                ),
              ),
              SvgPicture.asset(
                FeatureIcons.shareExternal,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
