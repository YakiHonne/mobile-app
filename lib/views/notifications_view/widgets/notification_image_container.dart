// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/event_relation.dart';
import '../../../utils/utils.dart';
import '../../widgets/profile_picture.dart';

// ponytail: kept as SVGs (not lucide) per explicit request; source assets
// still exist under assets/icons/features/n-*.svg.
class _NIcons {
  _NIcons._();

  static const String mentions = 'assets/icons/features/n-mentions.svg';
  static const String reposts = 'assets/icons/features/n-reposts.svg';
  static const String reactions = 'assets/icons/features/n-reactions.svg';
  static const String zaps = 'assets/icons/features/n-zaps.svg';
  static const String articles = 'assets/icons/features/n-articles.svg';
  static const String curations = 'assets/icons/features/n-curations.svg';
  static const String videos = 'assets/icons/features/n-videos.svg';
  static const String smartWidgets =
      'assets/icons/features/n-smart-widgets.svg';
  static const String paidNotes = 'assets/icons/features/n-paid-notes.svg';
  static const String quotes = 'assets/icons/features/n-quotes.svg';
  static const String replies = 'assets/icons/features/n-replies-comments.svg';
}

class NotificationImageContainer extends StatelessWidget {
  const NotificationImageContainer({
    super.key,
    required this.metadata,
    required this.event,
    this.isPremium = false,
  });

  final Metadata metadata;
  final EventRelation event;
  final bool isPremium;

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
              strokeWidth: isPremium ? 1 : 0,
              reduceSize: true,
              strokeColor: isPremium ? kPremiumColor : kTransparent,
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
    String icon = _NIcons.mentions;

    switch (event.kind) {
      case EventKind.REPOST:
        icon = _NIcons.reposts;
      case EventKind.REACTION:
        icon = _NIcons.reactions;
      case EventKind.ZAP:
        icon = _NIcons.zaps;
      case EventKind.CASHU_NUTZAP:
        icon = _NIcons.zaps;
      case EventKind.LONG_FORM:
        icon = _NIcons.articles;
      case EventKind.CURATION_ARTICLES:
        icon = _NIcons.curations;
      case EventKind.CURATION_VIDEOS:
        icon = _NIcons.curations;
      case EventKind.VIDEO_HORIZONTAL:
        icon = _NIcons.videos;
      case EventKind.VIDEO_VERTICAL:
        icon = _NIcons.videos;
      case EventKind.SMART_WIDGET_ENH:
        icon = _NIcons.smartWidgets;

      case EventKind.TEXT_NOTE:
        if (canSign() && event.isMention(currentSigner!.getPublicKey())) {
          icon = _NIcons.mentions;
        } else if (event.isFlashNews()) {
          icon = _NIcons.paidNotes;
        } else if (event.origin.isQuote()) {
          icon = _NIcons.quotes;
        } else if (event.replyId != null ||
            event.rootId != null ||
            event.rRootId != null) {
          icon = _NIcons.replies;
        } else {
          icon = _NIcons.paidNotes;
        }
    }

    return icon;
  }
}
