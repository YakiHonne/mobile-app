// ignore_for_file: public_member_api_docs, sort_constructors_first, avoid_bool_literals_in_conditional_expressions
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import '../../logic/users_info_list_cubit/users_info_list_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/picture_model.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/theme/custom/buttons_theme.dart';
import '../../utils/utils.dart';
import '../dm_view/widgets/dm_details.dart';
import '../note_view/note_view.dart';
import '../profile_view/profile_view.dart';
import '../subscription_view/subscription_view.dart';
import '../threads_view/threads_view.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../write_note_view/write_note_view.dart';
import 'app_icon.dart';
import 'buttons_containers_widgets.dart';
import 'container_boxes.dart';
import 'custom_icon_buttons.dart';
import 'data_providers.dart';
import 'dotted_container.dart';
import 'fluid_blur_container.dart';
import 'loading_indicators.dart';
import 'modal_sheet_container.dart';
import 'no_content_widgets.dart';
import 'note_stats_view.dart';
import 'parsed_media_container.dart';
import 'profile_picture.dart';
import 'pull_down_global_button.dart';
import 'response_snackbar.dart';
import 'sheet_drag_to_close.dart';
import 'subscription_badge_view.dart';
import 'zappers_view.dart';

class NoteStats extends HookWidget {
  const NoteStats({
    super.key,
    required this.id,
    required this.model,
    required this.isMain,
    this.autoTranslate = false,
    this.isHomeFeed = false,
    this.onEventAdded,
    this.onTextTranslated,
    this.onMuteActionSuccess,
  });

  final String id;
  final BaseEventModel model;
  final bool isMain;
  final bool isHomeFeed;
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
                                  isHomeFeed: isHomeFeed,
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
                      if (model is DetailedNoteModel && !isFluid())
                        TranslationButton(
                          autoTranslate: autoTranslate,
                          isMain: isMain,
                          note: model as DetailedNoteModel,
                          onTextTranslated: onTextTranslated,
                        ),
                      if (!isFluid() || model is! DetailedNoteModel)
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
                              enablePin:
                                  canSign() && model is DetailedNoteModel,
                              onDelete: () {
                                showCupertinoDeletionDialogue(
                                  context: context,
                                  title: context.t
                                      .deleteContent(type: context.t.note)
                                      .capitalizeFirst(),
                                  description: context.t
                                      .confirmDeleteContent(
                                          type: context.t.note)
                                      .capitalizeFirst(),
                                  buttonText:
                                      context.t.delete.capitalizeFirst(),
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
                      if (model is DetailedNoteModel && isFluid())
                        _fluidStatsButton(
                          context,
                          zappers as Map<String, MapEntry<String, int>>,
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
    required bool isHomeFeed,
  }) {
    final actions =
        nostrRepository.currentAppCustomization?.actionsArrangement ??
            defaultActionsArrangement;

    final widgets = actions.entries
        .where((action) => action.value)
        .map<Widget?>((action) {
          switch (action.key) {
            case 'reactions':
              return _reactButton(selfReaction, reactions);
            case 'replies':
              return _replyButton(context, selfReply, replies);
            case 'reposts':
              if (model is DetailedNoteModel) {
                if (isFluid()) {
                  return _fluidRepostPulldown(
                      context, reposts, quotes, selfRepost, selfQuote);
                }
                return _repostButton(context, reposts, selfRepost);
              }
              return null;
            case 'quotes':
              if (isFluid()) {
                return null;
              }
              return _quoteButton(selfQuote, context, quotes);
            case 'zaps':
              return _zapButton(selfZaps, zappers, zapsData);
            default:
              return null;
          }
        })
        .whereType<Widget>()
        .toList();

    return widgets
        .expand((widget) => [
              widget,
              SizedBox(
                width: isHomeFeed ? kDefaultPadding / 1.5 : kDefaultPadding / 3,
              )
            ])
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
        showAdaptiveModal(
          context,
          builder: (_) {
            return NetStatsView(
              id: model.id,
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
                final m = model;
                bool isComment = false;
                if (m is DetailedNoteModel) {
                  isComment = isReplaceable(m.rootKind);
                }

                return AddReply(
                  attachedEvent: model,
                  isMention: false,
                  isComment: isComment,
                  isQuote: true,
                  onSuccess: (ev) {
                    notesEventsCubit.addEventRelatedData(
                      event: ev,
                      replyNoteId: model.id,
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
      size: 18,
      fontSize: 15,
    );
  }

  CustomIconButton _repostButton(BuildContext context, reposts, selfRepost) {
    return CustomIconButton(
      backgroundColor: kTransparent,
      icon: FeatureIcons.repost,
      // Glass mode drops these long-presses, but desktop is *always* glass and
      // right-click is not a long-press — it costs the glass design nothing. So
      // the guard is relaxed on desktop only; on mobile this reads exactly as
      // `isFluid()` did.
      onLongPress: isFluid() && !isDesktopPlatform
          ? null
          : () {
              showAdaptiveModal(
                context,
                builder: (_) {
                  return NetStatsView(
                    id: model.id,
                    type: NoteRelatedEventsType.reposts,
                  );
                },
                dialogHeight: 620,
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
      onLongPress: isFluid()
          ? null
          : () {
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
            showAdaptiveModal(
              context,
              builder: (_) {
                if (model is DetailedNoteModel) {
                  final m = model as DetailedNoteModel;
                  final isComment = isReplaceable(m.rootKind);

                  return AddReply(
                    attachedEvent: isComment ? m : null,
                    isComment: isComment,
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
              // No backgroundColor: the isFluid()/kTransparent ternary this
              // replaced is exactly showAdaptiveModal's own default.
              dialogHeight: 640,
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
      enableLongPress: !isFluid() || isDesktopPlatform,
    );
  }

  Widget _fluidRepostPulldown(
    BuildContext context,
    dynamic reposts,
    dynamic quotes,
    dynamic selfRepost,
    dynamic selfQuote,
  ) {
    final count = (reposts as Map).length + (quotes as Map).length;
    return PullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) => [
        PullDownMenuItem(
          title: context.t.repost.capitalizeFirst(),
          onTap: () => doIfCanSign(
            func: () => notesEventsCubit.repostNote(model as DetailedNoteModel),
            context: context,
          ),
          iconWidget: AppIcon(
            FeatureIcons.repost,
            size: 20,
            color: selfRepost == true
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColorDark,
          ),
        ),
        PullDownMenuItem(
          title: context.t.quote.capitalizeFirst(),
          onTap: () => doIfCanSign(
            func: () {
              showAdaptiveModal(
                context,
                builder: (_) {
                  final m = model;
                  bool isComment = false;
                  if (m is DetailedNoteModel) {
                    isComment = isReplaceable(m.rootKind);
                  }
                  return AddReply(
                    attachedEvent: model,
                    isMention: false,
                    isComment: isComment,
                    isQuote: true,
                    onSuccess: (ev) {
                      notesEventsCubit.addEventRelatedData(
                        event: ev,
                        replyNoteId: model.id,
                      );
                    },
                  );
                },
                dialogHeight: 640,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
            context: context,
          ),
          iconWidget: AppIcon(
            FeatureIcons.quote,
            size: 20,
            color: selfQuote == true
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColorDark,
          ),
        ),
      ],
      buttonBuilder: (context, showMenu) => CustomIconButton(
        backgroundColor: kTransparent,
        icon: FeatureIcons.repost,
        onClicked: showMenu,
        value: count > 0 ? count.toString() : '0',
        iconColor: (selfRepost == true || selfQuote == true)
            ? Theme.of(context).primaryColor
            : Theme.of(context).highlightColor,
        textColor: (selfRepost == true || selfQuote == true)
            ? Theme.of(context).primaryColor
            : Theme.of(context).highlightColor,
        size: 18,
        fontSize: 15,
      ),
    );
  }

  Widget _fluidStatsButton(
    BuildContext context,
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
          builder: (_) => _NoteStatsModal(
            id: model.id,
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

                    // if (amount <= 0) {
                    //   return const SizedBox();
                    // }

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
    BuildContext context,
    int amount,
    String message,
    Metadata metadata,
  ) {
    final row = Row(
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
    );

    return Flexible(
      child: isFluid()
          ? FluidCardContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 4,
                vertical: kDefaultPadding / 6,
              ),
              child: row,
            )
          : Container(
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
              child: row,
            ),
    );
  }

  Row _zapAmount(int amount, BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 8,
      children: [
        AppIcon(
          FeatureIcons.zapAmount,
          size: 15,
          color: Theme.of(context).primaryColor,
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
            showAdaptiveModal(
              context,
              builder: (_) {
                return SendZapsView(
                  metadata: metadata,
                  isZapSplit: false,
                  zapSplits: const [],
                );
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          context: context,
        );
      },
      itemTheme: PullDownMenuItemTheme(
        textStyle: textStyle,
      ),
      iconWidget: AppIcon(
        FeatureIcons.zap,
        size: 20,
        color: Theme.of(context).primaryColorDark,
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
      iconWidget: AppIcon(
        FeatureIcons.message,
        size: 20,
        color: Theme.of(context).primaryColorDark,
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
      iconWidget: AppIcon(
        FeatureIcons.user,
        size: 20,
        color: Theme.of(context).primaryColorDark,
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
              showAdaptiveModal(
                context,
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
        onLongPress: isFluid() && !isDesktopPlatform
            ? null
            : () {
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
          nostrRepository.currentTranslations.capSize(200);

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
          await Future.delayed(const Duration(seconds: 3));

          if (context.mounted) {
            translateContent();
          }
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
          size: 18,
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
    this.enableLongPress = true,
    super.key,
  });

  final String id;
  final String pubkey;
  final bool isReplaceable;
  final Map<String, String> reactions;
  final String? selfReaction;
  final double size;
  final bool enableLongPress;

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
      onLongPress: enableLongPress
          ? () {
              showAdaptiveModal(
                context,
                builder: (_) {
                  return NetStatsView(
                    id: id,
                    type: NoteRelatedEventsType.reactions,
                  );
                },
                dialogHeight: 620,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          : null,
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

  IconData getIcon(Event? reactionEvent) {
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
    this.isExtended = false,
    this.onMuteActionSuccess,
  });

  final Event event;
  final bool isExtended;
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
      showAdaptiveModal(
        context,
        builder: (_) {
          return NetStatsView(
            id: repostedEventId.value,
            type: NoteRelatedEventsType.reposts,
          );
        },
        dialogHeight: 620,
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
            child: isFluid()
                ? FluidBlurContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                      vertical: kDefaultPadding / 4,
                    ),
                    child: _repostRow(repostedEventId, metadata, onClicked),
                  )
                : Container(
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
            isExtended: isExtended,
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
      buildWhen: (previous, current) =>
          previous.eventsStats[originalEvent.value] !=
              current.eventsStats[originalEvent.value] ||
          previous.previousNotes[originalEvent.value] !=
              current.previousNotes[originalEvent.value],
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
                isExtended: isExtended,
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
            AppIcon(
              FeatureIcons.repost,
              size: 15,
              color: Theme.of(context).primaryColorDark,
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
    this.isExtended = false,
    this.loadPreviousNote = false,
    this.enableReply = false,
    this.extendLine = false,
    this.autoTranslate = false,
    this.isReply = false,
    this.isFilterHidden = false,
    this.shouldConsiderHiddenReply = false,
    this.noRender = false,
    this.showFollowButton = false,
    this.onClicked,
    this.onEventAdded,
    this.onMuteActionSuccess,
  });

  final DetailedNoteModel note;
  final bool isMain;
  final bool isExtended;
  final bool addLine;
  final bool loadPreviousNote;
  final bool extendLine;
  final bool enableReply;
  final bool autoTranslate;
  final bool isReply;
  final bool isFilterHidden;
  final bool shouldConsiderHiddenReply;
  final bool noRender;
  final bool showFollowButton;
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
                YNavigator.pushPage(
                  context,
                  (context) => NoteView(note: note),
                );
              });

    final core = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: click,
      child: Builder(
        builder: (context) {
          final child = _feedColumn(context, replyEvent, click, noteContent);

          return _mainColumn(replyEvent, context, child, click, noteContent);
        },
      ),
    );

    if (!note.isPremium) {
      return core;
    }

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
        color: kPremiumColor.withValues(alpha: 0.06),
        border: Border.all(
          color: kPremiumColor.withValues(alpha: 0.4),
        ),
      ),
      child: core,
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
        if (isExtended || isMain || isReply) ...[
          if (enableReply &&
              replyEvent.value != null &&
              settingsCubit.useCompactReplies) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _replyBox(replyEvent),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
          ] else
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
            isHomeFeed: isExtended,
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
                thickness: 2,
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
          _generalInfoRow(context, noteContent),
          if (!isMain && !isReply && !isExtended) ...[
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

  Row _generalInfoRow(BuildContext context, ValueNotifier<String> noteContent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _noteInfo(),
        if (isFluid()) ...[
          TranslationButton(
            autoTranslate: autoTranslate,
            isMain: isMain,
            note: note,
            onTextTranslated: (text) => noteContent.value = text,
          ),
          BlocBuilder<NotesEventsCubit, NotesEventsState>(
            buildWhen: (previous, current) => previous.mutes != current.mutes,
            builder: (context, state) => PullDownGlobalButton(
              model: note,
              enableCopyNpub: true,
              enableCopyId: true,
              enableBookmark: true,
              enableCopyText: true,
              enableShareImage: true,
              enableShowRawEvent: true,
              enableDelete:
                  canSign() && currentSigner!.getPublicKey() == note.pubkey,
              enableRepublish: true,
              enablePin: canSign(),
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
                    final isSuccessful =
                        await notesEventsCubit.deleteNote(note.id);
                    if (isSuccessful && context.mounted) {
                      BotToastUtils.showSuccess(
                          context.t.noteDeletedSuccessfully);
                      Navigator.pop(context);
                    }
                  },
                );
              },
              bookmarkStatus:
                  notesEventsCubit.state.bookmarks.contains(note.id),
              enableShare: true,
              enableMute: true,
              enableMuteEvent: true,
              muteEventStatus: state.mutesEvents.contains(note.id),
              iconBackgroundColor: kTransparent,
              iconColor: Theme.of(context).highlightColor,
              muteStatus: state.mutes.contains(note.pubkey),
              size: 25,
              iconSize: 18,
            ),
          ),
        ],
      ],
    );
  }

  Expanded _noteInfo() {
    return Expanded(
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
                  Row(
                    children: [
                      Flexible(child: _metadataRow(context, style)),
                      if (!isMain && !isReply && !isExtended) ...[
                        DotContainer(
                          color: Theme.of(context).primaryColorDark,
                          size: 3,
                        ),
                        Text(
                          StringUtil.formatTimeDifference(
                            note.createdAt,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context).highlightColor,
                                    height: 1,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                  if (isMain || isReply || note.isPaid || isExtended) ...[
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note.isPaid)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) => const PaidNoteInfoSheet(),
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              backgroundColor: Colors.transparent,
                            ),
                            child: const PaidContainer(),
                          ),
                        if (note.isPaid &&
                            (isMain || isReply || isExtended)) ...[
                          DotContainer(
                            color: Theme.of(context).primaryColorDark,
                            size: 3,
                          ),
                        ],
                        if (isMain || isReply || isExtended)
                          Text(
                            StringUtil.formatTimeDifference(
                              note.createdAt,
                            ),
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).highlightColor,
                                      height: 1,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
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
              AppIcon(
                FeatureIcons.verified,
                size: 15,
                color: Theme.of(context).primaryColor,
              ),
            ],
            const SizedBox(width: kDefaultPadding / 4),
            SubscriptionBadgeView(pubkey: metadata.pubkey, size: 16),
            if (note.isPremium) ...[
              const SizedBox(width: kDefaultPadding / 4),
              const PremiumBadge(),
            ],
            if (showFollowButton &&
                canSign() &&
                currentSigner!.getPublicKey() != metadata.pubkey) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              InlineFollowButton(pubkey: metadata.pubkey),
            ],
          ],
        ),
      ),
    );
  }
}

class InlineFollowButton extends StatelessWidget {
  const InlineFollowButton({super.key, required this.pubkey});

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      initialData: contactListCubit.contacts,
      stream: nostrRepository.contactListStream,
      builder: (context, snapshot) {
        final isFollowing = (snapshot.data ?? const []).contains(pubkey);

        return TextButton(
          onPressed: () {
            doIfCanSign(
              context: context,
              func: () {
                NostrFunctionsRepository.setFollowingEvent(
                  isFollowingAuthor: isFollowing,
                  targetPubkey: pubkey,
                );
              },
            );
          },
          style: TbuttonsTheme.solidTextButtonStyle(
            isFollowing
                ? Theme.of(context).cardColor
                : Theme.of(context).primaryColor,
            foregroundColor:
                isFollowing ? Theme.of(context).highlightColor : kWhite,
            borderColor: isFollowing ? Theme.of(context).dividerColor : null,
          ).copyWith(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding / 1.5,
              ),
            ),
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            isFollowing
                ? context.t.unfollow.capitalizeFirst()
                : context.t.follow.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
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
                AppIcon(
                  isCollapsed.value
                      ? FeatureIcons.arrowDown
                      : FeatureIcons.arrowUp,
                  size: 18,
                  color: Theme.of(context).highlightColor,
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

class PaidNoteInfoSheet extends StatelessWidget {
  const PaidNoteInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isBasic = subscriptionCubit.isBasic;

    return ModalSheetContainer(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalBottomSheetHandle(),
          Icon(
            LucideIcons.megaphone,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.paid_note_sheet_title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: kDefaultPadding / 4),
          Text(
            isBasic
                ? context.t.paid_note_sheet_body_upgrade
                : context.t.paid_note_sheet_body_subscribe,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Theme.of(context).highlightColor),
          ),
          const SizedBox(height: kDefaultPadding),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                YNavigator.pop(context);
                YNavigator.pushPage(context, (_) => const SubscriptionView());
              },
              child: Text(isBasic
                  ? context.t.pricing_upgrade_to_pro
                  : context.t.pricing_cta_subscribe),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => YNavigator.pop(context),
              child: Text(context.t.close.capitalizeFirst()),
            ),
          ),
          const SizedBox(height: kBottomNavigationBarHeight / 2),
        ],
      ),
    );
  }
}

class PaidContainer extends StatefulWidget {
  const PaidContainer({super.key});

  @override
  State<PaidContainer> createState() => _PaidContainerState();
}

class _PaidContainerState extends State<PaidContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
              Color(0xFFF59E0B),
              Color(0xFF8B5CF6),
            ],
            begin: Alignment(-2 + t * 4, 0),
            end: Alignment(-0.5 + t * 4, 0),
          ).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.megaphone,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                context.t.paid.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: kPremiumColor.withValues(alpha: 0.4),
      ),
      child: Text(
        context.t.premium,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
      ),
    );
  }
}

class _NoteStatsModal extends HookWidget {
  const _NoteStatsModal({
    required this.id,
    required this.zappers,
  });

  final String id;
  final Map<String, MapEntry<String, int>> zappers;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 5);

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
              _fluidTabBar(context, tabController),
              const SizedBox(height: kDefaultPadding / 2),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    NetStatsView(
                      id: id,
                      type: NoteRelatedEventsType.replies,
                      embedded: true,
                    ),
                    NetStatsView(
                      id: id,
                      type: NoteRelatedEventsType.reactions,
                      embedded: true,
                    ),
                    NetStatsView(
                      id: id,
                      type: NoteRelatedEventsType.reposts,
                      embedded: true,
                    ),
                    NetStatsView(
                      id: id,
                      type: NoteRelatedEventsType.quotes,
                      embedded: true,
                    ),
                    _EmbeddedZappersList(zappers: zappers),
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

  Widget _fluidTabBar(BuildContext context, TabController controller) {
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
            tabIcon(FeatureIcons.repost),
            tabIcon(FeatureIcons.nQuotes),
            tabIcon(FeatureIcons.nZaps),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedZappersList extends StatefulWidget {
  const _EmbeddedZappersList({required this.zappers});

  final Map<String, MapEntry<String, int>> zappers;

  @override
  State<_EmbeddedZappersList> createState() => _EmbeddedZappersListState();
}

class _EmbeddedZappersListState extends State<_EmbeddedZappersList> {
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
