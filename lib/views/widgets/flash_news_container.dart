// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../logic/single_event_cubit/single_event_cubit.dart';
import '../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/flash_news_model.dart';
import '../../models/uncensored_notes_models.dart';
import '../../utils/utils.dart';
import '../add_bookmark_view/add_bookmark_view.dart';
import '../uncensored_notes_view/widgets/un_flashnews_container.dart';
import '../uncensored_notes_view/widgets/un_flashnews_details.dart';
import '../uncensored_notes_view/widgets/uncensored_note_component.dart';
import 'custom_icon_buttons.dart';
import 'data_providers.dart';
import 'flash_tags_row.dart';
import 'profile_picture.dart';

class FlashNewsContainer extends HookWidget {
  final MainFlashNews mainFlashNews;
  final FlashNewsType flashNewsType;
  final bool? trySearch;
  final String? selectedTag;
  final bool? isMuted;
  final bool? isComponent;
  final bool? isBookmarked;
  final Function()? onDelete;
  final Function()? onCopyInvoice;
  final Function()? onConfirmPayment;
  final Function()? onPayWithAlby;
  final Function()? onClicked;

  const FlashNewsContainer({
    super.key,
    required this.mainFlashNews,
    required this.flashNewsType,
    this.trySearch,
    this.selectedTag,
    this.isMuted,
    this.isComponent,
    this.isBookmarked,
    this.onDelete,
    this.onCopyInvoice,
    this.onConfirmPayment,
    this.onPayWithAlby,
    this.onClicked,
  });

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: flashNewsType != FlashNewsType.userPending ? onClicked : null,
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.all(kDefaultPadding / 1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: isComponent != null
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).primaryColorLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: flashNewsType == FlashNewsType.public
                        ? _metadataRow(context)
                        : _publishOn(context),
                  ),
                  if (flashNewsType == FlashNewsType.userActive)
                    CustomIconButton(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      icon: FeatureIcons.trash,
                      onClicked: onDelete!,
                      size: 22,
                    ),
                ],
              ),
              if (mainFlashNews.flashNews.tags.isNotEmpty ||
                  mainFlashNews.flashNews.isImportant) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                FlashTagsRow(
                  isImportant: mainFlashNews.flashNews.isImportant,
                  tags: mainFlashNews.flashNews.tags,
                  selectedTag: selectedTag,
                ),
              ],
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              ParsedText(
                text: mainFlashNews.flashNews.content,
                onClicked: onClicked,
              ),
              if (flashNewsType == FlashNewsType.public) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                SealedComponent(
                  mainFlashNews: mainFlashNews,
                  trySearch: trySearch ?? true,
                  hideSealed: trySearch,
                  isComponent: false,
                ),
              ],
              if (mainFlashNews.flashNews.source.isNotEmpty ||
                  (canSign() && flashNewsType == FlashNewsType.public)) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Spacer(),
                    if (mainFlashNews.flashNews.source.isNotEmpty)
                      CustomIconButton(
                        backgroundColor: isComponent != null
                            ? Theme.of(context).cardColor
                            : Theme.of(context).scaffoldBackgroundColor,
                        icon: FeatureIcons.globe,
                        onClicked: () {
                          openWebPage(url: mainFlashNews.flashNews.source);
                        },
                        size: 22,
                      ),
                  ],
                ),
              ],
              if (flashNewsType == FlashNewsType.userPending) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Column(
                  children: [
                    _onConfirmPayment(context),
                    _selectWallet(),
                  ],
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  BlocBuilder<WalletsManagerCubit, WalletsManagerState> _selectWallet() {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        if (state.selectedWalletId.isNotEmpty &&
            state.wallets[state.selectedWalletId] != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.orange,
                      Colors.yellow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: TextButton(
                  onPressed: onPayWithAlby,
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        LogosIcons.alby,
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Text(
                        context.t.payWithNwc.capitalizeFirst(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: kBlack,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Row _onConfirmPayment(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            onPressed: onCopyInvoice,
            child: Text(
              context.t.copyInvoice.capitalizeFirst(),
            ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            onPressed: onConfirmPayment,
            child: Text(
              context.t.confirmPayment.capitalizeFirst(),
            ),
          ),
        ),
      ],
    );
  }

  Column _publishOn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.publishedOnText.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          dateFormat4.format(
            mainFlashNews.flashNews.createdAt,
          ),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: kMainColor,
              ),
        ),
      ],
    );
  }

  MetadataProvider _metadataRow(BuildContext context) {
    return MetadataProvider(
      pubkey: mainFlashNews.flashNews.pubkey,
      child: (metadata, isNip05Valid) {
        return Row(
          children: [
            ProfilePicture2(
              size: 30,
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
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _userInfo(context, metadata),
            if (canSign() && flashNewsType == FlashNewsType.public)
              _addBookmark(context),
            IconButton(
              onPressed: onClicked,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  IconButton _addBookmark(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return AddBookmarkView(
              kind: EventKind.TEXT_NOTE,
              identifier: mainFlashNews.flashNews.id,
              eventPubkey: mainFlashNews.flashNews.pubkey,
              image: '',
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      icon: Builder(
        builder: (context) {
          final isDark = themeCubit.isDark;

          return SvgPicture.asset(
            isBookmarked!
                ? isDark
                    ? FeatureIcons.bookmarkFilledWhite
                    : FeatureIcons.bookmarkFilledBlack
                : isDark
                    ? FeatureIcons.bookmarkEmptyWhite
                    : FeatureIcons.bookmarkEmptyBlack,
          );
        },
      ),
    );
  }

  Expanded _userInfo(BuildContext context, Metadata metadata) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.byPerson(
              name: metadata.getName(),
            ),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            context.t.onDate(
              date: dateFormat4.format(
                mainFlashNews.flashNews.createdAt,
              ),
            ),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: kMainColor,
                ),
          ),
        ],
      ),
    );
  }
}

class SealedComponent extends StatelessWidget {
  SealedComponent({
    super.key,
    required this.mainFlashNews,
    this.trySearch,
    this.isComponent,
    this.hideSealed,
  }) {
    if (trySearch != null && mainFlashNews.sealedNote == null) {
      singleEventCubit.getSealedEventOverHttp(mainFlashNews.flashNews.id);
    }
  }

  final MainFlashNews mainFlashNews;
  final bool? trySearch;
  final bool? isComponent;
  final bool? hideSealed;

  @override
  Widget build(BuildContext context) {
    if (mainFlashNews.sealedNote != null) {
      return _sealedNote(context);
    } else if (trySearch != null) {
      return BlocBuilder<SingleEventCubit, SingleEventState>(
        buildWhen: (previous, current) =>
            previous.sealedNotes[mainFlashNews.flashNews.id] !=
            current.sealedNotes[mainFlashNews.flashNews.id],
        builder: (context, state) {
          final sealedNote = state.sealedNotes[mainFlashNews.flashNews.id];

          return _noneSealed(sealedNote, context);
        },
        bloc: singleEventCubit,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Padding _noneSealed(SealedNote? sealedNote, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sealedNote != null &&
              !sealedNote.uncensoredNote.leading &&
              hideSealed == null) ...[
            UncensoredNoteComponent(
              note: sealedNote.uncensoredNote,
              flashNewsPubkey: mainFlashNews.flashNews.pubkey,
              isUncensoredNoteAuthor: false,
              sealedNote: sealedNote,
              isComponent: isComponent ?? true,
              isSealed: true,
              sealDisable: false,
              onDelete: (id) {},
              onLike: () {},
              onDislike: () {},
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
          ],
          RoundedTextButtonWithArrow(
            text: context.t.seeAllAttempts.capitalizeFirst(),
            buttonColor: kBlue,
            textColor: kWhite,
            onClicked: () {
              Navigator.pushNamed(
                context,
                UnFlashNewsDetails.routeName,
                arguments: UnFlashNews(
                  flashNews: mainFlashNews.flashNews,
                  sealedNote: sealedNote,
                  uncensoredNotes: [],
                  isSealed: sealedNote != null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Padding _sealedNote(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!mainFlashNews.sealedNote!.uncensoredNote.leading &&
              hideSealed == null) ...[
            UncensoredNoteComponent(
              note: mainFlashNews.sealedNote!.uncensoredNote,
              flashNewsPubkey: mainFlashNews.flashNews.pubkey,
              isUncensoredNoteAuthor: false,
              sealedNote: mainFlashNews.sealedNote,
              isComponent: isComponent ?? true,
              isSealed: true,
              sealDisable: false,
              onDelete: (id) {},
              onLike: () {},
              onDislike: () {},
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          RoundedTextButtonWithArrow(
            text: context.t.seeAllAttempts.capitalizeFirst(),
            buttonColor: kBlue,
            textColor: kWhite,
            onClicked: () {
              Navigator.pushNamed(
                context,
                UnFlashNewsDetails.routeName,
                arguments: UnFlashNews(
                  flashNews: mainFlashNews.flashNews,
                  sealedNote: mainFlashNews.sealedNote,
                  uncensoredNotes: [],
                  isSealed: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
