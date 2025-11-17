// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import '../threads_view/threads_view.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../write_note_view/write_note_view.dart';
import 'custom_icon_buttons.dart';
import 'note_stats.dart';
import 'note_stats_view.dart';
import 'pull_down_global_button.dart';
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
    final isVideo =
        kind == EventKind.VIDEO_HORIZONTAL || kind == EventKind.VIDEO_VERTICAL;

    final aTag = isVideo ? identifier : '$kind:$pubkey:$identifier';

    // ✅ REPLACE the problematic useMemoized with this optimized version:
    final hasRequestedStats = useState(false);
    final isInViewport = useState(false);

    // Optimized stats loading - only when visible and not yet requested
    useEffect(() {
      if (isInViewport.value && !hasRequestedStats.value) {
        // Add small delay to avoid loading during fast scrolling
        final timer = Timer(const Duration(milliseconds: 300), () {
          if (context.mounted && isInViewport.value) {
            hasRequestedStats.value = true;
            notesEventsCubit.getContentStats(aTag, r: !isVideo);
          }
        });

        return () => timer.cancel(); // Cleanup timer
      }
      return null;
    }, [isInViewport.value]);

    return VisibilityDetector(
      key: ValueKey(aTag),
      onVisibilityChanged: (info) {
        if (context.mounted) {
          if (info.visibleFraction == 0.5) {
            notesEventsCubit.getContentStats(aTag, r: !isVideo);
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
              aTag: aTag);

          final pullDownButton = PullDownGlobalButton(
            model: attachedEvent,
            enablePostInNote: true,
            enableCopyNpub: true,
            enableRepublish: true,
            enableCopyId: attachedEvent is VideoModel,
            enableCopyNaddr: attachedEvent is! VideoModel,
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
                      Flexible(child: pullDownButton),
                    ]
                  : [
                      Expanded(
                        child: Row(
                          spacing: kDefaultPadding / 4,
                          children: widgets,
                        ),
                      ),
                      pullDownButton,
                    ],
            ),
          );

          if (isInside) {
            return sb;
          } else {
            return Column(
              spacing: kDefaultPadding / 4,
              children: [
                if (!isInside)
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      child: ZappersRow(
                        zapData: zapsData,
                        zappers: zappers,
                      ),
                    ),
                    secondChild: const SizedBox(
                      width: double.infinity,
                    ),
                    crossFadeState: zappers.isNotEmpty
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                  ),
                sb,
              ],
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
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return NetStatsView(
              id: aTag,
              type: NoteRelatedEventsType.quotes,
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onClicked: () {
        doIfCanSign(
          func: () {
            YNavigator.pushPage(
              context,
              (context) => AddContentView(
                contentType: AppContentType.note,
                attachedEvent: attachedEvent,
                isMention: false,
                onSuccess: (ev) {
                  notesEventsCubit.addEventRelatedData(
                    event: ev,
                    replyNoteId: aTag,
                  );
                },
              ),
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
    return showModalBottomSheet(
      context: context,
      elevation: 0,
      builder: (_) {
        return AddReply(
          replyContent: {
            'pubkey': pubkey,
            'date': createdAt,
            'content': title,
            'replyData': isVideo
                ? [
                    ['e', identifier, '', 'root']
                  ]
                : [
                    Nip33.coordinatesToTag(
                      EventCoordinates(
                        kind,
                        pubkey,
                        identifier,
                        '',
                      ),
                    )..add('root'),
                  ],
          },
          onSuccess: (ev) {
            notesEventsCubit.addEventRelatedData(
              event: ev,
              replyNoteId: aTag,
            );
          },
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
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
              showModalBottomSheet(
                elevation: 0,
                context: context,
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
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
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
          showModalBottomSheet(
            context: context,
            elevation: 0,
            builder: (_) {
              return ZappersView(
                zappers: zappers,
              );
            },
            isScrollControlled: true,
            useRootNavigator: true,
            useSafeArea: true,
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
