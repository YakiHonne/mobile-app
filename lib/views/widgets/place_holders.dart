import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../utils/utils.dart';

class VerticalSkeletonSelector extends StatelessWidget {
  const VerticalSkeletonSelector({
    super.key,
    required this.placeHolderWidget,
    this.useColumn = true,
    this.removePadding = false,
  });

  final Widget placeHolderWidget;
  final bool useColumn;
  final bool removePadding;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return isTablet ? _tabletPlaceholder() : _phonePlaceholder(context);
  }

  Padding _phonePlaceholder(BuildContext context) {
    return Padding(
      padding: removePadding
          ? EdgeInsets.zero
          : const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
      child: useColumn
          ? Column(
              children: [
                placeHolderWidget,
                const SizedBox(
                  height: kDefaultPadding,
                ),
                placeHolderWidget,
                const SizedBox(
                  height: kDefaultPadding,
                ),
                placeHolderWidget
              ],
            )
          : MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                children: [
                  placeHolderWidget,
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  placeHolderWidget,
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  placeHolderWidget
                ],
              ),
            ),
    );
  }

  Padding _tabletPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(
        kDefaultPadding / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                placeHolderWidget,
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                placeHolderWidget,
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                placeHolderWidget
              ],
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Column(
              children: [
                placeHolderWidget,
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                placeHolderWidget,
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                placeHolderWidget
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalSkeletonSelector extends StatelessWidget {
  const HorizontalSkeletonSelector({
    super.key,
    required this.placeHolderWidget,
  });

  final Widget placeHolderWidget;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return isTablet
        ? ListView.separated(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(
              width: kDefaultPadding / 2,
            ),
            itemBuilder: (context, index) {
              return placeHolderWidget;
            },
            itemCount: 6,
          )
        : ListView.separated(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(
              width: kDefaultPadding / 2,
            ),
            itemBuilder: (context, index) {
              return placeHolderWidget;
            },
            itemCount: 3,
          );
  }
}

class ArticleSkeleton extends StatelessWidget {
  const ArticleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Skeletonizer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonRow1(context),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            _skeletonRow2(context),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _skeletonRow3(context),
          ],
        ),
      ),
    );
  }

  Row _skeletonRow3(BuildContext context) {
    return Row(
      children: [
        Skeleton.shade(
          child: Container(
            height: 35,
            width: 35,
            decoration: const BoxDecoration(
              color: kWhite,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is a big title',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Text(
          'This is a detailes',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Row _skeletonRow2(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Text(
                lorem,
                style: Theme.of(context).textTheme.labelMedium,
                maxLines: 2,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                lorem,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          flex: 4,
          child: Skeleton.shade(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Row _skeletonRow1(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton.shade(
          child: Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: kWhite,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is a big title',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'This is a detailes',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Text(
          'This is',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class SearchProfileSkeleton extends StatelessWidget {
  const SearchProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      width: 300,
      margin: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 3,
        horizontal: kDefaultPadding / 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
      ),
      child: Skeletonizer(
        child: Row(
          children: [
            Skeleton.shade(
              child: Container(
                height: 55,
                width: 55,
                decoration: const BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lorem,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    'This is a big title',
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
