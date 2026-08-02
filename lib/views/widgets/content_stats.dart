// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../logic/users_info_list_cubit/users_info_list_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../threads_view/threads_view.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../write_note_view/write_note_view.dart';
import 'app_icon.dart';
import 'custom_icon_buttons.dart';
import 'dotted_container.dart';
import 'fluid_blur_container.dart';
import 'loading_indicators.dart';
import 'note_stats.dart';
import 'note_stats_view.dart';
import 'pull_down_global_button.dart';
import 'sheet_drag_to_close.dart';
import 'zappers_view.dart';

class ContentStats extends HookWidget {
  const ContentStats({
    super.key,
    required this.pubkey,
    required this.kind,
    required this.identifier,
    required this.createdAt,
    required this.title,
    required this.attachedEvent,
    this.isInside = true,
  });

  final String pubkey;
  final int kind;
  final String identifier;
  final DateTime createdAt;
  final String title;
  final BaseEventModel attachedEvent;
  final bool isInside;

  @override
  Widget build(BuildContext context) {
    final double iconSize = isInside ? 18 : 16;
    final double? fontSize = isInside ? 15 : null;
    final isVideo = VideoModel.isVideo(kind);

    final aTag = isVideo && !(attachedEvent as VideoModel).isRepleaceableVideo()
        ? identifier
        : '$kind:$pubkey:$identifier';

    // ✅ REPLACE the problematic useMemoized with this optimized version:
    final hasRequestedStats = useState(false);
    final isInViewport = useState(false);

    // Optimized stats loading - only when visible and not yet requested
    useEffect(() {
      if (isInViewport.value && !hasRequestedStats.value) {
        // Add small delay to avoid loading during fast scrolling
        final timer = Timer(const Duration(milliseconds: 300), () {
          if (context.mounted && isInViewport.value) {
            final isATag =
                !isVideo || (attachedEvent as VideoModel).isRepleaceableVideo();
            notesEventsCubit.getContentStats(
              aTag,
              r: isATag,
              includeComments: true,
            );
          }
        });

        return () => timer.cancel(); // Cleanup timer
      }
      return null;
    }, [isInViewport.value]);

    return VisibilityDetector(
      key: Key(aTag),
      onVisibilityChanged: (info) {
        if (context.mounted) {
          if (info.visibleFraction == 0.5) {
            final isATag =
                !isVideo || (attachedEvent as VideoModel).isRepleaceableVideo();
            notesEventsCubit.getContentStats(
              aTag,
              r: isATag,
              includeComments: true,
            );
          }

          if (!isInViewport.value) {
            isInViewport.value = true;
          }
        }
      },
      child: BlocBuilder<NotesEventsCubit, NotesEventsState>(
        buildWhen: (previous, current) =>
            previous.eventsStats != current.eventsStats ||
            previous.mutes != current.mutes,
        builder: (context, state) {
          final stats = notesEventsCubit.getDirectStats(aTag);

          final replies = stats['replies'];
          final quotes = stats['quotes'];
          final reactions = stats['reactions'];
          final zappers = stats['zappers'];
          final zapsData = stats['zapsData'];
          final selfZaps = stats['selfZaps'];
          final selfReaction = stats['selfReaction'];
          final selfQuote = stats['selfQuote'];
          final selfReply = stats['selfReply'];

          final widgets = buildActionButtons(
            context: context,
            reactions: reactions,
            selfReaction: selfReaction,
            replies: replies,
            selfReply: selfReply,
            quotes: quotes,
            selfQuote: selfQuote,
            zappers: zappers,
            zapsData: zapsData,
            selfZaps: selfZaps,
            iconSize: iconSize,
            fontSize: fontSize,
            isVideo: isVideo,
            aTag: aTag,
          );

          final pullDownButton = PullDownGlobalButton(
            model: attachedEvent,
            enablePostInNote: true,
            enableCopyNpub: true,
            enableRepublish: true,
            enableCopyId: attachedEvent is VideoModel &&
                !(attachedEvent as VideoModel).isRepleaceableVideo(),
            enableCopyNaddr: attachedEvent is! VideoModel ||
                (attachedEvent is VideoModel &&
                    (attachedEvent as VideoModel).isRepleaceableVideo()),
            enableBookmark: true,
            enableShareImage: true,
            enableAddToCuration: isInside,
            enableShowRawEvent: true,
            iconColor: Theme.of(context).highlightColor,
            enableEdit: isInside &&
                attachedEvent is! VideoModel &&
                (canSign() &&
                    currentSigner!.getPublicKey() == attachedEvent.pubkey),
            enableShare: true,
            enableMute: true,
            bookmarkStatus: notesEventsCubit.state.bookmarks.contains(
              identifier,
            ),
            muteStatus: state.mutes.contains(attachedEvent.pubkey),
            iconSize: 20,
            size: 25,
          );

          final sb = SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: isInside
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.start,
              children: isInside
                  ? [
                      ...widgets.map(
                        (e) {
                          return Expanded(
                            child: e,
                          );
                        },
                      ),
                      if (isFluid())
                        _fluidStatsButton(
                          context,
                          aTag,
                          zappers as Map<String, MapEntry<String, int>>,
                        ),
                      pullDownButton,
                    ]
                  : [
                      Expanded(
                        child: Row(
                          spacing: kDefaultPadding / 4,
                          children: widgets,
                        ),
                      ),
                      if (isFluid())
                        _fluidStatsButton(
                          context,
                          aTag,
                          zappers as Map<String, MapEntry<String, int>>,
                        ),
                      pullDownButton,
                    ],
            ),
          );

          final zappersRow = AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 4,
              ),
              child: ZappersRow(
                zapData: zapsData,
                zappers: zappers,
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: (zappers as Map).isNotEmpty
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          );

          if (isInside) {
            if (!isFluid()) {
              return sb;
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 4,
              children: [if (zappers.isNotEmpty) zappersRow, sb],
            );
          } else {
            return Column(
              spacing: kDefaultPadding / 4,
              children: [if (zappers.isNotEmpty) zappersRow, sb],
            );
          }
        },
      ),
    );
  }

  List<Widget> buildActionButtons({
    required BuildContext context,
    required dynamic reactions,
    required dynamic selfReaction,
    required dynamic replies,
    required dynamic selfReply,
    required dynamic quotes,
    required dynamic selfQuote,
    required dynamic zappers,
    required dynamic zapsData,
    required dynamic selfZaps,
    required double iconSize,
    required double? fontSize,
    required bool isVideo,
    required String aTag,
  }) {
    final actions = Map<String, bool>.from(
        nostrRepository.currentAppCustomization?.actionsArrangement ??
            defaultActionsArrangement)
      ..remove('reposts');

    return actions.entries
        .where(
      (action) => action.value,
    )
        .map((action) {
      switch (action.key) {
        case 'reactions':
          return action.value
              ? _reactButton(reactions, selfReaction, aTag, isVideo, iconSize)
              : const SizedBox.shrink();
        case 'replies':
          return _replyButton(
              context, aTag, isVideo, selfReply, replies, iconSize, fontSize);
        case 'quotes':
          return _quoteButton(
              context, aTag, quotes, selfQuote, iconSize, fontSize);
        case 'zaps':
          return _zapButton(
              aTag, zappers, zapsData, selfZaps, iconSize, fontSize, isVideo);
        default:
          return const SizedBox.shrink();
      }
    }).toList();
  }

  ContentZapButton _zapButton(
    String aTag,
    zappers,
    zapsData,
    selfZaps,
    double iconSize,
    double? fontSize,
    bool isVideo,
  ) {
    return ContentZapButton(
      aTag: aTag,
      pubkey: pubkey,
      attachedEvent: attachedEvent,
      zappers: zappers,
      zapsData: zapsData,
      selfZaps: selfZaps,
      iconSize: iconSize,
      fontSize: fontSize,
      isVideo: isVideo,
    );
  }

  CustomIconButton _quoteButton(
    BuildContext context,
    String aTag,
    quotes,
    selfQuote,
    double iconSize,
    double? fontSize,
  ) {
    return CustomIconButton(
      backgroundColor: kTransparent,
      icon: FeatureIcons.quote,
      onLongPress: () {
        showAdaptiveModal(
          context,
          builder: (_) {
            return NetStatsView(
              id: aTag,
              type: NoteRelatedEventsType.quotes,
            );
          },
          dialogHeight: 620,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onClicked: () {
        doIfCanSign(
          func: () {
            showAdaptiveModal(
              context,
              builder: (_) {
                return AddReply(
                  attachedEvent: attachedEvent,
                  isMention: false,
                  isComment: false,
                  isQuote: true,
                  onSuccess: (ev) {
                    notesEventsCubit.addEventRelatedData(
                      event: ev,
                      replyNoteId: aTag,
                    );
                  },
                );
              },
              dialogHeight: 640,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          context: context,
        );
      },
      value: quotes.length.toString(),
      iconColor: selfQuote
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      textColor: selfQuote
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      size: iconSize,
      fontSize: fontSize,
    );
  }

  CustomReactionButton _reactButton(
    reactions,
    selfReaction,
    String aTag,
    bool isVideo,
    double iconSize,
  ) {
    return CustomReactionButton(
      reactions: reactions,
      selfReaction: selfReaction,
      id: aTag,
      pubkey: pubkey,
      isReplaceable: !isVideo,
      size: iconSize,
    );
  }

  CustomIconButton _replyButton(
    BuildContext context,
    String aTag,
    bool isVideo,
    selfReply,
    replies,
    double iconSize,
    double? fontSize,
  ) {
    return CustomIconButton(
      backgroundColor: kTransparent,
      icon: FeatureIcons.comments,
      onLongPress: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ContentThreadsView(aTag: aTag),
          ),
        );
      },
      onClicked: () {
        doIfCanSign(
          func: () {
            _addReply(context, isVideo, aTag);
          },
          context: context,
        );
      },
      iconColor: selfReply
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      textColor: selfReply
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      value: replies.length.toString(),
      size: iconSize,
      fontSize: fontSize,
    );
  }

  Future<dynamic> _addReply(BuildContext context, bool isVideo, String aTag) {
    return showAdaptiveModal(
      context,
      builder: (_) {
        return AddReply(
          isComment: true,
          onSuccess: (ev) {
            notesEventsCubit.addEventRelatedData(
              event: ev,
              replyNoteId: aTag,
            );
          },
          attachedEvent: attachedEvent,
          replyContent: {
            'pubkey': pubkey,
            'pTags': attachedEvent is Article
                ? (attachedEvent as Article).cleanPtags()
                : attachedEvent is VideoModel
                    ? (attachedEvent as VideoModel).cleanPtags()
                    : [],
            'date': createdAt,
            'content': title,
          },
        );
      },
      dialogHeight: 640,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  String getTitle() {
    String title = '';

    switch (kind) {
      case EventKind.LONG_FORM:
        title = 'article';
      case EventKind.CURATION_VIDEOS:
        title = 'curation';
      case EventKind.CURATION_ARTICLES:
        title = 'curation';
      case EventKind.VIDEO_HORIZONTAL:
        title = 'video';
      case EventKind.VIDEO_VERTICAL:
        title = 'video';
      case EventKind.SMART_WIDGET_ENH:
        title = 'smart widget';
    }

    return title;
  }

  Widget _fluidStatsButton(
    BuildContext context,
    String aTag,
    Map<String, MapEntry<String, int>> zappers,
  ) {
    return CustomIconButton(
      backgroundColor: kTransparent,
      icon: FeatureIcons.unStats,
      size: 16,
      iconColor: Theme.of(context).highlightColor,
      onClicked: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) => _ContentStatsModal(
            aTag: aTag,
            zappers: zappers,
          ),
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
        );
      },
    );
  }
}

class ContentZapButton extends HookWidget {
  const ContentZapButton({
    super.key,
    required this.aTag,
    required this.pubkey,
    required this.attachedEvent,
    required this.isVideo,
    this.zapsData,
    required this.selfZaps,
    this.zappers,
    required this.iconSize,
    required this.fontSize,
  });

  final String aTag;
  final String pubkey;
  final BaseEventModel attachedEvent;
  final dynamic zapsData;
  final bool selfZaps;
  final bool isVideo;
  final dynamic zappers;
  final double iconSize;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isFastZapping = useState(false);

    final onDefaultZap = useCallback(
      () {
        doIfCanSign(
          func: () async {
            final m = await metadataCubit.getAvailableMetadata(pubkey);
            isFastZapping.value = true;

            walletManagerCubit.handleWalletZap(
              user: m,
              sats: getCurrentUserDefaultZapAmount(),
              comment: '',
              useExternalWallet: walletManagerCubit.state.useDefaultWallet,
              onFailure: (message) {
                isFastZapping.value = false;
                BotToastUtils.showError(message);
              },
              eventId: isVideo ? aTag : null,
              aTag: isVideo ? null : aTag,
              onSuccess: (_) {
                isFastZapping.value = false;

                notesEventsCubit.handleSubmittedZap(
                  eventId: aTag,
                  recipientPubkey: pubkey,
                  amount: getCurrentUserDefaultZapAmount(),
                  senderPubkey: currentSigner!.getPublicKey(),
                  isIdentifier: true,
                );
              },
              onFinished: (_) {
                isFastZapping.value = false;
              },
            );
          },
          context: context,
        );
      },
    );

    final onSetZap = useCallback(
      () {
        doIfCanSign(
          func: () async {
            final zs = zapSplits();
            final m = await metadataCubit.getAvailableMetadata(pubkey);

            if (context.mounted) {
              showAdaptiveModal(
                context,
                builder: (_) {
                  return SendZapsView(
                    metadata: m,
                    eventId: isVideo ? aTag : null,
                    aTag: isVideo ? null : aTag,
                    isZapSplit: zs.isNotEmpty,
                    zapSplits: zs,
                    onSuccess: (_, amount) {
                      notesEventsCubit.handleSubmittedZap(
                        recipientPubkey: pubkey,
                        eventId: aTag,
                        amount: amount,
                        senderPubkey: currentSigner!.getPublicKey(),
                        isIdentifier: true,
                      );
                    },
                  );
                },
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          },
          context: context,
        );
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isFastZapping.value
          ? SizedBox(
              width: 40,
              child: SpinKitCircle(
                key: const ValueKey('isZapping'),
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            )
          : _zapButton(context, onDefaultZap, onSetZap),
    );
  }

  CustomIconButton _zapButton(
      BuildContext context, Function() onDefaultZap, Function() onSetZap) {
    return CustomIconButton(
      key: ValueKey(selfZaps),
      backgroundColor: kTransparent,
      icon: selfZaps ? FeatureIcons.zapFilled : FeatureIcons.zap,
      onLongPress: () {
        if (zappers.isNotEmpty) {
          showAdaptiveModal(
            context,
            builder: (_) {
              return ZappersView(
                zappers: zappers,
              );
            },
            dialogHeight: 620,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        }
      },
      onDoubleTap: () {
        if (!nostrRepository.enableOneTapZap) {
          onDefaultZap();
        } else {
          onSetZap();
        }
      },
      onClicked: () {
        if (nostrRepository.enableOneTapZap) {
          onDefaultZap();
        } else {
          onSetZap();
        }
      },
      value: zapsData['total'].toString(),
      iconColor: selfZaps
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      textColor: selfZaps
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      size: iconSize,
      fontSize: fontSize,
    );
  }

  List<ZapSplit> zapSplits() {
    if (attachedEvent is Article) {
      return (attachedEvent as Article).zapsSplits;
    } else if (attachedEvent is VideoModel) {
      return (attachedEvent as VideoModel).zapsSplits;
    } else if (attachedEvent is Curation) {
      return (attachedEvent as Curation).zapsSplits;
    } else {
      return [];
    }
  }
}

class _ContentStatsModal extends HookWidget {
  const _ContentStatsModal({
    required this.aTag,
    required this.zappers,
  });

  final String aTag;
  final Map<String, MapEntry<String, int>> zappers;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 4);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FluidBlurContainer(
        customBorderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        customBorder: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          left: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        backgroundAlpha: isFluid() ? 0.55 : 1,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.60,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, __) => SheetDragToClose(
            child: Column(
            children: [
              const ModalBottomSheetHandle(),
              _tabBar(context, tabController),
              const SizedBox(height: kDefaultPadding / 2),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    NetStatsView(
                      id: aTag,
                      type: NoteRelatedEventsType.replies,
                      embedded: true,
                    ),
                    NetStatsView(
                      id: aTag,
                      type: NoteRelatedEventsType.reactions,
                      embedded: true,
                    ),
                    NetStatsView(
                      id: aTag,
                      type: NoteRelatedEventsType.quotes,
                      embedded: true,
                    ),
                    _ContentEmbeddedZappersList(zappers: zappers),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBar(BuildContext context, TabController controller) {
    Widget tabIcon(IconData asset) => Tab(
          height: 30,
          child: Builder(
            builder: (context) => AppIcon(
              asset,
              size: 20,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: FluidBlurContainer(
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: controller,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.all(3),
          labelColor: Theme.of(context).primaryColorDark,
          unselectedLabelColor: Theme.of(context).hintColor,
          indicator: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(300),
          ),
          tabs: [
            tabIcon(FeatureIcons.comments),
            tabIcon(FeatureIcons.heart),
            tabIcon(FeatureIcons.nQuotes),
            tabIcon(FeatureIcons.nZaps),
          ],
        ),
      ),
    );
  }
}

class _ContentEmbeddedZappersList extends StatefulWidget {
  const _ContentEmbeddedZappersList({required this.zappers});

  final Map<String, MapEntry<String, int>> zappers;

  @override
  State<_ContentEmbeddedZappersList> createState() =>
      _ContentEmbeddedZappersListState();
}

class _ContentEmbeddedZappersListState
    extends State<_ContentEmbeddedZappersList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersInfoListCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
        buildWhen: (previous, current) =>
            previous.isLoading != current.isLoading,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: LoadingWidget());
          }
          return ZappersList(
            zappers: Map.fromEntries(
              widget.zappers.entries.toList()
                ..sort((a, b) => b.value.value.compareTo(a.value.value)),
            ),
            controller: _controller,
          );
        },
      ),
    );
  }
}
