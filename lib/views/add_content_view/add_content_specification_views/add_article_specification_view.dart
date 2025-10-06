import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';

import '../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/publish_content_final_step.dart';
import '../related_adding_views/article_widgets/article_details.dart';

class AddArticleSpecificationView extends HookWidget {
  const AddArticleSpecificationView({required this.signer, super.key});

  final EventSigner signer;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteArticleCubit, WriteArticleState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.60,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                const ModalBottomSheetHandle(),
                Expanded(
                  child: ArticleDetails(
                    scrollController: scrollController,
                  ),
                ),
                Container(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                  padding: EdgeInsets.only(
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                    bottom: MediaQuery.of(context).padding.bottom / 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _saveDraft(context),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      _publish(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Expanded _publish(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: () {
          context.read<WriteArticleCubit>().setArticle(
                isDraft: false,
                signer: signer,
                onSuccess: (article) {
                  Navigator.pop(context);
                  Navigator.pop(context);

                  if (article != null) {
                    showModalBottomSheet(
                      context: context,
                      elevation: 0,
                      builder: (_) {
                        return PublishContentFinalStep(
                          appContentType: AppContentType.article,
                          event: article,
                        );
                      },
                      isScrollControlled: true,
                      useRootNavigator: true,
                      useSafeArea: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  }
                },
              );
        },
        child: Text(
          context.t.publish.capitalize(),
        ),
      ),
    );
  }

  Expanded _saveDraft(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: () {
          context.read<WriteArticleCubit>().setArticle(
                isDraft: true,
                signer: signer,
                onSuccess: (article) {
                  Navigator.pop(context);
                  Navigator.pop(context);

                  if (article != null) {
                    showModalBottomSheet(
                      context: context,
                      elevation: 0,
                      builder: (_) {
                        return PublishContentFinalStep(
                          appContentType: AppContentType.article,
                          event: article,
                        );
                      },
                      isScrollControlled: true,
                      useRootNavigator: true,
                      useSafeArea: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  }
                },
              );
        },
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          visualDensity: VisualDensity.standard,
        ),
        child: Text(
          context.t.saveDraft.capitalize(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).primaryColorDark,
              ),
        ),
      ),
    );
  }
}
