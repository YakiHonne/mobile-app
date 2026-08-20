// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/uncensored_notes_models.dart';
import '../../../utils/utils.dart';
import '../../add_bookmark_view/add_bookmark_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/flash_tags_row.dart';
import '../../widgets/fluid_pull_down_button.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/response_snackbar.dart';
import 'un_flashnews_add_rating.dart';
import 'uncensored_note_component.dart';

class UnFlashNewsContainer extends StatelessWidget {
  const UnFlashNewsContainer({
    super.key,
    required this.unNewFlashNews,
    required this.isBookmarked,
    required this.onClicked,
    required this.onRefresh,
  });

  final UnFlashNews unNewFlashNews;
  final bool isBookmarked;
  final Function() onClicked;
  final Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final pubkey = unNewFlashNews.flashNews.pubkey;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(pubkey, context),
              if (unNewFlashNews.flashNews.tags.isNotEmpty ||
                  unNewFlashNews.flashNews.isImportant) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                FlashTagsRow(
                  isImportant: unNewFlashNews.flashNews.isImportant,
                  tags: unNewFlashNews.flashNews.tags,
                ),
              ],
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              ParsedText(
                text: unNewFlashNews.flashNews.content,
                onClicked: onClicked,
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              if (unNewFlashNews.isSealed) ...[
                _sealedUncensoredNoteComponent(),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ] else if (unNewFlashNews.uncensoredNotes.isNotEmpty) ...[
                _uncensoredNotesList(),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ],
              _actionsRow(context),
            ],
          ),
        ],
      ),
    );
  }

  Row _actionsRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unNewFlashNews.flashNews.source.isNotEmpty) ...[
          CustomIconButton(
            backgroundColor: Theme.of(context).cardColor,
            icon: FeatureIcons.globe,
            onClicked: () {
              openWebPage(url: unNewFlashNews.flashNews.source);
            },
            size: 20,
            vd: -1,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
        ],
        Expanded(
          child: RoundedTextButtonWithArrow(
            text: context.t.seeAllAttempts.capitalizeFirst(),
            buttonColor: kBlue,
            textColor: kWhite,
            onClicked: onClicked,
          ),
        ),
      ],
    );
  }

  ListView _uncensoredNotesList() {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 4,
      ),
      shrinkWrap: true,
      primary: false,
      itemBuilder: (context, index) {
        final note = unNewFlashNews.uncensoredNotes[index];

        return UncensoredNoteComponent(
          note: note,
          sealDisable: false,
          isSealed: false,
          isComponent: false,
          sealedNote: unNewFlashNews.sealedNote,
          flashNewsPubkey: unNewFlashNews.flashNews.pubkey,
          onLike: () {
            showAppModalSheet(
              context: context,              builder: (_) {
                return UnFlashNewsAddRating(
                  isUpvote: true,
                  uncensoredNoteId: note.id,
                  onSuccess: () {
                    onRefresh.call();
                    Navigator.pop(context);
                  },
                );
              },            );
          },
          onDislike: () {
            showAppModalSheet(
              context: context,              builder: (_) {
                return UnFlashNewsAddRating(
                  isUpvote: false,
                  uncensoredNoteId: note.id,
                  onSuccess: () {
                    onRefresh.call();
                    Navigator.pop(context);
                  },
                );
              },            );
          },
          onDelete: (ratingNoteId) {
            showCupertinoDeletionDialogue(
              context: context,
              title: context.t.undoRating.capitalizeFirst(),
              description: context.t.undoRatingDesc.capitalizeFirst(),
              buttonText: context.t.undo.capitalizeFirst(),
              onDelete: () {
                context.read<UncensoredNotesCubit>().deleteRating(
                      uncensoredNoteId: note.id,
                      ratingId: ratingNoteId,
                      onSuccess: () {
                        onRefresh.call();
                        Navigator.pop(context);
                      },
                    );
              },
            );
          },
          isUncensoredNoteAuthor: canSign() &&
              nostrRepository.currentMetadata.pubkey == note.pubKey,
        );
      },
      itemCount: unNewFlashNews.uncensoredNotes.length,
    );
  }

  UncensoredNoteComponent _sealedUncensoredNoteComponent() {
    return UncensoredNoteComponent(
      sealDisable: false,
      note: unNewFlashNews.sealedNote!.uncensoredNote,
      isSealed: true,
      isComponent: false,
      sealedNote: unNewFlashNews.sealedNote,
      flashNewsPubkey: unNewFlashNews.flashNews.pubkey,
      onLike: () {},
      onDislike: () {},
      onDelete: (ratingNoteId) {},
      isUncensoredNoteAuthor: canSign() &&
          nostrRepository.currentMetadata.pubkey ==
              unNewFlashNews.sealedNote!.uncensoredNote.pubKey,
    );
  }

  Row _infoRow(String pubkey, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetadataProvider(
            key: ValueKey(pubkey),
            pubkey: pubkey,
            child: (metadata, nip05) => Row(
              children: [
                ProfilePicture2(
                  size: 25,
                  image: metadata.picture,
                  pubkey: metadata.pubkey,
                  padding: 0,
                  strokeWidth: 1,
                  reduceSize: true,
                  strokeColor: kWhite,
                  onClicked: () {
                    openProfileFastAccess(
                      context: context,
                      pubkey: metadata.pubkey,
                    );
                  },
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t
                            .byPerson(name: metadata.getName())
                            .capitalizeFirst(),
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        context.t
                            .onDate(
                              date: dateFormat4.format(
                                unNewFlashNews.flashNews.createdAt,
                              ),
                            )
                            .capitalizeFirst(),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
                _pulldownButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  FluidPullDownButton _pulldownButton(BuildContext context) {
    return FluidPullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          if (canSign())
            PullDownMenuItem(
              title: context.t.bookmark.capitalizeFirst(),
              onTap: () {
                showAppModalSheet(
                  context: context,                  builder: (_) {
                    return AddBookmarkView(
                      kind: EventKind.TEXT_NOTE,
                      identifier: unNewFlashNews.flashNews.id,
                      eventPubkey: unNewFlashNews.flashNews.pubkey,
                      model: unNewFlashNews.flashNews,
                    );
                  },                );
              },
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
              iconWidget: Builder(
                builder: (context) {
                  final isDark = themeCubit.isDark;

                  return AppIcon(
                    isBookmarked
                        ? isDark
                            ? FeatureIcons.bookmarkFilledWhite
                            : FeatureIcons.bookmarkFilledBlack
                        : isDark
                            ? FeatureIcons.bookmarkEmptyWhite
                            : FeatureIcons.bookmarkEmptyBlack,
                  );
                },
              ),
            ),
          PullDownMenuItem(
            title: context.t.share.capitalizeFirst(),
            onTap: () {},
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: AppIcon(
              FeatureIcons.link,
              size: 20,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          visualDensity: const VisualDensity(
            horizontal: -4,
            vertical: -1,
          ),
        ),
        icon: Icon(
          LucideIcons.moreVertical,
          color: Theme.of(context).primaryColorDark,
          size: 20,
        ),
      ),
    );
  }
}

class RoundedTextButtonWithArrow extends StatelessWidget {
  const RoundedTextButtonWithArrow({
    super.key,
    required this.text,
    required this.onClicked,
    this.buttonColor,
    this.textColor,
  });

  final String text;
  final Color? buttonColor;
  final Color? textColor;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onClicked,
      icon: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: textColor ?? Theme.of(context).primaryColorDark,
            ),
      ),
      label: const Icon(
        LucideIcons.chevronRight,
      ),
      style: TextButton.styleFrom(
        backgroundBuilder: (_, __, child) => child!,
        visualDensity: const VisualDensity(
          vertical: -2,
        ),
        backgroundColor: buttonColor ?? Theme.of(context).primaryColorLight,
      ),
    );
  }
}
