import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../../models/app_models/diverse_functions.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/auto_complete_textfield.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/fluid_blur_container.dart';
import '../../../widgets/fluid_sheet.dart';
import '../../../widgets/single_image_selector.dart';
import 'article_publish_sections.dart';

class ArticleDetailsKey {
  static final GlobalKey<AutoCompleteTextFieldState<String>> key = GlobalKey();
}

class ArticleDetails extends HookWidget {
  const ArticleDetails({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final keywordController = useTextEditingController(text: '');
    final titleController = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.title,
    );
    final summaryController = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.excerpt,
    );

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final components = <Widget>[];

    components.add(_header(context));
    components.add(const SizedBox(height: kDefaultPadding));
    components.add(_titleField(context, titleController));
    components.add(const SizedBox(height: kDefaultPadding));
    components.add(
      PublishSection(
        label: context.t.coverImage.capitalizeFirst(),
        child: _coverImageContainer(context),
      ),
    );
    components.add(
      PublishSection(
        label: context.t.summary.capitalizeFirst(),
        child: _summaryField(context, summaryController),
      ),
    );
    components.add(
      PublishSection(
        label: context.t.addYourTopics.capitalizeFirst(),
        child: _tagsField(context, keywordController),
      ),
    );

    components.add(
      BlocBuilder<WriteArticleCubit, WriteArticleState>(
        buildWhen: (previous, current) =>
            previous.isSensitive != current.isSensitive,
        builder: (context, state) {
          return PublishOptionsCard(
            children: [
              PublishToggleRow(
                title: context.t.sensitiveContent.capitalizeFirst(),
                value: state.isSensitive,
                onChanged: () =>
                    context.read<WriteArticleCubit>().toggleSensitive(),
              ),
            ],
          );
        },
      ),
    );

    return ListView(
      padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
      controller: scrollController,
      children: components,
    );
  }

  Widget _tagsField(
    BuildContext context,
    TextEditingController keywordController,
  ) {
    void addKeyword(WriteArticleState state) {
      final text = keywordController.text.trim();
      if (text.isNotEmpty && !state.keywords.contains(text)) {
        context.read<WriteArticleCubit>().addKeyword(text);
        keywordController.clear();
      }
    }

    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SimpleAutoCompleteTextField(
                    key: ArticleDetailsKey.key,
                    cursorColor: Theme.of(context).primaryColorDark,
                    decoration: InputDecoration(
                      hintText: context.t.addYourTopics,
                    ),
                    controller: keywordController,
                    suggestions: state.suggestions,
                    isBottom: false,
                    textSubmitted: (_) => addKeyword(state),
                  ),
                ),
                const SizedBox(width: kDefaultPadding / 2),
                TextButton(
                  onPressed: () => addKeyword(state),
                  child: Text(context.t.add.capitalizeFirst()),
                ),
              ],
            ),
            if (state.keywords.isNotEmpty) ...[
              const SizedBox(height: kDefaultPadding / 2),
              Wrap(
                runSpacing: kDefaultPadding / 4,
                spacing: kDefaultPadding / 4,
                children: state.keywords
                    .map(
                      (keyword) => Chip(
                        visualDensity: const VisualDensity(vertical: -4),
                        backgroundColor: Theme.of(context).cardColor,
                        label: Text(
                          keyword,
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    height: 1.5,
                                  ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                          side: const BorderSide(
                            color: kTransparent,
                          ),
                        ),
                        onDeleted: () {
                          context
                              .read<WriteArticleCubit>()
                              .deleteKeyword(keyword);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      buildWhen: (previous, current) =>
          previous.title != current.title ||
          previous.content != current.content,
      builder: (context, state) {
        final isContentEmpty = state.content.trim().isEmpty;
        final wordCount = isContentEmpty
            ? 0
            : state.content.trim().split(RegExp(r'\s+')).length;
        final readTime =
            isContentEmpty ? 0 : estimateReadingTime(state.content);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.publishArticle.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: kDefaultPadding / 4),
            Text(
              '${context.t.wordsCount(count: wordCount)}  •  ${context.t.readTime(time: readTime)}',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _titleField(
      BuildContext context, TextEditingController titleController) {
    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      buildWhen: (previous, current) => previous.title != current.title,
      builder: (context, state) {
        if (titleController.text != state.title) {
          titleController.text = state.title;
        }
        return TextField(
          controller: titleController,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w800,
              ),
          decoration: InputDecoration(
            hintText: context.t.title.capitalizeFirst(),
            hintStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).highlightColor,
                ),
            filled: false,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (title) {
            context.read<WriteArticleCubit>().setTitleText(title);
          },
        );
      },
    );
  }

  Widget _coverImageContainer(BuildContext context) {
    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      buildWhen: (previous, current) => previous.imageLink != current.imageLink,
      builder: (context, state) {
        void addImage() {
          showAppModalSheet(
            context: context,
            builder: (_) {
              return SingleImageSelector(
                onUrlProvided: (url, {imeta}) {
                  context.read<WriteArticleCubit>().setImage(url);
                  if (imeta != null) {
                    context.read<WriteArticleCubit>().addImeta(imeta);
                  }
                  Navigator.pop(context);
                },
              );
            },
            backgroundColor: Theme.of(context).cardColor,
          );
        }

        return GestureDetector(
          onTap: addImage,
          child: state.imageLink.isEmpty
              ? DottedBorder(
                  color: Theme.of(context).primaryColorDark,
                  borderType: BorderType.rRect,
                  radius: const Radius.circular(kDefaultPadding / 1.5),
                  dashPattern: const [6, 4],
                  padding: EdgeInsets.zero,
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          FeatureIcons.imageUpload,
                          size: 30,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        const SizedBox(height: kDefaultPadding / 4),
                        Text(
                          context.t.uploadImage.capitalizeFirst(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CommonThumbnail(
                          image: state.imageLink,
                          width: double.infinity,
                          height: double.infinity,
                          isRound: true,
                          radius: kDefaultPadding / 1.5,
                        ),
                        Positioned(
                          top: kDefaultPadding / 4,
                          right: kDefaultPadding / 4,
                          child: CustomIconButton(
                            onClicked: () {
                              context.read<WriteArticleCubit>().deleteImage();
                            },
                            icon: FeatureIcons.trash,
                            size: 20,
                            backgroundColor:
                                Theme.of(context).cardColor.withValues(
                                      alpha: 0.9,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _summaryField(
      BuildContext context, TextEditingController summaryController) {
    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      buildWhen: (previous, current) => previous.excerpt != current.excerpt,
      builder: (context, state) {
        if (summaryController.text != state.excerpt) {
          summaryController.text = state.excerpt;
        }
        return TextField(
          controller: summaryController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: publishInputDecoration(
            context,
            context.t.writeSummary.capitalizeFirst(),
          ),
          onChanged: (summary) {
            context.read<WriteArticleCubit>().setDescription(summary);
          },
        );
      },
    );
  }
}

class ArticleCheckBoxListTile extends StatelessWidget {
  const ArticleCheckBoxListTile({
    super.key,
    required this.isEnabled,
    required this.status,
    required this.text,
    required this.onToggle,
    this.textColor,
  });

  final bool isEnabled;
  final bool status;
  final String text;
  final Color? textColor;
  final Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.translucent,
      child: FluidCardContainer(
        padding: const EdgeInsets.all(kDefaultPadding / 6),
        borderRadius: kDefaultPadding / 2,
        child: Row(
          children: [
            Checkbox(
              value: status,
              onChanged: (value) {
                onToggle.call();
              },
              side: BorderSide(
                color: Theme.of(context).primaryColorDark,
                width: 1.5,
              ),
              visualDensity: VisualDensity.compact,
              activeColor: Theme.of(context).primaryColor,
              checkColor: kWhite,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
