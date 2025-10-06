import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/smart_widget_search_cubit/smart_widget_search_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';
import 'smart_widget_search_container.dart';

class SmartWidgetSearchSuggestionRow extends HookWidget {
  const SmartWidgetSearchSuggestionRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDisplayed = useState(true);

    return BlocListener<SmartWidgetSearchCubit, SmartWidgetSearchState>(
      listener: (context, state) {
        if (state.dvmSearch.isNotEmpty) {
          isDisplayed.value = false;
        }
      },
      child: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _tips(context, isDisplayed),
            AnimatedCrossFade(
              crossFadeState: isDisplayed.value
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
              secondChild: const SizedBox(
                width: double.infinity,
              ),
              firstChild: _widgetSearch(context),
            ),
          ],
        ),
      ),
    );
  }

  Column _widgetSearch(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        IntrinsicHeight(
          child: Row(
            spacing: kDefaultPadding / 4,
            children: [
              Expanded(
                child: SmartWidgetSearchSuggestionBox(
                  title: context.t.widgetSearch.capitalizeFirst(),
                  description: context.t.widgetSearchDesc,
                ),
              ),
              Expanded(
                child: SmartWidgetSearchSuggestionBox(
                  title: context.t.getInspired.capitalizeFirst(),
                  description: context.t.getInspirtedDesc,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        _tryMiniApp(context),
      ],
    );
  }

  IntrinsicHeight _tryMiniApp(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        spacing: kDefaultPadding / 4,
        children: [
          Expanded(
            child: SmartWidgetSearchSuggestionBox(
              title: '',
              description: context.t.tryMiniApp,
              widget: Row(
                spacing: kDefaultPadding / 4,
                children: [
                  Flexible(
                    child: SmartWidgetSearchOptionBox(
                      icon: FeatureIcons.smartWidget,
                      isActive: false,
                      onClicked: () {
                        openWebPage(
                          url: playgroundUrl,
                          openInternal: false,
                        );
                      },
                      title: context.t.playground.capitalizeFirst(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SmartWidgetSearchSuggestionBox(
              title: '',
              description: context.t.exploreOurRepos.capitalizeFirst(),
              widget: Row(
                spacing: kDefaultPadding / 4,
                children: [
                  CustomIconButton(
                    onClicked: () {
                      openWebPage(
                        url: reposUrl,
                        openInternal: false,
                      );
                    },
                    icon: FeatureIcons.github,
                    size: 17,
                    vd: -1.5,
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  Flexible(
                    child: SmartWidgetSearchOptionBox(
                      icon: FeatureIcons.note,
                      isActive: false,
                      onClicked: () {
                        openWebPage(
                          url: docsUrl,
                          openInternal: false,
                        );
                      },
                      title: context.t.docs.capitalizeFirst(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row _tips(BuildContext context, ValueNotifier<bool> isDisplayed) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.tips,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ),
        CustomIconButton(
          onClicked: () {
            isDisplayed.value = !isDisplayed.value;
          },
          icon: !isDisplayed.value
              ? FeatureIcons.arrowDown
              : FeatureIcons.arrowUp,
          size: 15,
          vd: -2,
          backgroundColor: kTransparent,
        ),
      ],
    );
  }
}

class SmartWidgetSearchSuggestionBox extends StatelessWidget {
  const SmartWidgetSearchSuggestionBox({
    super.key,
    required this.title,
    required this.description,
    this.widget,
  });

  final String title;
  final String description;
  final Widget? widget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        border: Border.all(
          width: 0.5,
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        spacing: kDefaultPadding / 2,
        children: [
          _buildTitleDescription(context),
          const Spacer(),
          if (widget != null) widget! else const SizedBox.shrink(),
        ],
      ),
    );
  }

  RichText _buildTitleDescription(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelMedium,
        children: [
          if (title.isNotEmpty)
            TextSpan(
              text: '$title ',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kMainColor,
                  ),
            ),
          TextSpan(
            text: description,
          ),
        ],
      ),
    );
  }
}
