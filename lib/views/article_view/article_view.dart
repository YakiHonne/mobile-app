// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
import '../add_content_view/add_content_view.dart';
import '../gallery_view/gallery_view.dart';
import '../search_view/search_view.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/content_stats.dart';
import '../widgets/data_providers.dart';
import '../widgets/fluid_blur_container.dart';
import '../widgets/fluid_scaffold.dart';
import '../widgets/fluid_sheet.dart';
import '../widgets/mark_down_widget.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/note_stats.dart';
import '../widgets/profile_picture.dart';
import '../widgets/scroll_to_top.dart';
import 'widgets/articles_header.dart';

// Reading measure for the fluid layout. On a phone the screen is narrower than
// this so it's a no-op; on a tablet it keeps lines from running edge to edge.
const double _kMaxReadingWidth = 700;

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

        textDirectionality.value = getTextDirect(
          extractedContent.value['replacedString'],
        );

        if (nostrRepository.getAutoTranslationStatus()) {
          await Future.delayed(const Duration(seconds: 3));
          if (context.mounted) {
            translateContent();
          }
        }
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
            return FluidScaffold(
              title: context.t.article.capitalizeFirst(),
              bottomBar: isFluid()
                  ? null
                  : _contentStatsBar(
                      context,
                      isTranslating: isTranslating,
                      showOriginalContent: showOriginalContent,
                      translateContent: translateContent,
                      articleContent: articleContent,
                      articleTitle: articleTitle,
                      articleSummary: articleSummary,
                    ),
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
                padding: EdgeInsets.only(
                  top: kDefaultPadding + fluidScaffoldTopInset(context),
                  bottom: isFluid()
                      ? MediaQuery.of(context).padding.bottom + 160
                      : kDefaultPadding,
                  left: kDefaultPadding / 2,
                  right: kDefaultPadding / 2,
                ),
                physics: const ClampingScrollPhysics(),
                controller: scrollController,
                children: isFluid()
                    ? [
                        _fluidContent(
                          context,
                          textDirectionality,
                          articleTitle,
                          articleSummary,
                          articleContent,
                        ),
                      ]
                    : [
                        ArticleHeader(
                          article: article,
                        ),
                        Divider(
                          thickness: 0.3,
                          height: kDefaultPadding,
                          color: Theme.of(context).dividerColor,
                        ),
                        _directionalityWidget(
                          textDirectionality,
                          articleTitle,
                          context,
                          articleSummary,
                          articleContent,
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                      ],
              ),
            );
          },
        ),
        if (!isFluid())
          _translationContainer(
              isTranslating,
              showOriginalContent,
              translateContent,
              articleContent,
              articleTitle,
              articleSummary,
              context),
        if (!isFluid())
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ResetScrollButton(
          scrollController: scrollController,
          padding:
              isFluid() ? MediaQuery.of(context).padding.bottom + 100 : null,
        ),
        if (isFluid())
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _contentStatsBar(
              context,
              isTranslating: isTranslating,
              showOriginalContent: showOriginalContent,
              translateContent: translateContent,
              articleContent: articleContent,
              articleTitle: articleTitle,
              articleSummary: articleSummary,
            ),
          ),
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
              border: Border.all(color: Theme.of(context).primaryColor),
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
          if (article.isPremium) ...[
            const Center(child: PremiumBadge(large: true)),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
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
      alignment: isFluid() ? WrapAlignment.center : WrapAlignment.start,
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
      mainAxisAlignment:
          isFluid() ? MainAxisAlignment.center : MainAxisAlignment.start,
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
                        color: Theme.of(context).primaryColor,
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
                        color: Theme.of(context).primaryColor,
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

  Widget _contentStatsBar(
    BuildContext context, {
    required ValueNotifier<bool> isTranslating,
    required ValueNotifier<bool> showOriginalContent,
    required Function() translateContent,
    required ValueNotifier<String> articleContent,
    required ValueNotifier<String> articleTitle,
    required ValueNotifier<String> articleSummary,
  }) {
    final stats = ContentStats(
      attachedEvent: article,
      pubkey: article.pubkey,
      kind: EventKind.LONG_FORM,
      identifier: article.identifier,
      createdAt: article.createdAt,
      title: article.title,
      isInside: !isFluid(),
    );

    if (isFluid()) {
      final bottomPad =
          MediaQuery.of(context).padding.bottom + kDefaultPadding / 4;
      return Visibility(
        visible: !isUserMuted(article.pubkey),
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Padding(
          padding: EdgeInsets.only(
            left: kDefaultPadding / 2,
            right: kDefaultPadding / 2,
            bottom: bottomPad,
            top: kDefaultPadding / 4,
          ),
          // Capped to match the article column above, so the bar's edges line
          // up with the text instead of spanning the whole tablet.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxReadingWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kDefaultPadding / 4,
                children: [
                  _fluidTranslationButton(
                    context,
                    isTranslating: isTranslating,
                    showOriginalContent: showOriginalContent,
                    translateContent: translateContent,
                    articleContent: articleContent,
                    articleTitle: articleTitle,
                    articleSummary: articleSummary,
                  ),
                  FluidBlurContainer(
                    customBorderRadius: BorderRadius.circular(kDefaultPadding),
                    padding: const EdgeInsets.all(
                      kDefaultPadding / 2,
                    ),
                    child: stats,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
            const Divider(height: 0, thickness: 0.5),
            SizedBox(height: kBottomNavigationBarHeight, child: stats),
          ],
        ),
      ),
    );
  }

  Widget _fluidContent(
    BuildContext context,
    ValueNotifier<TextDirection> textDirectionality,
    ValueNotifier<String> articleTitle,
    ValueNotifier<String> articleSummary,
    ValueNotifier<String> articleContent,
  ) {
    return BlocBuilder<ArticleCubit, ArticleState>(
      builder: (context, state) {
        // Center passes loose constraints down; without it the ConstrainedBox
        // inherits the ListView's tight width and the cap does nothing.
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxReadingWidth),
            child: Directionality(
              textDirection: textDirectionality.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fluidAuthorRow(context, state),
                  const SizedBox(height: kDefaultPadding / 4),
                  _postedFromRow(context),
                  const SizedBox(height: kDefaultPadding / 2),
                  Builder(
                    builder: (context) {
                      final title = articleTitle.value.trim();
                      return SelectableText(
                        title.isEmpty
                            ? context.t.noTitle.capitalizeFirst()
                            : title,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineLarge!.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: title.isEmpty
                                      ? Theme.of(context).highlightColor
                                      : Theme.of(context).primaryColorDark,
                                ),
                      );
                    },
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  if (article.isPremium) ...[
                    const Center(child: PremiumBadge(large: true)),
                    const SizedBox(height: kDefaultPadding),
                  ],
                  if (articleSummary.value.trim().isNotEmpty) ...[
                    SelectableText(
                      articleSummary.value.trim(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                  ],
                  if (article.hashTags.isNotEmpty) ...[
                    const SizedBox(height: kDefaultPadding / 2),
                    _tagWrap(context),
                  ],
                  const SizedBox(height: kDefaultPadding),
                  if (article.image.isNotEmpty) ...[
                    _imageContainer(),
                    const SizedBox(height: kDefaultPadding / 2),
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
            ),
          ),
        );
      },
    );
  }

  Widget _fluidAuthorRow(BuildContext context, ArticleState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ProfilePicture3(
          size: 40,
          image: state.metadata.picture,
          pubkey: state.metadata.pubkey,
          padding: 0,
          strokeWidth: 0,
          strokeColor: kTransparent,
          onClicked: () => openProfileFastAccess(
            context: context,
            pubkey: state.metadata.pubkey,
          ),
        ),
        const SizedBox(width: kDefaultPadding / 2),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  state.metadata.getName(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).primaryColorDark,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              MetadataProvider(
                pubkey: state.metadata.pubkey,
                child: (metadata, isNip05Valid) {
                  if (!isNip05Valid) {
                    return const SizedBox.shrink();
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: kDefaultPadding / 4),
                      AppIcon(
                        FeatureIcons.verified,
                        size: 15,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: kDefaultPadding / 2),
        Text(
          '|',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        const SizedBox(width: kDefaultPadding / 2),
        if (canSign() && state.isSameArticleAuthor)
          AppIconButton(
            onClicked: () {
              YNavigator.pushPage(
                context,
                (context) => AddContentView(
                  article: article,
                  contentType: AppContentType.article,
                ),
              );
            },
            icon: FeatureIcons.editArticle,
            size: 40,
            iconSize: 20,
            buttonStatus: ButtonStatus.inactive,
          )
        else
          AbsorbPointer(
            absorbing: !canSign() || state.isSameArticleAuthor,
            child: AppIconButton(
              onClicked: () => context.read<ArticleCubit>().setFollowingState(),
              icon: state.isFollowingAuthor
                  ? FeatureIcons.profileRemove
                  : FeatureIcons.profileAdd,
              size: 40,
              iconSize: 20,
              buttonStatus: (!canSign() || state.isSameArticleAuthor)
                  ? ButtonStatus.disabled
                  : ButtonStatus.inactive,
            ),
          ),
        const SizedBox(width: kDefaultPadding / 4),
        AppIconButton(
          onClicked: () {
            showAppModalSheet(
              context: context,
              builder: (_) => SendZapsView(
                metadata: state.metadata,
                isZapSplit: article.zapsSplits.isNotEmpty,
                zapSplits: article.zapsSplits,
                aTag:
                    '${EventKind.LONG_FORM}:${article.pubkey}:${article.identifier}',
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          icon: FeatureIcons.zaps,
          size: 40,
          iconSize: 20,
          buttonStatus: !state.canBeZapped
              ? ButtonStatus.disabled
              : ButtonStatus.inactive,
        ),
      ],
    );
  }

  Widget _fluidTranslationButton(
    BuildContext context, {
    required ValueNotifier<bool> isTranslating,
    required ValueNotifier<bool> showOriginalContent,
    required Function() translateContent,
    required ValueNotifier<String> articleContent,
    required ValueNotifier<String> articleTitle,
    required ValueNotifier<String> articleSummary,
  }) {
    return GestureDetector(
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
      child: FluidCardContainer(
        borderRadius: 300,
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
          horizontal: kDefaultPadding / 2,
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
              const SizedBox(width: kDefaultPadding / 4),
              const SizedBox(
                height: 15,
                width: 15,
                child: SpinKitFadingCircle(color: kWhite, size: 15),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
