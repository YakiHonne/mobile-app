import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import 'managae_interests.dart';
import 'tag_container.dart';

class CommonTagsBar extends HookWidget {
  const CommonTagsBar({
    super.key,
    required this.mainTypes,
    required this.onMainTypeSelected,
    required this.onTagSelected,
  });

  final List<CommonFeedTypes> mainTypes;
  final Function(CommonFeedTypes) onMainTypeSelected;
  final Function(String) onTagSelected;

  @override
  Widget build(BuildContext context) {
    final selectedMainType = useState(
      getCommonFeedTypesText(mainTypes.first, context),
    );

    final selectedTypeEnum = useState(mainTypes.first);
    final selectedOffTag = useState('');
    final isMainSelected = useState(true);

    return StreamBuilder<List<String>>(
      initialData: nostrRepository.interests,
      stream: nostrRepository.interestsStream,
      builder: (context, snapshot) {
        final interests = snapshot.data ?? [];

        return SizedBox(
          height: 36,
          child: ScrollShadow(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(
                width: kDefaultPadding / 4,
              ),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _pulldownButton(context, selectedMainType,
                      selectedTypeEnum, isMainSelected);
                } else {
                  if (snapshot.data?.isEmpty ?? false) {
                    return _suggestedInterests(context);
                  } else {
                    final interest = interests[index - 1];

                    return _tagContainer(
                        interest, selectedOffTag, isMainSelected);
                  }
                }
              },
              itemCount: canSign()
                  ? interests.isNotEmpty
                      ? interests.length + 1
                      : 2
                  : 1,
            ),
          ),
        );
      },
    );
  }

  TagContainer _tagContainer(
      String interest,
      ValueNotifier<String> selectedOffTag,
      ValueNotifier<bool> isMainSelected) {
    return TagContainer(
      title: interest.capitalize(),
      isActive: selectedOffTag.value == interest && !isMainSelected.value,
      onClick: () {
        selectedOffTag.value = interest;
        isMainSelected.value = false;
        onTagSelected.call(interest);
        HapticFeedback.lightImpact();
      },
    );
  }

  GestureDetector _suggestedInterests(BuildContext context) {
    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) => ManagaeInterests(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
          horizontal: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        ),
        child: Row(
          children: [
            Text(
              context.t.suggestedInterests.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(
              width: kDefaultPadding / 3,
            ),
            SvgPicture.asset(
              FeatureIcons.addRaw,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
              width: 13,
              height: 13,
            ),
          ],
        ),
      ),
    );
  }

  PullDownButton _pulldownButton(
      BuildContext context,
      ValueNotifier<String> selectedMainType,
      ValueNotifier<CommonFeedTypes> selectedTypeEnum,
      ValueNotifier<bool> isMainSelected) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          ...mainTypes.map(
            (t) => PullDownMenuItem(
              title: getCommonFeedTypesText(t, context),
              onTap: () {
                selectedMainType.value = getCommonFeedTypesText(t, context);

                selectedTypeEnum.value = t;
                isMainSelected.value = true;
                onMainTypeSelected.call(t);
                HapticFeedback.lightImpact();
              },
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
              iconWidget:
                  selectedMainType.value == getCommonFeedTypesText(t, context)
                      ? const Icon(
                          Icons.check_rounded,
                        )
                      : null,
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => DropdownTag(
        onClick: isMainSelected.value
            ? showMenu
            : () {
                isMainSelected.value = true;
                onMainTypeSelected.call(selectedTypeEnum.value);
                HapticFeedback.lightImpact();
              },
        title: selectedMainType.value,
        isActive: isMainSelected.value,
      ),
    );
  }
}

String getCommonFeedTypesText(CommonFeedTypes type, BuildContext context) {
  String title = '';

  switch (type) {
    case CommonFeedTypes.recent:
      title = context.t.recent.capitalizeFirst();
    case CommonFeedTypes.recentWithReplies:
      title = context.t.recentWithReplies.capitalizeFirst();
    case CommonFeedTypes.explore:
      title = context.t.explore.capitalizeFirst();
    case CommonFeedTypes.following:
      title = context.t.following.capitalizeFirst();
    case CommonFeedTypes.trending:
      title = context.t.trending.capitalizeFirst();
    case CommonFeedTypes.highlights:
      title = context.t.highlights.capitalizeFirst();
    case CommonFeedTypes.widgets:
      title = context.t.widgets.capitalizeFirst();
    case CommonFeedTypes.paid:
      title = context.t.paid.capitalizeFirst();
    case CommonFeedTypes.others:
      title = context.t.others.capitalizeFirst();
    case CommonFeedTypes.global:
      title = context.t.global.capitalizeFirst();
  }

  return title;
}
