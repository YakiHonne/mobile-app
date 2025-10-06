// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';

import '../../../logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../dotted_container.dart';
import 'dicover_settings_views/relay_settings_view.dart';
import 'discover_sources_settings.dart';

class AppSourcesList extends HookWidget {
  const AppSourcesList({
    super.key,
    required this.isDiscover,
  });

  final bool isDiscover;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final widgets = <Widget>[];

        Widget? getWidget(BaseFeed feed) {
          if (feed is DiscoverCommunityFeed && !feed.isDisabled()) {
            return CommunityDiscoverList(isDiscover: isDiscover);
          } else if (feed is NotesCommunityFeed && !feed.isDisabled()) {
            return CommunityDiscoverList(isDiscover: isDiscover);
          }
          return null;
        }

        final sources = isDiscover ? state.discoverSources : state.notesSources;
        final hasFavorite =
            appSettingsManagerCubit.state.favoriteRelays.isNotEmpty;

        bool relayInserted = false;

        for (int i = 0; i < sources.length; i++) {
          final source = sources[i];
          final sourceWidget = getWidget(source);

          if (i != 0 && sourceWidget != null) {
            widgets.add(
              const Divider(
                height: kDefaultPadding * 2,
                thickness: 0.5,
              ),
            );
          }

          if (sourceWidget != null) {
            widgets.add(sourceWidget);

            // Insert RelayDiscoverList right after first Discover/Notes feed
            if (!relayInserted &&
                (source is DiscoverCommunityFeed ||
                    source is NotesCommunityFeed) &&
                hasFavorite) {
              widgets.add(
                const Divider(
                  height: kDefaultPadding * 2,
                  thickness: 0.5,
                ),
              );
              widgets.add(
                RelaysDiscoverList(isDiscover: isDiscover),
              );
              relayInserted = true;
            }
          }
        }

        // If no Discover/Notes feed, put RelayDiscoverList at the top
        if (!relayInserted && hasFavorite) {
          widgets.insertAll(0, [
            RelaysDiscoverList(isDiscover: isDiscover),
            const Divider(
              height: kDefaultPadding * 2,
              thickness: 0.5,
            ),
          ]);
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
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
            child: _content(widgets),
          ),
        );
      },
    );
  }

  DraggableScrollableSheet _content(List<Widget> widgets) {
    return DraggableScrollableSheet(
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
            _contentFeed(context),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(
                  top: kDefaultPadding / 2,
                  bottom: kBottomNavigationBarHeight,
                ),
                children: widgets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ModalBottomSheetAppbar _contentFeed(BuildContext context) {
    return ModalBottomSheetAppbar(
      title: context.t.contentFeed.capitalizeFirst(),
      isBack: false,
      onSecondClick: () {
        doIfCanSign(
          func: () {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return DiscoverSourcesSettings(
                  isDiscover: isDiscover,
                );
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          context: context,
        );
      },
      secondIcon: FeatureIcons.settings,
    );
  }
}

class RelaysDiscoverList extends StatelessWidget {
  const RelaysDiscoverList({
    super.key,
    required this.isDiscover,
  });

  final bool isDiscover;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final relays = state.favoriteRelays;

        final selectedKey = isDiscover
            ? state.selectedDiscoverSource.key
            : state.selectedNotesSource.key;

        return Column(
          spacing: kDefaultPadding / 3,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.relaysFeed,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: kMainColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            _relaysList(relays, selectedKey),
          ],
        );
      },
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _relaysList(
      List<String> relays, String selectedKey) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        return MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: ListView.separated(
            shrinkWrap: true,
            primary: false,
            separatorBuilder: (_, __) => const SizedBox(
              height: kDefaultPadding / 2,
            ),
            itemBuilder: (context, index) {
              final r = relays[index];

              return _relayContainer(r, selectedKey, context);
            },
            itemCount: relays.length,
          ),
        );
      },
    );
  }

  RelayContainer _relayContainer(
      String r, String selectedKey, BuildContext context) {
    return RelayContainer(
      url: r,
      isSelected: selectedKey == r,
      onShareRelay: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return ShareRelayFeed(
              relay: r,
              isDiscover: isDiscover,
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onClick: () {
        appSettingsManagerCubit.setSource(
          source: MapEntry(
            r,
            r,
          ),
          isDiscover: isDiscover,
        );

        YNavigator.pop(context);
      },
    );
  }
}

class CommunityDiscoverList extends StatelessWidget {
  const CommunityDiscoverList({super.key, required this.isDiscover});

  final bool isDiscover;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final communityFeed = isDiscover
            ? state.discoverCommunity.entries.toList().toList().where(
                  (element) => element.value.enabled,
                )
            : state.notesCommunity.entries.toList().where(
                  (element) => element.value.enabled,
                );

        final selectedKey = isDiscover
            ? state.selectedDiscoverSource.key
            : state.selectedNotesSource.key;

        return Column(
          spacing: kDefaultPadding / 3,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.communityFeed,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: kMainColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            _communityOptions(communityFeed, selectedKey, context),
          ],
        );
      },
    );
  }

  Column _communityOptions(
      Iterable<MapEntry<String, CommunityFeedOption>> communityFeed,
      String selectedKey,
      BuildContext context) {
    return Column(
      spacing: kDefaultPadding / 3,
      children: communityFeed
          .map(
            (communityOption) => CommunityOptionContainer(
              communityOption: communityOption,
              isSelected: communityOption.key == selectedKey,
              onClick: () {
                appSettingsManagerCubit.setSource(
                  source: MapEntry(
                    communityOption.key,
                    communityOption.value.name,
                  ),
                  isDiscover: isDiscover,
                );

                YNavigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }
}

class CommunityOptionContainer extends StatelessWidget {
  const CommunityOptionContainer({
    super.key,
    required this.communityOption,
    required this.isSelected,
    this.onClick,
  });

  final MapEntry<String, CommunityFeedOption> communityOption;
  final bool isSelected;
  final Function()? onClick;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: GestureDetector(
        onTap: onClick,
        behavior: HitTestBehavior.translucent,
        child: Row(
          spacing: kDefaultPadding / 2,
          children: [
            _image(context),
            Expanded(
              child: Text(
                getSourceName(
                  name: communityOption.value.name,
                  context: context,
                ).capitalizeFirst(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _image(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: !isSelected
            ? Theme.of(context).cardColor
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        getSourceIcon(communityOption.value.name),
        width: 25,
        height: 25,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

String getSourceIcon(String name) {
  if (name == SOURCE_GLOBAL) {
    return FeatureIcons.globe;
  } else if (name == SOURCE_NETWORK) {
    return FeatureIcons.note;
  } else if (name == SOURCE_TOP) {
    return FeatureIcons.unStats;
  } else if (name == SOURCE_RECENT) {
    return FeatureIcons.recent;
  } else if (name == SOURCE_RECENT_WITH_REPLIES) {
    return FeatureIcons.recentWithReplies;
  } else if (name == SOURCE_PAID) {
    return FeatureIcons.sats;
  } else if (name == SOURCE_WIDGETS) {
    return FeatureIcons.smartWidget;
  }

  return FeatureIcons.globe;
}

String getSourceName({required String name, BuildContext? context}) {
  final ctx = context ?? gc;

  if (name == SOURCE_GLOBAL) {
    return ctx.t.global;
  } else if (name == SOURCE_NETWORK) {
    return ctx.t.fromNetwork;
  } else if (name == SOURCE_TOP) {
    return ctx.t.top;
  } else if (name == SOURCE_RECENT) {
    return ctx.t.recent;
  } else if (name == SOURCE_RECENT_WITH_REPLIES) {
    return ctx.t.recentWithReplies;
  } else if (name == SOURCE_PAID) {
    return ctx.t.paid;
  } else if (name == SOURCE_WIDGETS) {
    return ctx.t.widgets;
  }

  return name;
}
