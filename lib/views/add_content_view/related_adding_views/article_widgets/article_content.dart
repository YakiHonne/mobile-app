import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../common/markdown/format_markdown.dart';
import '../../../../common/markdown/markdown_text_input.dart';
import '../../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/mark_down_widget.dart';

class ArticleContent extends HookWidget {
  const ArticleContent({
    super.key,
    required this.isMenuDismissed,
  });

  final bool isMenuDismissed;

  @override
  Widget build(BuildContext context) {
    final toggleArticleContent = useState(true);

    final title = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.title,
    );

    final content = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.content,
    );

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocConsumer<WriteArticleCubit, WriteArticleState>(
      listenWhen: (previous, current) =>
          previous.tryToLoad != current.tryToLoad,
      listener: (context, state) {
        title.text = state.title;
        content.text = state.content;
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.all(isTablet ? 5.w : 0),
          child: MarkdownTextInput(
            (content) {
              context.read<WriteArticleCubit>().setContentText(content);
            },
            (title) {
              context.read<WriteArticleCubit>().setTitleText(title);
            },
            title,
            state.content,
            isMenuDismissed,
            label: context.t.whatsOnYourMind,
            toggleArticleContent: toggleArticleContent,
            previewWidget: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 1.5,
              ),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: BlocBuilder<WriteArticleCubit, WriteArticleState>(
                      buildWhen: (previous, current) =>
                          previous.title != current.title,
                      builder: (context, state) {
                        return Text(
                          state.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MarkDownWidget(
                      content: state.content,
                      onLinkClicked: (link) => openWebPage(url: link),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                ],
              ),
            ),
            actions: MarkdownType.values,
            controller: content,
            maxLines:
                ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 15 : 10,
          ),
        );
      },
    );
  }
}
