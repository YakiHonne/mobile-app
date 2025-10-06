import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../../logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../relay_feed_view/relay_feed_view.dart';
import '../../../settings_view/widgets/properties_relay_list.dart';
import '../../../settings_view/widgets/relays_update.dart';
import '../../common_thumbnail.dart';
import '../../custom_icon_buttons.dart';
import '../../data_providers.dart';
import '../../dotted_container.dart';

class RelaySettingsView extends HookWidget {
  const RelaySettingsView({
    super.key,
    required this.isDiscover,
    required this.controller,
    required this.favoriteRelays,
  });

  final ValueNotifier<List<String>> favoriteRelays;
  final bool isDiscover;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final formkey = useMemoized(() => GlobalKey<FormState>());
    final addRelayController = useTextEditingController();
    final connect = useState<RelayConnectivity>(RelayConnectivity.idle);
    final addRelayState = useState('');

    final addRelay = useCallback(() {
      final r = getProperRelayUrl(addRelayState.value);
      favoriteRelays.value = List<String>.from(favoriteRelays.value)..add(r);
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: CustomScrollView(
        controller: controller,
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding,
            ),
          ),
          _searchAvailableRelays(formkey, addRelayController, connect, addRelay,
              addRelayState, context),
          if (favoriteRelays.value.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding / 2,
              ),
            ),
            _relaysList(setFavoriteOrder),
          ],
        ],
      ),
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _relaysList(
      Function(int, int) setFavoriteOrder) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            primary: false,
            itemBuilder: (context, index) {
              final url = favoriteRelays.value[index];

              return RelayContainer(
                key: ValueKey(url),
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
            onReorder: (oldIndex, newIndex) =>
                setFavoriteOrder(oldIndex, newIndex),
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _searchAvailableRelays(
      GlobalKey<FormState> formkey,
      TextEditingController addRelayController,
      ValueNotifier<RelayConnectivity> connect,
      Function() addRelay,
      ValueNotifier<String> addRelayState,
      BuildContext context) {
    return SliverToBoxAdapter(
      child: Row(
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
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 1.5,
              ),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: CustomIconButton(
              icon: FeatureIcons.search,
              size: 18,
              backgroundColor: Theme.of(context).cardColor,
              vd: -2,
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
                            List<String>.from(favoriteRelays.value)..add(relay);
                      },
                      remoteRelay: (relay) {
                        favoriteRelays.value =
                            List<String>.from(favoriteRelays.value)
                              ..remove(relay);
                      },
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                );
              },
            ),
          )
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
              placeholder: getRandomPlaceholder(input: url, isPfp: false),
              width: size ?? 40,
              height: size ?? 40,
              isRound: true,
              radius: kDefaultPadding / 2,
            )
          : Text(
              url.split('wss://').last.characters.first.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
    );
  }
}

class ShareRelayFeed extends StatelessWidget {
  const ShareRelayFeed({
    super.key,
    required this.relay,
    required this.isDiscover,
  });

  final String relay;
  final bool isDiscover;

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
                  'https://www.yakihonne.com/r/${isDiscover ? 'discover' : 'notes'}?r=$relay';

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
