// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../../models/event_relation.dart';
import '../../../utils/utils.dart';
import '../../widgets/profile_picture.dart';

class NotificationImageContainer extends StatelessWidget {
  const NotificationImageContainer({
    super.key,
    required this.metadata,
    required this.event,
  });

  final Metadata metadata;
  final EventRelation event;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const SizedBox(
          width: 50,
          height: 50,
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: ProfilePicture3(
              size: 45,
              image: metadata.picture,
              pubkey: metadata.pubkey,
              padding: 0,
              strokeWidth: 0,
              reduceSize: true,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              getIcon(),
              width: 18,
              height: 18,
            ),
          ),
        ),
      ],
    );
  }

  String getIcon() {
    String icon = FeatureIcons.nMentions;

    switch (event.kind) {
      case EventKind.REPOST:
        icon = FeatureIcons.nReposts;
      case EventKind.REACTION:
        icon = FeatureIcons.nReactions;
      case EventKind.ZAP:
        icon = FeatureIcons.nZaps;
      case EventKind.CASHU_NUTZAP:
        icon = FeatureIcons.nZaps;
      case EventKind.LONG_FORM:
        icon = FeatureIcons.nArticles;
      case EventKind.CURATION_ARTICLES:
        icon = FeatureIcons.nCurations;
      case EventKind.CURATION_VIDEOS:
        icon = FeatureIcons.nCurations;
      case EventKind.VIDEO_HORIZONTAL:
        icon = FeatureIcons.nVideos;
      case EventKind.VIDEO_VERTICAL:
        icon = FeatureIcons.nVideos;
      case EventKind.SMART_WIDGET_ENH:
        icon = FeatureIcons.nSmartWidgets;

      case EventKind.TEXT_NOTE:
        if (event.isMention(currentSigner!.getPublicKey())) {
          icon = FeatureIcons.nMentions;
        } else if (event.isFlashNews()) {
          icon = FeatureIcons.nPaidNotes;
        } else if (event.origin.isQuote()) {
          icon = FeatureIcons.nQuotes;
        } else if (event.replyId != null ||
            event.rootId != null ||
            event.rRootId != null) {
          icon = FeatureIcons.nReplies;
        }
    }

    return icon;
  }
}
