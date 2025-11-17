// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:override_text_scale_factor/override_text_scale_factor.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/detailed_note_model.dart';
import '../../utils/utils.dart';
import '../note_view/note_view.dart';
import 'buttons_containers_widgets.dart';
import 'data_providers.dart';
import 'profile_picture.dart';

class NoteContainer extends StatelessWidget {
  const NoteContainer({
    super.key,
    required this.note,
    this.inverseNoteColor,
    this.disableVisualParsing,
    this.vMargin,
    this.hMargin,
    this.scrollPhysics,
    this.enableHidingMedia = true,
  });

  final DetailedNoteModel note;
  final bool? inverseNoteColor;
  final bool? disableVisualParsing;
  final double? vMargin;
  final double? hMargin;
  final ScrollPhysics? scrollPhysics;
  final bool enableHidingMedia;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NoteView.routeName,
          arguments: [note],
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        margin: EdgeInsets.symmetric(
          vertical: vMargin ?? 0,
          horizontal: hMargin ?? 0,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: inverseNoteColor != null
              ? Theme.of(context).scaffoldBackgroundColor
              : Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileInfoHeader(
              createdAt: note.createdAt,
              pubkey: note.pubkey,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            OverrideTextScaleFactor(
              child: ParsedText(
                text: note.content,
                pubkey: note.pubkey,
                disableNoteParsing: disableVisualParsing,
                scrollPhysics: scrollPhysics,
                enableHidingMedia: enableHidingMedia,
                onClicked: () {
                  Navigator.pushNamed(
                    context,
                    NoteView.routeName,
                    arguments: [note],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoHeader extends StatelessWidget {
  const ProfileInfoHeader({
    super.key,
    required this.pubkey,
    required this.createdAt,
    this.isMinimised = false,
  });

  final String pubkey;
  final DateTime createdAt;
  final bool isMinimised;

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      key: ValueKey(pubkey),
      pubkey: pubkey,
      child: (metadata, isNip05Valid) {
        return Row(
          children: [
            ProfilePicture2(
              image: isUserMuted(pubkey) ? '' : metadata.picture,
              pubkey: metadata.pubkey,
              size: 20,
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
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            _content(context, metadata, isNip05Valid),
          ],
        );
      },
    );
  }

  Expanded _content(
      BuildContext context, Metadata metadata, bool isNip05Valid) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(
              isUserMuted(pubkey)
                  ? context.t.mutedUser
                  : context.t.byPerson(name: metadata.getName()),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: isMinimised ? FontWeight.w400 : FontWeight.w800,
                    color: isMinimised
                        ? Theme.of(context).highlightColor
                        : Theme.of(context).primaryColorDark,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isMinimised) ...[
            if (isNip05Valid) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              SvgPicture.asset(
                FeatureIcons.verified,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
            DotContainer(
              color: Theme.of(context).primaryColorDark,
              size: 3,
            ),
            Text(
              StringUtil.getLastDate(createdAt),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: Theme.of(context).highlightColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      ),
    );
  }
}
