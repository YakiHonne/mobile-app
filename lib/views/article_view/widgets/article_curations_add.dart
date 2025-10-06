// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/article_cubit/article_curations_cubit/article_curations_cubit.dart';
import '../../../models/curation_model.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/related_adding_views/article_widgets/article_selected_relays.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/content_zap_splits.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';

class AddItemToCurationView extends StatelessWidget {
  const AddItemToCurationView({
    super.key,
    required this.articleId,
    required this.articlePubkey,
    required this.kind,
  });

  final String articleId;
  final String articlePubkey;
  final int kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ArticleCurationsCubit(
        articleId: articleId,
        articleAuthor: articlePubkey,
        kind: kind,
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          width: double.infinity,
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
            initialChildSize: 0.9,
            minChildSize: 0.60,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) => _contentColumn(controller),
          ),
        ),
      ),
    );
  }

  Column _contentColumn(ScrollController controller) {
    return Column(
      children: [
        const ModalBottomSheetHandle(),
        _topBar(),
        const Divider(
          height: 0,
        ),
        BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
          builder: (context, state) {
            return Expanded(
              child: getView(
                state.articleCuration,
                controller,
                state,
                context,
              ),
            );
          },
        ),
        const ArticleCurationsBottomBar(),
      ],
    );
  }

  BlocBuilder<ArticleCurationsCubit, ArticleCurationsState> _topBar() {
    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      buildWhen: (previous, current) =>
          previous.articleCuration != current.articleCuration,
      builder: (context, state) {
        return SizedBox(
          height: kToolbarHeight - 5,
          child: Center(
            child: Stack(
              children: [
                if (state.articleCuration != ArticleCuration.curationsList)
                  IconButton(
                    onPressed: () {
                      context
                          .read<ArticleCurationsCubit>()
                          .setView(ArticleCuration.curationsList);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                Center(
                  child: Text(
                    state.articleCuration == ArticleCuration.curationsList
                        ? context.t.addToCuration.capitalizeFirst()
                        : context.t.submitCuration.capitalizeFirst(),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getView(
    ArticleCuration isCurationsList,
    ScrollController controller,
    ArticleCurationsState state,
    BuildContext context,
  ) {
    return isCurationsList == ArticleCuration.curationsList
        ? ArticleSuggestedCurationList(
            scrollController: controller,
          )
        : isCurationsList == ArticleCuration.curationContent
            ? AddCuration(
                controller: controller,
              )
            : isCurationsList == ArticleCuration.zaps
                ? _contentZapSplitContainer()
                : _articleSelectedRelays(state, context);
  }

  ArticleSelectedRelays _articleSelectedRelays(
      ArticleCurationsState state, BuildContext context) {
    return ArticleSelectedRelays(
      selectedRelays: state.selectedRelays,
      totaRelays: state.totalRelays,
      onToggle: (relay) {
        if (!mandatoryRelays.contains(relay)) {
          context.read<ArticleCurationsCubit>().setRelaySelection(relay);
        }
      },
      deleteDraft: false,
      isDraft: false,
      isDraftShown: false,
      isForwardedAsDraft: false,
      onDeleteDraft: () {},
    );
  }

  BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>
      _contentZapSplitContainer() {
    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        return ContentZapSplits(
          kind: 'curation',
          isZapSplitEnabled: state.isZapSplitEnabled,
          zaps: state.zapsSplits,
          onToggleZapSplit: () {
            context.read<ArticleCurationsCubit>().toggleZapsSplits();
          },
          onAddZapSplitUser: (pubkey) {
            context.read<ArticleCurationsCubit>().addZapSplit(pubkey);
          },
          onRemoveZapSplitUser: (pubkey) {
            context.read<ArticleCurationsCubit>().onRemoveZapSplit(pubkey);
          },
          onSetZapProportions: (index, zap, percentage) {
            context.read<ArticleCurationsCubit>().setZapPropertion(
                  index: index,
                  zapSplit: zap,
                  newPercentage: percentage,
                );
          },
        );
      },
    );
  }
}

class AddCuration extends HookWidget {
  const AddCuration({
    super.key,
    required this.controller,
  });

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final imageUrlController = useTextEditingController(text: '');

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding),
          children: [
            _contentStack(imageUrlController),
            const SizedBox(
              height: kDefaultPadding,
            ),
            _actionsRow(imageUrlController),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _titleTextfield(state, context),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _descriptionTextfield(state, context),
          ],
        );
      },
    );
  }

  TextFormField _descriptionTextfield(
      ArticleCurationsState state, BuildContext context) {
    return TextFormField(
      initialValue: state.description,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (value) {
        context.read<ArticleCurationsCubit>().setText(false, value);
      },
      decoration: InputDecoration(
        hintText: context.t.description.capitalizeFirst(),
      ),
      minLines: 5,
      maxLines: 5,
    );
  }

  TextFormField _titleTextfield(
      ArticleCurationsState state, BuildContext context) {
    return TextFormField(
      initialValue: state.title,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (value) {
        context.read<ArticleCurationsCubit>().setText(true, value);
      },
      decoration: InputDecoration(
        hintText: context.t.title.capitalizeFirst(),
      ),
    );
  }

  Row _actionsRow(TextEditingController imageUrlController) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
            builder: (context, state) {
              return TextFormField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  hintText: context.t.imageUrl.capitalizeFirst(),
                ),
                onChanged: (link) {
                  context.read<ArticleCurationsCubit>().selectUrlImage(
                        url: link,
                        onFailed: () {
                          BotToastUtils.showError(
                            context.t.selectValidUrlImage.capitalizeFirst(),
                          );
                        },
                      );
                },
                onFieldSubmitted: (url) {},
              );
            },
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
          builder: (context, state) {
            return BorderedIconButton(
              firstSelection: true,
              onClicked: () {
                imageUrlController.clear();

                context.read<ArticleCurationsCubit>().selectProfileImage(
                  onFailed: () {
                    BotToastUtils.showError(
                      context.t.issueOccuredSelectingImage.capitalizeFirst(),
                    );
                  },
                );
              },
              primaryIcon: FeatureIcons.upload,
              secondaryIcon: FeatureIcons.notVisible,
              borderColor: state.isLocalImage
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColorLight,
            );
          },
        ),
      ],
    );
  }

  BlocBuilder<ArticleCurationsCubit, ArticleCurationsState> _contentStack(
      TextEditingController imageUrlController) {
    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        return Stack(
          children: [
            _imageContainer(state, context),
            if (state.isImageSelected)
              Positioned(
                right: kDefaultPadding / 2,
                top: kDefaultPadding / 2,
                child: CircleAvatar(
                  backgroundColor: kWhite.withValues(alpha: 0.8),
                  child: IconButton(
                    onPressed: () {
                      context.read<ArticleCurationsCubit>().removeImage();
                      imageUrlController.clear();
                    },
                    icon: SvgPicture.asset(
                      FeatureIcons.trash,
                      width: 25,
                      height: 25,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Container _imageContainer(ArticleCurationsState state, BuildContext context) {
    return Container(
      height: 20.h,
      decoration: state.isImageSelected
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              border: Border.all(
                width: 0.5,
                color: Theme.of(context).highlightColor,
              ),
            ),
      foregroundDecoration: state.isImageSelected && state.isLocalImage
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              image: DecorationImage(
                image: FileImage(
                  state.localImage!,
                ),
                fit: BoxFit.cover,
              ),
            )
          : null,
      child: state.isImageSelected && !state.isLocalImage
          ? state.imageLink.isEmpty
              ? SizedBox(
                  height: 20.h,
                  child: const NoMediaPlaceHolder(
                    isError: false,
                    image: '',
                  ),
                )
              : CommonThumbnail(
                  image: state.imageLink,
                  height: 20.h,
                  width: double.infinity,
                  placeholder: getRandomPlaceholder(
                    input: state.imageLink,
                    isPfp: false,
                  ),
                  isRound: true,
                  radius: kDefaultPadding,
                )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    FeatureIcons.image,
                    width: 30,
                    height: 30,
                    fit: BoxFit.scaleDown,
                    colorFilter: const ColorFilter.mode(
                      kDimGrey,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    context.t.thumbnailPreview.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
    );
  }
}

class ArticleSuggestedCurationList extends StatelessWidget {
  const ArticleSuggestedCurationList({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        if (state.isCurationsLoading) {
          return SpinKitSpinningLines(
            size: 30,
            color: Theme.of(context).primaryColorDark,
          );
        } else if (state.curations.isEmpty) {
          return Center(
            child: EmptyList(
              description: context.t.noCurationsFound.capitalizeFirst(),
              icon: FeatureIcons.selfCurations,
            ),
          );
        } else {
          return ScrollShadow(
            color: Theme.of(context).primaryColorLight,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: kDefaultPadding / 2,
                );
              },
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding,
              ),
              controller: scrollController,
              itemBuilder: (context, index) {
                final curation = state.curations[index];
                final canBeAddedValue =
                    canBeAdded(curation.eventsIds, state.articleId);

                return _curationContainer(context, curation, canBeAddedValue);
              },
              itemCount: state.curations.length,
            ),
          );
        }
      },
    );
  }

  Container _curationContainer(
      BuildContext context, Curation curation, bool canBeAddedValue) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: Theme.of(context).primaryColorLight,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Row(
        children: [
          CommonThumbnail(
            image: curation.image,
            placeholder: curation.placeHolder,
            width: 60,
            height: 60,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _curationinfo(curation, context, canBeAddedValue),
          if (canBeAddedValue) _addButton(context, curation),
        ],
      ),
    );
  }

  IconButton _addButton(BuildContext context, Curation curation) {
    return IconButton(
      onPressed: () {
        context.read<ArticleCurationsCubit>().setCuration(
              curation: curation,
              onFailure: (message) {},
              onSuccess: () {
                Navigator.pop(context);
                BotToastUtils.showSuccess(
                  curation.isArticleCuration()
                      ? context.t.articleAddedCuration
                      : context.t.videoAddedCuration,
                );
              },
            );
      },
      icon: const Icon(
        Icons.add_rounded,
      ),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Expanded _curationinfo(
      Curation curation, BuildContext context, bool canBeAddedValue) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            curation.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
          ),
          Text(
            curation.isArticleCuration()
                ? context.t.availableArticles(
                    number:
                        curation.eventsIds.length.toString().padLeft(2, '0'),
                  )
                : context.t.availableVideos(
                    number:
                        curation.eventsIds.length.toString().padLeft(2, '0'),
                  ),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (!canBeAddedValue)
            Text(
              curation.isArticleCuration()
                  ? context.t.articlesAvailableCuration
                  : context.t.videosAvailableCuration,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kMainColor,
                  ),
            ),
        ],
      ),
    );
  }

  bool canBeAdded(List<EventCoordinates> events, String articleId) {
    final list = events.where((element) => element.identifier == articleId);

    return list.isEmpty;
  }
}

class ArticleCurationsBottomBar extends HookWidget {
  const ArticleCurationsBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 4,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: state.articleCuration == ArticleCuration.zaps,
                child: IconButton(
                  onPressed: () {
                    context
                        .read<ArticleCurationsCubit>()
                        .setView(ArticleCuration.curationContent);
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_left_rounded,
                    color: kWhite,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: kPurple,
                  ),
                ),
              ),
              _textbutton(state, context),
            ],
          ),
        );
      },
    );
  }

  TextButton _textbutton(ArticleCurationsState state, BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        if (state.articleCuration == ArticleCuration.curationsList) {
          context
              .read<ArticleCurationsCubit>()
              .setView(ArticleCuration.curationContent);
        } else if (state.articleCuration == ArticleCuration.curationContent) {
          final isTitleEmpty = state.title.trim().isEmpty;
          final isDescriptionEmpty = state.description.trim().isEmpty;

          final isDisabled = !state.isImageSelected ||
              state.title.trim().isEmpty ||
              state.description.trim().isEmpty;

          if (isDisabled) {
            final text = isTitleEmpty
                ? context.t.validTitleCuration
                : isDescriptionEmpty
                    ? context.t.validDescriptionCuration
                    : context.t.validImageCuration;

            BotToastUtils.showError(text);
          } else {
            context.read<ArticleCurationsCubit>().setView(
                  ArticleCuration.zaps,
                );
          }
        } else {
          context.read<ArticleCurationsCubit>().addCuration(
            onFailure: (message) {
              BotToastUtils.showError(message);
            },
          );
        }
      },
      icon: Text(
        state.articleCuration == ArticleCuration.curationsList
            ? context.t.addCuration.capitalizeFirst()
            : state.articleCuration == ArticleCuration.curationContent ||
                    state.articleCuration == ArticleCuration.zaps
                ? context.t.next.capitalizeFirst()
                : context.t.submitCuration.capitalizeFirst(),
      ),
      label: Icon(
        state.articleCuration == ArticleCuration.curationsList
            ? Icons.add_rounded
            : state.articleCuration == ArticleCuration.curationContent ||
                    state.articleCuration == ArticleCuration.zaps
                ? Icons.arrow_forward_ios_rounded
                : Icons.check,
        size: 20,
      ),
    );
  }
}
