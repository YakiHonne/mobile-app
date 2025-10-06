import 'package:flutter/material.dart';

import '../views/article_view/article_view.dart';
import '../views/curation_view/curation_view.dart';
import '../views/dashboard_view/widgets/bookmarks/add_bookmarks_list_view.dart';
import '../views/dashboard_view/widgets/bookmarks/bookmarks_list_details.dart';
import '../views/dm_view/widgets/dm_details.dart';
import '../views/dm_view/widgets/dm_user_search.dart';
import '../views/note_view/note_view.dart';
import '../views/points_management_view/points_management_view.dart';
import '../views/profile_view/profile_view.dart';
import '../views/rewards_view/rewards_view.dart';
import '../views/routing_view/routing_view.dart';
import '../views/settings_view/widgets/keys_view.dart';
import '../views/settings_view/widgets/mute_list_view.dart';
import '../views/settings_view/widgets/relay_info_view.dart';
import '../views/settings_view/widgets/relays_update.dart';
import '../views/smart_widgets_view/widgets/smart_widget_checker.dart';
import '../views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import '../views/widgets/video_components/horizontal_video_view.dart';
import '../views/widgets/video_components/vertical_video_view.dart';

Route onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case RoutingView.routeName:
      return RoutingView.route();
    case CurationView.routeName:
      return CurationView.route(settings);
    case ArticleView.routeName:
      return ArticleView.route(settings);
    case ProfileView.routeName:
      return ProfileView.route(settings);
    case RelayUpdateView.routeName:
      return RelayUpdateView.route(settings);
    case KeysView.routeName:
      return KeysView.route(settings);
    case AddBookmarksListView.routeName:
      return AddBookmarksListView.route(settings);
    case BookmarksListDetails.routeName:
      return BookmarksListDetails.route(settings);
    case MuteListView.routeName:
      return MuteListView.route();
    case UnFlashNewsDetails.routeName:
      return UnFlashNewsDetails.route(settings);
    case NoteView.routeName:
      return NoteView.route(settings);
    case RewardsView.routeName:
      return RewardsView.route(settings);
    case DmDetails.routeName:
      return DmDetails.route(settings);
    case DmUserSearch.routeName:
      return DmUserSearch.route();
    case HorizontalVideoView.routeName:
      return HorizontalVideoView.route(settings);
    case VerticalVideoView.routeName:
      return VerticalVideoView.route(settings);
    case PointsStatisticsView.routeName:
      return PointsStatisticsView.route(settings);
    case SmartWidgetChecker.routeName:
      return SmartWidgetChecker.route(settings);
    case RelayInfoView.routeName:
      return RelayInfoView.route(settings);
    default:
      return _errorRoute();
  }
}

Route _errorRoute() {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'error',
        ),
      ),
    ),
    settings: const RouteSettings(
      name: '/error',
    ),
  );
}
