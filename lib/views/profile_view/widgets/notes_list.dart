// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/note_stats.dart';

class ProfileNotes extends StatelessWidget {
  const ProfileNotes({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
              child: NotesPlaceholder(),
            ),
          );
        } else {
          if (state.content.isEmpty) {
            return SliverToBoxAdapter(
              child: EmptyList(
                description: context.t
                    .userNoNotes(name: state.user.getName())
                    .capitalizeFirst(),
                icon: FeatureIcons.note,
              ),
            );
          } else {
            if (isTablet && !useSingleColumn) {
              return _itemsGrid(state);
            } else {
              return _itemsList(state);
            }
          }
        }
      },
    );
  }

  SliverList _itemsList(ProfileState state) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final event = state.content[index];

        if (event.kind == EventKind.REPOST) {
          return RepostNoteContainer(
            key: ValueKey(event.id),
            event: event,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        } else {
          return DetailedNoteContainer(
            key: ValueKey(event.id),
            note: DetailedNoteModel.fromEvent(event),
            isMain: false,
            addLine: false,
            enableReply: true,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        }
      },
      itemCount: state.content.length,
    );
  }

  SliverMasonryGrid _itemsGrid(ProfileState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      childCount: state.content.length,
      itemBuilder: (context, index) {
        final event = state.content[index];
        if (event.kind == EventKind.REPOST) {
          return RepostNoteContainer(
            key: ValueKey(event.id),
            event: event,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        } else {
          return DetailedNoteContainer(
            key: ValueKey(event.id),
            note: DetailedNoteModel.fromEvent(event),
            isMain: false,
            addLine: false,
            enableReply: true,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        }
      },
    );
  }
}

// class ProfileReplies extends StatefulWidget {
//   const ProfileReplies({
//     super.key,
//   });

//   @override
//   State<ProfileReplies> createState() => _ProfileRepliesState();
// }

// class _ProfileRepliesState extends State<ProfileReplies> {
//   final refreshController = RefreshController();

//   void onRefresh({required Function() onInit}) {
//     refreshController.resetNoData();
//     onInit.call();
//     refreshController.refreshCompleted();
//   }

//   @override
//   void dispose() {
//     refreshController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
//     final useSingleColumn =
//         nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

//     return BlocConsumer<ProfileCubit, ProfileState>(
//       listener: (context, state) {
//         if (state.repliesLoading == UpdatingState.success) {
//           refreshController.loadComplete();
//         } else if (state.repliesLoading == UpdatingState.idle) {
//           refreshController.loadNoData();
//         }
//       },
//       buildWhen: (previous, current) =>
//           previous.isRepliesLoading != current.isRepliesLoading ||
//           previous.repliesLoading != current.repliesLoading ||
//           previous.replies != current.replies ||
//           previous.mutes != current.mutes ||
//           previous.user != current.user,
//       builder: (context, state) {
//         if (state.isRepliesLoading) {
//           return const SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
//               child: NotesPlaceholder(),
//             ),
//           );
//         } else {
//           if (state.replies.isEmpty) {
//             return SliverToBoxAdapter(
//               child: EmptyList(
//                 description: context.t
//                     .userNoNotes(name: state.user.getName())
//                     .capitalizeFirst(),
//                 icon: FeatureIcons.note,
//               ),
//             );
//           } else {
//             if (isTablet && !useSingleColumn) {
//               return _itemsGrid(state);
//             } else {
//               return _itemsList(state);
//             }
//           }
//         }
//       },
//     );
//   }

//   SliverList _itemsList(ProfileState state) {
//     return SliverList.separated(
//       separatorBuilder: (context, index) => const Divider(
//         height: kDefaultPadding * 1.5,
//         thickness: 0.5,
//       ),
//       itemBuilder: (context, index) {
//         final event = state.replies[index];

//         return DetailedNoteContainer(
//           key: ValueKey(event.id),
//           note: DetailedNoteModel.fromEvent(event),
//           isMain: false,
//           addLine: false,
//           enableReply: true,
//           onMuteActionSuccess: (pubkey, status) {
//             context.read<ProfileCubit>().onRemoveMutedContent(
//                   pubkey,
//                   false,
//                 );
//           },
//         );
//       },
//       itemCount: state.replies.length,
//     );
//   }

//   SliverMasonryGrid _itemsGrid(ProfileState state) {
//     return SliverMasonryGrid.count(
//       crossAxisCount: 2,
//       crossAxisSpacing: kDefaultPadding / 2,
//       mainAxisSpacing: kDefaultPadding / 2,
//       childCount: state.replies.length,
//       itemBuilder: (context, index) {
//         final event = state.replies[index];
//         if (event.kind == EventKind.REPOST) {
//           return RepostNoteContainer(
//             key: ValueKey(event.id),
//             event: event,
//             onMuteActionSuccess: (pubkey, status) {
//               context.read<ProfileCubit>().onRemoveMutedContent(
//                     pubkey,
//                     false,
//                   );
//             },
//           );
//         } else {
//           return DetailedNoteContainer(
//             key: ValueKey(event.id),
//             note: DetailedNoteModel.fromEvent(event),
//             isMain: false,
//             addLine: false,
//             enableReply: true,
//             onMuteActionSuccess: (pubkey, status) {
//               context.read<ProfileCubit>().onRemoveMutedContent(
//                     pubkey,
//                     false,
//                   );
//             },
//           );
//         }
//       },
//     );
//   }
// }

// class ProfileMentions extends StatefulWidget {
//   const ProfileMentions({
//     super.key,
//   });

//   @override
//   State<ProfileMentions> createState() => _ProfileMentionsState();
// }

// class _ProfileMentionsState extends State<ProfileMentions> {
//   final refreshController = RefreshController();

//   void onRefresh({required Function() onInit}) {
//     refreshController.resetNoData();
//     onInit.call();
//     refreshController.refreshCompleted();
//   }

//   @override
//   void dispose() {
//     refreshController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
//     final useSingleColumn =
//         nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

//     return BlocConsumer<ProfileCubit, ProfileState>(
//       listener: (context, state) {
//         if (state.mentionsLoading == UpdatingState.success) {
//           refreshController.loadComplete();
//         } else if (state.mentionsLoading == UpdatingState.idle) {
//           refreshController.loadNoData();
//         }
//       },
//       buildWhen: (previous, current) =>
//           previous.isMentionsLoading != current.isMentionsLoading ||
//           previous.mentionsLoading != current.mentionsLoading ||
//           previous.mentions != current.mentions ||
//           previous.mutes != current.mutes ||
//           previous.user != current.user,
//       builder: (context, state) {
//         if (state.isMentionsLoading) {
//           return const SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
//               child: NotesPlaceholder(),
//             ),
//           );
//         } else {
//           if (state.mentions.isEmpty) {
//             return SliverToBoxAdapter(
//               child: EmptyList(
//                 description: context.t
//                     .userNoNotes(name: state.user.getName())
//                     .capitalizeFirst(),
//                 icon: FeatureIcons.note,
//               ),
//             );
//           } else {
//             if (isTablet && !useSingleColumn) {
//               return _itemsGrid(state);
//             } else {
//               return _itemsList(state);
//             }
//           }
//         }
//       },
//     );
//   }

//   SliverList _itemsList(ProfileState state) {
//     return SliverList.separated(
//       separatorBuilder: (context, index) => const Divider(
//         height: kDefaultPadding * 1.5,
//         thickness: 0.5,
//       ),
//       itemBuilder: (context, index) {
//         final event = state.mentions[index];

//         return DetailedNoteContainer(
//           key: ValueKey(event.id),
//           note: event,
//           isMain: false,
//           addLine: false,
//           enableReply: true,
//           onMuteActionSuccess: (pubkey, status) {
//             context.read<ProfileCubit>().onRemoveMutedContent(
//                   pubkey,
//                   false,
//                 );
//           },
//         );
//       },
//       itemCount: state.mentions.length,
//     );
//   }

//   SliverMasonryGrid _itemsGrid(ProfileState state) {
//     return SliverMasonryGrid.count(
//       crossAxisCount: 2,
//       crossAxisSpacing: kDefaultPadding / 2,
//       mainAxisSpacing: kDefaultPadding / 2,
//       childCount: state.mentions.length,
//       itemBuilder: (context, index) {
//         final event = state.mentions[index];
//         return DetailedNoteContainer(
//           key: ValueKey(event.id),
//           note: event,
//           isMain: false,
//           addLine: false,
//           enableReply: true,
//           onMuteActionSuccess: (pubkey, status) {
//             context.read<ProfileCubit>().onRemoveMutedContent(
//                   pubkey,
//                   false,
//                 );
//           },
//         );
//       },
//     );
//   }
// }

// class ProfilePinned extends StatefulWidget {
//   const ProfilePinned({
//     super.key,
//   });

//   @override
//   State<ProfilePinned> createState() => _ProfilePinnedState();
// }

// class _ProfilePinnedState extends State<ProfilePinned> {
//   final refreshController = RefreshController();

//   void onRefresh({required Function() onInit}) {
//     refreshController.resetNoData();
//     onInit.call();
//     refreshController.refreshCompleted();
//   }

//   @override
//   void dispose() {
//     refreshController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
//     final useSingleColumn =
//         nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

//     return BlocConsumer<ProfileCubit, ProfileState>(
//       listener: (context, state) {
//         if (state.mentionsLoading == UpdatingState.success) {
//           refreshController.loadComplete();
//         } else if (state.mentionsLoading == UpdatingState.idle) {
//           refreshController.loadNoData();
//         }
//       },
//       buildWhen: (previous, current) =>
//           previous.isMentionsLoading != current.isMentionsLoading ||
//           previous.mentionsLoading != current.mentionsLoading ||
//           previous.mentions != current.mentions ||
//           previous.mutes != current.mutes ||
//           previous.user != current.user,
//       builder: (context, state) {
//         if (state.isMentionsLoading) {
//           return const SliverToBoxAdapter(
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
//               child: NotesPlaceholder(),
//             ),
//           );
//         } else {
//           if (state.mentions.isEmpty) {
//             return SliverToBoxAdapter(
//               child: EmptyList(
//                 description: context.t
//                     .userNoNotes(name: state.user.getName())
//                     .capitalizeFirst(),
//                 icon: FeatureIcons.note,
//               ),
//             );
//           } else {
//             if (isTablet && !useSingleColumn) {
//               return _itemsGrid(state);
//             } else {
//               return _itemsList(state);
//             }
//           }
//         }
//       },
//     );
//   }

//   SliverList _itemsList(ProfileState state) {
//     return SliverList.separated(
//       separatorBuilder: (context, index) => const Divider(
//         height: kDefaultPadding * 1.5,
//         thickness: 0.5,
//       ),
//       itemBuilder: (context, index) {
//         final event = state.mentions[index];

//         return DetailedNoteContainer(
//           key: ValueKey(event.id),
//           note: event,
//           isMain: false,
//           addLine: false,
//           enableReply: true,
//           onMuteActionSuccess: (pubkey, status) {
//             context.read<ProfileCubit>().onRemoveMutedContent(
//                   pubkey,
//                   false,
//                 );
//           },
//         );
//       },
//       itemCount: state.mentions.length,
//     );
//   }

//   SliverMasonryGrid _itemsGrid(ProfileState state) {
//     return SliverMasonryGrid.count(
//       crossAxisCount: 2,
//       crossAxisSpacing: kDefaultPadding / 2,
//       mainAxisSpacing: kDefaultPadding / 2,
//       childCount: state.mentions.length,
//       itemBuilder: (context, index) {
//         final event = state.mentions[index];
//         return DetailedNoteContainer(
//           key: ValueKey(event.id),
//           note: event,
//           isMain: false,
//           addLine: false,
//           enableReply: true,
//           onMuteActionSuccess: (pubkey, status) {
//             context.read<ProfileCubit>().onRemoveMutedContent(
//                   pubkey,
//                   false,
//                 );
//           },
//         );
//       },
//     );
//   }
// }
