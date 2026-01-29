// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/event_stats.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:numeral/numeral.dart';

import '../../../../logic/dashboard_cubits/dashboard_bookmarks_cubit/bookmarks_cubit.dart';
import '../../../../logic/dashboard_cubits/dashboard_home_cubit/dashboard_home_cubit.dart';
import '../../../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../../../models/article_model.dart';
import '../../../../models/bookmark_list_model.dart';
import '../../../../models/detailed_note_model.dart';
import '../../../../models/flash_news_model.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../add_content_view/add_content_view.dart';
import '../../../note_view/note_view.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/note_stats.dart';
import '../../../widgets/pull_down_global_button.dart';
import '../../../widgets/response_snackbar.dart';
import '../bookmarks/add_bookmarks_list_view.dart';

class DashboardNoteContainer extends StatelessWidget {
  const DashboardNoteContainer({
    super.key,
    required this.note,
  });

  final DetailedNoteModel note;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) => NoteView(note: note),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          children: [
            const ContentTypeIconBox(
              icon: FeatureIcons.uncensoredNote,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _noteContent(context),
            PullDownGlobalButton(
              model: note,
              enableShare: true,
              enableCopyId: true,
              enableShowRawEvent: true,
            ),
          ],
        ),
      ),
    );
  }

  Expanded _noteContent(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t
                .publishedOn(
                  date: dateFormat2.format(note.createdAt),
                )
                .capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Row(
            children: [
              DashboardContentStats(id: note.id),
              if (note.isPaid) ...[
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                const PaidContainer(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ContentTypeIconBox extends StatelessWidget {
  const ContentTypeIconBox({
    super.key,
    required this.icon,
  });

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        icon,
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

class DashboardContentStats extends HookWidget {
  const DashboardContentStats({
    super.key,
    required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    useMemoized(
      () {
        notesEventsCubit.getContentStats(id, r: true);
      },
    );

    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      builder: (context, state) {
        final noteStats = state.eventsStats[id];
        final replies = noteStats?.replies ?? {};
        final reactions = noteStats?.reactions ?? {};
        final zaps =
            noteStats?.getZapsData(state.mutes) ?? EventStats.emptyZapData();

        return Row(
          children: [
            DashboardStatBox(
              icon: FeatureIcons.heart,
              val: reactions.length,
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            DashboardStatBox(
              icon: FeatureIcons.comments,
              val: replies.length,
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            DashboardStatBox(
              icon: FeatureIcons.zap,
              val: zaps['total'],
            ),
          ],
        );
      },
    );
  }
}

class DashboardStatBox extends StatelessWidget {
  const DashboardStatBox({
    super.key,
    required this.icon,
    required this.val,
  });

  final String icon;
  final num val;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon,
          width: 15,
          height: 15,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
          child: Text(
            val.numeral(digits: 2),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
        ),
      ],
    );
  }
}

class DashboardDraftContainer extends StatelessWidget {
  const DashboardDraftContainer({
    super.key,
    required this.text,
    required this.createdAt,
    required this.article,
    required this.type,
  });

  final String text;
  final DateTime createdAt;
  final String type;
  final Article? article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) {
            return AddContentView(
              article: article,
              contentType: AppContentType.article,
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: article != null
                ? Theme.of(context).dividerColor
                : Theme.of(context).primaryColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          children: [
            ContentTypeIconBox(
              icon: type == 'Article'
                  ? FeatureIcons.selfArticles
                  : type == 'Note'
                      ? FeatureIcons.uncensoredNote
                      : FeatureIcons.smartWidget,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _draftInfo(context),
            if (article != null)
              PullDownGlobalButton(
                model: article!,
                enableEdit: true,
                enableDelete: true,
                onDelete: () {
                  showCupertinoDeletionDialogue(
                    context: context,
                    title: context.t.deleteDraft.capitalizeFirst(),
                    description: context.t.confirmDeleteDraft.capitalizeFirst(),
                    buttonText: context.t.delete.capitalizeFirst(),
                    onDelete: () {
                      YNavigator.pop(context);
                      context
                          .read<DashboardHomeCubit>()
                          .onDeleteContent(article!.id, isNote: type == 'Note');
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Expanded _draftInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  context.t.lastUpdatedOn(date: dateFormat2.format(createdAt)),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              TypeContainer(type: type),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            text.isEmpty ? context.t.noDescription.capitalizeFirst() : text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: text.isEmpty
                      ? Theme.of(context).highlightColor
                      : Theme.of(context).primaryColorDark,
                ),
          ),
        ],
      ),
    );
  }
}

class TypeContainer extends StatelessWidget {
  const TypeContainer({super.key, required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 4),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.3,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 8,
        horizontal: kDefaultPadding / 2,
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class DashboardContentContainer extends StatelessWidget {
  const DashboardContentContainer({
    super.key,
    required this.image,
    required this.id,
    required this.content,
    required this.createdAt,
    required this.kind,
    required this.item,
    required this.onClick,
    this.borderColor,
    this.onDeleteItem,
    this.onRefresh,
    this.isPaid,
    this.isRepost,
    this.isHiddenType,
  });

  final String? image;
  final String id;
  final String content;
  final DateTime createdAt;
  final int kind;

  final BaseEventModel item;
  final Function() onClick;
  final Color? borderColor;
  final Function(String)? onDeleteItem;
  final Function()? onRefresh;
  final bool? isPaid;
  final bool? isRepost;
  final bool? isHiddenType;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClick,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: borderColor ?? Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          children: [
            if (image != null)
              CommonThumbnail(
                image: image!,
                width: 50,
                height: 50,
                radius: kDefaultPadding / 2,
                isRound: true,
              )
            else
              ContentTypeIconBox(
                icon: getIcon(),
              ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _contentInfo(context),
            _pulldownButton(context),
          ],
        ),
      ),
    );
  }

  PullDownGlobalButton _pulldownButton(BuildContext context) {
    return PullDownGlobalButton(
      model: item,
      enablePostInNote: kind != EventKind.LONG_FORM_DRAFT &&
          kind != EventKind.TEXT_NOTE &&
          kind != EventKind.CATEGORIZED_BOOKMARK,
      enableCheckValidity: item is SmartWidget,
      enableClone: item is SmartWidget,
      enableShowRawEvent: true,
      enableEdit: kind != EventKind.TEXT_NOTE ||
          kind != EventKind.VIDEO_HORIZONTAL ||
          kind != EventKind.VIDEO_VERTICAL,
      enableCopyId: kind != EventKind.LONG_FORM_DRAFT &&
          kind != EventKind.CATEGORIZED_BOOKMARK &&
          (kind == EventKind.TEXT_NOTE ||
              kind == EventKind.PICTURE ||
              kind == EventKind.VIDEO_HORIZONTAL ||
              kind == EventKind.VIDEO_VERTICAL),
      enableCopyNaddr: kind != EventKind.LONG_FORM_DRAFT &&
          kind != EventKind.CATEGORIZED_BOOKMARK &&
          kind != EventKind.TEXT_NOTE &&
          kind != EventKind.VIDEO_HORIZONTAL &&
          kind != EventKind.VIDEO_VERTICAL &&
          kind != EventKind.PICTURE,
      enableShare: kind != EventKind.LONG_FORM_DRAFT &&
          kind != EventKind.CATEGORIZED_BOOKMARK,
      enableDelete: true,
      visualDensity: -4,
      onEdit: kind == EventKind.CATEGORIZED_BOOKMARK
          ? () {
              Navigator.pushNamed(
                context,
                AddBookmarksListView.routeName,
                arguments: [
                  context.read<DashboardBookmarksCubit>(),
                  item,
                ],
              );
            }
          : null,
      onDelete: () => onDelete.call(context),
    );
  }

  Expanded _contentInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.publishedOn(
              date: dateFormat2.format(createdAt),
            ),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (item is DetailedNoteModel)
            ParsedText(
              text: content,
              disableNoteParsing: true,
            )
          else
            Row(
              spacing: kDefaultPadding / 2,
              children: [
                Flexible(
                  child: Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if ((isHiddenType == null || !isHiddenType!) &&
                    kind == EventKind.CATEGORIZED_BOOKMARK) ...[
                  TypeContainer(
                    type: getType(context),
                  ),
                ],
              ],
            ),
          if (kind != EventKind.CATEGORIZED_BOOKMARK) ...[
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Row(
              children: [
                DashboardContentStats(id: id),
                if (isHiddenType == null || !isHiddenType!) ...[
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  TypeContainer(
                    type: getType(context),
                  ),
                ],
                if (isPaid ?? false) ...[
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  const PaidContainer(),
                ],
                if (isRepost ?? false) ...[
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                      color: Theme.of(context).cardColor,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.3,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 8,
                      horizontal: kDefaultPadding / 2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          context.t.reposted.capitalizeFirst(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        SvgPicture.asset(
                          FeatureIcons.repost,
                          width: 15,
                          height: 15,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ]
        ],
      ),
    );
  }

  void onDelete(BuildContext context) {
    showCupertinoDeletionDialogue(
      context: context,
      title: context.t.deleteContent(type: getType(context)).capitalizeFirst(),
      description: context.t
          .confirmDeleteContent(type: getType(context))
          .capitalizeFirst(),
      buttonText: context.t.delete.capitalizeFirst(),
      onDelete: () {
        onDeleteItem?.call(item.id);
      },
    );
  }

  void onAddToNote(BuildContext context) {
    YNavigator.pushPage(
      context,
      (context) => AddContentView(
        contentType: AppContentType.note,
        attachedEvent: item,
        isMention: true,
      ),
    );
  }

  String getIcon() {
    switch (kind) {
      case EventKind.TEXT_NOTE:
        return FeatureIcons.uncensoredNote;
      case EventKind.SMART_WIDGET_ENH:
        return FeatureIcons.smartWidget;

      default:
        return FeatureIcons.add;
    }
  }

  String getType(BuildContext context) {
    String type = '';

    switch (kind) {
      case EventKind.LONG_FORM:
        type = context.t.article.capitalizeFirst();
      case EventKind.LONG_FORM_DRAFT:
        type = context.t.draft.capitalizeFirst();
      case EventKind.CURATION_ARTICLES:
        type = context.t.curation.capitalizeFirst();
      case EventKind.CURATION_VIDEOS:
        type = context.t.curation.capitalizeFirst();
      case EventKind.VIDEO_HORIZONTAL:
        type = context.t.video.capitalizeFirst();
      case EventKind.VIDEO_VERTICAL:
        type = context.t.video.capitalizeFirst();
      case EventKind.SMART_WIDGET_ENH:
        type = context.t.smartWidget.capitalizeFirst();
      case EventKind.TEXT_NOTE:
        type = context.t.note.capitalizeFirst();
      case EventKind.CATEGORIZED_BOOKMARK:
        final bookmark = item as BookmarkListModel;
        type = context.t.itemsNumber(
          number:
              '${bookmark.bookmarkedEvents.length + bookmark.bookmarkedReplaceableEvents.length + bookmark.bookmarkedTags.length + bookmark.bookmarkedUrls.length}',
        );
    }

    return type;
  }
}
