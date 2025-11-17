import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/auto_complete_textfield.dart';
import '../../../widgets/content_zap_splits.dart';
import '../../widgets/publish_preview_container.dart';

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

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final components = <Widget>[];

    components.add(
      BlocBuilder<WriteArticleCubit, WriteArticleState>(
        builder: (context, state) {
          return PublishPreviewContainer(
            descInitText: context.read<WriteArticleCubit>().state.excerpt,
            title: state.title,
            onDescChanged: (desc) {
              context.read<WriteArticleCubit>().setDescription(desc);
            },
            imageLink: state.imageLink,
            onImageLinkChanged: (url) {
              context.read<WriteArticleCubit>().setImage(url);
              Navigator.pop(context);
            },
          );
        },
      ),
    );

    components.add(
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    components.add(
      BlocBuilder<WriteArticleCubit, WriteArticleState>(
        buildWhen: (previous, current) =>
            previous.isSensitive != current.isSensitive,
        builder: (context, state) {
          return ArticleCheckBoxListTile(
            isEnabled: true,
            status: state.isSensitive,
            text: context.t.sensitiveContent,
            onToggle: () {
              context.read<WriteArticleCubit>().toggleSensitive();
            },
          );
        },
      ),
    );

    components.add(
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    components.add(
      BlocBuilder<WriteArticleCubit, WriteArticleState>(
        builder: (context, state) {
          return Row(
            children: [
              Expanded(
                child: SimpleAutoCompleteTextField(
                  key: ArticleDetailsKey.key,
                  cursorColor: Theme.of(context).primaryColorDark,
                  decoration: InputDecoration(
                    hintText: context.t.addYourTopics,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  controller: keywordController,
                  suggestions: state.suggestions,
                  isBottom: false,
                  textSubmitted: (text) {
                    if (text.isNotEmpty &&
                        !state.keywords.contains(text.trim())) {
                      context
                          .read<WriteArticleCubit>()
                          .addKeyword(keywordController.text);
                      keywordController.clear();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );

    components.add(
      BlocBuilder<WriteArticleCubit, WriteArticleState>(
        buildWhen: (previous, current) => previous.keywords != current.keywords,
        builder: (context, state) {
          if (state.keywords.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
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
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
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
                )
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );

    components.add(
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    components.add(
      BlocBuilder<WriteArticleCubit, WriteArticleState>(
        buildWhen: (previous, current) =>
            previous.isZapSplitEnabled != current.isZapSplitEnabled ||
            previous.zapsSplits != current.zapsSplits,
        builder: (context, state) {
          return ContentZapSplits(
            kind: context.t.article,
            isZapSplitEnabled: state.isZapSplitEnabled,
            zaps: state.zapsSplits,
            onToggleZapSplit: () {
              context.read<WriteArticleCubit>().toggleZapsSplits();
            },
            onAddZapSplitUser: (pubkey) {
              context.read<WriteArticleCubit>().addZapSplit(pubkey);
            },
            onRemoveZapSplitUser: (pubkey) {
              context.read<WriteArticleCubit>().onRemoveZapSplit(pubkey);
            },
            onSetZapProportions: (index, zap, percentage) {
              context.read<WriteArticleCubit>().setZapPropertion(
                    index: index,
                    zapSplit: zap,
                    newPercentage: percentage,
                  );
            },
          );
        },
      ),
    );

    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
          controller: scrollController,
          children: components,
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
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
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
