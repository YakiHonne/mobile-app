import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/leading_cubit/customize_leading_cubit/customize_leading_cubit.dart';
import '../../../utils/utils.dart';
import '../../settings_view/widgets/property_customization.dart';
import '../../widgets/dotted_container.dart';

class LeadingCustomization extends HookWidget {
  const LeadingCustomization({super.key});

  @override
  Widget build(BuildContext context) {
    final useBoxViewReply = useState(settingsCubit.useCompactReplies);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => CustomizeLeadingCubit(),
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) =>
              BlocBuilder<CustomizeLeadingCubit, CustomizeLeadingState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Center(child: ModalBottomSheetHandle()),
                    Center(
                      child: Text(
                        context.t.feedSettings.capitalizeFirst(),
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    const Divider(
                      height: kDefaultPadding * 1.5,
                      thickness: 0.5,
                    ),
                    _viewOptions(context, useBoxViewReply, isTablet, state),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    Text(
                      context.t.suggestionsBox.capitalizeFirst(),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    _showSuggestions(context, state),
                    const SizedBox(
                      height: kDefaultPadding / 1.5,
                    ),
                    _showSuggestedPeople(context, state),
                    const SizedBox(
                      height: kDefaultPadding / 1.5,
                    ),
                    _showArticlesNotesSuggestions(context, state),
                    const SizedBox(
                      height: kDefaultPadding / 1.5,
                    ),
                    _showSuggestedInterests(context, state),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Row _showSuggestedInterests(
      BuildContext context, CustomizeLeadingState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.showSuggestedInterests.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                context.t.showSuggInterests,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.showInterests,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<CustomizeLeadingCubit>().setInterestsStatus();
            },
          ),
        ),
      ],
    );
  }

  Row _showArticlesNotesSuggestions(
      BuildContext context, CustomizeLeadingState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.showArticlesNotesSuggestions.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                context.t.showSuggContent,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.showRelatedContent,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<CustomizeLeadingCubit>().setRelatedContentStatus();
            },
          ),
        ),
      ],
    );
  }

  Row _showSuggestedPeople(BuildContext context, CustomizeLeadingState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.showSuggestedPeople.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                context.t.showSuggPeople,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.showPeopleToFollow,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<CustomizeLeadingCubit>().setPeopleStatus();
            },
          ),
        ),
      ],
    );
  }

  Row _showSuggestions(BuildContext context, CustomizeLeadingState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.showSuggestions.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                context.t.showSuggDesc,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.showSuggestions,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<CustomizeLeadingCubit>().setSuggestionStatus();
            },
          ),
        ),
      ],
    );
  }

  Column _viewOptions(BuildContext context, ValueNotifier<bool> useBoxViewReply,
      bool isTablet, CustomizeLeadingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kDefaultPadding / 1.5,
      children: [
        Text(
          context.t.viewOptions.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: ReplyOptionContainer(
                icon: Images.boxView,
                title: context.t.boxView,
                isSelected: useBoxViewReply.value,
                onTap: () {
                  settingsCubit.useCompactReplies = true;
                  useBoxViewReply.value = true;
                },
              ),
            ),
            Expanded(
              child: ReplyOptionContainer(
                icon: Images.threadView,
                title: context.t.threadView,
                isSelected: !useBoxViewReply.value,
                onTap: () {
                  settingsCubit.useCompactReplies = false;
                  useBoxViewReply.value = false;
                },
              ),
            ),
          ],
        ),
        if (isTablet)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.singleColumnFeed.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      context.t.singleColumnFeedDesc,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: state.useSingleColumnFeed,
                  activeTrackColor: kMainColor,
                  onChanged: (isToggled) {
                    context.read<CustomizeLeadingCubit>().setColumnFeedStatus();
                  },
                ),
              ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.collapseNote.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    context.t.collapseNoteDesc,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Transform.scale(
              scale: 0.8,
              child: CupertinoSwitch(
                value: state.collapseNote,
                activeTrackColor: kMainColor,
                onChanged: (isToggled) {
                  context.read<CustomizeLeadingCubit>().setCollapseNoteStatus();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String getCommenFeedTypeName(CommonFeedTypes type, BuildContext context) {
  String name = '';

  switch (type) {
    case CommonFeedTypes.recent:
      name = context.t.recent.capitalizeFirst();
    case CommonFeedTypes.recentWithReplies:
      name = context.t.recentWithReplies.capitalizeFirst();
    case CommonFeedTypes.explore:
      name = context.t.explore.capitalizeFirst();
    case CommonFeedTypes.following:
      name = context.t.following.capitalizeFirst();
    case CommonFeedTypes.trending:
      name = context.t.trending.capitalizeFirst();
    case CommonFeedTypes.highlights:
      name = context.t.highlights.capitalizeFirst();
    case CommonFeedTypes.widgets:
      name = context.t.widgets.capitalizeFirst();
    case CommonFeedTypes.paid:
      name = context.t.paid.capitalizeFirst();
    case CommonFeedTypes.others:
      name = context.t.others.capitalizeFirst();
    case CommonFeedTypes.global:
      name = context.t.global.capitalizeFirst();
  }

  return name;
}
