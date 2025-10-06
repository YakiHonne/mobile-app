// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../logic/suggestion_box_cubit/suggestions_box_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import '../profile_picture.dart';

class SuggestedTrendingUsers24 extends StatelessWidget {
  const SuggestedTrendingUsers24({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuggestionsBoxCubit, SuggestionsBoxState>(
      builder: (context, state) {
        return StreamBuilder<List<String>>(
          initialData: contactListCubit.contacts,
          stream: nostrRepository.contactListStream,
          builder: (context, snapshot) {
            return SizedBox(
              height: 205,
              child: ListView.separated(
                key: const PageStorageKey('trending-users-24'),
                separatorBuilder: (context, index) => const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  final metadata = state.trendingUsers24[index];

                  return TrendingUserContainer(
                    metadata: metadata,
                  );
                },
                itemCount: state.trendingUsers24.length,
              ),
            );
          },
        );
      },
    );
  }
}

class TrendingUserContainer extends StatelessWidget {
  const TrendingUserContainer({
    super.key,
    required this.metadata,
  });

  final Metadata metadata;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToProfile.call(context),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfilePicture3(
              size: 60,
              image: metadata.picture,
              pubkey: metadata.pubkey,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {
                navigateToProfile.call(context);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _nip05(),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              '${metadata.about}\n',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            _follow(context),
          ],
        ),
      ),
    );
  }

  SizedBox _follow(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          doIfCanSign(
            func: () {
              context.read<SuggestionsBoxCubit>().setFollowingState(
                    pubkey: metadata.pubkey,
                  );
            },
            context: context,
          );
        },
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
        ),
        child: Text(
          context.t.follow.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: kMainColor,
              ),
        ),
      ),
    );
  }

  FutureBuilder<bool> _nip05() {
    return FutureBuilder(
      future: metadataCubit.isNip05Valid(metadata),
      builder: (context, snapshot) {
        final isVerified = snapshot.data != null && snapshot.data!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                metadata.getName().trim(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              SvgPicture.asset(
                FeatureIcons.verified,
                width: 15,
                height: 15,
              ),
            ],
          ],
        );
      },
    );
  }

  void navigateToProfile(BuildContext context) {
    openProfileFastAccess(context: context, pubkey: metadata.pubkey);
  }
}
