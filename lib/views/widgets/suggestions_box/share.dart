import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../utils/utils.dart';
import '../../main_view/widgets/profile_share_view.dart';
import '../profile_picture.dart';

class SuggestedShare extends StatelessWidget {
  const SuggestedShare({super.key});

  @override
  Widget build(BuildContext context) {
    final m = nostrRepository.currentMetadata;

    return Container(
      key: const PageStorageKey('suggested-share'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              Images.spBackground,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: SvgPicture.asset(
                FeatureIcons.spLeaves,
              ),
            ),
          ),
          _content(m, context),
        ],
      ),
    );
  }

  Padding _content(Metadata m, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: 18.w,
      ),
      child: Column(
        children: [
          ProfilePicture3(
            size: 55,
            image: m.picture,
            pubkey: m.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () {
              openProfileFastAccess(context: context, pubkey: m.pubkey);
            },
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            '@${m.getName()}',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            context.t.shareProfileDesc.capitalizeFirst(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  createViewFromBottom(
                    ProfileShareView(
                      metadata: m,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
              child: Text(
                context.t.shareProfile.capitalizeFirst(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: kWhite,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
