// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../logic/interests_management_cubit/interests_management_cubit.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../dashboard_view/widgets/interests/interests_dashboard.dart';
import 'custom_app_bar.dart';
import 'custom_icon_buttons.dart';

class ManagaeInterests extends HookWidget {
  ManagaeInterests({
    super.key,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Interests view');
  }

  final _listViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final mention = useState<String?>(null);
    final controller = useTextEditingController();
    final topics = useState(
      nostrRepository.topics
          .map(
            (e) => e.topic,
          )
          .toList(),
    );

    const spacer = SliverToBoxAdapter(
      child: SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    final enableInterest = mention.value?.trim().isNotEmpty ?? false;

    return BlocProvider(
      create: (context) => InterestsManagementCubit(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.interests.capitalizeFirst(),
        ),
        body: Builder(
          builder: (context) {
            return Column(
              children: [
                _content(spacer, context, mention, controller, enableInterest,
                    topics),
                if (enableInterest) ...[
                  const Divider(
                    thickness: 0.5,
                    height: 0,
                  ),
                  SizedBox(
                    height: 20.h,
                    child: ScrollShadow(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: InterestsSuggestionBox(
                        searchKey: mention.value!,
                        onInterestAdded: (interest) {
                          context
                              .read<InterestsManagementCubit>()
                              .setInterest(interest.toLowerCase());

                          mention.value = null;
                          controller.clear();
                        },
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Expanded _content(
      SliverToBoxAdapter spacer,
      BuildContext context,
      ValueNotifier<String?> mention,
      TextEditingController controller,
      bool enableInterest,
      ValueNotifier<List<String>> topics) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        child: CustomScrollView(
          slivers: [
            spacer,
            _interests(context),
            spacer,
            _textfield(mention, controller, context, enableInterest),
            spacer,
            _interestsList(),
            spacer,
            spacer,
            SliverToBoxAdapter(
              child: Text(
                context.t.suggestedInterests.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            spacer,
            _topicList(topics),
            spacer,
            spacer,
          ],
        ),
      ),
    );
  }

  BlocBuilder<InterestsManagementCubit, InterestsManagementState> _topicList(
      ValueNotifier<List<String>> topics) {
    return BlocBuilder<InterestsManagementCubit, InterestsManagementState>(
      builder: (context, state) {
        return SliverList.separated(
          itemBuilder: (context, index) {
            final topic = topics.value[index];

            return DashboardInterestContainer(
              interest: topic.toLowerCase(),
              interestStatus: state.interests.contains(topic.toLowerCase())
                  ? InterestStatus.available
                  : InterestStatus.add,
              onClick: () {
                context
                    .read<InterestsManagementCubit>()
                    .setInterest(topic.toLowerCase());
              },
            );
          },
          itemCount: topics.value.length,
          separatorBuilder: (context, index) => const SizedBox(
            height: kDefaultPadding / 2,
          ),
        );
      },
    );
  }

  BlocBuilder<InterestsManagementCubit, InterestsManagementState>
      _interestsList() {
    return BlocBuilder<InterestsManagementCubit, InterestsManagementState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: ReorderableListView.builder(
            key: _listViewKey,
            shrinkWrap: true,
            primary: false,
            onReorder: (oldIndex, newIndex) {
              final index = newIndex > oldIndex ? newIndex - 1 : newIndex;

              context
                  .read<InterestsManagementCubit>()
                  .setFeedTypesNewOrder(oldIndex, index);
            },
            itemBuilder: (context, index) {
              final i = state.interests.toList()[index];

              return Padding(
                key: ValueKey(i),
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 4,
                ),
                child: DashboardInterestContainer(
                  interest: i.toLowerCase(),
                  interestStatus: InterestStatus.delete,
                  canBeDragged: true,
                  onClick: () {
                    context
                        .read<InterestsManagementCubit>()
                        .setInterest(i.toLowerCase());
                  },
                ),
              );
            },
            itemCount: state.interests.length,
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _textfield(
      ValueNotifier<String?> mention,
      TextEditingController controller,
      BuildContext context,
      bool enableInterest) {
    return SliverToBoxAdapter(
      child: TextFormField(
        onChanged: (value) {
          mention.value = value;
        },
        controller: controller,
        minLines: 1,
        maxLines: 5,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: context.t.addInterests.capitalizeFirst(),
          focusColor: Theme.of(context).primaryColorLight,
          suffixIcon: enableInterest
              ? CustomIconButton(
                  onClicked: () {
                    final text = controller.text.trim();
                    context.read<InterestsManagementCubit>().setInterest(
                          text.toLowerCase(),
                        );

                    mention.value = null;
                    controller.clear();
                  },
                  icon: FeatureIcons.addRaw,
                  size: 15,
                  backgroundColor: Theme.of(context).cardColor,
                )
              : null,
        ),
      ),
    );
  }

  SliverToBoxAdapter _interests(BuildContext context) {
    return SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.t.interests.capitalizeFirst(),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<InterestsManagementCubit>().updateInterest(
                    () => YNavigator.pop(context),
                  );
            },
            style:
                TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
            child: Text(
              context.t.updateInterests.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kWhite,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class InterestsSuggestionBox extends StatelessWidget {
  const InterestsSuggestionBox(
      {super.key, required this.searchKey, required this.onInterestAdded});

  final String searchKey;
  final Function(String) onInterestAdded;

  @override
  Widget build(BuildContext context) {
    final interests = getInterests();
    return ListView.separated(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final interest = interests[index];

        return GestureDetector(
          onTap: () {
            onInterestAdded.call(interest);
          },
          behavior: HitTestBehavior.translucent,
          child: Row(
            children: <Widget>[
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Text(
                  interest,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      itemCount: getInterests().length,
    );
  }

  List<String> getInterests() {
    return nostrRepository
        .getFilteredTopics()
        .where(
          (t) => t.toLowerCase().contains(searchKey.toLowerCase()),
        )
        .toList();
  }
}
