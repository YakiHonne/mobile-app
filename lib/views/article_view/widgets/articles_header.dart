// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../logic/article_cubit/article_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/article_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/add_content_view.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';

class ArticleHeader extends StatelessWidget {
  const ArticleHeader({
    super.key,
    required this.article,
  });

  final Article article;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCubit, ArticleState>(
      builder: (context, state) {
        return Row(
          children: [
            BlocBuilder<ArticleCubit, ArticleState>(
              builder: (context, state) {
                return ProfilePicture3(
                  size: 40,
                  image: state.metadata.picture,
                  pubkey: state.metadata.pubkey,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {
                    openProfileFastAccess(
                      context: context,
                      pubkey: state.metadata.pubkey,
                    );
                  },
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _postedBy(context, state),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            if (canSign() && currentSigner?.getPublicKey() == article.pubkey)
              _editButton(context)
            else
              _actionsRow(context, state),
          ],
        );
      },
    );
  }

  AbsorbPointer _actionsRow(BuildContext context, ArticleState state) {
    return AbsorbPointer(
      absorbing: !canSign(),
      child: Row(
        children: [
          BlocBuilder<ArticleCubit, ArticleState>(
            builder: (context, state) {
              final isDisabled = !canSign() || state.isSameArticleAuthor;

              return AbsorbPointer(
                absorbing: isDisabled,
                child: TextButton(
                  onPressed: () {
                    if (!canSign()) {
                    } else {
                      context.read<ArticleCubit>().setFollowingState();
                    }
                  },
                  style: TextButton.styleFrom(
                    visualDensity: const VisualDensity(
                      vertical: -1,
                    ),
                    backgroundColor: isDisabled
                        ? Theme.of(context).highlightColor
                        : state.isFollowingAuthor
                            ? Theme.of(context).cardColor
                            : kMainColor,
                  ),
                  child: Text(
                    state.isFollowingAuthor
                        ? context.t.unfollow.capitalizeFirst()
                        : context.t.follow.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: state.isFollowingAuthor
                              ? Theme.of(context).primaryColorDark
                              : kWhite,
                        ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          NewBorderedIconButton(
            onClicked: () {
              showModalBottomSheet(
                elevation: 0,
                context: context,
                builder: (_) {
                  return SendZapsView(
                    metadata: state.metadata,
                    isZapSplit: article.zapsSplits.isNotEmpty,
                    zapSplits: article.zapsSplits,
                    aTag:
                        '${EventKind.LONG_FORM}:${article.pubkey}:${article.identifier}',
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
            icon: FeatureIcons.zaps,
            buttonStatus: !state.canBeZapped
                ? ButtonStatus.disabled
                : ButtonStatus.inactive,
          ),
        ],
      ),
    );
  }

  TextButton _editButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        YNavigator.pushPage(
          context,
          (context) => AddContentView(
            article: article,
            contentType: AppContentType.article,
          ),
        );
      },
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
        visualDensity: VisualDensity.comfortable,
      ),
      child: Text(
        context.t.edit.capitalizeFirst(),
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).primaryColorDark,
            ),
      ),
    );
  }

  Expanded _postedBy(BuildContext context, ArticleState state) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.postedBy.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  state.metadata.getName(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: kMainColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              MetadataProvider(
                pubkey: state.metadata.pubkey,
                child: (metadata, isNip05Valid) {
                  if (isNip05Valid) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        SvgPicture.asset(
                          FeatureIcons.verified,
                          width: 15,
                          height: 15,
                          colorFilter: const ColorFilter.mode(
                            kMainColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
