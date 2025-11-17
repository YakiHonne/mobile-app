import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../utils/utils.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';

class ReplyContainer extends StatelessWidget {
  const ReplyContainer({
    super.key,
    required this.replyContent,
  });

  final Map<String, dynamic> replyContent;

  @override
  Widget build(BuildContext context) {
    final pubkey = replyContent['pubkey'];
    final date = replyContent['date'];
    final content = replyContent['content'];

    return MetadataProvider(
      key: ValueKey(pubkey),
      pubkey: pubkey,
      child: (metadata, _) => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
          horizontal: kDefaultPadding / 2,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _userProfile(metadata, context),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              _repliedToNote(context, date, content, metadata),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _repliedToNote(
      BuildContext context, date, content, Metadata metadata) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t
                .onDate(
                  date: dateFormat3.format(date),
                )
                .capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 4,
            ),
            child: ParsedText(
              text: content,
            ),
          ),
          GestureDetector(
            onTap: () {
              openProfileFastAccess(
                context: context,
                pubkey: metadata.pubkey,
              );
            },
            child: Text(
              context.t
                  .replyingTo(
                    name: metadata.getName(),
                  )
                  .capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
        ],
      ),
    );
  }

  Column _userProfile(Metadata metadata, BuildContext context) {
    return Column(
      children: [
        ProfilePicture2(
          size: 35,
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
        Expanded(
          child: VerticalDivider(
            indent: kDefaultPadding / 4,
            color: Theme.of(context).highlightColor,
            width: 0.2,
          ),
        ),
      ],
    );
  }
}
