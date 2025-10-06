// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:pull_to_refresh/pull_to_refresh.dart';
// import 'package:responsive_framework/responsive_framework.dart';

// import '../../../logic/relay_feed_cubit/relay_feed_cubit.dart';
// import '../../../models/article_model.dart';
// import '../../../models/curation_model.dart';
// import '../../../models/detailed_note_model.dart';
// import '../../../models/flash_news_model.dart';
// import '../../../models/video_model.dart';
// import '../../../routes/navigator.dart';
// import '../../../utils/utils.dart';
// import '../../article_view/article_view.dart';
// import '../../curation_view/curation_view.dart';
// import '../../widgets/article_container.dart';
// import '../../widgets/classic_footer.dart';
// import '../../widgets/content_placeholder.dart';
// import '../../widgets/curation_container.dart';
// import '../../widgets/data_providers.dart';
// import '../../widgets/empty_list.dart';
// import '../../widgets/note_stats.dart';
// import '../../widgets/video_common_container.dart';
// import '../../widgets/video_components/horizontal_video_view.dart';
// import '../../widgets/video_components/vertical_video_view.dart';

// class RelayNotesFeed extends StatefulWidget {
//   const RelayNotesFeed({super.key});

//   @override
//   State<RelayNotesFeed> createState() => _RelayNotesFeedState();
// }

// class _RelayNotesFeedState extends State<RelayNotesFeed> {
//   final refreshController = RefreshController();
//   CommonFeedTypes? mainType;

//   @override
//   void dispose() {
//     refreshController.dispose();
//     super.dispose();
//   }

//   void buildNotesFeed(
//     BuildContext context,
//     bool isAdding,
//   ) {
//     context.read<RelayFeedCubit>().buildRelayFeed(
//           isAdding: isAdding,
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<RelayFeedCubit, RelayFeedState>(
//       listener: (context, state) {
//         if (state.onAddingData == UpdatingState.success) {
//           refreshController.loadComplete();
//         } else if (state.onAddingData == UpdatingState.idle) {
//           refreshController.loadNoData();
//         }

//         if (!state.onLoading) {
//           refreshController.refreshCompleted();
//         }
//       },
//       buildWhen: (previous, current) => previous.onLoading != current.onLoading,
//       builder: (context, state) {
//         return SmartRefresher(
//           controller: refreshController,
//           enablePullUp: true,
//           header: const RefresherClassicHeader(),
//           footer: const RefresherClassicFooter(),
//           onLoading: () => buildNotesFeed.call(context, true),
//           onRefresh: () => buildNotesFeed.call(context, false),
//           child: ScrollShadow(
//             color: Theme.of(context).scaffoldBackgroundColor,
//             child: CustomScrollView(
//               slivers: [
//                 if (state.onLoading)
//                   const SliverToBoxAdapter(child: NotesPlaceholder())
//                 else
//                   const ContentList(),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
