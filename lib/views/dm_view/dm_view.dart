// ==================================================
// MAIN DMS VIEW
// ==================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/remote_event_signer.dart';
import 'package:nostr_core_enhanced/utils/string_utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/dms_cubit/dms_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/dm_models.dart';
import '../../routes/navigator.dart';
import '../../routes/pages_router.dart';
import '../../utils/utils.dart';
import '../settings_view/widgets/relays_update.dart';
import '../widgets/animated_components/animated_line.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/data_providers.dart';
import '../widgets/empty_list.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/profile_picture.dart';
import 'widgets/dm_details.dart';
import 'widgets/dm_user_search.dart';

// Imports...

class DmsView extends HookWidget {
  DmsView({
    super.key,
    required this.scrollController,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Private messages view');
  }

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final textController = useState('');
    final tabController = useTabController(
      initialLength: 3,
      initialIndex: dmsCubit.state.index,
    );

    useEffect(() {
      void listener() {
        if (!tabController.indexIsChanging &&
            dmsCubit.state.index != tabController.index) {
          context.read<DmsCubit>().setIndex(tabController.index);
        }
      }

      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    return FadeIn(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          nostrRepository.mainCubit.updateIndex(MainViews.leading);
        },
        child: BlocConsumer<DmsCubit, DmsState>(
          listenWhen: (previous, current) => previous.index != current.index,
          listener: (context, state) {
            tabController.animateTo(state.index);
          },
          builder: (context, state) =>
              _buildContent(context, state, textController, tabController),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DmsState state,
      ValueNotifier<String> textController, TabController tabController) {
    if (isDisconnected() || canRoam()) {
      return const _DisconnectedView();
    }

    return Stack(
      children: [
        _DmsTabView(
          textController: textController,
          tabController: tabController,
          scrollController: scrollController,
        ),
        if (canSign()) _FloatingNewDmButton(),
      ],
    );
  }
}

// ==================================================
// DISCONNECTED STATE VIEW
// ==================================================

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [VerticalViewModeWidget()],
      ),
    );
  }
}

// ==================================================
// MAIN TAB VIEW WITH HEADER
// ==================================================

class _DmsTabView extends StatelessWidget {
  const _DmsTabView({
    required this.textController,
    required this.tabController,
    required this.scrollController,
  });

  final ValueNotifier<String> textController;
  final TabController tabController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (currentSigner is RemoteEventSigner) {
      return const NoMessagesWidget();
    }

    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _DmsAppBar(
            textController: textController,
            tabController: tabController,
          ),
          BlocBuilder<DmsCubit, DmsState>(
            builder: (context, state) {
              if (state.isLoadingHistory) {
                return SliverToBoxAdapter(
                  child: Align(
                    child: Column(
                      key: const ValueKey('loading_history'),
                      mainAxisSize: MainAxisSize.min,
                      spacing: kDefaultPadding / 4,
                      children: [
                        Text(
                          context.t.loadingChatHistory,
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).highlightColor,
                                    height: 1,
                                  ),
                        ),
                        RepaintBoundary(
                          child: SizedBox(
                            width: 50.w,
                            child: const AnimatedPulseLine(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const SliverToBoxAdapter();
              }
            },
          )
        ],
        body: _DmsTabBarView(
          textController: textController,
          tabController: tabController,
        ),
      ),
    );
  }
}

// ==================================================
// APP BAR WITH SEARCH AND FILTER
// ==================================================

class _DmsAppBar extends StatelessWidget {
  const _DmsAppBar({
    required this.textController,
    required this.tabController,
  });

  final ValueNotifier<String> textController;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      elevation: 5,
      floating: true,
      actions: const [SizedBox.shrink()],
      titleSpacing: 0,
      title: _SearchAndFilterRow(textController: textController),
    );
  }
}

// ==================================================
// SEARCH BAR AND FILTER BUTTON
// ==================================================

class _SearchAndFilterRow extends StatelessWidget {
  const _SearchAndFilterRow({required this.textController});

  final ValueNotifier<String> textController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: _SearchTextField(textController: textController),
    );
  }
}

// ==================================================
// SEARCH TEXT FIELD
// ==================================================

class _SearchTextField extends StatelessWidget {
  const _SearchTextField({required this.textController});

  final ValueNotifier<String> textController;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      placeholder: context.t.searchByUserName.capitalizeFirst(),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Icon(
          CupertinoIcons.search,
          color: CupertinoColors.systemGrey,
          size: 20,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).cardColor,
      ),
      onChanged: (value) => textController.value = value,
    );
  }
}

// ==================================================
// FILTER DROPDOWN BUTTON
// ==================================================

// ==================================================
// TAB BAR VIEW CONTENT
// ==================================================

class _DmsTabBarView extends StatelessWidget {
  const _DmsTabBarView({
    required this.textController,
    required this.tabController,
  });

  final ValueNotifier<String> textController;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        SelectedDms(
          dmsType: DmsType.followings,
          key: ValueKey(DmsType.followings.name),
          search: textController.value.trim(),
        ),
        SelectedDms(
          dmsType: DmsType.known,
          key: ValueKey(DmsType.known.name),
          search: textController.value.trim(),
        ),
        SelectedDms(
          dmsType: DmsType.unknown,
          key: ValueKey(DmsType.unknown.name),
          search: textController.value.trim(),
        ),
      ],
    );
  }
}

// ==================================================
// FLOATING ACTION BUTTON
// ==================================================

class _FloatingNewDmButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: kDefaultPadding - 4,
      right: kDefaultPadding - 4,
      child: ZoomIn(
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            YNavigator.pushPage(context, (context) => DmUserSearch());
          },
          heroTag: 'dms',
          backgroundColor: kMainColor,
          shape: const CircleBorder(),
          child: SvgPicture.asset(
            FeatureIcons.startDms,
            colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

// ==================================================
// DM TAB WIDGET
// ==================================================

class DmTab extends StatelessWidget {
  const DmTab({
    super.key,
    required this.dmsType,
    required this.title,
    this.removeCount,
  });

  final DmsType dmsType;
  final String title;
  final bool? removeCount;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Builder(
        builder: (context) {
          return FutureBuilder(
            future: dmsCubit.howManyNewDMSessionsWithNewMessages(dmsType),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Badge(
                isLabelVisible: count != 0,
                backgroundColor: kRed,
                textColor: kWhite,
                label: Text(removeCount != null ? '' : count.toString()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================================================
// DMS LIST VIEW
// ==================================================

class SelectedDms extends HookWidget {
  const SelectedDms({
    super.key,
    required this.dmsType,
    required this.search,
  });

  final DmsType dmsType;
  final String search;

  @override
  Widget build(BuildContext context) {
    final showDmRelaysMessage = useState(dmsCubit.showDmsRelayMessage);

    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, state) {
        return FutureBuilder(
          future: _getFilteredDmSessions(state),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _emptyDmsView(context);
            }

            return Stack(
              children: [
                _DmsListView(dmsSessions: snapshot.data!),
                if (showDmRelaysMessage.value)
                  _RelayMessageBanner(showDmRelaysMessage: showDmRelaysMessage),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<DMSessionDetail>> _getFilteredDmSessions(DmsState state) async {
    final dmsSessions = await dmsCubit.getSessionDetailsByType(
      search.isNotEmpty ? DmsType.all : dmsType,
    );

    List<DMSessionDetail> filteredSessions = [];

    if (search.isNotEmpty) {
      for (final dmSessionDetail in dmsSessions) {
        final author = await metadataCubit
            .getCachedMetadata(dmSessionDetail.dmSession.pubkey);
        if (author != null &&
            (author.name.contains(search) || author.nip05.contains(search))) {
          filteredSessions.add(dmSessionDetail);
        }
      }
    } else {
      filteredSessions = dmsSessions;
    }

    // Remove muted sessions
    filteredSessions.removeWhere(
      (element) => state.mutes.contains(element.info.peerPubkey),
    );

    return filteredSessions;
  }

  Widget _emptyDmsView(BuildContext context) {
    return EmptyList(
      description: context.t.noMessageCanBeFound.capitalizeFirst(),
      icon: FeatureIcons.dms,
    );
  }
}

// ==================================================
// DMS LIST VIEW
// ==================================================

class _DmsListView extends StatelessWidget {
  const _DmsListView({required this.dmsSessions});

  final List<DMSessionDetail> dmsSessions;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Positioned.fill(
      child: ListView.separated(
        separatorBuilder: (context, index) =>
            const SizedBox(height: kDefaultPadding / 1.5),
        padding: EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
          horizontal: isMobile ? kDefaultPadding / 1.5 : 20.w,
        ),
        itemBuilder: (context, index) => DmContainer(
          dmSessionDetail: dmsSessions[index],
          onClicked: () => _onDmTapped(context, dmsSessions[index]),
        ),
        itemCount: dmsSessions.length,
      ),
    );
  }

  void _onDmTapped(BuildContext context, DMSessionDetail dmSessionDetail) {
    context.read<DmsCubit>().updateReadedTime(dmSessionDetail.dmSession.pubkey);
    Navigator.pushNamed(
      context,
      DmDetails.routeName,
      arguments: [dmSessionDetail.dmSession.pubkey],
    );
  }
}

// ==================================================
// RELAY MESSAGE BANNER
// ==================================================

class _RelayMessageBanner extends StatelessWidget {
  const _RelayMessageBanner({required this.showDmRelaysMessage});

  final ValueNotifier<bool> showDmRelaysMessage;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kDefaultPadding / 2,
      left: kDefaultPadding / 2,
      right: kDefaultPadding / 2,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: _relayMessageContent()),
            _closeButton(),
          ],
        ),
      ),
    );
  }

  Widget _relayMessageContent() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kDefaultPadding / 4,
        children: [
          Text(
            context.t.dmRelayTitle,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: context.t.dmRelayDesc,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
                TextSpan(
                  text: context.t.settings.capitalizeFirst(),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _onSettingsTapped(context),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: kMainColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _closeButton() {
    return CustomIconButton(
      onClicked: () {
        showDmRelaysMessage.value = false;
        dmsCubit.showDmsRelayMessage = false;
      },
      icon: FeatureIcons.closeRaw,
      size: 15,
      backgroundColor: kTransparent,
      vd: -4,
    );
  }

  void _onSettingsTapped(BuildContext context) {
    YNavigator.push(
      context,
      SlideupPageRoute(
        builder: (context) => RelayUpdateView(initialIndex: 1),
        settings: const RouteSettings(),
      ),
    );
    showDmRelaysMessage.value = false;
    dmsCubit.showDmsRelayMessage = false;
  }
}

// ==================================================
// DM CONTAINER ITEM
// ==================================================

class DmContainer extends HookWidget {
  const DmContainer({
    super.key,
    required this.dmSessionDetail,
    required this.onClicked,
  });

  final DMSessionDetail dmSessionDetail;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked,
      child: MetadataProvider(
        pubkey: dmSessionDetail.dmSession.pubkey,
        child: (metadata, isNip05Valid) => _DmContainerContent(
          dmSessionDetail: dmSessionDetail,
        ),
      ),
    );
  }
}

// ==================================================
// DM CONTAINER CONTENT
// ==================================================

class _DmContainerContent extends StatelessWidget {
  const _DmContainerContent({required this.dmSessionDetail});

  final DMSessionDetail dmSessionDetail;

  @override
  Widget build(BuildContext context) {
    final newestEvent = dmSessionDetail.dmSession.newestEvent;

    return MetadataProvider(
      pubkey: dmSessionDetail.dmSession.pubkey,
      child: (metadata, _) => Row(
        children: [
          _ProfileSection(metadata: metadata),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: _MessageSection(
              metadata: metadata,
              dmSessionDetail: dmSessionDetail,
              newestEvent: newestEvent,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// PROFILE SECTION
// ==================================================

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.metadata});

  final Metadata metadata;

  @override
  Widget build(BuildContext context) {
    return ProfilePicture3(
      size: 45,
      image: metadata.picture,
      pubkey: metadata.pubkey,
      padding: 0,
      strokeWidth: 0,
      reduceSize: true,
      strokeColor: kTransparent,
      onClicked: () => openProfileFastAccess(
        context: context,
        pubkey: metadata.pubkey,
      ),
    );
  }
}

// ==================================================
// MESSAGE SECTION
// ==================================================

class _MessageSection extends StatelessWidget {
  const _MessageSection({
    required this.metadata,
    required this.dmSessionDetail,
    required this.newestEvent,
  });

  final dynamic metadata;
  final DMSessionDetail dmSessionDetail;
  final dynamic newestEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UserNameRow(metadata: metadata, dmSessionDetail: dmSessionDetail),
        if (newestEvent != null) ...[
          const SizedBox(height: kDefaultPadding / 8),
          _LastMessageRow(
              newestEvent: newestEvent, dmSessionDetail: dmSessionDetail),
        ],
      ],
    );
  }
}

// ==================================================
// USER NAME ROW
// ==================================================

class _UserNameRow extends StatelessWidget {
  const _UserNameRow({
    required this.metadata,
    required this.dmSessionDetail,
  });

  final dynamic metadata;
  final DMSessionDetail dmSessionDetail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            metadata.getName(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        if (dmSessionDetail.hasNewMessage())
          const DotContainer(
            color: kRed,
            isNotMarging: true,
            size: 8,
          ),
      ],
    );
  }
}

// ==================================================
// LAST MESSAGE ROW
// ==================================================

class _LastMessageRow extends StatelessWidget {
  const _LastMessageRow({
    required this.newestEvent,
    required this.dmSessionDetail,
  });

  final dynamic newestEvent;
  final DMSessionDetail dmSessionDetail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: _MessagePreview(newestEvent: newestEvent),
        ),
        DotContainer(
          color: Theme.of(context).highlightColor,
          size: 3,
        ),
        _MessageTimestamp(dmSessionDetail: dmSessionDetail),
      ],
    );
  }
}

// ==================================================
// MESSAGE PREVIEW
// ==================================================

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.newestEvent});

  final dynamic newestEvent;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: dmsCubit.getMessage(newestEvent),
      builder: (context, snapshot) {
        String text = '';
        if (snapshot.hasData) {
          text = snapshot.data!.first.trim();
        }

        return RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: Theme.of(context).textTheme.labelMedium,
            children: [
              if (currentSigner!.getPublicKey() == newestEvent.pubkey)
                TextSpan(
                  text: context.t.you.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              TextSpan(
                text: text.isEmpty
                    ? context.t.decrMessage.capitalizeFirst()
                    : text,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================================================
// MESSAGE TIMESTAMP
// ==================================================

class _MessageTimestamp extends StatelessWidget {
  const _MessageTimestamp({required this.dmSessionDetail});

  final DMSessionDetail dmSessionDetail;

  @override
  Widget build(BuildContext context) {
    return Text(
      StringUtil.getLastDate(
        DateTime.fromMillisecondsSinceEpoch(
          dmSessionDetail.dmSession.lastTime() * 1000,
        ),
      ),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
