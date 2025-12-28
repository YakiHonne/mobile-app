import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../utils/utils.dart';
import 'place_holders.dart';

class MediaPlaceholder extends StatelessWidget {
  const MediaPlaceholder({super.key, this.removePadding = false});
  final bool removePadding;

  @override
  Widget build(BuildContext context) {
    return const MediaSkeleton();
  }
}

class ContentPlaceholder extends StatelessWidget {
  const ContentPlaceholder({super.key, this.removePadding = false});
  final bool removePadding;
  @override
  Widget build(BuildContext context) {
    return VerticalSkeletonSelector(
      placeHolderWidget: const ExploreMediaSkeleton(),
      removePadding: removePadding,
    );
  }
}

class NotesPlaceholder extends StatelessWidget {
  const NotesPlaceholder({
    super.key,
    this.useColumn = true,
    this.removePadding = false,
  });
  final bool useColumn;
  final bool removePadding;
  @override
  Widget build(BuildContext context) {
    return VerticalSkeletonSelector(
      placeHolderWidget: const LeadingNotesSkeleton(),
      useColumn: useColumn,
      removePadding: removePadding,
    );
  }
}

class MediaSkeleton extends StatelessWidget {
  const MediaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Skeletonizer(
        effect: ShimmerEffect(
          baseColor: Theme.of(context).cardColor,
          duration: const Duration(seconds: 1),
          highlightColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          spacing: kDefaultPadding / 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonRow(context: context, flip: true),
            _skeletonRow(context: context),
            _skeletonRow(context: context, flip: true),
            _skeletonRow(context: context),
          ],
        ),
      ),
    );
  }

  Widget _skeletonRow({required BuildContext context, bool flip = false}) {
    final width = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kDefaultPadding / 8,
      children: [
        if (flip)
          Expanded(
            child: Skeleton.shade(
              child: Container(
                height: ((width / 3) * 2) + kDefaultPadding / 8,
                decoration: const BoxDecoration(
                  color: kDimGrey,
                ),
              ),
            ),
          ),
        Expanded(
          child: Column(
            spacing: kDefaultPadding / 8,
            children: [
              Skeleton.shade(
                child: Container(
                  height: width / 3,
                  decoration: const BoxDecoration(
                    color: kDimGrey,
                  ),
                ),
              ),
              Skeleton.shade(
                child: Container(
                  height: width / 3,
                  decoration: const BoxDecoration(
                    color: kDimGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            spacing: kDefaultPadding / 8,
            children: [
              Skeleton.shade(
                child: Container(
                  height: width / 3,
                  decoration: const BoxDecoration(
                    color: kDimGrey,
                  ),
                ),
              ),
              Skeleton.shade(
                child: Container(
                  height: width / 3,
                  decoration: const BoxDecoration(
                    color: kDimGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!flip)
          Expanded(
            child: Skeleton.shade(
              child: Container(
                height: ((width / 3) * 2) + kDefaultPadding / 8,
                decoration: const BoxDecoration(
                  color: kDimGrey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LeadingNotesSkeleton extends StatelessWidget {
  const LeadingNotesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Skeletonizer(
        effect: ShimmerEffect(
          baseColor: Theme.of(context).cardColor,
          duration: const Duration(seconds: 1),
          highlightColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.shade(
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: kDimGrey,
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                _skeletonColumn(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Expanded _skeletonColumn(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This is a big title',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            'This is a detailes that we need',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            lorem,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 2,
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          Skeleton.shade(
            child: Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kDimGrey,
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExploreMediaSkeleton extends StatelessWidget {
  const ExploreMediaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: Theme.of(context).cardColor,
        duration: const Duration(seconds: 1),
        highlightColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonRow1(context),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _skeletonRow2(context),
        ],
      ),
    );
  }

  Row _skeletonRow2(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 12,
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
          flex: 3,
          child: Skeleton.shade(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: kDimGrey,
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
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: kDimGrey,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
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
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                'This is a detailes that we need',
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

class LeadingMediaPlaceholder extends StatelessWidget {
  const LeadingMediaPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const HorizontalSkeletonSelector(
      placeHolderWidget: LeadingMediaSkeleton(),
    );
  }
}

class LeadingMediaSkeleton extends StatelessWidget {
  const LeadingMediaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: Theme.of(context).cardColor,
        duration: const Duration(seconds: 1),
        highlightColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SizedBox(
        height: 250,
        child: AspectRatio(
          aspectRatio: 1 / 1.2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.shade(
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kDimGrey,
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              _skeletonRow1(context),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _skeletonRow2(context),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _skeletonRow2(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 12,
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
                maxLines: 1,
              ),
            ],
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
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              color: kDimGrey,
              borderRadius: BorderRadius.circular(300),
            ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Expanded(
          child: Text(
            'This is a big title',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
