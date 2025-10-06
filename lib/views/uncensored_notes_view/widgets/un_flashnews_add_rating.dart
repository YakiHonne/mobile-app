// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/uncensored_notes_cubit/set_un_rating_cubit/set_un_rating_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/profile_picture.dart';

class UnFlashNewsAddRating extends StatefulWidget {
  const UnFlashNewsAddRating({
    super.key,
    required this.isUpvote,
    required this.uncensoredNoteId,
    required this.onSuccess,
  });

  final bool isUpvote;
  final String uncensoredNoteId;
  final Function() onSuccess;

  @override
  State<UnFlashNewsAddRating> createState() => _UnFlashNewsAddRatingState();
}

class _UnFlashNewsAddRatingState extends State<UnFlashNewsAddRating> {
  final selectionReasons = <String>[];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SetUnRatingCubit(),
      child: Container(
        width: double.infinity,
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
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            children: [
              const Center(child: ModalBottomSheetHandle()),
              _actionsRow(context),
              const Divider(
                height: kDefaultPadding,
                thickness: 0.5,
              ),
              _voteRow(),
              const SizedBox(
                height: kDefaultPadding,
              ),
              _ratingRow(context),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: Theme.of(context).primaryColorLight,
                ),
                padding: const EdgeInsets.all(kDefaultPadding),
                child: Text(
                  context.t.changeRatingNote.capitalizeFirst(),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding _ratingRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.whatThinkOfThat.capitalizeFirst(),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          if (widget.isUpvote)
            ListView(
              shrinkWrap: true,
              primary: false,
              padding: EdgeInsets.zero,
              children: helpfulRatingPoints
                  .map(
                    (e) => RatingTile(
                      title: e,
                      isSelected: selectionReasons.contains(e),
                      onClicked: () {
                        setState(() {
                          if (selectionReasons.contains(e)) {
                            selectionReasons.remove(e);
                          } else {
                            selectionReasons.add(e);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            )
          else
            ListView(
              shrinkWrap: true,
              primary: false,
              padding: EdgeInsets.zero,
              children: notHelpfulRatingPoints
                  .map(
                    (e) => RatingTile(
                      title: e,
                      isSelected: selectionReasons.contains(e),
                      onClicked: () {
                        setState(
                          () {
                            if (selectionReasons.contains(e)) {
                              selectionReasons.remove(e);
                            } else {
                              selectionReasons.add(e);
                            }
                          },
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Padding _voteRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: Row(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final pubKey = nostrRepository.currentMetadata.pubkey;

                return MetadataProvider(
                  key: ValueKey(pubKey),
                  pubkey: pubKey,
                  child: (metadata, nip05) => Row(
                    children: [
                      ProfilePicture2(
                        size: 40,
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
                              widget.isUpvote
                                  ? context.t.findThisHelpful.capitalizeFirst()
                                  : context.t.findThisNotHelpful
                                      .capitalizeFirst(),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              context.t.setYourRating.capitalizeFirst(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Row _actionsRow(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: kRed,
          ),
          child: Text(
            context.t.cancel.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: kWhite,
                ),
          ),
        ),
        const Spacer(),
        BlocBuilder<SetUnRatingCubit, SetUnRatingState>(
          builder: (context, state) {
            return TextButton.icon(
              onPressed: () {
                if (selectionReasons.isEmpty) {
                  BotToastUtils.showError(
                    context.t.selectOneReason.capitalizeFirst(),
                  );
                  return;
                }

                context.read<SetUnRatingCubit>().addRating(
                      isUpvote: widget.isUpvote,
                      uncensoredNoteId: widget.uncensoredNoteId,
                      reasons: selectionReasons,
                      onSuccess: widget.onSuccess,
                    );
              },
              label: SvgPicture.asset(
                widget.isUpvote ? FeatureIcons.like : FeatureIcons.dislike,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorLight,
                  BlendMode.srcIn,
                ),
                fit: BoxFit.scaleDown,
              ),
              icon: Text(
                widget.isUpvote
                    ? context.t.rateHelpful.capitalizeFirst()
                    : context.t.rateNotHelpful.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).primaryColorLight,
                    ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColorDark,
              ),
            );
          },
        ),
      ],
    );
  }
}

class RatingTile extends StatelessWidget {
  const RatingTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onClicked,
  });

  final String title;
  final bool isSelected;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).primaryColorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      ),
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: isSelected,
        onChanged: (value) {
          onClicked.call();
        },
        side: BorderSide(
          color: Theme.of(context).primaryColorDark,
          width: 1.5,
        ),
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        activeColor: kPurple,
        checkColor: kWhite,
      ),
      dense: true,
      title: Text(
        title,
      ),
      onTap: onClicked,
    );
  }
}
