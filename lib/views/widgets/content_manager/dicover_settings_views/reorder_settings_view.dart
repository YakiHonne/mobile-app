// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';

import '../../../../logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import '../add_discover_filter.dart';
import '../discover_sources_list.dart';

class ReorderSettingsView extends HookWidget {
  const ReorderSettingsView({
    super.key,
    required this.currentAppSettings,
    required this.controller,
    required this.isDiscover,
    required this.favoriteRelays,
  });

  final ValueNotifier<AppSharedSettings> currentAppSettings;
  final ScrollController controller;
  final bool isDiscover;
  final ValueNotifier<List<String>> favoriteRelays;

  @override
  Widget build(BuildContext context) {
    final dSources = currentAppSettings.value.contentSources.discoverSources;
    final nSources = currentAppSettings.value.contentSources.notesSources;

    final dSourcesList = useState([
      dSources.communityFeed,
    ]);

    final nSourcesList = useState([
      nSources.communityFeed,
    ]);

    void setSourcesList() {
      if (isDiscover) {
        final s = currentAppSettings.value.contentSources.discoverSources;

        dSourcesList.value = [
          s.communityFeed,
        ];
      } else {
        final s = currentAppSettings.value.contentSources.notesSources;

        nSourcesList.value = [
          s.communityFeed,
        ];
      }
    }

    void toggleOption(int index, bool status, BaseFeed feed) {
      int countEnabledOptions() {
        int count = 0;

        final settings = currentAppSettings.value;

        if (isDiscover) {
          final discoverSources = settings.contentSources.discoverSources;

          final communityFeed = discoverSources.communityFeed;
          count += [
            communityFeed.network,
            communityFeed.top,
            communityFeed.global,
          ].where((opt) => opt.enabled).length;
        } else {
          final notesSources = settings.contentSources.notesSources;

          final communityFeed = notesSources.communityFeed;
          count += [
            communityFeed.recent,
            communityFeed.recentWithReplies,
            communityFeed.global,
            communityFeed.paid,
            communityFeed.widgets,
          ].where((opt) => opt.enabled).length;
        }

        return count;
      }

      if (feed is DiscoverCommunityFeed) {
        final options = [
          feed.network,
          feed.top,
          feed.global,
        ]..sort(
            (a, b) => a.index.compareTo(b.index),
          );

        if (index < 0 || index >= options.length) {
          return;
        }

        if (!status && countEnabledOptions() == 1 && options[index].enabled) {
          BotToastUtils.showWarning(context.t.oneFeedOptionAvailable);
          return;
        }

        options[index] = CommunityFeedOption(
          name: options[index].name,
          enabled: status,
          index: options[index].index,
          id: options[index].id,
        );

        final c = currentAppSettings.value;

        currentAppSettings.value = c.copyWith(
          contentSources: c.contentSources.copyWith(
            discoverSources: c.contentSources.discoverSources.copyWith(
              communityFeed: DiscoverCommunityFeed(
                index: feed.index,
                network: options
                    .firstWhere((option) => option.name == SOURCE_NETWORK),
                top: options.firstWhere((option) => option.name == SOURCE_TOP),
                global: options
                    .firstWhere((option) => option.name == SOURCE_GLOBAL),
              ),
            ),
          ),
        );

        setSourcesList();
      } else if (feed is NotesCommunityFeed) {
        final options = [
          feed.recent,
          feed.recentWithReplies,
          feed.global,
          feed.paid,
          feed.widgets,
        ]..sort(
            (a, b) => a.index.compareTo(b.index),
          );

        if (index < 0 || index >= options.length) {
          return;
        }

        if (!status && countEnabledOptions() == 1 && options[index].enabled) {
          BotToastUtils.showWarning(context.t.oneFeedOptionAvailable);
          return;
        }

        options[index] = CommunityFeedOption(
          name: options[index].name,
          enabled: status,
          index: options[index].index,
          id: options[index].id,
        );

        final c = currentAppSettings.value;

        currentAppSettings.value = c.copyWith(
          contentSources: c.contentSources.copyWith(
            notesSources: c.contentSources.notesSources.copyWith(
              communityFeed: NotesCommunityFeed(
                index: feed.index,
                recent: options.firstWhere((option) => option.name == 'recent'),
                recentWithReplies: options.firstWhere(
                  (option) => option.name == 'recent_with_replies',
                ),
                global: options.firstWhere((option) => option.name == 'global'),
                paid: options.firstWhere((option) => option.name == 'paid'),
                widgets:
                    options.firstWhere((option) => option.name == 'widgets'),
              ),
            ),
          ),
        );

        setSourcesList();
      }
    }

    void setOrder(int oldIndex, int newIndex, BaseFeed feed) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      if (feed is DiscoverCommunityFeed) {
        final options = [feed.network, feed.top, feed.global]..sort(
            (a, b) => a.index.compareTo(b.index),
          );

        if (oldIndex < 0 ||
            oldIndex >= options.length ||
            newIndex < 0 ||
            newIndex >= options.length) {
          return;
        }

        final movedOption = options.removeAt(oldIndex);
        options.insert(newIndex, movedOption);

        for (int i = 0; i < options.length; i++) {
          options[i] = CommunityFeedOption(
            name: options[i].name,
            enabled: options[i].enabled,
            index: i,
            id: options[i].id,
          );
        }

        final c = currentAppSettings.value;

        final ds = DiscoverCommunityFeed(
          index: feed.index,
          network:
              options.firstWhere((option) => option.name == SOURCE_NETWORK),
          top: options.firstWhere((option) => option.name == SOURCE_TOP),
          global: options.firstWhere((option) => option.name == SOURCE_GLOBAL),
        );

        currentAppSettings.value = c.copyWith(
          contentSources: c.contentSources.copyWith(
            discoverSources: c.contentSources.discoverSources.copyWith(
              communityFeed: ds,
            ),
          ),
        );

        setSourcesList();
      } else if (feed is NotesCommunityFeed) {
        final options = [
          feed.recent,
          feed.recentWithReplies,
          feed.global,
          feed.paid,
          feed.widgets
        ]..sort(
            (a, b) => a.index.compareTo(b.index),
          );

        if (oldIndex < 0 ||
            oldIndex >= options.length ||
            newIndex < 0 ||
            newIndex >= options.length) {
          return;
        }

        final movedOption = options.removeAt(oldIndex);
        options.insert(newIndex, movedOption);

        for (int i = 0; i < options.length; i++) {
          options[i] = CommunityFeedOption(
            name: options[i].name,
            enabled: options[i].enabled,
            index: i,
            id: options[i].id,
          );
        }

        final c = currentAppSettings.value;

        final ns = NotesCommunityFeed(
          index: feed.index,
          recent: options.firstWhere((option) => option.name == 'recent'),
          recentWithReplies: options
              .firstWhere((option) => option.name == 'recent_with_replies'),
          global: options.firstWhere((option) => option.name == 'global'),
          paid: options.firstWhere((option) => option.name == 'paid'),
          widgets: options.firstWhere((option) => option.name == 'widgets'),
        );

        currentAppSettings.value = c.copyWith(
          contentSources: c.contentSources.copyWith(
            notesSources: c.contentSources.notesSources.copyWith(
              communityFeed: ns,
            ),
          ),
        );

        setSourcesList();
      }
    }

    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        late Widget widget;

        if (isDiscover) {
          final feed = dSourcesList.value.first;
          widget = DiscoverCommunitySettingsBox(
            key: const ValueKey('community'),
            feed: feed,
            onReorder: (oldIndex, newIndex) => setOrder(
              oldIndex,
              newIndex,
              feed,
            ),
            onToggle: (index, status) => toggleOption(index, status, feed),
          );
        } else {
          final feed = nSourcesList.value.first;
          widget = NotesCommunitySettingsBox(
            key: const ValueKey('community'),
            feed: feed,
            onReorder: (oldIndex, newIndex) => setOrder(
              oldIndex,
              newIndex,
              feed,
            ),
            onToggle: (index, status) => toggleOption(index, status, feed),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding,
            horizontal: kDefaultPadding / 2,
          ),
          child: CustomScrollView(
            controller: controller,
            slivers: [
              SliverToBoxAdapter(
                child: widget,
              )
            ],
          ),
        );
      },
    );
  }
}

class DiscoverCommunitySettingsBox extends StatelessWidget {
  const DiscoverCommunitySettingsBox({
    super.key,
    required this.feed,
    required this.onToggle,
    required this.onReorder,
  });

  final DiscoverCommunityFeed feed;
  final Function(int, bool) onToggle;
  final Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return CommunityFeedList(
      items: feed
          .getMappedContent()
          .entries
          .map(
            (option) => MapEntry(option.value.name, option.value.enabled),
          )
          .toList(),
      onToggle: onToggle,
      onReorder: onReorder,
    );
  }
}

class NotesCommunitySettingsBox extends StatelessWidget {
  const NotesCommunitySettingsBox({
    super.key,
    required this.feed,
    required this.onToggle,
    required this.onReorder,
  });

  final NotesCommunityFeed feed;
  final Function(int, bool) onToggle;
  final Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return CommunityFeedList(
      items: feed
          .getMappedContent()
          .entries
          .map(
            (option) => MapEntry(option.value.name, option.value.enabled),
          )
          .toList(),
      onToggle: onToggle,
      onReorder: onReorder,
    );
  }
}

class CommunityFeedList extends StatelessWidget {
  const CommunityFeedList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onToggle,
  });

  final List<MapEntry<String, bool>> items;
  final Function(int, int) onReorder;
  final Function(int, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      primary: false,
      itemBuilder: (context, index) {
        final item = items[index];

        return _communityFeedItem(item, context, index);
      },
      itemCount: items.length,
      onReorder: onReorder,
    );
  }

  Container _communityFeedItem(
    MapEntry<String, bool> item,
    BuildContext context,
    int index,
  ) {
    return Container(
      key: ValueKey(item.hashCode.toString()),
      padding: const EdgeInsets.all(kDefaultPadding / 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.only(top: kDefaultPadding / 4),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              getSourceIcon(item.key),
              width: 25,
              height: 25,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: ToggleBox(
              title: getSourceName(name: item.key).capitalizeFirst(),
              isToggled: item.value,
              onToggle: (p0) => onToggle(index, p0),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Icon(
            Icons.drag_indicator_rounded,
            size: 20,
          ),
        ],
      ),
    );
  }
}
