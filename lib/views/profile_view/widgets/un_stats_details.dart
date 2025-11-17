// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/profile_picture.dart';

class UnStatsDetails extends HookWidget {
  const UnStatsDetails({
    super.key,
    required this.metadata,
    required this.writingImpact,
    required this.positiveWritingImpact,
    required this.negativeWritingImpact,
    required this.ongoingWritingImpact,
    required this.ratingImpact,
    required this.positiveRatingImpactH,
    required this.positiveRatingImpactNh,
    required this.negativeRatingImpactH,
    required this.negativeRatingImpactNh,
    required this.ongoingRatingImpact,
  });

  final Metadata metadata;
  final num writingImpact;
  final num positiveWritingImpact;
  final num negativeWritingImpact;
  final num ongoingWritingImpact;
  final num ratingImpact;
  final num positiveRatingImpactH;
  final num positiveRatingImpactNh;
  final num negativeRatingImpactH;
  final num negativeRatingImpactNh;
  final num ongoingRatingImpact;

  @override
  Widget build(BuildContext context) {
    final isWriting = useState(true);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).cardColor,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.70,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return CustomScrollView(
            controller: scrollController,
            primary: false,
            shrinkWrap: true,
            slivers: [
              _appbar(context, isWriting),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              _stats(isWriting, context),
            ],
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _stats(
      ValueNotifier<bool> isWriting, BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Column(
          children: [
            Builder(
              builder: (context) {
                final texts = getFirstTexts(isWriting.value, 0, context);

                return UnStatsDataColumn(
                  totalVal:
                      '+${isWriting.value ? positiveWritingImpact : positiveRatingImpactH}',
                  color: kGreen,
                  title: texts.first,
                  description: texts.last,
                );
              },
            ),
            const Divider(
              thickness: 0.5,
              height: kDefaultPadding * 2,
              endIndent: kDefaultPadding * 2,
              indent: kDefaultPadding * 2,
            ),
            Builder(
              builder: (context) {
                final texts = getFirstTexts(isWriting.value, 1, context);
                return UnStatsDataColumn(
                  totalVal:
                      '${isWriting.value ? '-' : '+'}${isWriting.value ? negativeWritingImpact : positiveRatingImpactNh}',
                  color: isWriting.value ? kRed : kGreen,
                  title: texts.first,
                  description: texts.last,
                );
              },
            ),
            const Divider(
              thickness: 0.5,
              height: kDefaultPadding * 2,
              endIndent: kDefaultPadding * 2,
              indent: kDefaultPadding * 2,
            ),
            Builder(
              builder: (context) {
                final texts = getFirstTexts(isWriting.value, 2, context);
                return UnStatsDataColumn(
                  totalVal:
                      '${isWriting.value ? '' : '-'}${isWriting.value ? ongoingWritingImpact : negativeRatingImpactH}',
                  color:
                      isWriting.value ? Theme.of(context).highlightColor : kRed,
                  title: texts.first,
                  description: texts.last,
                );
              },
            ),
            if (!isWriting.value) ...[
              const Divider(
                thickness: 0.5,
                height: kDefaultPadding * 2,
                endIndent: kDefaultPadding * 2,
                indent: kDefaultPadding * 2,
              ),
              UnStatsDataColumn(
                timeTwo: true,
                totalVal: '-$negativeRatingImpactNh',
                color: kRed,
                title: context.t.un1.capitalizeFirst(),
                description: context.t.un1Desc.capitalizeFirst(),
              ),
              const Divider(
                thickness: 0.5,
                height: kDefaultPadding * 2,
                endIndent: kDefaultPadding * 2,
                indent: kDefaultPadding * 2,
              ),
              UnStatsDataColumn(
                totalVal: '$ongoingRatingImpact',
                color: Theme.of(context).highlightColor,
                title: context.t.un2.capitalizeFirst(),
                description: context.t.un2Desc.capitalizeFirst(),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverAppBar _appbar(BuildContext context, ValueNotifier<bool> isWriting) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 115,
      backgroundColor: Theme.of(context).cardColor,
      flexibleSpace: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalBottomSheetHandle(
              color: kWhite,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfilePicture2(
                  size: 35,
                  pubkey: metadata.pubkey,
                  image: metadata.picture,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {},
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            SizedBox(
              width: double.infinity,
              height: 35,
              child: TabBar(
                onTap: (selectedIndex) {
                  isWriting.value = selectedIndex == 0;
                },
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                padding: EdgeInsets.zero,
                labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.w600,
                    ),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                indicatorColor: Theme.of(context).primaryColor,
                dividerColor: Theme.of(context).dividerColor,
                tabAlignment: TabAlignment.fill,
                tabs: [
                  Tab(
                    child: impactRow(
                        'Writing impact', writingImpact.toString(), context),
                  ),
                  Tab(
                    child: impactRow(
                        'Rating impact', ratingImpact.toString(), context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row impactRow(String title, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: kWhite,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }

  List<String> getFirstTexts(
      bool isWriting, int isFirst, BuildContext context) {
    return isFirst == 0
        ? [
            if (isWriting)
              context.t.unTextW1.capitalizeFirst()
            else
              context.t.unTextR1.capitalizeFirst(),
            if (isWriting)
              context.t.unTextW1Desc.capitalizeFirst()
            else
              context.t.unTextR1Desc.capitalizeFirst(),
          ]
        : isFirst == 1
            ? [
                if (isWriting)
                  context.t.unTextW2.capitalizeFirst()
                else
                  context.t.unTextR2.capitalizeFirst(),
                if (isWriting)
                  context.t.unTextW2Desc.capitalizeFirst()
                else
                  context.t.unTextR2Desc.capitalizeFirst(),
              ]
            : [
                if (isWriting)
                  context.t.unTextW3.capitalizeFirst()
                else
                  context.t.unTextR3.capitalizeFirst(),
                if (isWriting)
                  context.t.unTextW3Desc.capitalizeFirst()
                else
                  context.t.unTextR3Desc.capitalizeFirst(),
              ];
  }
}

class UnStatsDataColumn extends StatelessWidget {
  const UnStatsDataColumn(
      {super.key,
      required this.totalVal,
      required this.title,
      required this.description,
      required this.color,
      this.timeTwo});

  final String totalVal;
  final String title;
  final String description;
  final Color color;
  final bool? timeTwo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _totalVal(context),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          description,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: Theme.of(context).highlightColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Row _totalVal(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          totalVal,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
        if (timeTwo != null) ...[
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 3),
              color: kRed.withValues(alpha: 0.4),
            ),
            child: Text(
              'x2',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontWeight: FontWeight.w700, color: kRed),
            ),
          ),
        ],
      ],
    );
  }
}
