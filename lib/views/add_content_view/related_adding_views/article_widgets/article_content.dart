import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../common/markdown/format_markdown.dart';
import '../../../../common/markdown/markdown_text_input.dart';
import '../../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/mark_down_widget.dart';
import 'article_editor_shared.dart';
import 'article_quill_editor.dart';

class ArticleContent extends HookWidget {
  const ArticleContent({
    super.key,
    required this.isMenuDismissed,
    this.useAdvanced = false,
    this.signer,
    required this.isSubscriber,
  });

  final bool isMenuDismissed;
  final bool useAdvanced;
  final ValueNotifier<EventSigner>? signer;
  final bool isSubscriber;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final articleWritingState = useState(
      isTablet ? ArticleWritingState.editPreview : ArticleWritingState.edit,
    );

    final content = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.content,
    );

    // Sync the classic editor text into the cubit when switching to advanced,
    // so AppFlowy builds its document from the latest typed content.
    useEffect(() {
      if (useAdvanced) {
        context.read<WriteArticleCubit>().setContentText(content.text);
      }
      return null;
    }, [useAdvanced]);

    return BlocConsumer<WriteArticleCubit, WriteArticleState>(
      listenWhen: (previous, current) =>
          previous.tryToLoad != current.tryToLoad,
      listener: (context, state) {
        content.text = state.content;
      },
      builder: (context, state) {
        void onDeleteDraft() => confirmDeleteDraft(
              context,
              () => context.read<WriteArticleCubit>().deleteDraft(),
            );

        return Column(
          children: [
            Expanded(
              child: useAdvanced
                  ? ArticlePremiumEditor(
                      initialContent: state.content,
                      cubit: context.read<WriteArticleCubit>(),
                      onDeleteDraft:
                          context.read<WriteArticleCubit>().deleteDraft,
                    )
                  : Padding(
                      padding:
                          EdgeInsets.all(isTablet ? kDefaultPadding / 2 : 0),
                      child: MarkdownTextInput(
                        (c) =>
                            context.read<WriteArticleCubit>().setContentText(c),
                        state.content,
                        isMenuDismissed,
                        removeBottomPadding: isSubscriber,
                        onDeleteDraft: onDeleteDraft,
                        onMetadataInserted: (imeta) {
                          context.read<WriteArticleCubit>().addImeta(imeta);
                        },
                        label: context.t.whatsOnYourMind,
                        toggleArticleContent: articleWritingState,
                        previewWidget: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 1.5,
                          ),
                          child: CustomScrollView(
                            slivers: [
                              const SliverToBoxAdapter(
                                child: SizedBox(height: kDefaultPadding / 2),
                              ),
                              SliverToBoxAdapter(
                                child: Directionality(
                                  textDirection: getTextDirect(state.content),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BlocBuilder<WriteArticleCubit,
                                          WriteArticleState>(
                                        buildWhen: (p, c) => p.title != c.title,
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
                                          height: kDefaultPadding / 2),
                                      MarkDownWidget(
                                        content: state.content,
                                        onLinkClicked: (link) =>
                                            openWebPage(url: link),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: kDefaultPadding / 2),
                              ),
                            ],
                          ),
                        ),
                        actions: MarkdownType.values,
                        controller: content,
                        maxLines: isTablet ? 15 : 10,
                      ),
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        );
      },
    );
  }
}
