// ignore_for_file: public_member_api_docs, sort_constructors_first, avoid_bool_literals_in_conditional_expressions
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:numeral/numeral.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../common/animations/heartbeat_fade.dart';
import '../../logic/leading_cubit/leading_cubit.dart';
import '../../logic/metadata_cubit/metadata_cubit.dart';
import '../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/picture_model.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../dm_view/widgets/dm_details.dart';
import '../note_view/note_view.dart';
import '../profile_view/profile_view.dart';
import '../threads_view/threads_view.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../write_note_view/write_note_view.dart';
import 'buttons_containers_widgets.dart';
import 'container_boxes.dart';
import 'custom_icon_buttons.dart';
import 'data_providers.dart';
import 'no_content_widgets.dart';
import 'note_stats_view.dart';
import 'parsed_media_container.dart';
import 'profile_picture.dart';
import 'pull_down_global_button.dart';
import 'response_snackbar.dart';
import 'zappers_view.dart';

class NoteStats extends HookWidget {
  const NoteStats({
    super.key,
    required this.id,
    required this.model,
    required this.isMain,
    this.autoTranslate = false,
    this.onEventAdded,
    this.onTextTranslated,
    this.onMuteActionSuccess,
  });

  final String id;
  final BaseEventModel model;
  final bool isMain;
  final bool autoTranslate;
  final Function(String)? onTextTranslated;
  final Function()? onEventAdded;
  final Function(String, bool)? onMuteActionSuccess;

  @override
  Widget build(BuildContext context) {
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
            if (isMain) {
              notesEventsCubit.getSpecificContentStats(model.id);
            } else {
              notesEventsCubit.getContentStatsOptimized(model.id);
            }
          }
        });

        return () => timer.cancel(); // Cleanup timer
      }
      return null;
    }, [isInViewport.value]);

    return VisibilityDetector(
      key: ValueKey(model.id),
      onVisibilityChanged: (info) {
        if (context.mounted) {
          if (info.visibleFraction == 0.5) {
            if (isMain) {
              notesEventsCubit.getSpecificContentStats(model.id);
            } else {
              notesEventsCubit.getContentStats(model.id);
            }
          }

          if (!isInViewport.value) {
            isInViewport.value = true;
          }
        }
      },
      child: BlocBuilder<NotesEventsCubit, NotesEventsState>(
        buildWhen: (previous, current) =>
            previous.eventsStats[model.id] != current.eventsStats[model.id] ||
            previous.mutes != current.mutes,
        builder: (context, state) {
          final stats = notesEventsCubit.getDirectStats(model.id);

          final replies = stats['replies'];
          final reposts = stats['reposts'];
          final quotes = stats['quotes'];
          final reactions = stats['reactions'];
          final zappers = stats['zappers'];
          final zapsData = stats['zapsData'];
          final selfZaps = stats['selfZaps'];
          final selfReaction = stats['selfReaction'];
          final selfRepost = stats['selfRepost'];
          final selfQuote = stats['selfQuote'];
          final selfReply = stats['selfReply'];

          return RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 4,
              children: [
                if (model is DetailedNoteModel)
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
                SizedBox(
                  height: 25,
                  child: Row(
                    children: [
                      Expanded(
                        child: model is DetailedNoteModel
                            ? ListView(
                                scrollDirection: Axis.horizontal,
                                children: buildActionButtons(
                                  context: context,
                                  reactions: reactions,
                                  selfReaction: selfReaction,
                                  replies: replies,
                                  selfReply: selfReply,
                                  reposts: reposts,
                                  selfRepost: selfRepost,
                                  quotes: quotes,
                                  selfQuote: selfQuote,
                                  zappers: zappers,
                                  zapsData: zapsData,
                                  selfZaps: selfZaps,
                                ))
                            : _buildPictureActionButtons(
                                context: context,
                                reactions: reactions,
                                selfReaction: selfReaction,
                                replies: replies,
                                selfReply: selfReply,
                                reposts: reposts,
                                selfRepost: selfRepost,
                                quotes: quotes,
                                selfQuote: selfQuote,
                                zappers: zappers,
                                zapsData: zapsData,
                                selfZaps: selfZaps,
                              ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      if (model is DetailedNoteModel)
                        TranslationButton(
                          autoTranslate: autoTranslate,
                          isMain: isMain,
                          note: model as DetailedNoteModel,
                          onTextTranslated: onTextTranslated,
                        ),
                      BlocBuilder<NotesEventsCubit, NotesEventsState>(
                        buildWhen: (previous, current) =>
                            previous.mutes != current.mutes,
                        builder: (context, state) {
                          return PullDownGlobalButton(
                            model: model,
                            enableCopyNpub: true,
                            enableCopyId: true,
                            enableBookmark: true,
                            enableCopyText: true,
                            enableShareImage: model is DetailedNoteModel,
                            enableShowRawEvent: true,
                            enableDelete: canSign() &&
                                currentSigner!.getPublicKey() == model.pubkey,
                            enableRepublish: true,
                            enablePin: canSign() && model is DetailedNoteModel,
                            onDelete: () {
                              showCupertinoDeletionDialogue(
                                context: context,
                                title: context.t
                                    .deleteContent(type: context.t.note)
                                    .capitalizeFirst(),
                                description: context.t
                                    .confirmDeleteContent(type: context.t.note)
                                    .capitalizeFirst(),
                                buttonText: context.t.delete.capitalizeFirst(),
                                onDelete: () async {
                                  final isSuccessful = await notesEventsCubit
                                      .deleteNote(model.id);

                                  if (isSuccessful && context.mounted) {
                                    BotToastUtils.showSuccess(
                                        context.t.noteDeletedSuccessfully);
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            },
                            bookmarkStatus:
                                notesEventsCubit.state.bookmarks.contains(
                              model.id,
                            ),
                            enableShare: true,
                            enableMute: true,
                            enableMuteEvent: model is DetailedNoteModel,
                            muteEventStatus:
                                state.mutesEvents.contains(model.id),
                            iconColor: Theme.of(context).highlightColor,
                            muteStatus: state.mutes.contains(model.pubkey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPictureActionButtons({
    required BuildContext context,
    required dynamic reactions,
    required dynamic selfReaction,
    required dynamic replies,
    required dynamic selfReply,
    required dynamic reposts,
    required dynamic selfRepost,
    required dynamic quotes,
    required dynamic selfQuote,
    required dynamic zappers,
    required dynamic zapsData,
    required dynamic selfZaps,
  }) {
    final actions =
        nostrRepository.currentAppCustomization?.actionsArrangement ??
            defaultActionsArrangement;

    return Row(
      children: [
        ...actions.entries
            .where(
          (action) => action.value,
        )
            .map((action) {
          switch (action.key) {
            case 'reactions':
              return Expanded(
                child: _reactButton(selfReaction, reactions),
              );
            case 'replies':
              return Expanded(
                child: _replyButton(context, selfReply, replies),
              );
            case 'quotes':
              return Expanded(
                child: _quoteButton(selfQuote, context, quotes),
              );
            case 'zaps':
              return Expanded(
                child: _zapButton(selfZaps, zappers, zapsData),
              );
            default:
              return const SizedBox.shrink();
          }
        }),
      ],
    );
  }

  List<Widget> buildActionButtons({
    required BuildContext context,
    required dynamic reactions,
    required dynamic selfReaction,
    required dynamic replies,
    required dynamic selfReply,
    required dynamic reposts,
    required dynamic selfRepost,
    required dynamic quotes,
    required dynamic selfQuote,
    required dynamic zappers,
    required dynamic zapsData,
    required dynamic selfZaps,
  }) {
    final actions =
        nostrRepository.currentAppCustomization?.actionsArrangement ??
            defaultActionsArrangement;

    return actions.entries
        .where(
          (action) => action.value,
        )
        .map((action) {
          switch (action.key) {
            case 'reactions':
              return _reactButton(selfReaction, reactions);
            case 'replies':
              return _replyButton(context, selfReply, replies);
            case 'reposts':
              if (model is DetailedNoteModel) {
                return _repostButton(context, reposts, selfRepost);
              }

              return const SizedBox.shrink();
            case 'quotes':
              return _quoteButton(selfQuote, context, quotes);
            case 'zaps':
              return _zapButton(selfZaps, zappers, zapsData);
            default:
              return const SizedBox.shrink();
          }
        })
        .expand(
            (widget) => [widget, const SizedBox(width: kDefaultPadding / 3)])
        .toList();
  }

  ZapButton _zapButton(selfZaps, zappers, zapsData) {
    return ZapButton(
      id: model.id,
      eventPubkey: model.pubkey,
      pubkey: currentSigner?.getPublicKey() ?? '',
      selfZaps: selfZaps,
      zappers: zappers,
      zapsData: zapsData,
    );
  }

  CustomIconButton _quoteButton(selfQuote, BuildContext context, quotes) {
    return CustomIconButton(
      key: ValueKey(selfQuote),
      backgroundColor: kTransparent,
      icon: FeatureIcons.quote,
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return NetStatsView(
              id: model.id,
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
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return AddReply(
                  attachedEvent: model,
                  isMention: false,
                  onSuccess: (ev) {
                    notesEventsCubit.addEventRelatedData(
                      event: ev,
                      replyNoteId: model.id,
                    );
                  },
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
      value: quotes.length.toString(),
      iconColor: selfQuote
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      textColor: selfQuote
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      size: 18,
      fontSize: 15,
    );
  }

  CustomIconButton _repostButton(BuildContext context, reposts, selfRepost) {
    return CustomIconButton(
      backgroundColor: kTransparent,
      icon: FeatureIcons.repost,
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return NetStatsView(
              id: model.id,
              type: NoteRelatedEventsType.reposts,
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
            notesEventsCubit.repostNote(model as DetailedNoteModel);
          },
          context: context,
        );
      },
      value: reposts.length.toString(),
      iconColor: selfRepost
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      textColor: selfRepost
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      size: 18,
      fontSize: 15,
    );
  }

  CustomIconButton _replyButton(BuildContext context, selfReply, replies) {
    return CustomIconButton(
      backgroundColor: kTransparent,
      icon: FeatureIcons.comments,
      onLongPress: () {
        YNavigator.pushPage(
          context,
          (context) => model is DetailedNoteModel
              ? NoteView(note: model as DetailedNoteModel)
              : ContentThreadsView(aTag: model.id),
        );
      },
      onClicked: () {
        doIfCanSign(
          func: () {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                if (model is DetailedNoteModel) {
                  final m = model as DetailedNoteModel;
                  return AddReply(
                    onSuccess: (ev) {
                      notesEventsCubit.addEventRelatedData(
                        event: ev,
                        replyNoteId: m.id,
                      );

                      onEventAdded?.call();
                    },
                    replyContent: {
                      'pubkey': m.pubkey,
                      'pTags': m.cleanPtags(),
                      'date': m.createdAt,
                      'content': m.content,
                      'replyData': m.replyData(),
                    },
                  );
                } else {
                  final m = model as PictureModel;

                  return AddReply(
                    onSuccess: (ev) {
                      notesEventsCubit.addEventRelatedData(
                        event: ev,
                        replyNoteId: m.id,
                      );

                      onEventAdded?.call();
                    },
                    // attachedEvent: m,
                    replyContent: {
                      'pubkey': m.pubkey,
                      'date': m.createdAt,
                      'content': m.content,
                      'replyData': [
                        ['e', m.id, '', 'root'],
                      ]
                    },
                  );
                }
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
      iconColor: selfReply
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      textColor: selfReply
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      value: replies.length.toString(),
      size: 18,
      fontSize: 15,
    );
  }

  CustomReactionButton _reactButton(selfReaction, reactions) {
    return CustomReactionButton(
      selfReaction: selfReaction,
      id: model.id,
      isReplaceable: false,
      pubkey: model.pubkey,
      reactions: reactions,
      size: 16,
    );
  }
}

class ZappersRow extends StatelessWidget {
  const ZappersRow({
    super.key,
    required this.zapData,
    required this.zappers,
  });

  final Map<String, dynamic> zapData;
  final Map<String, MapEntry<String, int>> zappers;

  @override
  Widget build(BuildContext context) {
    final commonPubkeys = zapData['nextBestPubkeys'] as List;
    void openZappersList() {
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

    return BlocBuilder<MetadataCubit, MetadataState>(
      builder: (context, state) {
        final List<Widget> images = [];

        for (int i = 0; i < commonPubkeys.length; i++) {
          final pubkey = commonPubkeys.elementAt(i);

          images.add(
            MetadataProvider(
              pubkey: pubkey,
              child: (metadata, p1) => ProfilePicture2(
                size: 30,
                image: metadata.picture,
                pubkey: metadata.pubkey,
                padding: 0,
                strokeWidth: 2,
                strokeColor: Theme.of(context).scaffoldBackgroundColor,
                onClicked: openZappersList,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: openZappersList,
          behavior: HitTestBehavior.translucent,
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final amount = zapData['highestZap'] as int;

                    if (amount <= 0) {
                      return const SizedBox();
                    }

                    final id = zapData['highestZapId'] as String;

                    return _highestZapper(id, openZappersList, amount);
                  },
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Stack(
                children: [
                  SizedBox(
                    height: 30,
                    width: 30 + (images.length - 1) * 17,
                  ),
                  ...images.reversed.map(
                    (e) => Positioned(
                      left: images.indexOf(e) * 17,
                      child: e,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  FutureBuilder<Event?> _highestZapper(
      String id, Function() openZappersList, int amount) {
    String message = '';

    return FutureBuilder(
        future: id.isNotEmpty ? nc.db.loadEventById(id, false) : null,
        builder: (context, snapshot) {
          final ev = snapshot.data;

          if (ev != null) {
            message = getZapPubkey(ev.tags)[1];
          }
          return MetadataProvider(
            pubkey: zapData['highestZapPubkey'],
            child: (metadata, p1) => Row(
              spacing: kDefaultPadding / 8,
              children: [
                ProfilePicture2(
                  size: 30,
                  image: metadata.picture,
                  pubkey: metadata.pubkey,
                  padding: 0,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).scaffoldBackgroundColor,
                  onClicked: openZappersList,
                ),
                _dataContainer(context, amount, message, metadata),
              ],
            ),
          );
        });
  }

  Flexible _dataContainer(
      BuildContext context, int amount, String message, Metadata metadata) {
    return Flexible(
      child: Container(
        height: 30,
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: kDefaultPadding / 4,
          children: [
            _zapAmount(amount, context),
            if (message.isNotEmpty)
              Flexible(
                child: ScrollShadow(
                  color: Theme.of(context).cardColor,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            height: 1,
                          ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            _pulldownButton(context, metadata),
          ],
        ),
      ),
    );
  }

  Row _zapAmount(int amount, BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 8,
      children: [
        SizedBox(
          width: 15,
          height: 15,
          child: SvgPicture.asset(
            FeatureIcons.zapAmount,
            fit: BoxFit.scaleDown,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        Text(
          amount.numeral(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  PullDownButton _pulldownButton(BuildContext context, Metadata metadata) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          PullDownMenuActionsRow.medium(
            items: [
              _profileButton(context, metadata, textStyle),
              _messageButton(context, metadata, textStyle),
              _zapButton(context, metadata, textStyle),
            ],
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => RotatedBox(
        quarterTurns: 1,
        child: CustomIconButton(
          backgroundColor: Theme.of(context).cardColor,
          onClicked: showMenu,
          size: 15,
          vd: -4,
          icon: FeatureIcons.more,
        ),
      ),
    );
  }

  PullDownMenuItem _zapButton(
      BuildContext context, Metadata metadata, TextStyle? textStyle) {
    return PullDownMenuItem(
      title: context.t.zap.capitalizeFirst(),
      onTap: () {
        doIfCanSign(
          func: () {
            showModalBottomSheet(
              elevation: 0,
              context: context,
              builder: (_) {
                return SendZapsView(
                  metadata: metadata,
                  isZapSplit: false,
                  zapSplits: const [],
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
      itemTheme: PullDownMenuItemTheme(
        textStyle: textStyle,
      ),
      iconWidget: SvgPicture.asset(
        FeatureIcons.zap,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  PullDownMenuItem _messageButton(
      BuildContext context, Metadata metadata, TextStyle? textStyle) {
    return PullDownMenuItem(
      title: context.t.message.capitalizeFirst(),
      onTap: () {
        doIfCanSign(
          func: () {
            Navigator.pushNamed(
              context,
              DmDetails.routeName,
              arguments: [
                metadata.pubkey,
              ],
            );
          },
          context: context,
        );
      },
      itemTheme: PullDownMenuItemTheme(
        textStyle: textStyle,
      ),
      iconWidget: SvgPicture.asset(
        FeatureIcons.message,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  PullDownMenuItem _profileButton(
      BuildContext context, Metadata metadata, TextStyle? textStyle) {
    return PullDownMenuItem(
      title: context.t.profile.capitalizeFirst(),
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) => ProfileView(
            pubkey: metadata.pubkey,
          ),
        );
      },
      itemTheme: PullDownMenuItemTheme(
        textStyle: textStyle,
      ),
      iconWidget: SvgPicture.asset(
        FeatureIcons.user,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class ZapButton extends HookWidget {
  const ZapButton({
    super.key,
    required this.id,
    required this.eventPubkey,
    required this.zapsData,
    required this.zappers,
    required this.selfZaps,
    required this.pubkey,
  });

  final String id;
  final String eventPubkey;
  final Map<String, dynamic> zapsData;
  final Map<String, MapEntry<String, int>> zappers;
  final bool selfZaps;
  final String pubkey;

  @override
  Widget build(BuildContext context) {
    final isFastZapping = useState(false);

    final onDefaultZap = useCallback(
      () {
        doIfCanSign(
          func: () async {
            final m = await metadataCubit.getAvailableMetadata(eventPubkey);
            isFastZapping.value = true;

            walletManagerCubit.handleWalletZap(
              user: m,
              sats: getCurrentUserDefaultZapAmount(),
              comment: '',
              useExternalWallet: walletManagerCubit.state.useDefaultWallet,
              onFailure: (message) {
                if (context.mounted) {
                  isFastZapping.value = false;
                }

                BotToastUtils.showError(message);
              },
              eventId: id,
              onSuccess: (_) {
                if (context.mounted) {
                  isFastZapping.value = false;
                }

                notesEventsCubit.handleSubmittedZap(
                  eventId: id,
                  recipientPubkey: eventPubkey,
                  amount: getCurrentUserDefaultZapAmount(),
                  senderPubkey: currentSigner!.getPublicKey(),
                  isIdentifier: false,
                );
              },
              onFinished: (_) {
                if (context.mounted) {
                  isFastZapping.value = false;
                }
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
            final m = await metadataCubit.getAvailableMetadata(eventPubkey);

            if (context.mounted) {
              showModalBottomSheet(
                elevation: 0,
                context: context,
                builder: (_) {
                  return SendZapsView(
                    metadata: m,
                    eventId: id,
                    isZapSplit: false,
                    zapSplits: const [],
                    onSuccess: (_, amount) {
                      notesEventsCubit.handleSubmittedZap(
                        eventId: id,
                        recipientPubkey: eventPubkey,
                        amount: amount,
                        senderPubkey: currentSigner!.getPublicKey(),
                        isIdentifier: false,
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
              key: const ValueKey('selfZaps'),
              width: 40,
              child: SpinKitThreeBounce(
                size: 10,
                color: Theme.of(context).primaryColor,
              ),
            )
          : _zapButton(context, onDefaultZap, onSetZap),
    );
  }

  Widget _zapButton(
      BuildContext context, Function() onDefaultZap, Function() onSetZap) {
    return Opacity(
      opacity: pubkey == eventPubkey ? 0.5 : 1,
      child: CustomIconButton(
        key: ValueKey(selfZaps),
        backgroundColor: kTransparent,
        icon: selfZaps ? FeatureIcons.zapAmount : FeatureIcons.zap,
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
          if (pubkey == eventPubkey) {
            return;
          }

          if (!nostrRepository.enableOneTapZap) {
            onDefaultZap();
          } else {
            onSetZap();
          }
        },
        onClicked: () {
          if (pubkey == eventPubkey) {
            return;
          }

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
        size: 18,
        fontSize: 15,
      ),
    );
  }
}

class TranslationButton extends HookWidget {
  const TranslationButton({
    super.key,
    required this.note,
    required this.autoTranslate,
    required this.isMain,
    this.onTextTranslated,
  });

  final DetailedNoteModel note;
  final bool autoTranslate;
  final bool isMain;
  final Function(String)? onTextTranslated;

  @override
  Widget build(BuildContext context) {
    final isTranslating = useState(autoTranslate);
    final showOriginalContent = useState(true);

    final extractedContent = useState(<String, dynamic>{});

    Future<void> translateContent() async {
      if (!isMain && canBeTruncated(note.content)) {
        YNavigator.pushPage(
          context,
          (context) => NoteView(
            note: note,
            autoTranslate: true,
          ),
        );

        return;
      }

      isTranslating.value = true;

      final lc = LocaleSettings.currentLocale.languageCode;
      final n =
          nostrRepository.currentTranslations[generateSpecialId(note.content)];

      final translation = n?[lc];

      if (translation != null) {
        final val = restoreOriginalString(
          replacedString: translation,
          extractedData: extractedContent.value['extractedData'],
        );

        onTextTranslated?.call(val);

        showOriginalContent.value = false;
      } else {
        final res = await localizationCubit.translateContent(
          content: extractedContent.value['replacedString'],
        );

        if (res.key) {
          nostrRepository.currentTranslations[generateSpecialId(note.content)] =
              {
            lc: res.value,
          };

          final val = restoreOriginalString(
            replacedString: res.value,
            extractedData: extractedContent.value['extractedData'],
          );

          onTextTranslated?.call(val);

          showOriginalContent.value = false;
        } else {
          BotToastUtils.showError(res.value);
        }
      }

      isTranslating.value = false;
    }

    useMemoized(
      () async {
        extractedContent.value = replaceWithIndexAndExtract(
          input: note.content,
        );

        if (autoTranslate && isMain) {
          translateContent();
        }
      },
    );

    return HeartbeatFade(
      enabled: isTranslating.value,
      child: Tooltip(
        message: context.t.seeTranslation,
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
        child: CustomIconButton(
          key: const ValueKey('translate_text'),
          onClicked: () async {
            if (!isTranslating.value) {
              if (showOriginalContent.value) {
                translateContent();
              } else {
                onTextTranslated?.call(note.content);
                showOriginalContent.value = true;
              }
            }
          },
          icon: FeatureIcons.translation,
          size: 16,
          backgroundColor: kTransparent,
          iconColor: showOriginalContent.value
              ? Theme.of(context).highlightColor
              : Theme.of(context).primaryColor,
          vd: -4,
        ),
      ),
    );
  }
}

class CustomReactionButton extends HookWidget {
  const CustomReactionButton({
    required this.id,
    required this.pubkey,
    required this.isReplaceable,
    required this.reactions,
    required this.size,
    this.selfReaction,
    super.key,
  });

  final String id;
  final String pubkey;
  final bool isReplaceable;
  final Map<String, String> reactions;
  final String? selfReaction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reactionButtonKey = useMemoized(() => GlobalKey(), []);
    final event = useState<Event?>(null);

    useEffect(() {
      bool isMounted = true;

      Future<void> loadEvent() async {
        if (selfReaction != null) {
          final loaded = await nc.db.loadEventById(selfReaction!, false);

          if (isMounted) {
            event.value = loaded;
          }
        } else {
          if (isMounted) {
            event.value = null;
          }
        }
      }

      loadEvent();

      return () {
        isMounted = false; // cleanup on dispose
      };
    }, [selfReaction]);

    final onDefaultReaction = useCallback(
      () {
        doIfCanSign(
          func: () {
            notesEventsCubit.onReact(
              id: id,
              pubkey: pubkey,
              r: isReplaceable,
              customReaction: nostrRepository
                  .defaultReactions[currentSigner!.getPublicKey()],
            );
          },
          context: context,
        );
      },
    );

    final onSetReaction = useCallback(
      () {
        doIfCanSign(
          func: () {
            showReactionPopup(
              context,
              reactionButtonKey,
              (emoji) {
                notesEventsCubit.onReact(
                  id: id,
                  pubkey: pubkey,
                  r: isReplaceable,
                  customReaction: emoji,
                );
              },
            );
          },
          context: context,
        );
      },
    );

    return CustomIconButton(
      key: reactionButtonKey,
      backgroundColor: kTransparent,
      icon: getIcon(event.value),
      emoji: getEmoji(event.value),
      imageUrl: getCustomEmoji(event.value),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return NetStatsView(
              id: id,
              type: NoteRelatedEventsType.reactions,
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onDoubleTap: () {
        if (!nostrRepository.enableOneTapReaction) {
          onDefaultReaction();
        } else {
          onSetReaction();
        }
      },
      onClicked: () {
        if (nostrRepository.enableOneTapReaction) {
          onDefaultReaction();
        } else {
          onSetReaction();
        }
      },
      value: reactions.length.toString(),
      iconColor: event.value != null
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      textColor: event.value != null
          ? Theme.of(context).primaryColor
          : Theme.of(context).highlightColor,
      size: 18,
      fontSize: 15,
    );
  }

  String getIcon(Event? reactionEvent) {
    return reactionEvent != null
        ? FeatureIcons.heartFilled
        : FeatureIcons.heart;
  }

  String? getEmoji(Event? reactionEvent) {
    final emoji = reactionEvent != null &&
            reactionEvent.content.isNotEmpty &&
            reactionEvent.content != '+' &&
            reactionEvent.content != '-' &&
            reactionEvent.content.length <= 2
        ? reactionEvent.content
        : null;

    return emoji;
  }

  String? getCustomEmoji(Event? reactionEvent) {
    return reactionEvent != null &&
            reactionEvent.content.isNotEmpty &&
            reactionEvent.content.startsWith(':') &&
            reactionEvent.content.endsWith(':')
        ? reactionEvent.getCustomEmojiUrl(reactionEvent.content)
        : null;
  }
}

class RepostNoteContainer extends HookWidget {
  const RepostNoteContainer({
    super.key,
    required this.event,
    this.onMuteActionSuccess,
  });

  final Event event;
  final Function(String, bool)? onMuteActionSuccess;

  @override
  Widget build(BuildContext context) {
    final originalEvent = useState<dynamic>(null);
    final repostedEventId = useState(
      event.eTags.isNotEmpty ? event.eTags.first : '',
    );

    useMemoized(
      () {
        originalEvent.value = getRepostedEvent();

        if (originalEvent.value != null && originalEvent.value is String) {
          singleEventCubit.getEvent(originalEvent.value, false);
        } else if (originalEvent.value is Event) {
          nc.db.saveEvent(originalEvent.value);
        }
      },
    );

    void onClicked() {
      showModalBottomSheet(
        context: context,
        elevation: 0,
        builder: (_) {
          return NetStatsView(
            id: repostedEventId.value,
            type: NoteRelatedEventsType.reposts,
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetadataProvider(
          pubkey: event.pubkey,
          child: (metadata, nip05) => GestureDetector(
            onTap: onClicked,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding / 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                color: Theme.of(context).cardColor,
              ),
              child: _repostRow(repostedEventId, metadata, onClicked),
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        if (originalEvent.value != null && originalEvent.value is Event)
          DetailedNoteContainer(
            note: DetailedNoteModel.fromEvent(originalEvent.value),
            isMain: false,
            addLine: false,
            enableReply: true,
            onMuteActionSuccess: onMuteActionSuccess,
          )
        else if (originalEvent.value != null)
          _fetchedNote(originalEvent)
        else
          Container(),
      ],
    );
  }

  BlocBuilder<NotesEventsCubit, NotesEventsState> _fetchedNote(
      ValueNotifier<dynamic> originalEvent) {
    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      builder: (context, state) {
        return SingleEventProvider(
          id: originalEvent.value,
          isReplaceable: false,
          child: (event) {
            if (event == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kDefaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  context.t.postNotFound.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              );
            } else {
              return DetailedNoteContainer(
                note: DetailedNoteModel.fromEvent(event),
                isMain: false,
                addLine: false,
              );
            }
          },
        );
      },
    );
  }

  BlocBuilder<NotesEventsCubit, NotesEventsState> _repostRow(
      ValueNotifier<String> repostedEventId,
      Metadata metadata,
      Function() onClicked) {
    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      buildWhen: (previous, current) =>
          previous.eventsStats[repostedEventId.value] !=
              current.eventsStats[repostedEventId.value] ||
          previous.mutes != current.mutes,
      builder: (context, state) {
        final noteStats = state.eventsStats[repostedEventId.value];
        final reposts = noteStats?.filteredReposts(state.mutes) ?? {};

        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: kDefaultPadding / 3,
          children: [
            SvgPicture.asset(
              FeatureIcons.repost,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
              width: 15,
              height: 15,
            ),
            ProfilePicture2(
              size: 18,
              image: metadata.picture,
              pubkey: metadata.pubkey,
              padding: 0,
              strokeWidth: 0,
              reduceSize: true,
              strokeColor: kTransparent,
              onClicked: onClicked,
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      metadata.getName(),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reposts.length > 1) ...[
                    Text(
                      '  ${context.t.andMore(number: reposts.length - 1)}',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).highlightColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  dynamic getRepostedEvent() {
    dynamic data;

    if (event.content.isNotEmpty) {
      try {
        data = Event.fromJson(jsonDecode(event.content));
      } catch (_) {
        data = event.eTags.isNotEmpty ? event.eTags.first : null;
      }
    } else {
      data = event.eTags.isNotEmpty ? event.eTags.first : null;
    }

    return data;
  }
}

class DetailedNoteContainer extends HookWidget {
  const DetailedNoteContainer({
    super.key,
    required this.note,
    required this.isMain,
    required this.addLine,
    this.loadPreviousNote = false,
    this.enableReply = false,
    this.extendLine = false,
    this.autoTranslate = false,
    this.isReply = false,
    this.isFilterHidden = false,
    this.shouldConsiderHiddenReply = false,
    this.noRender = false,
    this.onClicked,
    this.onEventAdded,
    this.onMuteActionSuccess,
  });

  final DetailedNoteModel note;
  final bool isMain;
  final bool addLine;
  final bool loadPreviousNote;
  final bool extendLine;
  final bool enableReply;
  final bool autoTranslate;
  final bool isReply;
  final bool isFilterHidden;
  final bool shouldConsiderHiddenReply;
  final bool noRender;
  final Function()? onClicked;
  final Function()? onEventAdded;
  final Function(String, bool)? onMuteActionSuccess;

  @override
  Widget build(BuildContext context) {
    final replyEvent = useState<MapEntry<String, bool>?>(null);
    final noteContent = useState(note.content);

    useMemoized(
      () async {
        if (context.mounted) {
          if (enableReply) {
            if (note.replyTo.isNotEmpty) {
              replyEvent.value = MapEntry(note.replyTo, false);
            } else if (note.originId != null && note.isOriginEtag != null) {
              if (note.isOriginEtag!) {
                replyEvent.value = MapEntry(note.originId!, false);
              } else {
                try {
                  final identifier = note.originId!.split(':').last;
                  replyEvent.value = MapEntry(identifier, true);
                } catch (e) {
                  lg.i(e);
                }
              }
            }

            if (replyEvent.value != null) {
              singleEventCubit.getEvent(
                replyEvent.value!.key,
                replyEvent.value!.value,
              );
            }
          }
        }
      },
    );

    final click = onClicked ??
        (isMain
            ? () {}
            : () {
                Navigator.pushNamed(
                  context,
                  NoteView.routeName,
                  arguments: [note],
                );
              });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: click,
      child: Builder(
        builder: (context) {
          final child = _feedColumn(context, replyEvent, click, noteContent);

          return _mainColumn(replyEvent, context, child, click, noteContent);
        },
      ),
    );
  }

  Column _mainColumn(
      ValueNotifier<MapEntry<String, bool>?> replyEvent,
      BuildContext context,
      Expanded child,
      Function() click,
      ValueNotifier<String> noteContent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enableReply &&
            replyEvent.value != null &&
            !settingsCubit.useCompactReplies) ...[
          ReplyContainer(
            replyEvent: replyEvent,
            isMain: isMain,
            shouldConsiderHiddenReply: shouldConsiderHiddenReply,
          ),
        ],
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mainMetadataRow(context),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              child,
            ],
          ),
        ),
        if (isMain || isReply) ...[
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          ParsedText(
            key: ValueKey(note.id),
            onClicked: click,
            pubkey: note.pubkey,
            text: noteContent.value.trim(),
            enableHidingMedia: true,
            style: noRender
                ? Theme.of(context).textTheme.labelLarge
                : Theme.of(context).textTheme.bodyMedium,
            isMainNote: isMain,
            disableNoteParsing: noRender ? noRender : null,
            disableUrlParsing: noRender ? noRender : null,
            maxLines: noRender ? 5 : null,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          NoteStats(
            id: note.id,
            model: note,
            isMain: isMain,
            onEventAdded: onEventAdded,
            autoTranslate: autoTranslate,
            onTextTranslated: (text) {
              noteContent.value = text;
            },
            onMuteActionSuccess: onMuteActionSuccess,
          ),
        ],
      ],
    );
  }

  MetadataProvider _mainMetadataRow(BuildContext context) {
    return MetadataProvider(
      pubkey: note.pubkey,
      child: (metadata, p1) => Column(
        children: [
          ProfilePicture3(
            image: isUserMuted(note.pubkey) ? '' : metadata.picture,
            pubkey: metadata.pubkey,
            size: noRender
                ? 30
                : isMain
                    ? 45
                    : isReply
                        ? 30
                        : 35,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () {
              openProfileFastAccess(
                context: context,
                pubkey: metadata.pubkey,
              );
            },
          ),
          if (addLine) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            const Expanded(
              child: VerticalDivider(
                thickness: 1.5,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Expanded _feedColumn(
      BuildContext context,
      ValueNotifier<MapEntry<String, bool>?> replyEvent,
      Function() click,
      ValueNotifier<String> noteContent) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _generalInfoRow(context),
          if (enableReply &&
              replyEvent.value != null &&
              settingsCubit.useCompactReplies) ...[
            _replyBox(replyEvent),
          ],
          if (!isMain && !isReply) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            ParsedText(
              key: ValueKey(note.id),
              onClicked: click,
              text: noteContent.value.trim(),
              enableHidingMedia: true,
              pubkey: note.pubkey,
              style: Theme.of(context).textTheme.bodyMedium,
              isMainNote: isMain,
            ),
            const SizedBox(
              height: kDefaultPadding / 3,
            ),
            NoteStats(
              id: note.id,
              model: note,
              isMain: isMain,
              onEventAdded: onEventAdded,
              autoTranslate: autoTranslate,
              onTextTranslated: (text) {
                noteContent.value = text;
              },
              onMuteActionSuccess: onMuteActionSuccess,
            ),
            if (extendLine)
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
          ],
        ],
      ),
    );
  }

  SingleEventProvider _replyBox(
      ValueNotifier<MapEntry<String, bool>?> replyEvent) {
    return SingleEventProvider(
      id: replyEvent.value!.key,
      isReplaceable: replyEvent.value!.value,
      child: (event) {
        return Column(
          children: [
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            NoteReplyBox(event: event),
          ],
        );
      },
    );
  }

  Row _generalInfoRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _noteInfo(),
              if (!isMain && !isReply) ...[
                DotContainer(
                  color: Theme.of(context).primaryColorDark,
                  size: 3,
                ),
                Text(
                  StringUtil.formatTimeDifference(
                    note.createdAt,
                  ),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).highlightColor,
                        height: 1,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
            ],
          ),
        ),
        if (note.isPaid) ...[
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          const PaidContainer(),
        ],
      ],
    );
  }

  Flexible _noteInfo() {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final style = noRender
                  ? Theme.of(context).textTheme.labelLarge
                  : isMain
                      ? Theme.of(context).textTheme.bodyLarge
                      : Theme.of(context).textTheme.bodyMedium;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metadataRow(context, style),
                  if (isMain || isReply) ...[
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      StringUtil.formatTimeDifference(
                        note.createdAt,
                      ),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(
                              context,
                            ).highlightColor,
                            height: 1,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  MetadataProvider _metadataRow(BuildContext context, TextStyle? style) {
    return MetadataProvider(
      pubkey: note.pubkey,
      child: (metadata, isNip05Valid) => GestureDetector(
        onTap: () => openProfileFastAccess(
          context: context,
          pubkey: metadata.pubkey,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                isUserMuted(note.pubkey)
                    ? context.t.mutedUser
                    : metadata.getName(),
                style: style!.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNip05Valid) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              SvgPicture.asset(
                FeatureIcons.verified,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColor, BlendMode.srcIn),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReplyContainer extends StatefulWidget {
  const ReplyContainer({
    super.key,
    required this.replyEvent,
    required this.isMain,
    required this.shouldConsiderHiddenReply,
  });

  final ValueNotifier<MapEntry<String, bool>?> replyEvent;
  final bool isMain;
  final bool shouldConsiderHiddenReply;

  @override
  State<ReplyContainer> createState() => _ReplyContainerState();
}

class _ReplyContainerState extends State<ReplyContainer> {
  bool filterHidden = false;

  Event? event;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: nostrRepository.mutesStream,
      builder: (context, snapshot) {
        return DeletedNoteProvider(
            id: widget.replyEvent.value!.key,
            child: (isDeleted) {
              if (isDeleted) {
                return _content(null, true, context);
              }
              return SingleEventProvider(
                id: widget.replyEvent.value!.key,
                isReplaceable: widget.replyEvent.value!.value,
                child: (event) {
                  final shouldBeHidden = widget.shouldConsiderHiddenReply
                      ? (event != null &&
                          context
                              .read<LeadingCubit>()
                              .applyNotesFilter([event]).isEmpty)
                      : false;

                  return _content(event, shouldBeHidden, context);
                },
              );
            });
      },
    );
  }

  AnimatedCrossFade _content(
      Event? event, bool shouldBeHidden, BuildContext context) {
    return AnimatedCrossFade(
      firstChild: Padding(
        padding: const EdgeInsets.only(
          bottom: kDefaultPadding / 1.5,
        ),
        child: event == null
            ? const SizedBox(
                width: double.infinity,
              )
            : (shouldBeHidden && !filterHidden)
                ? _filter(context)
                : isUserMuted(event.pubkey)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MutedUserActionBox(pubkey: event.pubkey),
                          const SizedBox(
                            height: kDefaultPadding * 1.5,
                            child: VerticalDivider(
                              width: 35,
                            ),
                          ),
                        ],
                      )
                    : DetailedNoteContainer(
                        note: DetailedNoteModel.fromEvent(event),
                        isMain: widget.isMain,
                        addLine: true,
                      ),
      ),
      secondChild: const SizedBox(
        width: double.infinity,
      ),
      crossFadeState:
          event != null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 300),
    );
  }

  Column _filter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              filterHidden = true;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: defaultBoxDecoration().copyWith(
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              children: [
                Text(
                  context.t.appliedFilterDesc,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
                SizedBox(
                  child: Text(
                    ' ${context.t.showNote}',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 35,
          margin: const EdgeInsets.only(
            left: 15,
          ),
          child: const VerticalDivider(
            indent: kDefaultPadding / 2,
            width: 0,
          ),
        ),
      ],
    );
  }
}

class NoteReplyBox extends HookWidget {
  const NoteReplyBox({
    super.key,
    required this.event,
  });

  final Event? event;

  @override
  Widget build(BuildContext context) {
    final isCollapsed = useState(true);

    return StreamBuilder(
        stream: nostrRepository.mutesStream,
        builder: (context, snapshot) {
          return Column(
            children: [
              _replyTo(isCollapsed, context),
              if (event != null)
                if (isCollapsed.value)
                  const SizedBox(
                    width: double.infinity,
                    height: 0,
                  )
                else
                  _muteRow(context),
            ],
          );
        });
  }

  GestureDetector _replyTo(
      ValueNotifier<bool> isCollapsed, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (event != null) {
          isCollapsed.value = !isCollapsed.value;
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Text(
            '${context.t.replyingTo(name: '').capitalizeFirst()} ',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).highlightColor,
                ),
          ),
          _userInfo(context, isCollapsed),
        ],
      ),
    );
  }

  Padding _muteRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: kDefaultPadding / 2),
      child: IntrinsicHeight(
        child: Row(
          spacing: kDefaultPadding / 1.5,
          children: [
            VerticalDivider(
              color: Theme.of(context).primaryColor,
              width: 0,
              thickness: 2,
            ),
            Expanded(
              child: isUserMuted(event!.pubkey)
                  ? MutedUserActionBox(pubkey: event!.pubkey)
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      child: getSecondChild(
                        event: event!,
                        context: context,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Flexible _userInfo(BuildContext context, ValueNotifier<bool> isCollapsed) {
    return Flexible(
      child: event == null
          ? Text(
              context.t.user,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).highlightColor,
                  ),
            )
          : Row(
              spacing: kDefaultPadding / 4,
              children: [
                _metadataRow(context),
                SvgPicture.asset(
                  isCollapsed.value
                      ? FeatureIcons.arrowDown
                      : FeatureIcons.arrowUp,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).highlightColor,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
    );
  }

  Flexible _metadataRow(BuildContext context) {
    return Flexible(
      child: isUserMuted(event!.pubkey)
          ? Text(
              context.t.mutedUser.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : MetadataProvider(
              pubkey: event!.pubkey,
              child: (metadata, isNip05Valid) {
                return Text(
                  '@${metadata.getName()}',
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
    );
  }

  Widget getSecondChild({
    required Event event,
    required BuildContext context,
  }) {
    Widget widget = const SizedBox.shrink();
    switch (event.kind) {
      case EventKind.TEXT_NOTE:
        widget = DetailedNoteContainer(
          note: DetailedNoteModel.fromEvent(event),
          isMain: false,
          addLine: false,
          isReply: true,
        );
      case EventKind.LONG_FORM:
        widget = ParsedMediaContainer(
          key: ValueKey(event.id),
          baseEventModel: Article.fromEvent(event),
        );
      case EventKind.VIDEO_HORIZONTAL:
        widget = ParsedMediaContainer(
          key: ValueKey(event.id),
          baseEventModel: VideoModel.fromEvent(event),
        );
      case EventKind.VIDEO_VERTICAL:
        widget = ParsedMediaContainer(
          key: ValueKey(event.id),
          baseEventModel: VideoModel.fromEvent(event),
        );
      case EventKind.CURATION_ARTICLES:
        widget = ParsedMediaContainer(
          key: ValueKey(event.id),
          baseEventModel: Curation.fromEvent(event, ''),
        );
      case EventKind.CURATION_VIDEOS:
        widget = ParsedMediaContainer(
          key: ValueKey(event.id),
          baseEventModel: Curation.fromEvent(event, ''),
        );
    }

    return widget;
  }
}

class PaidContainer extends StatelessWidget {
  const PaidContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 4,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 6,
      ),
      child: Text(
        context.t.paid.capitalizeFirst(),
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: kWhite,
            ),
      ),
    );
  }
}
