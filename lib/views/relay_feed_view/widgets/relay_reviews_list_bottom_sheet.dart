import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../logic/relay_feed_cubit/relay_feed_cubit.dart';
import '../../../models/relay_review.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/modal_sheet_container.dart';
import 'relay_review_bottom_sheet.dart';
import 'relay_review_card.dart';

class RelayReviewListBottomSheet extends StatelessWidget {
  const RelayReviewListBottomSheet({super.key, required this.relay});

  final String relay;

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<RelayFeedCubit>().state.reviews;

    return ModalSheetContainer(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          top: false,
          child: Column(
            children: [
              const Center(child: ModalBottomSheetHandle()),
              Text(
                context.t.reviews.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                relay,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              ReviewsTotalRating(reviews: reviews),
              const SizedBox(height: kDefaultPadding),
              Expanded(
                child: reviews.isEmpty
                    ? EmptyList(
                        title: context.t.noReviews,
                        description: context.t.noReviewsDesc,
                        icon: FeatureIcons.note,
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 2,
                        ),
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return RelayReviewCard(review: review);
                        },
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: kDefaultPadding / 4);
                        },
                        itemCount: reviews.length,
                      ),
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BlocProvider.value(
                        value: context.read<RelayFeedCubit>(),
                        child: const RelayReviewBottomSheet(),
                      ),
                    );
                  },
                  child: Text(context.t.submitReview.capitalizeFirst()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewsTotalRating extends StatelessWidget {
  const ReviewsTotalRating({
    super.key,
    required this.reviews,
    this.itemSize = 20,
  });

  final List<RelayReview> reviews;
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    final rating = reviews.isNotEmpty
        ? reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rating.toStringAsFixed(1),
        ),
        const SizedBox(width: kDefaultPadding / 4),
        Flexible(
          child: RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) => Icon(
              LucideIcons.star,
              color: Theme.of(context).primaryColorDark,
            ),
            itemSize: itemSize,
          ),
        ),
      ],
    );
  }
}
