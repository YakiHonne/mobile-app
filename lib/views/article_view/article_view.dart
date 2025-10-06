// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart' as intl;
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../logic/article_cubit/article_cubit.dart';
import '../../logic/settings_cubit/settings_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../repositories/localdatabase_repository.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../gallery_view/gallery_view.dart';
import '../search_view/search_view.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/content_stats.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/mark_down_widget.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/scroll_to_top.dart';
import 'widgets/articles_header.dart';

class ArticleView extends HookWidget {
  static const routeName = '/articleView';
  static Route route(RouteSettings settings) {
    final article = settings.arguments! as Article;

    return CupertinoPageRoute(
      builder: (_) => ArticleView(
        article: article,
      ),
    );
  }

  final Article article;

  ArticleView({
    super.key,
    required this.article,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Article view');
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    final articleContent = useState(article.content);
    final articleTitle = useState(article.title);
    final articleSummary = useState(article.summary);
    final isTranslating = useState(false);
    final showOriginalContent = useState(true);
    final extractedContent = useState(<String, dynamic>{});
    final concatenatedContent = useState('');
    final textDirectionality = useState(Directionality.of(context));

    Future<void> translateContent() async {
      isTranslating.value = true;

      final res = await localizationCubit.translateContent(
        content: concatenatedContent.value,
      );

      if (res.key) {
        try {
          final texts = res.value.split('ABCAF');

          articleTitle.value = texts[0].trim();
          articleSummary.value =
              article.summary.isNotEmpty ? texts[1].trim() : '';

          articleContent.value = restoreOriginalString(
            replacedString:
                article.summary.isNotEmpty ? texts[2].trim() : texts[1].trim(),
            extractedData: extractedContent.value['extractedData'],
          );

          showOriginalContent.value = false;
        } catch (_) {
          showOriginalContent.value = false;
        }
      } else {
        BotToastUtils.showError(res.value);
      }

      isTranslating.value = false;
    }

    useMemoized(
      () async {
        extractedContent.value = replaceWithIndexAndExtract(
          input: article.content,
        );

        String text = '';

        text = article.title.trim();

        text = text.isEmpty
            ? article.summary
            : article.summary.isNotEmpty
                ? '$text ABCAF ${article.summary.trim()}'
                : text;

        text = "$text ABCAF ${extractedContent.value['replacedString']}";

        concatenatedContent.value = text;

        textDirectionality.value = intl.Bidi.detectRtlDirectionality(
          extractedContent.value['replacedString'],
        )
            ? TextDirection.rtl
            : TextDirection.ltr;
      },
    );

    return BlocProvider(
      create: (context) => ArticleCubit(
        article: article,
        nostrRepository: context.read<NostrDataRepository>(),
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
      )..initView(),
      child: ScrollsToTop(
        onScrollsToTop: (event) async {
          onScrollsToTop(event, scrollController);
        },
        child: BlocBuilder<ArticleCubit, ArticleState>(
          builder: (context, state) {
            return Scaffold(
              appBar: CustomAppBar(
                title: context.t.article.capitalizeFirst(),
              ),
              bottomNavigationBar: _contentStatsBar(context),
              body: isUserMuted(article.pubkey)
                  ? Center(
                      child: MutedUserContent(
                        pubkey: article.pubkey,
                      ),
                    )
                  : _contentStack(
                      scrollController,
                      textDirectionality,
                      articleTitle,
                      articleSummary,
                      articleContent,
                      isTranslating,
                      showOriginalContent,
                      translateContent,
                      context),
            );
          },
        ),
      ),
    );
  }

  Stack _contentStack(
      ScrollController scrollController,
      ValueNotifier<TextDirection> textDirectionality,
      ValueNotifier<String> articleTitle,
      ValueNotifier<String> articleSummary,
      ValueNotifier<String> articleContent,
      ValueNotifier<bool> isTranslating,
      ValueNotifier<bool> showOriginalContent,
      Function() translateContent,
      BuildContext context) {
    return Stack(
      children: [
        Builder(
          builder: (context) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ArticleCubit>().emptyArticleState();
                context.read<ArticleCubit>().initView();
              },
              displacement: kDefaultPadding / 2,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              notificationPredicate: (notification) {
                return notification.depth == 0;
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding,
                  horizontal: kDefaultPadding / 2,
                ),
                physics: const ClampingScrollPhysics(),
                controller: scrollController,
                children: [
                  ArticleHeader(
                    article: article,
                  ),
                  Divider(
                    thickness: 0.3,
                    height: kDefaultPadding,
                    color: Theme.of(context).dividerColor,
                  ),
                  _directionalityWidget(textDirectionality, articleTitle,
                      context, articleSummary, articleContent),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                ],
              ),
            );
          },
        ),
        _translationContainer(
            isTranslating,
            showOriginalContent,
            translateContent,
            articleContent,
            articleTitle,
            articleSummary,
            context),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        ResetScrollButton(scrollController: scrollController),
      ],
    );
  }

  Align _translationContainer(
      ValueNotifier<bool> isTranslating,
      ValueNotifier<bool> showOriginalContent,
      Function() translateContent,
      ValueNotifier<String> articleContent,
      ValueNotifier<String> articleTitle,
      ValueNotifier<String> articleSummary,
      BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: GestureDetector(
          onTap: () {
            if (!isTranslating.value) {
              if (showOriginalContent.value) {
                translateContent();
              } else {
                articleContent.value = article.content;
                articleTitle.value = article.title;
                articleSummary.value = article.summary;
                showOriginalContent.value = true;
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              border: Border.all(color: kMainColor),
              boxShadow: [
                BoxShadow(
                  blurRadius: 5,
                  offset: const Offset(0, 5),
                  color: kBlack.withValues(alpha: 0.3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 2,
              horizontal: kDefaultPadding,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showOriginalContent.value
                      ? context.t.seeTranslation.capitalizeFirst()
                      : context.t.seeOriginal.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).primaryColorDark,
                        height: 1,
                      ),
                ),
                if (isTranslating.value) ...[
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  const SizedBox(
                    height: 15,
                    width: 15,
                    child: SpinKitFadingCircle(
                      color: kWhite,
                      size: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Directionality _directionalityWidget(
      ValueNotifier<TextDirection> textDirectionality,
      ValueNotifier<String> articleTitle,
      BuildContext context,
      ValueNotifier<String> articleSummary,
      ValueNotifier<String> articleContent) {
    return Directionality(
      textDirection: textDirectionality.value,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final title = articleTitle.value.trim();

              return SelectableText(
                title.isEmpty ? context.t.noTitle.capitalizeFirst() : title,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: title.isEmpty
                          ? Theme.of(context).highlightColor
                          : Theme.of(context).primaryColorDark,
                    ),
              );
            },
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _postedFromRow(context),
          if (articleSummary.value.trim().isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            SelectableText(
              articleSummary.value.trim(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
          if (article.hashTags.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _tagWrap(context),
          ],
          const SizedBox(
            height: kDefaultPadding,
          ),
          if (article.image.isNotEmpty) ...[
            _imageContainer(),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          Builder(
            builder: (context) {
              try {
                return MarkDownWidget(
                  content: articleContent.value,
                  onLinkClicked: (link) => openWebPage(url: link),
                );
              } catch (e) {
                return MarkDownWidget(
                  content: article.content,
                  onLinkClicked: (link) => openWebPage(url: link),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  LayoutBuilder _imageContainer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            openGallery(
              source: MapEntry(article.image, UrlType.image),
              index: 0,
              context: context,
            );
          },
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CommonThumbnail(
              image: article.image,
              placeholder: getRandomPlaceholder(
                input: article.identifier,
                isPfp: false,
              ),
              width: double.infinity,
              radius: kDefaultPadding,
            ),
          ),
        );
      },
    );
  }

  Wrap _tagWrap(BuildContext context) {
    return Wrap(
      spacing: kDefaultPadding / 3,
      runSpacing: kDefaultPadding / 3,
      children: article.hashTags.map((tag) {
        if (tag.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return InfoRoundedContainer(
          tag: tag,
          color: Theme.of(context).primaryColor,
          textColor: kWhite,
          onClicked: () {
            YNavigator.pushPage(
              context,
              (context) => SearchView(
                search: tag,
                index: 2,
              ),
              type: PushPageType.opacity,
            );
          },
        );
      }).toList(),
    );
  }

  Row _postedFromRow(BuildContext context) {
    return Row(
      children: [
        Text(
          '${context.t.postedFrom.capitalizeFirst()} ',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        Flexible(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, appClientsState) {
              if (article.client.isEmpty ||
                  !article.client
                      .contains(EventKind.APPLICATION_INFO.toString())) {
                return Text(
                  article.client.isEmpty ? 'N/A' : article.client,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: kMainColor,
                      ),
                );
              } else {
                final appApplication = appClientsState
                    .appClients[context.read<ArticleCubit>().identifier];

                return Text(
                  appApplication == null
                      ? 'N/A'
                      : appApplication.name.trim().capitalize(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: kMainColor,
                      ),
                );
              }
            },
          ),
        ),
        DotContainer(
          color: Theme.of(context).highlightColor,
          size: 2,
        ),
        Text(
          StringUtil.formatTimeDifference(
            article.createdAt,
          ),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Visibility _contentStatsBar(BuildContext context) {
    return Visibility(
      visible: !isUserMuted(article.pubkey),
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: SizedBox(
        height:
            kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
        child: Column(
          children: [
            const Divider(
              height: 0,
              thickness: 0.5,
            ),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: ContentStats(
                attachedEvent: article,
                pubkey: article.pubkey,
                kind: EventKind.LONG_FORM,
                identifier: article.identifier,
                createdAt: article.createdAt,
                title: article.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
