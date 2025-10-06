import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/managae_interests.dart';

class InterestsDashboard extends HookWidget {
  const InterestsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const spacer = SliverToBoxAdapter(
      child: SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    final emptyBox = SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          children: [
            Text(
              context.t.getStartedNow.capitalize(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Text(
              context.t.expandWorld.capitalize(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            TextButton.icon(
              onPressed: () {
                YNavigator.pushPage(
                  context,
                  (context) => ManagaeInterests(),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
              label: Text(
                context.t.addInterests.capitalize(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: kWhite,
                    ),
              ),
              icon: const Icon(
                Icons.add,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );

    return StreamBuilder<List<String>>(
      stream: nostrRepository.interestsStream,
      initialData: nostrRepository.interests,
      builder: (context, snapshot) {
        final hideData = snapshot.data == null || snapshot.data!.isEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: CustomScrollView(
            slivers: [
              spacer,
              _interestsContainer(context, hideData),
              spacer,
              if (hideData)
                emptyBox
              else ...[
                SliverList.separated(
                  separatorBuilder: (context, index) => const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  itemBuilder: (context, index) {
                    final interest = snapshot.data![index];

                    return DashboardInterestContainer(
                      interest: interest,
                    );
                  },
                  itemCount: snapshot.data!.length,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _interestsContainer(BuildContext context, bool hideData) {
    return SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.t.interests.capitalize(),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (!hideData)
            TextButton(
              onPressed: () {
                YNavigator.pushPage(
                  context,
                  (context) => ManagaeInterests(),
                );
              },
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.comfortable),
              child: Text(
                context.t.manageInterests.capitalize(),
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

class DashboardInterestContainer extends StatelessWidget {
  const DashboardInterestContainer({
    super.key,
    required this.interest,
    this.onClick,
    this.interestStatus,
    this.canBeDragged,
  });

  final String interest;
  final Function()? onClick;
  final InterestStatus? interestStatus;
  final bool? canBeDragged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final image = getImage();

              if (image != null) {
                return CommonThumbnail(
                  image: image,
                  placeholder:
                      getRandomPlaceholder(input: interest, isPfp: false),
                  width: 40,
                  height: 40,
                  radius: kDefaultPadding / 2,
                  isRound: true,
                );
              } else {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    interest.characters.first.capitalize(),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                );
              }
            },
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Text(
              interest.capitalize(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (interestStatus != null) ...[
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            CustomIconButton(
              onClicked: onClick!,
              vd: -1,
              icon: interestStatus == InterestStatus.add
                  ? FeatureIcons.addRaw
                  : interestStatus == InterestStatus.delete
                      ? FeatureIcons.trash
                      : ToastsIcons.check,
              size: 17,
              iconColor: interestStatus == InterestStatus.delete
                  ? Theme.of(context).primaryColorDark
                  : kWhite,
              backgroundColor: interestStatus == InterestStatus.add
                  ? kMainColor
                  : interestStatus == InterestStatus.delete
                      ? Theme.of(context).cardColor
                      : kGreen,
            ),
          ],
          if (canBeDragged != null) ...[
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            const Icon(
              Icons.drag_indicator_rounded,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  String? getImage() {
    for (final topic in nostrRepository.topics) {
      if (topic.topic.toLowerCase() == interest ||
          topic.subTopics.any(
            (e) => e.toLowerCase() == interest,
          )) {
        return topic.icon;
      }
    }

    return null;
  }
}
