// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/app_models/extended_model.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/detailed_note_model.dart';
import '../../../models/event_relation.dart';
import '../../../models/picture_model.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../curation_view/curation_view.dart';
import '../../dm_view/widgets/dm_details.dart';
import '../../note_view/note_view.dart';
import '../../smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../wallet_cashu_view/widgets/cashu_history.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/media_components/horizontal_video_view.dart';
import '../../widgets/media_components/picture_view.dart';
import '../../widgets/media_components/vertical_video_view.dart';
import '../../write_note_view/write_note_view.dart';
import 'notification_event_quote.dart';
import 'notification_image_container.dart';

class NotificationGlobalContainer extends StatefulWidget {
  const NotificationGlobalContainer({
    super.key,
    required this.mainEvent,
  });

  final Event mainEvent;

  @override
  State<NotificationGlobalContainer> createState() =>
      _NotificationGlobalContainerState();
}

class _NotificationGlobalContainerState
    extends State<NotificationGlobalContainer> {
  Event? relatedEvent;
  late ExtendedEvent _ev;
  late EventRelation _eventRelation;

  @override
  void initState() {
    super.initState();
    _ev = ExtendedEvent.fromEv(widget.mainEvent);
    _eventRelation = EventRelation.fromEvent(widget.mainEvent);
    metadataCubit.requestMetadata(getPubkey(widget.mainEvent));
  }

  @override
  Widget build(BuildContext context) {
    final ev = _ev;

    return Slidable(
      key: ValueKey(widget.mainEvent.id),
      enabled: ev.kind == EventKind.TEXT_NOTE && ev.isUserTagged() && canSign(),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          _zapButton(context),
          _replyButton(context),
          _dmButton(context),
        ],
      ),
      child: _notificationContent(context),
    );
  }

  Padding _notificationContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onClick.call(context),
        child: MetadataProvider(
          pubkey: getPubkey(widget.mainEvent),
          child: (metadata, isNip05Valid) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NotificationImageContainer(
                  metadata: metadata,
                  event: _eventRelation,
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            StringUtil.formatTimeDifference(
                              DateTime.fromMillisecondsSinceEpoch(
                                widget.mainEvent.createdAt * 1000,
                              ),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: Theme.of(context).highlightColor,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 8,
                      ),
                      NotificationEventQuote(
                        eventRelation: _eventRelation,
                        metadata: metadata,
                        onRelatedEvent: (event) {
                          relatedEvent = event;
                        },
                        onClick: () => onClick.call(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Expanded _dmButton(BuildContext context) {
    return Expanded(
      child: SlidableButton(
        onClick: () {
          YNavigator.pushPage(
            context,
            (context) => DmDetails(pubkey: widget.mainEvent.pubkey),
          );
        },
        label: context.t.chat,
        backgroundColor: noGreen,
        borderRadius: 0,
        effectiveForegroundColor: kWhite,
        icon: FeatureIcons.messageFilled,
      ),
    );
  }

  Expanded _replyButton(BuildContext context) {
    return Expanded(
      child: SlidableButton(
        onClick: () {
          final note = DetailedNoteModel.fromEvent(widget.mainEvent);

          showAdaptiveModal(
            context,
            builder: (_) {
              final isComment = isReplaceable(note.rootKind);

              return AddReply(
                attachedEvent: note,
                isComment: isComment,
                onSuccess: (ev) {
                  notesEventsCubit.addEventRelatedData(
                    event: ev,
                    replyNoteId: note.id,
                  );
                },
                replyContent: {
                  'pubkey': note.pubkey,
                  'pTags': note.cleanPtags(),
                  'date': note.createdAt,
                  'content': note.content,
                  'replyData': note.replyData(),
                },
              );
            },
            dialogHeight: 640,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
        label: context.t.reply,
        backgroundColor: noBlue,
        borderRadius: 0,
        effectiveForegroundColor: kWhite,
        icon: FeatureIcons.commentsFilled,
      ),
    );
  }

  Expanded _zapButton(BuildContext context) {
    return Expanded(
      child: SlidableButton(
        onClick: () async {
          final m =
              await metadataCubit.getAvailableMetadata(widget.mainEvent.pubkey);

          if (context.mounted) {
            showAdaptiveModal(
              context,
              builder: (_) {
                return SendZapsView(
                  metadata: m,
                  eventId: widget.mainEvent.id,
                  isZapSplit: false,
                  zapSplits: const [],
                );
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          }
        },
        label: context.t.zap,
        backgroundColor: noOrange,
        borderRadius: 0,
        effectiveForegroundColor: kWhite,
        icon: FeatureIcons.zapFilled,
      ),
    );
  }

  void onClick(BuildContext context) {
    // Open Cashu history modal for NutZaps
    if (widget.mainEvent.kind == EventKind.CASHU_NUTZAP) {
      showAdaptiveModal(
        context,
        dialogHeight: 620,
        backgroundColor: Colors.transparent,
        // This site never opted into either; kept so mobile is unchanged.
        useRootNavigator: false,
        useSafeArea: false,
        builder: (context) => const CashuHistory(initialIndex: 2),
      );
      return;
    }

    if (relatedEvent != null) {
      final page = getView(
        widget.mainEvent.kind == EventKind.REACTION ||
                widget.mainEvent.kind == EventKind.REPOST ||
                widget.mainEvent.kind == EventKind.ZAP ||
                widget.mainEvent.kind == EventKind.CASHU_NUTZAP
            ? relatedEvent!
            : widget.mainEvent,
      );

      if (page != null) {
        YNavigator.pushPage(context, (context) => page);
      }
    } else {
      final page = getView(widget.mainEvent);

      if (page != null) {
        YNavigator.pushPage(
          context,
          (context) => page,
        );
      }
    }
  }

  Widget? getView(Event event) {
    Widget? page;

    switch (event.kind) {
      case EventKind.LONG_FORM:
        page = ArticleView(article: Article.fromEvent(event));
      case EventKind.CURATION_ARTICLES:
        page = CurationView(curation: Curation.fromEvent(event, ''));
      case EventKind.CURATION_VIDEOS:
        page = CurationView(curation: Curation.fromEvent(event, ''));
      case EventKind.VIDEO_HORIZONTAL:
        page = HorizontalVideoView(video: VideoModel.fromEvent(event));
      case EventKind.VIDEO_VERTICAL:
        page = VerticalVideoView(video: VideoModel.fromEvent(event));
      case EventKind.LEGACY_VIDEO_HORIZONTAL:
        page = HorizontalVideoView(video: VideoModel.fromEvent(event));
      case EventKind.LEGACY_VIDEO_VERTICAL:
        page = VerticalVideoView(video: VideoModel.fromEvent(event));
      case EventKind.TEXT_NOTE:
        page = NoteView(note: DetailedNoteModel.fromEvent(event));
      case EventKind.PICTURE:
        page = PictureView(picture: PictureModel.fromEvent(event));
      case EventKind.SMART_WIDGET_ENH:
        final swm = SmartWidget.fromEvent(event);
        page = SmartWidgetChecker(
          naddr: swm.getScheme(),
          swm: swm,
        );
    }

    return page;
  }

  String getZapContent() {
    if (widget.mainEvent.kind == EventKind.ZAP ||
        widget.mainEvent.kind == EventKind.CASHU_NUTZAP) {
      final result = getZapPubkey(widget.mainEvent.tags);
      return result.last;
    }

    return '';
  }
}

class SlidableButton extends StatelessWidget {
  const SlidableButton({
    super.key,
    required this.backgroundColor,
    required this.effectiveForegroundColor,
    required this.borderRadius,
    required this.icon,
    required this.label,
    required this.onClick,
  });

  final Color backgroundColor;
  final Color effectiveForegroundColor;
  final double borderRadius;
  final IconData icon;
  final String label;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: OutlinedButton(
        onPressed: () {
          onClick.call();
          Slidable.of(context)?.close();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(kDefaultPadding / 4),
          backgroundColor: backgroundColor,
          disabledForegroundColor: effectiveForegroundColor.withValues(
            alpha: 0.38,
          ),
          iconColor: effectiveForegroundColor,
          foregroundColor: effectiveForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          side: BorderSide.none,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kDefaultPadding / 4,
          children: [
            AppIcon(
              icon,
              size: 20,
              color: effectiveForegroundColor,
            ),
            Text(
              label.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String getPubkey(Event event) {
  if (event.kind == EventKind.ZAP) {
    final result = getZapPubkey(event.tags);
    return result.first;
  } else {
    return event.pubkey;
  }
}
