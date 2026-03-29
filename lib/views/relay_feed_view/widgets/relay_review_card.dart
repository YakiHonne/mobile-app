import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../models/relay_review.dart';
import '../../../utils/utils.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';

class RelayReviewCard extends StatelessWidget {
  const RelayReviewCard({
    super.key,
    required this.review,
  });

  final RelayReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetadataProvider(
            pubkey: review.pubkey,
            child: (metadata, isNip05Valid) {
              return GestureDetector(
                onTap: () {
                  openProfileFastAccess(
                    context: context,
                    pubkey: metadata.pubkey,
                  );
                },
                child: Row(
                  spacing: kDefaultPadding / 4,
                  children: [
                    ProfilePicture2(
                      size: 30,
                      image: metadata.picture,
                      pubkey: metadata.pubkey,
                      padding: 0,
                      strokeWidth: 0,
                      strokeColor: kTransparent,
                      onClicked: () {
                        openProfileFastAccess(
                          context: context,
                          pubkey: metadata.pubkey,
                        );
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metadata.getName(),
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        RatingBarIndicator(
                          rating: review.rating.toDouble(),
                          itemBuilder: (context, index) => Icon(
                            Icons.star,
                            color: Theme.of(context).primaryColorDark,
                          ),
                          itemSize: 15.0,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            review.comment.trim(),
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            dateFormat3.format(review.createdAt),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }
}
