import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/auto_complete_textfield.dart';
import '../../widgets/publish_preview_container.dart';
import '../article_widgets/article_details.dart';

class FrameContent extends HookWidget {
  const FrameContent({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final titleController = useTextEditingController(
        text: context.read<WriteSmartWidgetCubit>().state.title);

    final keywordController = useTextEditingController(text: '');

    final components = <Widget>[];

    components.add(
      BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
        builder: (context, state) {
          return PublishPreviewContainer(
            descInitText: context.read<WriteSmartWidgetCubit>().state.title,
            noDescription: true,
            title: state.title,
            onDescChanged: (desc) {
              context.read<WriteSmartWidgetCubit>().setTitle(desc);
            },
            imageLink: state.icon,
            onImageLinkChanged: (url) {
              context.read<WriteSmartWidgetCubit>().setImage(url);
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
      BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
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
                  suggestions: state.keywords,
                  isBottom: false,
                  textSubmitted: (text) {
                    if (text.isNotEmpty &&
                        !state.keywords.contains(text.trim())) {
                      context
                          .read<WriteSmartWidgetCubit>()
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
      BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
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
                                .read<WriteSmartWidgetCubit>()
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

    return BlocConsumer<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      listenWhen: (previous, current) =>
          previous.smartWidgetUpdate != current.smartWidgetUpdate,
      listener: (context, state) {
        titleController.text = state.title;
      },
      builder: (context, state) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
          children: components,
        );
      },
    );
  }
}
