// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/uncensored_notes_cubit/un_flash_news_details_cubit/un_flash_news_details_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/uncensored_notes_models.dart';
import '../../../utils/utils.dart';
import '../../add_bookmark_view/add_bookmark_view.dart';
import '../../search_view/search_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/flash_tags_row.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/response_snackbar.dart';
import 'un_flashnews_add_note.dart';
import 'un_flashnews_add_rating.dart';
import 'uncensored_note_component.dart';

class UnFlashNewsDetails extends HookWidget {
  const UnFlashNewsDetails({
    super.key,
    required this.unFlashNews,
  });

  static const routeName = '/unFlashNewsDetails';
  static Route route(RouteSettings settings) {
    final unFlashNews = settings.arguments! as UnFlashNews;

    return CupertinoPageRoute(
      builder: (_) => UnFlashNewsDetails(unFlashNews: unFlashNews),
    );
  }

  final UnFlashNews unFlashNews;

  @override
  Widget build(BuildContext context) {
    final index = useState(0);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final pubkey = unFlashNews.flashNews.pubkey;

    return BlocProvider(
      create: (context) => UnFlashNewsDetailsCubit(
        unFlashNews: unFlashNews,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.details.capitalizeFirst(),
          notElevated: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                  _unStateColumn(pubkey),
                  _alreadyContributed(),
                  if (unFlashNews.isSealed) ...[
                    _uncensoredNoteComponent(),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: kDefaultPadding,
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: Divider(
                      height: kDefaultPadding,
                      thickness: 0.5,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: kDefaultPadding / 2,
                        top: kDefaultPadding / 4,
                      ),
                      child: Text(
                        context.t.notesFromCommunity.capitalizeFirst(),
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                  _appbar(context, index),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                ];
              },
              body: _content(index, isMobile),
            ),
          ),
        ),
      ),
    );
  }

  BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState> _content(
      ValueNotifier<int> index, bool isMobile) {
    return BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>(
      builder: (context, state) {
        if (state.loading) {
          return const SearchLoading();
        } else {
          List<UncensoredNote> filteredUncensoredNotes = state.uncensoredNotes;

          final List<String> notHelpfulIds =
              state.notHelpFulNotes.map((e) => e.uncensoredNote.id).toList();

          if (index.value == 1) {
            filteredUncensoredNotes = filteredUncensoredNotes.where((element) {
              return notHelpfulIds.contains(element.id);
            }).toList();
          } else if (state.notHelpFulNotes.isNotEmpty) {
            filteredUncensoredNotes = filteredUncensoredNotes.where((element) {
              return !notHelpfulIds.contains(element.id);
            }).toList();
          }

          if (filteredUncensoredNotes.isEmpty) {
            return ListView(
              children: [
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Image.asset(
                  Images.chilling,
                  width: 150,
                  height: 150,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  context.t.noCommunityNotes.capitalizeFirst(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            );
          }

          if (isMobile) {
            return _itemsList(filteredUncensoredNotes, state);
          } else {
            return _itemsGrid(filteredUncensoredNotes, state);
          }
        }
      },
    );
  }

  MasonryGridView _itemsGrid(List<UncensoredNote> filteredUncensoredNotes,
      UnFlashNewsDetailsState state) {
    return MasonryGridView.builder(
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: kDefaultPadding / 2,
      crossAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final note = filteredUncensoredNotes[index];
        final isNoteSealedNotHelpful = state.notHelpFulNotes
            .where((element) => element.uncensoredNote.id == note.id)
            .toList();

        return getComponent(
          context: context,
          note: note,
          sealedNotHelpful: isNoteSealedNotHelpful,
          isSealed: state.isSealed,
        );
      },
      itemCount: filteredUncensoredNotes.length,
    );
  }

  ListView _itemsList(List<UncensoredNote> filteredUncensoredNotes,
      UnFlashNewsDetailsState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final note = filteredUncensoredNotes[index];
        final isNoteSealedNotHelpful = state.notHelpFulNotes
            .where((element) => element.uncensoredNote.id == note.id)
            .toList();

        return getComponent(
          context: context,
          note: note,
          sealedNotHelpful: isNoteSealedNotHelpful,
          isSealed: state.isSealed,
        );
      },
      itemCount: filteredUncensoredNotes.length,
    );
  }

  SliverAppBar _appbar(BuildContext context, ValueNotifier<int> index) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 1),
      toolbarHeight: 45,
      titleSpacing: 0,
      actions: const [SizedBox.shrink()],
      elevation: 0,
      title: SizedBox(
        width: double.infinity,
        child: ButtonsTabBar(
          backgroundColor: Theme.of(context).primaryColorDark,
          unselectedDecoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).primaryColorLight,
              width: 3,
            ),
          ),
          radius: 300,
          unselectedLabelStyle: TextStyle(
            color: Theme.of(context).primaryColorDark,
          ),
          labelStyle: TextStyle(
            color: Theme.of(context).scaffoldBackgroundColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          height: 40,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          onTap: (selectedIndex) {
            index.value = selectedIndex;
          },
          tabs: [
            Tab(
              icon: SvgPicture.asset(
                FeatureIcons.uncensoredNote,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  getColor(
                    context: context,
                    index: 0,
                    selectedIndex: index.value,
                  ),
                  BlendMode.srcIn,
                ),
              ),
              text: context.t.ongoing.capitalizeFirst(),
              height: 50,
            ),
            Tab(
              icon: const Icon(
                CupertinoIcons.clear_circled,
                size: 18,
              ),
              text: context.t.notHelpful.capitalizeFirst(),
              height: 50,
            ),
          ],
        ),
      ),
    );
  }

  BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>
      _uncensoredNoteComponent() {
    return BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: UncensoredNoteComponent(
            note: unFlashNews.sealedNote!.uncensoredNote,
            isComponent: true,
            isSealed: true,
            sealDisable: true,
            onLike: () {},
            onDislike: () {},
            onDelete: (ratingNoteId) {},
            sealedNote: unFlashNews.sealedNote,
            flashNewsPubkey: unFlashNews.flashNews.pubkey,
            isUncensoredNoteAuthor: canSign() &&
                nostrRepository.currentMetadata.pubkey ==
                    unFlashNews.sealedNote!.uncensoredNote.pubKey,
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _alreadyContributed() {
    return SliverToBoxAdapter(
      child: BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>(
        builder: (context, state) {
          if (state.writingNoteStatus == WritingNoteStatus.alreadyWritten) {
            return Container(
              padding: const EdgeInsets.all(
                kDefaultPadding / 2,
              ),
              margin: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 2,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  kDefaultPadding,
                ),
                color: kGreenSide,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: kGreen,
                    size: 20,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  Flexible(
                    child: Text(
                      context.t.alreadyContributed.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: kGreen,
                          ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState> _unStateColumn(
      String pubkey) {
    return BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>(
      builder: (context, unState) {
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(pubkey, context, unState),
              if (unFlashNews.flashNews.tags.isNotEmpty ||
                  unFlashNews.flashNews.isImportant) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                FlashTagsRow(
                  isImportant: unFlashNews.flashNews.isImportant,
                  tags: unFlashNews.flashNews.tags,
                ),
              ],
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              ParsedText(
                text: unFlashNews.flashNews.content,
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _flashnewSourceRow(context),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Row _flashnewSourceRow(BuildContext context) {
    return Row(
      children: [
        if (unFlashNews.flashNews.source.isNotEmpty)
          CustomIconButton(
            backgroundColor: Theme.of(context).primaryColorLight,
            icon: FeatureIcons.globe,
            onClicked: () {
              openWebPage(
                url: unFlashNews.flashNews.source,
              );
            },
            size: 22,
          ),
        const Spacer(),
        Expanded(
          child: BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>(
            builder: (context, state) {
              if (state.writingNoteStatus == WritingNoteStatus.canBeWritten) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        elevation: 0,
                        builder: (_) {
                          return BlocProvider.value(
                            value: context.read<UnFlashNewsDetailsCubit>(),
                            child: UnFlashNewsAddNote(
                              onAdd: (content, source, isCorrect) {
                                context
                                    .read<UnFlashNewsDetailsCubit>()
                                    .addUncensoredNotes(
                                      content: content,
                                      source: source,
                                      isCorrect: isCorrect,
                                      onSuccess: () => Navigator.pop(context),
                                    );
                              },
                            ),
                          );
                        },
                        isScrollControlled: true,
                        useRootNavigator: true,
                        useSafeArea: true,
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                      );
                    },
                    icon: Icon(
                      Icons.add,
                      size: 17,
                      color: Theme.of(context).primaryColorLight,
                    ),
                    label: Text(
                      context.t.addNote.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: Theme.of(context).primaryColorLight,
                          ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorDark,
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  Row _infoRow(
      String pubkey, BuildContext context, UnFlashNewsDetailsState unState) {
    return Row(
      children: [
        Expanded(
          child: MetadataProvider(
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
                            .byPerson(
                              name: metadata.getName(),
                            )
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
                                unFlashNews.flashNews.createdAt,
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
                _pulldowbButton(context, unState),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PullDownButton _pulldowbButton(
      BuildContext context, UnFlashNewsDetailsState unState) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          if (canSign())
            PullDownMenuItem(
              title: context.t.bookmark.capitalizeFirst(),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  elevation: 0,
                  builder: (_) {
                    return AddBookmarkView(
                      kind: EventKind.TEXT_NOTE,
                      identifier: unFlashNews.flashNews.id,
                      eventPubkey: unFlashNews.flashNews.pubkey,
                      model: unFlashNews.flashNews,
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
              iconWidget: Builder(
                builder: (context) {
                  final isDark = themeCubit.isDark;

                  return SvgPicture.asset(
                    unState.isBookmarked
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
            iconWidget: SvgPicture.asset(
              FeatureIcons.link,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColorLight,
        ),
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }

  Widget getComponent({
    required BuildContext context,
    required UncensoredNote note,
    required List<SealedNote> sealedNotHelpful,
    required bool isSealed,
  }) {
    return UncensoredNoteComponent(
      note: note,
      isComponent: true,
      isSealed: sealedNotHelpful.isNotEmpty,
      sealDisable: isSealed,
      onLike: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return UnFlashNewsAddRating(
              isUpvote: true,
              uncensoredNoteId: note.id,
              onSuccess: () {
                context.read<UnFlashNewsDetailsCubit>().getUncensoredNotes();
                Navigator.pop(context);
              },
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onDislike: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return UnFlashNewsAddRating(
              isUpvote: false,
              uncensoredNoteId: note.id,
              onSuccess: () {
                context.read<UnFlashNewsDetailsCubit>().getUncensoredNotes();
                Navigator.pop(context);
              },
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onDelete: (ratingNoteId) {
        showCupertinoDeletionDialogue(
          context: context,
          title: context.t.undoRating.capitalizeFirst(),
          description: context.t.undoRatingDesc.capitalizeFirst(),
          buttonText: context.t.undo.capitalizeFirst(),
          onDelete: () {
            context.read<UnFlashNewsDetailsCubit>().deleteRating(
                  uncensoredNoteId: note.id,
                  ratingId: ratingNoteId,
                  onSuccess: () {
                    context
                        .read<UnFlashNewsDetailsCubit>()
                        .getUncensoredNotes();
                    Navigator.pop(context);
                  },
                );
          },
        );
      },
      sealedNote: sealedNotHelpful.isEmpty ? null : sealedNotHelpful.first,
      flashNewsPubkey: unFlashNews.flashNews.pubkey,
      isUncensoredNoteAuthor:
          canSign() && nostrRepository.currentMetadata.pubkey == note.pubKey,
    );
  }

  Color getColor({
    required BuildContext context,
    required int index,
    required int selectedIndex,
  }) {
    final isLight = !themeCubit.isDark;

    if (index == 0 && selectedIndex == 0 ||
        index == 1 && selectedIndex == 1 ||
        index == 2 && selectedIndex == 2) {
      if (isLight) {
        return kWhite;
      } else {
        return kBlack;
      }
    } else {
      if (isLight) {
        return kBlack;
      } else {
        return kWhite;
      }
    }
  }
}
