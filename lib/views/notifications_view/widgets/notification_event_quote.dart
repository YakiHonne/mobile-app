// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/app_models/extended_model.dart';
import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/event_relation.dart';
import '../../../models/poll_model.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/data_providers.dart';

class NotificationEventQuote extends StatefulWidget {
  const NotificationEventQuote({
    super.key,
    required this.eventRelation,
    required this.metadata,
    required this.onRelatedEvent,
    required this.onClick,
  });

  final EventRelation eventRelation;
  final Metadata metadata;
  final Function(Event?) onRelatedEvent;
  final Function() onClick;

  @override
  State<NotificationEventQuote> createState() => _NotificationEventQuoteState();
}

class _NotificationEventQuoteState extends State<NotificationEventQuote> {
  String id = '';
  bool isReplaceable = false;

  @override
  void initState() {
    super.initState();

    if (widget.eventRelation.kind == EventKind.REACTION) {
      final entry = widget.eventRelation.getReactionId();

      if (entry != null) {
        id = entry.key;
        isReplaceable = entry.value;

        singleEventCubit.getEvent(id, isReplaceable);
      }
    } else {
      final isRoot = widget.eventRelation.replyId == null &&
          widget.eventRelation.rootId == null &&
          widget.eventRelation.rRootId == null;

      if (!isRoot) {
        id = widget.eventRelation.replyId != null
            ? widget.eventRelation.replyId!
            : widget.eventRelation.rootId != null
                ? widget.eventRelation.rootId!
                : widget.eventRelation.rRootId!;

        isReplaceable = widget.eventRelation.rootId == null &&
            widget.eventRelation.replyId == null;

        singleEventCubit.getEvent(id, isReplaceable);
      } else {
        if (widget.eventRelation.origin.isQuote()) {
          final entry = widget.eventRelation.origin.getQtag();

          if (entry != null) {
            id = entry.key;
            isReplaceable = entry.value;

            singleEventCubit.getEvent(id, isReplaceable);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleEventProvider(
      id: id,
      isReplaceable: isReplaceable,
      child: (event) {
        widget.onRelatedEvent(event);

        return NotificationEventMain(
          event: event,
          mainEvent: widget.eventRelation,
          metadata: widget.metadata,
          onClick: widget.onClick,
        );
      },
    );
  }
}

class NotificationEventMain extends StatelessWidget {
  const NotificationEventMain({
    super.key,
    required this.event,
    required this.mainEvent,
    required this.metadata,
    required this.onClick,
  });

  final Event? event;
  final EventRelation mainEvent;
  final Metadata metadata;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return getWidget(event, mainEvent, context);
  }

  Widget getWidget(
    Event? event,
    EventRelation mainEvent,
    BuildContext context,
  ) {
    final isAuthor =
        event != null && event.pubkey == currentSigner!.getPublicKey();

    final metadataSpan = TextSpan(
      text: metadata.getName().trim(),
      style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).primaryColorDark,
            fontWeight: FontWeight.w600,
          ),
    );

    Widget getRichtext(List<InlineSpan> spans) {
      return RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: spans,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    if (mainEvent.kind == EventKind.ZAP) {
      List<InlineSpan> spans = [metadataSpan];

      if (event != null) {
        spans = getSpans(event, isAuthor, metadataSpan, context);
      } else {
        spans = [
          TextSpan(
            text: context.t.userZappedYou(
              name: metadata.getName().trim(),
              number: getZapValue(mainEvent.origin).toInt().toString(),
            ),
          ),
        ];
      }

      return getRichtext(spans);
    } else if (mainEvent.kind == EventKind.REACTION) {
      List<InlineSpan> spans = [metadataSpan];

      if (event != null) {
        spans = getSpans(event, isAuthor, metadataSpan, context);
      } else {
        spans = [
          TextSpan(
            text: context.t.userReactedYou(
              name: metadata.getName().trim(),
              reaction: getReaction(mainEvent.origin),
            ),
          ),
        ];
      }

      return getRichtext(spans);
    } else if (mainEvent.kind == EventKind.REPOST) {
      List<InlineSpan> spans = [metadataSpan];

      final ev = event ?? Event.fromString(mainEvent.origin.content);

      if (ev != null) {
        spans = getSpans(ev, isAuthor, metadataSpan, context);
      } else {
        spans = [
          TextSpan(
            text: context.t.userRepostedYou(name: metadata.getName().trim()),
          ),
        ];
      }

      return getRichtext(spans);
    } else if (mainEvent.kind == EventKind.TEXT_NOTE) {
      final ev = ExtendedEvent.fromEv(mainEvent.origin);

      if (ev.isUserTagged()) {
        List<InlineSpan> spans = [metadataSpan];

        if (event != null) {
          spans = getSpans(event, isAuthor, metadataSpan, context);
        } else {
          spans = [
            TextSpan(
              text: getMentionText(
                origin: mainEvent.origin,
                event: ev,
                metadata: metadata,
                attachedText: ev.content.trim(),
                context: context,
              ),
            ),
            if (ev.content.isNotEmpty) ...[
              TextSpan(
                text: '\n',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
              ),
              WidgetSpan(
                child: ParsedText(
                  text: ev.content,
                  scrollPhysics: const NeverScrollableScrollPhysics(),
                  disableNoteParsing: false,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                  isNotification: true,
                  onClicked: onClick,
                ),
              ),
            ]
          ];
        }

        return getRichtext(spans);
      } else if (ev.isFlashNews()) {
        List<InlineSpan> spans = [];

        spans = [
          TextSpan(
            text: context.t.userPublishedPaidNote(
              name: metadata.getName().trim(),
            ),
          ),
        ];

        return getRichtext(spans);
      } else {
        return const SizedBox.shrink();
      }
    } else if (mainEvent.kind == EventKind.LONG_FORM ||
        mainEvent.kind == EventKind.VIDEO_HORIZONTAL ||
        mainEvent.kind == EventKind.VIDEO_VERTICAL ||
        mainEvent.kind == EventKind.SMART_WIDGET_ENH ||
        mainEvent.kind == EventKind.POLL ||
        mainEvent.kind == EventKind.CURATION_ARTICLES ||
        mainEvent.kind == EventKind.CURATION_VIDEOS) {
      List<InlineSpan> spans = [];
      String text = '';

      switch (mainEvent.kind) {
        case EventKind.LONG_FORM:
          text = context.t.userPublishedArticle(
            name: metadata.getName().trim(),
          );
        case EventKind.CURATION_ARTICLES:
          text = context.t.userPublishedCuration(
            name: metadata.getName().trim(),
          );
        case EventKind.CURATION_VIDEOS:
          text = context.t.userPublishedCuration(
            name: metadata.getName().trim(),
          );
        case EventKind.SMART_WIDGET_ENH:
          text = context.t.userPublishedSmartWidget(
            name: metadata.getName().trim(),
          );
        case EventKind.VIDEO_HORIZONTAL:
          text = context.t.userPublishedVideo(
            name: metadata.getName().trim(),
          );
        case EventKind.VIDEO_VERTICAL:
          text = context.t.userPublishedVideo(
            name: metadata.getName().trim(),
          );
        case EventKind.POLL:
          text = context.t.userPublishedPoll(
            name: metadata.getName().trim(),
          );
      }

      spans = [
        TextSpan(text: text),
        TextSpan(
          text: '\n',
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
        ),
        WidgetSpan(
          child: ParsedText(
            text: getEventContent(mainEvent.origin),
            scrollPhysics: const NeverScrollableScrollPhysics(),
            disableNoteParsing: false,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            isNotification: true,
            onClicked: onClick,
          ),
        ),
      ];

      return getRichtext(spans);
    } else {
      return const SizedBox.shrink();
    }
  }

  String getEventContent(Event event) {
    String text = '';
    switch (event.kind) {
      case EventKind.LONG_FORM:
        text = Article.fromEvent(event).title;
      case EventKind.CURATION_ARTICLES:
        text = Curation.fromEvent(event, '').title;
      case EventKind.CURATION_VIDEOS:
        text = Curation.fromEvent(event, '').title;
      case EventKind.SMART_WIDGET_ENH:
        text = SmartWidget.fromEvent(event).title;
      case EventKind.REACTION:
        text = event.content;
      case EventKind.VIDEO_HORIZONTAL:
        text = VideoModel.fromEvent(event).title;
      case EventKind.VIDEO_VERTICAL:
        text = VideoModel.fromEvent(event).title;
      case EventKind.POLL:
        text = PollModel.fromEvent(event).content;
      case EventKind.TEXT_NOTE:
        text = event.content.trim();
    }

    return text;
  }

  List<InlineSpan> getSpans(
    Event ev,
    bool isAuthor,
    InlineSpan metadataSpan,
    BuildContext context,
  ) {
    final event = ExtendedEvent.fromEv(ev);
    List<InlineSpan> spans = [];
    String attachedText = '';

    if (event.kind == EventKind.LONG_FORM) {
      final article = Article.fromEvent(event);
      attachedText = article.title.trim();
    } else if (event.kind == EventKind.CURATION_ARTICLES ||
        event.kind == EventKind.CURATION_VIDEOS) {
      final curation = Curation.fromEvent(event, '');
      attachedText = curation.title.trim();
    } else if (event.kind == EventKind.SMART_WIDGET_ENH) {
      final sw = SmartWidget.fromEvent(event);
      attachedText = sw.title.trim();
    } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
        event.kind == EventKind.VIDEO_VERTICAL) {
      final video = VideoModel.fromEvent(event);
      attachedText = video.title.trim();
    } else if (event.kind == EventKind.TEXT_NOTE) {
      if (mainEvent.origin.kind != EventKind.REACTION &&
          mainEvent.origin.kind != EventKind.REPOST) {
        attachedText = mainEvent.origin.content.trim();
      } else {
        attachedText = ev.content.trim();
      }
    }

    if (event.kind != EventKind.LONG_FORM &&
        event.kind != EventKind.SMART_WIDGET_ENH &&
        event.kind != EventKind.REACTION &&
        event.kind != EventKind.CURATION_ARTICLES &&
        event.kind != EventKind.DIRECT_MESSAGE &&
        event.kind != EventKind.APP_CUSTOM &&
        event.kind != EventKind.VIDEO_HORIZONTAL &&
        event.kind != EventKind.VIDEO_VERTICAL &&
        event.kind != EventKind.POLL &&
        event.kind != EventKind.TEXT_NOTE) {
      spans.add(const TextSpan(text: 'undefined'));
    } else {
      String text = '';

      switch (mainEvent.kind) {
        case EventKind.ZAP:
          text = getZapText(
            origin: mainEvent.origin,
            event: event,
            metadata: metadata,
            attachedText: attachedText,
            context: context,
          );
        case EventKind.REACTION:
          text = getReactionText(
            origin: mainEvent.origin,
            event: event,
            metadata: metadata,
            attachedText: attachedText,
            isAuthor: isAuthor,
            context: context,
          );

        case EventKind.REPOST:
          text = getRepostsText(
            origin: mainEvent.origin,
            event: event,
            metadata: metadata,
            attachedText: attachedText,
            isAuthor: isAuthor,
            context: context,
          );

        case EventKind.TEXT_NOTE:
          if (mainEvent.isMention(currentSigner!.getPublicKey())) {
            text = getMentionText(
              origin: mainEvent.origin,
              event: event,
              metadata: metadata,
              attachedText: attachedText,
              context: context,
            );
          } else if (mainEvent.replyId != null) {
            text = getReplyText(
              origin: mainEvent.origin,
              event: event,
              metadata: metadata,
              attachedText: attachedText,
              isAuthor: isAuthor,
              context: context,
            );
          } else if (mainEvent.rootId != null || mainEvent.rRootId != null) {
            text = getCommentText(
              origin: mainEvent.origin,
              event: event,
              metadata: metadata,
              attachedText: attachedText,
              isAuthor: isAuthor,
              context: context,
            );
          } else if (mainEvent.origin.isQuote()) {
            text = getQuoteText(
              origin: mainEvent.origin,
              event: event,
              metadata: metadata,
              attachedText: attachedText,
              isAuthor: isAuthor,
              context: context,
            );
          }
      }

      spans = [
        TextSpan(
          text: text,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (attachedText.isNotEmpty) ...[
          TextSpan(
            text: ':\n',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
          ),
          WidgetSpan(
            child: ParsedText(
              text: attachedText,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              isNotification: true,
              onClicked: onClick,
            ),
          ),
        ]
      ];
    }

    return spans;
  }

  String getZapText({
    required Event origin,
    required ExtendedEvent event,
    required Metadata metadata,
    required String attachedText,
    required BuildContext context,
  }) {
    String text = '';

    final amount = getZapValue(mainEvent.origin).toInt().toString();

    switch (event.kind) {
      case EventKind.LONG_FORM:
        text = context.t.userZappedYourArticle(
          name: metadata.getName().trim(),
          number: amount,
        );
      case EventKind.CURATION_ARTICLES:
        text = context.t.userZappedYourCuration(
          name: metadata.getName().trim(),
          number: amount,
        );
      case EventKind.CURATION_VIDEOS:
        text = context.t.userZappedYourCuration(
          name: metadata.getName().trim(),
          number: amount,
        );
      case EventKind.SMART_WIDGET_ENH:
        text = context.t.userZappedYourSmartWidget(
          name: metadata.getName().trim(),
          number: amount,
        );
      case EventKind.VIDEO_HORIZONTAL:
        text = context.t.userZappedYourVideo(
          name: metadata.getName().trim(),
          number: amount,
        );
      case EventKind.VIDEO_VERTICAL:
        text = context.t.userZappedYourVideo(
          name: metadata.getName().trim(),
          number: amount,
        );
      case EventKind.POLL:
        text = context.t.userZappedYourPoll(
          name: metadata.getName().trim(),
          number: amount,
        );
      case EventKind.TEXT_NOTE:
        text = event.isFlashNews()
            ? text = context.t.userZappedYourPaidNote(
                name: metadata.getName().trim(),
                number: amount,
              )
            : text = context.t.userZappedYourNote(
                name: metadata.getName().trim(),
                number: amount,
              );
    }

    return text;
  }

  String getReactionText({
    required Event origin,
    required ExtendedEvent event,
    required Metadata metadata,
    required String attachedText,
    required bool isAuthor,
    required BuildContext context,
  }) {
    String text = '';

    switch (event.kind) {
      case EventKind.LONG_FORM:
        text = isAuthor
            ? context.t.userReactedYourArticle(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              )
            : context.t.userReactedArticleYouIn(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              );
      case EventKind.CURATION_ARTICLES:
        text = isAuthor
            ? context.t.userReactedYourCuration(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              )
            : context.t.userReactedCurationYouIn(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              );
      case EventKind.CURATION_VIDEOS:
        text = isAuthor
            ? context.t.userReactedYourCuration(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              )
            : context.t.userReactedCurationYouIn(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              );
      case EventKind.SMART_WIDGET_ENH:
        text = isAuthor
            ? context.t.userReactedYourSmartWidget(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              )
            : context.t.userReactedSmartWidgetYouIn(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              );
      case EventKind.VIDEO_HORIZONTAL:
        text = isAuthor
            ? context.t.userReactedYourVideo(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              )
            : context.t.userReactedVideoYouIn(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              );
      case EventKind.VIDEO_VERTICAL:
        text = isAuthor
            ? context.t.userReactedYourVideo(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              )
            : context.t.userReactedVideoYouIn(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              );
      case EventKind.DIRECT_MESSAGE:
        text = context.t.userReactedYourMessage(
          name: metadata.getName().trim(),
          reaction: getReaction(origin),
        );
      case EventKind.POLL:
        text = isAuthor
            ? context.t.userReactedYourPoll(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              )
            : context.t.userReactedPollYouIn(
                name: metadata.getName().trim(),
                reaction: getReaction(origin),
              );
      case EventKind.TEXT_NOTE:
        text = event.isFlashNews()
            ? text = isAuthor
                ? context.t.userReactedYourPaidNote(
                    name: metadata.getName().trim(),
                    reaction: getReaction(origin),
                  )
                : context.t.userReactedPaidNoteYouIn(
                    name: metadata.getName().trim(),
                    reaction: getReaction(origin),
                  )
            : text = isAuthor
                ? context.t.userReactedYourNote(
                    name: metadata.getName().trim(),
                    reaction: getReaction(origin).trim(),
                  )
                : context.t.userReactedNoteYouIn(
                    name: metadata.getName().trim(),
                    reaction: getReaction(origin),
                  );
    }

    return text;
  }

  String getRepostsText({
    required Event origin,
    required ExtendedEvent event,
    required Metadata metadata,
    required String attachedText,
    required bool isAuthor,
    required BuildContext context,
  }) {
    String text = '';

    switch (event.kind) {
      case EventKind.TEXT_NOTE:
        text = event.isFlashNews()
            ? text = isAuthor
                ? context.t.userRepostedYourPaidNote(
                    name: metadata.getName().trim(),
                  )
                : context.t.userRepostedPaidNoteYouIn(
                    name: metadata.getName().trim(),
                  )
            : text = isAuthor
                ? context.t.userRepostedYourNote(
                    name: metadata.getName().trim(),
                  )
                : context.t.userRepostedNoteYouIn(
                    name: metadata.getName().trim(),
                  );
    }

    return text;
  }

  String getReplyText({
    required Event origin,
    required ExtendedEvent event,
    required Metadata metadata,
    required String attachedText,
    required bool isAuthor,
    required BuildContext context,
  }) {
    String text = '';

    switch (event.kind) {
      case EventKind.LONG_FORM:
        text = isAuthor
            ? context.t.userRepliedYourArticle(
                name: metadata.getName().trim(),
              )
            : context.t.userRepliedArticleYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.CURATION_ARTICLES:
        text = isAuthor
            ? context.t.userRepliedYourCuration(
                name: metadata.getName().trim(),
              )
            : context.t.userRepliedCurationYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.CURATION_VIDEOS:
        text = isAuthor
            ? context.t.userRepliedYourCuration(
                name: metadata.getName().trim(),
              )
            : context.t.userRepliedCurationYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.SMART_WIDGET_ENH:
        text = isAuthor
            ? context.t.userRepliedYourSmartWidget(
                name: metadata.getName().trim(),
              )
            : context.t.userRepliedSmartWidgetYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.VIDEO_HORIZONTAL:
        text = isAuthor
            ? context.t.userRepliedYourVideo(
                name: metadata.getName().trim(),
              )
            : context.t.userRepliedVideoYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.VIDEO_VERTICAL:
        text = isAuthor
            ? context.t.userRepliedYourVideo(
                name: metadata.getName().trim(),
              )
            : context.t.userRepliedVideoYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.POLL:
        text = isAuthor
            ? context.t.userRepliedYourPoll(
                name: metadata.getName().trim(),
              )
            : context.t.userRepliedPollYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.TEXT_NOTE:
        text = event.isFlashNews()
            ? text = isAuthor
                ? context.t.userRepliedYourPaidNote(
                    name: metadata.getName().trim(),
                  )
                : context.t.userRepliedPaidNoteYouIn(
                    name: metadata.getName().trim(),
                  )
            : text = isAuthor
                ? context.t.userRepliedYourNote(
                    name: metadata.getName().trim(),
                  )
                : context.t.userRepliedNoteYouIn(
                    name: metadata.getName().trim(),
                  );
    }

    return text;
  }

  String getMentionText({
    required Event origin,
    required ExtendedEvent event,
    required Metadata metadata,
    required String attachedText,
    required BuildContext context,
  }) {
    String text = '';
    final name = metadata.getName().trim();

    switch (event.kind) {
      case EventKind.LONG_FORM:
        text = context.t.userMentionedYouInArticle(name: name);
      case EventKind.CURATION_ARTICLES:
        text = context.t.userMentionedYouInCuration(name: name);
      case EventKind.CURATION_VIDEOS:
        text = context.t.userMentionedYouInCuration(name: name);
      case EventKind.SMART_WIDGET_ENH:
        text = context.t.userMentionedYouInSmartWidget(name: name);
      case EventKind.VIDEO_HORIZONTAL:
        text = context.t.userMentionedYouInVideo(name: name);
      case EventKind.VIDEO_VERTICAL:
        text = context.t.userMentionedYouInVideo(name: name);
      case EventKind.POLL:
        text = context.t.userMentionedYouInPoll(name: name);
      case EventKind.TEXT_NOTE:
        text = event.isFlashNews()
            ? text = context.t.userMentionedYouInPaidNote(name: name)
            : text = hasMention(
                        content: origin.content,
                        pubkey: currentSigner!.getPublicKey()) &&
                    origin.root != null
                ? context.t.userMentionedYouInComment(name: name)
                : context.t.userMentionedYouInNote(name: name);
    }

    return text;
  }

  String getCommentText({
    required Event origin,
    required ExtendedEvent event,
    required Metadata metadata,
    required String attachedText,
    required bool isAuthor,
    required BuildContext context,
  }) {
    String text = '';
    final name = metadata.getName().trim();

    switch (event.kind) {
      case EventKind.LONG_FORM:
        text = isAuthor
            ? context.t.userCommentedYourArticle(name: name)
            : context.t.userCommentedArticleYouIn(name: name);
      case EventKind.CURATION_ARTICLES:
        text = isAuthor
            ? context.t.userCommentedYourCuration(name: name)
            : context.t.userCommentedCurationYouIn(name: name);
      case EventKind.CURATION_VIDEOS:
        text = isAuthor
            ? context.t.userCommentedYourCuration(name: name)
            : context.t.userCommentedCurationYouIn(name: name);
      case EventKind.SMART_WIDGET_ENH:
        text = isAuthor
            ? context.t.userCommentedYourSmartWidget(name: name)
            : context.t.userCommentedSmartWidgetYouIn(name: name);
      case EventKind.VIDEO_HORIZONTAL:
        text = isAuthor
            ? context.t.userCommentedYourVideo(name: name)
            : context.t.userCommentedVideoYouIn(name: name);
      case EventKind.VIDEO_VERTICAL:
        text = isAuthor
            ? context.t.userCommentedYourVideo(name: name)
            : context.t.userCommentedVideoYouIn(name: name);
      case EventKind.POLL:
        text = isAuthor
            ? context.t.userCommentedYourPoll(name: name)
            : context.t.userCommentedPollYouIn(name: name);
      case EventKind.TEXT_NOTE:
        text = event.isFlashNews()
            ? text = isAuthor
                ? context.t.userCommentedYourPaidNote(name: name)
                : context.t.userCommentedPaidNoteYouIn(name: name)
            : text = isAuthor
                ? context.t.userCommentedYourNote(name: name)
                : hasMention(
                    content: origin.content,
                    pubkey: currentSigner!.getPublicKey(),
                  )
                    ? context.t.userMentionedYouInComment(name: name)
                    : context.t.userCommentedNoteYouIn(name: name);
    }

    return text;
  }

  String getQuoteText({
    required Event origin,
    required ExtendedEvent event,
    required Metadata metadata,
    required String attachedText,
    required bool isAuthor,
    required BuildContext context,
  }) {
    String text = '';

    switch (event.kind) {
      case EventKind.LONG_FORM:
        text = isAuthor
            ? context.t.userQuotedYourArticle(
                name: metadata.getName().trim(),
              )
            : context.t.userQuotedArticleYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.CURATION_ARTICLES:
        text = isAuthor
            ? context.t.userQuotedYourCuration(
                name: metadata.getName().trim(),
              )
            : context.t.userQuotedCurationYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.CURATION_VIDEOS:
        text = isAuthor
            ? context.t.userQuotedYourCuration(
                name: metadata.getName().trim(),
              )
            : context.t.userQuotedCurationYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.VIDEO_HORIZONTAL:
        text = isAuthor
            ? context.t.userQuotedYourVideo(
                name: metadata.getName().trim(),
              )
            : context.t.userQuotedVideoYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.VIDEO_VERTICAL:
        text = isAuthor
            ? context.t.userQuotedYourVideo(
                name: metadata.getName().trim(),
              )
            : context.t.userQuotedVideoYouIn(
                name: metadata.getName().trim(),
              );
      case EventKind.TEXT_NOTE:
        text = event.isFlashNews()
            ? text = isAuthor
                ? context.t.userQuotedYourPaidNote(
                    name: metadata.getName().trim(),
                  )
                : context.t.userQuotedPaidNoteYouIn(
                    name: metadata.getName().trim(),
                  )
            : text = isAuthor
                ? context.t.userQuotedYourNote(
                    name: metadata.getName().trim(),
                  )
                : context.t.userQuotedNoteYouIn(
                    name: metadata.getName().trim(),
                  );
    }

    return text;
  }
}

String getReaction(Event e) {
  final r = e.content;

  if (r == '+') {
    return '👍';
  } else {
    return r == '-' ? '👎' : r.trim();
  }
}
