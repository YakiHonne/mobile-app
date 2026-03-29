import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../logic/relay_feed_cubit/relay_feed_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';

class RelayReviewBottomSheet extends StatefulWidget {
  const RelayReviewBottomSheet({super.key});

  @override
  State<RelayReviewBottomSheet> createState() => _RelayReviewBottomSheetState();
}

class _RelayReviewBottomSheetState extends State<RelayReviewBottomSheet> {
  double currentRating = 5;
  final TextEditingController commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: ModalBottomSheetHandle()),
              Text(
                context.t.writeReview.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kDefaultPadding),
              Center(
                child: RatingBar.builder(
                  initialRating: 5,
                  minRating: 1,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  unratedColor:
                      Theme.of(context).highlightColor.withValues(alpha: 0.2),
                  itemBuilder: (context, _) => Icon(
                    Icons.star_rounded,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      currentRating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              TextField(
                controller: commentController,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: context.t.writeComment.capitalizeFirst(),
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    final review = commentController.text.trim();
                    if (review.isEmpty) {
                      return;
                    }

                    context.read<RelayFeedCubit>().addRelayReview(
                          review: review,
                          rating: currentRating.toInt(),
                          onSuccess: () => Navigator.pop(context),
                        );
                  },
                  child: Text(context.t.submit.capitalizeFirst()),
                ),
              ),
              const SizedBox(height: kDefaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
