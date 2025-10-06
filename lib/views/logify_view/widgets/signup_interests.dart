// ignore_for_file: prefer_foreach

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../models/app_models/interests_set.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';

class SignupInterestsAndFollowings extends HookWidget {
  const SignupInterestsAndFollowings({super.key});

  @override
  Widget build(BuildContext context) {
    final l = InterestSet.getInterestSets();
    final selectedIndex = useState(-1);
    final scrollController = useScrollController();
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final slivers = <Widget>[];

    slivers.add(
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.interests.capitalizeFirst(),
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: kDefaultPadding / 4),
            Text(
              context.t.taylorExperienceInterests.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
      ),
    );

    slivers.add(
      const SliverToBoxAdapter(
        child: SizedBox(
          height: kDefaultPadding / 2,
        ),
      ),
    );

    slivers.add(
      isTablet
          ? SliverMasonryGrid.count(
              crossAxisCount: 2,
              itemBuilder: (context, index) {
                final interestSet = l[index];

                return InterestFollowingContainer(
                  interestSet: interestSet,
                  isExpanded: selectedIndex.value == index,
                  scrollController: scrollController,
                  onExpand: () {
                    if (selectedIndex.value == index) {
                      selectedIndex.value = -1;
                    } else {
                      selectedIndex.value = index;
                    }
                  },
                );
              },
              childCount: l.length,
              crossAxisSpacing: kDefaultPadding,
              mainAxisSpacing: kDefaultPadding,
            )
          : SliverList.separated(
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 1.5,
              ),
              itemBuilder: (context, index) {
                final interestSet = l[index];

                return InterestFollowingContainer(
                  interestSet: interestSet,
                  isExpanded: selectedIndex.value == index,
                  scrollController: scrollController,
                  onExpand: () {
                    if (selectedIndex.value == index) {
                      selectedIndex.value = -1;
                    } else {
                      selectedIndex.value = index;
                    }
                  },
                );
              },
              itemCount: l.length,
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      child: ScrollShadow(
        color: Theme.of(context).primaryColorLight.withValues(alpha: 0.5),
        size: 3,
        child: CustomScrollView(slivers: slivers),
      ),
    );
  }
}

class InterestFollowingContainer extends HookWidget {
  const InterestFollowingContainer({
    super.key,
    required this.interestSet,
    required this.isExpanded,
    required this.onExpand,
    required this.scrollController,
  });

  final InterestSet interestSet;
  final bool isExpanded;
  final ScrollController scrollController;
  final Function() onExpand;

  @override
  Widget build(BuildContext context) {
    final components = <Widget>[];
    final pubkeys = useState(getRandomPubkeys());

    final mainBox = GestureDetector(
      onTap: onExpand,
      behavior: HitTestBehavior.translucent,
      child: LayoutBuilder(
        builder: (context, cts) => Row(
          children: [
            CommonThumbnail(
              image: interestSet.image,
              width: cts.maxWidth * 0.17,
              height: cts.maxWidth * 0.17,
              placeholder: getRandomPlaceholder(
                input: interestSet.image,
                isPfp: false,
              ),
              radius: kDefaultPadding,
              isRound: true,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interestSet.interest,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  _metadataRow(cts, pubkeys, context),
                ],
              ),
            ),
            BlocBuilder<LogifyCubit, LogifyState>(
              builder: (context, state) {
                if (isInterestAvailable(
                    pubkeys: state.pubkeys,
                    interestsPubkeys: interestSet.pubkeys.toSet())) {
                  return const DotContainer(
                    color: kMainColor,
                    size: 6,
                  );
                }

                return const SizedBox(
                  width: kDefaultPadding / 2,
                );
              },
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: isExpanded ? 0.125 : 0,
              child: IconButton(
                onPressed: onExpand,
                style: IconButton.styleFrom(
                  backgroundColor: kMainColor,
                  visualDensity: VisualDensity.compact,
                ),
                icon: SvgPicture.asset(
                  FeatureIcons.addRaw,
                  width: 15,
                  height: 15,
                  colorFilter: const ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final expandedBox = AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: isExpanded
          ? BlocBuilder<LogifyCubit, LogifyState>(
              builder: (context, logState) {
                return Column(
                  children: [
                    _suggestions(context, logState),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    ...interestSet.pubkeys.map(
                      (p) => _metadataContainer(p, logState, context),
                    ),
                  ],
                );
              },
            )
          : const SizedBox.shrink(),
    );

    components.add(
      Column(
        children: [
          mainBox,
          if (isExpanded)
            const Divider(
              height: kDefaultPadding,
            ),
          expandedBox
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: isExpanded
          ? const EdgeInsets.all(kDefaultPadding / 2)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isExpanded ? Theme.of(context).cardColor : kTransparent,
        borderRadius:
            isExpanded ? BorderRadius.circular(kDefaultPadding) : null,
      ),
      child: Column(
        children: components,
      ),
    );
  }

  MetadataProvider _metadataContainer(
      String p, LogifyState logState, BuildContext context) {
    return MetadataProvider(
      pubkey: p,
      child: (metadata, isNip05Valid) {
        final isAvailable = logState.pubkeys.contains(metadata.pubkey);

        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding / 8,
          ),
          child: Row(
            children: [
              ProfilePicture2(
                size: 30,
                pubkey: metadata.pubkey,
                image: metadata.picture,
                padding: 0,
                strokeWidth: 0,
                strokeColor: kTransparent,
                onClicked: () {},
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.getName(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              IconButton(
                onPressed: () {
                  context.read<LogifyCubit>().setPubkey(metadata.pubkey);
                },
                style: IconButton.styleFrom(
                  backgroundColor: isAvailable ? kMainColor : kTransparent,
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(
                    color: kMainColor,
                  ),
                ),
                icon: SvgPicture.asset(
                  FeatureIcons.userToFollow,
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    isAvailable ? kWhite : Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Row _suggestions(BuildContext context, LogifyState logState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.t.suggestions.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        Builder(
          builder: (context) {
            final canFollowAll = interestSet.pubkeys
                    .toSet()
                    .intersection(logState.pubkeys)
                    .length !=
                interestSet.pubkeys.length;

            return TextButton(
              onPressed: () {
                context.read<LogifyCubit>().setListPubkeys(
                      pkeys: interestSet.pubkeys,
                      isDelete: !canFollowAll,
                    );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                canFollowAll
                    ? context.t.followAll.capitalizeFirst()
                    : context.t.unfollowAll.capitalizeFirst(),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(color: kWhite),
              ),
            );
          },
        ),
      ],
    );
  }

  Row _metadataRow(BoxConstraints cts, ValueNotifier<List<String>> pubkeys,
      BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            SizedBox(
              height: cts.maxWidth * 0.08,
              width: cts.maxWidth * 0.15,
            ),
            Positioned(
              top: 0,
              left: 0,
              child: MetadataProvider(
                pubkey: pubkeys.value.first,
                child: (metadata, isNip05Valid) {
                  return ProfilePicture2(
                    size: cts.maxWidth * 0.06,
                    pubkey: metadata.pubkey,
                    image: metadata.picture,
                    padding: 0,
                    strokeWidth: 0,
                    strokeColor: kTransparent,
                    onClicked: () {},
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: MetadataProvider(
                pubkey: pubkeys.value[2],
                child: (metadata, isNip05Valid) {
                  return ProfilePicture2(
                    size: cts.maxWidth * 0.045,
                    pubkey: metadata.pubkey,
                    image: metadata.picture,
                    padding: 0,
                    strokeWidth: 0,
                    strokeColor: kTransparent,
                    onClicked: () {},
                  );
                },
              ),
            ),
            Positioned(
              right: cts.maxWidth * 0.045,
              bottom: 0,
              child: MetadataProvider(
                pubkey: pubkeys.value[1],
                child: (metadata, isNip05Valid) {
                  return ProfilePicture2(
                    size: cts.maxWidth * 0.04,
                    pubkey: metadata.pubkey,
                    image: metadata.picture,
                    padding: 0,
                    strokeWidth: 0,
                    strokeColor: kTransparent,
                    onClicked: () {},
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Text(
          context.t.peopleCountPlus(
            number: (interestSet.pubkeys.length - 3).toString(),
          ),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }

  List<String> getRandomPubkeys() {
    final l = List<String>.from(interestSet.pubkeys);
    l.shuffle(Random());
    return l.take(3).toList();
  }

  bool isInterestAvailable({
    required Set<String> pubkeys,
    required Set<String> interestsPubkeys,
  }) {
    return pubkeys.intersection(interestsPubkeys).isNotEmpty;
  }
}
