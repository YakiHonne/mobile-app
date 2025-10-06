// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/write_video_cubit/write_video_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/auto_complete_textfield.dart';
import '../../../widgets/content_zap_splits.dart';
import '../../widgets/publish_preview_container.dart';
import '../article_widgets/article_details.dart';

class VideoSpecifications extends HookWidget {
  const VideoSpecifications({
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
      BlocBuilder<WriteVideoCubit, WriteVideoState>(
        builder: (context, state) {
          return PublishPreviewContainer(
            descInitText: context.read<WriteVideoCubit>().state.summary,
            title: state.title,
            onDescChanged: (desc) {
              context.read<WriteVideoCubit>().setSummary(desc);
            },
            imageLink: state.imageLink,
            onImageLinkChanged: (url) {
              context.read<WriteVideoCubit>().setImage(url);
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
      BlocBuilder<WriteVideoCubit, WriteVideoState>(
        buildWhen: (previous, current) =>
            previous.isHorizontal != current.isHorizontal,
        builder: (context, state) {
          return ArticleCheckBoxListTile(
            isEnabled: true,
            status: state.isHorizontal,
            text: context.t.horizontalVideo.capitalizeFirst(),
            onToggle: () {
              context.read<WriteVideoCubit>().toggleVideoOrientation();
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
      BlocBuilder<WriteVideoCubit, WriteVideoState>(
        builder: (context, state) {
          return Row(
            children: [
              Expanded(
                child: SimpleAutoCompleteTextField(
                  key: ArticleDetailsKey.key,
                  cursorColor: Theme.of(context).primaryColorDark,
                  decoration: InputDecoration(
                    hintText: context.t.addYourTopics.capitalizeFirst(),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  controller: keywordController,
                  suggestions: state.suggestions,
                  isBottom: false,
                  textSubmitted: (text) {
                    if (text.isNotEmpty && !state.tags.contains(text.trim())) {
                      context
                          .read<WriteVideoCubit>()
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
      BlocBuilder<WriteVideoCubit, WriteVideoState>(
        buildWhen: (previous, current) => previous.tags != current.tags,
        builder: (context, state) {
          if (state.tags.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Wrap(
                  runSpacing: kDefaultPadding / 4,
                  spacing: kDefaultPadding / 4,
                  children: state.tags
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
                                .read<WriteVideoCubit>()
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
      BlocBuilder<WriteVideoCubit, WriteVideoState>(
        buildWhen: (previous, current) =>
            previous.isZapSplitEnabled != current.isZapSplitEnabled ||
            previous.zapsSplits != current.zapsSplits,
        builder: (context, state) {
          return ContentZapSplits(
            kind: 'video',
            isZapSplitEnabled: state.isZapSplitEnabled,
            zaps: state.zapsSplits,
            onToggleZapSplit: () {
              context.read<WriteVideoCubit>().toggleZapsSplits();
            },
            onAddZapSplitUser: (pubkey) {
              context.read<WriteVideoCubit>().addZapSplit(pubkey);
            },
            onRemoveZapSplitUser: (pubkey) {
              context.read<WriteVideoCubit>().onRemoveZapSplit(pubkey);
            },
            onSetZapProportions: (index, zap, percentage) {
              context.read<WriteVideoCubit>().setZapPropertion(
                    index: index,
                    zapSplit: zap,
                    newPercentage: percentage,
                  );
            },
          );
        },
      ),
    );

    return BlocBuilder<WriteVideoCubit, WriteVideoState>(
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
