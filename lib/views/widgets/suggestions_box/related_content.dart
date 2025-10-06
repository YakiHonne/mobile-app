import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../logic/suggestion_box_cubit/suggestions_box_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/article_model.dart';
import '../../../models/detailed_note_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../note_view/note_view.dart';
import '../buttons_containers_widgets.dart';
import '../common_thumbnail.dart';
import '../data_providers.dart';
import '../profile_picture.dart';
import '../pull_down_global_button.dart';

class SuggestedRelatedContent extends StatelessWidget {
  const SuggestedRelatedContent({super.key, required this.isLeading});

  final bool isLeading;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuggestionsBoxCubit, SuggestionsBoxState>(
      key: const PageStorageKey('related-content'),
      builder: (context, state) {
        if (isLeading) {
          return SuggestedArticles(
            articles: state.articles,
          );
        } else {
          return SuggestedNotes(
            notes: state.notes,
          );
        }
      },
    );
  }
}

class SuggestedArticles extends StatelessWidget {
  const SuggestedArticles({super.key, required this.articles});

  final List<Article> articles;

  @override
  Widget build(BuildContext context) {
    final usedArticles =
        articles.length > 4 ? articles.sublist(0, 4) : articles;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      primary: false,
      itemBuilder: (context, index) {
        final article = usedArticles[index];

        return SuggestedArticleContainer(article: article);
      },
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 4,
      ),
      itemCount: usedArticles.length,
    );
  }
}

class SuggestedArticleContainer extends HookWidget {
  const SuggestedArticleContainer({
    super.key,
    required this.article,
  });

  final Article article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) => ArticleView(article: article),
        );
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            CommonThumbnail(
              image: article.image,
              placeholder: article.placeholder,
              width: 45,
              height: 45,
              radius: kDefaultPadding / 2,
              isRound: true,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _articleAuthor(context),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Theme.of(context).highlightColor,
            ),
          ],
        ),
      ),
    );
  }

  MetadataProvider _articleAuthor(BuildContext context) {
    return MetadataProvider(
      pubkey: article.pubkey,
      child: (metadata, isNip05Valid) {
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(metadata, context, isNip05Valid),
              Text(
                article.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Row _infoRow(Metadata metadata, BuildContext context, bool isNip05Valid) {
    return Row(
      children: [
        Flexible(
          child: Text(
            metadata.getName(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
          ),
        ],
        DotContainer(
          color: Theme.of(context).highlightColor,
          size: 3,
        ),
        Text(
          context.t
              .readTime(
                time: estimateReadingTime(article.content).toString(),
              )
              .capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: kMainColor,
              ),
        ),
      ],
    );
  }
}

class SuggestedNotes extends StatelessWidget {
  const SuggestedNotes({super.key, required this.notes});

  final List<DetailedNoteModel> notes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 145,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        primary: false,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final note = notes[index];

          return SuggestedNoteContainer(note: note);
        },
        separatorBuilder: (context, index) => const SizedBox(
          width: kDefaultPadding / 4,
        ),
        itemCount: notes.length,
      ),
    );
  }
}

class SuggestedNoteContainer extends HookWidget {
  const SuggestedNoteContainer({super.key, required this.note});

  final DetailedNoteModel note;

  @override
  Widget build(BuildContext context) {
    useMemoized(
      () {
        metadataCubit.requestMetadata(note.pubkey);
      },
    );

    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) => NoteView(note: note),
        );
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _user(context),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              note.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  MetadataProvider _user(BuildContext context) {
    return MetadataProvider(
      pubkey: note.pubkey,
      child: (metadata, isNip05Valid) {
        return Row(
          children: [
            ProfilePicture3(
              size: 30,
              image: metadata.picture,
              pubkey: metadata.pubkey,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: note.pubkey,
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _infoRow(metadata, context, isNip05Valid),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            PullDownGlobalButton(
              model: note,
              enableCopyId: true,
            ),
          ],
        );
      },
    );
  }

  Expanded _infoRow(
      Metadata metadata, BuildContext context, bool isNip05Valid) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(
              metadata.getName(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
            ),
          ],
        ],
      ),
    );
  }
}
