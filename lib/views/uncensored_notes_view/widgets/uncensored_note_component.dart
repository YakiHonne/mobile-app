// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/uncensored_notes_models.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/custom_icon_buttons.dart';

class UncensoredNoteComponent extends HookWidget {
  const UncensoredNoteComponent({
    super.key,
    required this.note,
    required this.flashNewsPubkey,
    required this.isUncensoredNoteAuthor,
    required this.isComponent,
    required this.isSealed,
    required this.sealDisable,
    required this.onDelete,
    required this.onLike,
    required this.onDislike,
    this.sealedNote,
  });

  final UncensoredNote note;
  final String flashNewsPubkey;
  final SealedNote? sealedNote;
  final bool isUncensoredNoteAuthor;
  final bool isComponent;
  final bool isSealed;
  final bool sealDisable;
  final Function(String) onDelete;
  final Function() onLike;
  final Function() onDislike;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(
          color: isUncensoredNoteAuthor
              ? Theme.of(context).primaryColorDark
              : kTransparent,
        ),
        color: isComponent
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: isSealed ? _sealedNote() : _needMoreRating(context),
          ),
          const Divider(
            height: 0,
          ),
          _noteSource(context),
          if (canSign()) ...[
            if (!isSealed && !sealDisable) ...[
              const Divider(
                height: 0,
              ),
              _noteRating()
            ] else if (isSealed) ...[
              const Divider(
                height: 0,
              ),
              _reasons(context)
            ],
          ]
        ],
      ),
    );
  }

  Padding _reasons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Row(
        children: [
          SvgPicture.asset(
            FeatureIcons.tag,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.topReasonsSelected.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 6,
                ),
                ScrollShadow(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SizedBox(
                    height: 17,
                    child: sealedNote!.reasons.isEmpty
                        ? Text(
                            context.t.noReasonsSpecified.capitalizeFirst(),
                            style: Theme.of(context).textTheme.labelSmall,
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (context, index) =>
                                const DotContainer(
                              color: kMainColor,
                              size: 4,
                            ),
                            itemBuilder: (context, index) {
                              final reason = sealedNote!.reasons[index];

                              return Text(
                                reason,
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            },
                            itemCount: sealedNote!.reasons.length,
                          ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Builder _noteRating() {
    return Builder(
      builder: (context) {
        final ratingNote = getRating(note: note);

        final isFlashNewsAuthor = canSign() &&
            nostrRepository.currentMetadata.pubkey == flashNewsPubkey;

        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: isFlashNewsAuthor
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 6,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.timer,
                          color: kMainColor,
                          size: 18,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Text(
                          context.t.thisNoteAwaitRating.capitalizeFirst(),
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                )
              : isUncensoredNoteAuthor
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 6,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.timer,
                              color: kMainColor,
                              size: 18,
                            ),
                            const SizedBox(
                              width: kDefaultPadding / 4,
                            ),
                            Text(
                              context.t.yourNoteAwaitRating.capitalizeFirst(),
                              style: Theme.of(context).textTheme.labelSmall,
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ratingNote != null
                      ? RatingTimerWidget(
                          ratingNote: ratingNote,
                          onDelete: onDelete,
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.t.findThisHelpful.capitalizeFirst(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      color: Theme.of(context).highlightColor,
                                    ),
                              ),
                            ),
                            CustomIconButton(
                              backgroundColor: isComponent
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : Theme.of(context).primaryColorLight,
                              icon: FeatureIcons.like,
                              onClicked: onLike,
                              size: 22,
                            ),
                            const SizedBox(
                              width: kDefaultPadding / 4,
                            ),
                            CustomIconButton(
                              backgroundColor: isComponent
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : Theme.of(context).primaryColorLight,
                              icon: FeatureIcons.dislike,
                              onClicked: onDislike,
                              size: 22,
                            ),
                          ],
                        ),
        );
      },
    );
  }

  Padding _noteSource(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t
                      .postedOn(
                        date: dateFormat4.format(note.createdAt),
                      )
                      .capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
              if (note.source.isNotEmpty)
                TransparentTextButtonWithIcon(
                  onClicked: () {
                    openWebPage(url: note.source);
                  },
                  text: context.t.source.capitalizeFirst(),
                  iconWidget: SvgPicture.asset(
                    FeatureIcons.globe,
                    width: 15,
                    height: 15,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          ParsedText(
            text: note.content,
          ),
        ],
      ),
    );
  }

  Row _needMoreRating(BuildContext context) {
    return Row(
      children: [
        DotContainer(
          color: Theme.of(context).highlightColor,
          isNotMarging: true,
          size: 5,
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Expanded(
          child: Text(
            context.t.needsMoreRating.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (isUncensoredNoteAuthor) ...[
          SvgPicture.asset(
            FeatureIcons.user,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
            width: 20,
            height: 20,
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
        ],
        InfoRoundedContainer(
          tag: sealDisable
              ? context.t.notSealed.capitalizeFirst()
              : context.t.notSealedYet.capitalizeFirst(),
          color: isComponent
              ? Theme.of(context).cardColor
              : Theme.of(context).scaffoldBackgroundColor,
          textColor: Theme.of(context).primaryColorDark,
          onClicked: () {},
        ),
      ],
    );
  }

  Builder _sealedNote() {
    return Builder(builder: (context) {
      final color = sealedNote!.isHelpful ? kGreen : kRed;

      return Row(
        children: [
          Icon(
            sealedNote!.isHelpful
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.clear_circled,
            color: color,
            size: 18,
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Expanded(
            child: Text(
              sealedNote!.isHelpful
                  ? context.t.ratedHelpful.capitalizeFirst()
                  : context.t.ratedNotHelpful.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ),
          InfoRoundedContainer(
            tag: context.t.sealed.capitalizeFirst(),
            color: color,
            textColor: kWhite,
            onClicked: () {},
          ),
        ],
      );
    });
  }

  NotesRating? getRating({
    required UncensoredNote note,
  }) {
    if (!canSign()) {
      return null;
    } else {
      final rating = note.ratings.where((element) {
        return element.pubKey == nostrRepository.currentMetadata.pubkey;
      }).toList();

      if (rating.isEmpty) {
        return null;
      }

      return rating.first;
    }
  }
}

class RatingTimerWidget extends HookWidget {
  const RatingTimerWidget({
    super.key,
    required this.ratingNote,
    required this.onDelete,
  });

  final NotesRating ratingNote;
  final Function(String ratingNoteId) onDelete;

  @override
  Widget build(BuildContext context) {
    final timerShown = useState(
      DateTime.now().difference(ratingNote.createdAt).inSeconds < 350,
    );

    final timerText = useState('');

    useMemoized(() {
      if (timerShown.value) {
        final topDate = ratingNote.createdAt
            .add(const Duration(minutes: 5))
            .toSecondsSinceEpoch();

        return Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (!context.mounted) {
              timer.cancel();
              return;
            }

            if (timerShown.value) {
              final currentTime =
                  topDate - DateTime.now().toSecondsSinceEpoch();
              timerText.value = currentTime.formattedSeconds();
              if (currentTime <= 0) {
                timerShown.value = false;
                timer.cancel();
              }
            }
          },
        );
      }
    });

    return Builder(
      builder: (context) {
        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.check_mark_circled,
                    color: kMainColor,
                    size: 18,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  Text(
                    'You rated this as ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    ratingNote.ratingValue
                        ? context.t.youRatedHelpful.capitalizeFirst()
                        : context.t.youRatedNotHelpful.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            if (timerShown.value) ...[
              Column(
                children: [
                  TransparentTextButton(
                    onClicked: () {
                      onDelete.call(ratingNote.id);
                    },
                    text: context.t.undo.capitalizeFirst(),
                    underlined: true,
                  ),
                  Text(
                    timerText.value,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ]
          ],
        );
      },
    );
  }
}

class TransparentTextButtonWithIcon extends StatelessWidget {
  const TransparentTextButtonWithIcon({
    super.key,
    required this.onClicked,
    required this.text,
    this.iconWidget,
  });

  final Function() onClicked;
  final String text;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onClicked,
      style: TextButton.styleFrom(
        backgroundColor: kTransparent,
        padding: EdgeInsets.zero,
        visualDensity: const VisualDensity(
          horizontal: -4,
          vertical: -4,
        ),
      ),
      icon: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).primaryColorDark,
              height: 1,
            ),
      ),
      label: iconWidget ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: Theme.of(context).primaryColorDark,
          ),
    );
  }
}

class TransparentTextButton extends StatelessWidget {
  const TransparentTextButton({
    super.key,
    required this.onClicked,
    required this.text,
    this.underlined,
  });

  final Function() onClicked;
  final String text;
  final bool? underlined;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClicked,
      style: TextButton.styleFrom(
        backgroundColor: kTransparent,
        padding: EdgeInsets.zero,
        visualDensity: const VisualDensity(
          horizontal: -4,
          vertical: -4,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).primaryColorDark,
              height: 1,
              decoration: underlined != null ? TextDecoration.underline : null,
            ),
      ),
    );
  }
}
