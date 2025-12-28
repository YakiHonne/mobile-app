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
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final articleWritingState = useState(
      isTablet ? ArticleWritingState.editPreview : ArticleWritingState.edit,
    );

    final title = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.title,
    );

    final content = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.content,
    );

    return BlocConsumer<WriteArticleCubit, WriteArticleState>(
      listenWhen: (previous, current) =>
          previous.tryToLoad != current.tryToLoad,
      listener: (context, state) {
        title.text = state.title;
        content.text = state.content;
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.all(isTablet ? kDefaultPadding / 2 : 0),
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
            toggleArticleContent: articleWritingState,
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
                    child: Directionality(
                      textDirection: getTextDirect(state.content),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocBuilder<WriteArticleCubit, WriteArticleState>(
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
                          const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          MarkDownWidget(
                            content: state.content,
                            onLinkClicked: (link) => openWebPage(url: link),
                          ),
                        ],
                      ),
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
