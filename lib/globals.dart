import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';

import 'common/tracker/umami_tracker.dart';
import 'logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import 'logic/bot_utils_loading_progress_cubit/bot_utils_loading_progress_cubit.dart';
import 'logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import 'logic/contact_list_cubit/contact_list_cubit.dart';
import 'logic/crashlytics_cubit/crashlytics_cubit.dart';
import 'logic/discover_cubit/discover_cubit.dart';
import 'logic/dms_cubit/dms_cubit.dart';
import 'logic/leading_cubit/leading_cubit.dart';
import 'logic/localization_cubit/localization_cubit.dart';
import 'logic/media_cubit/media_cubit.dart';
import 'logic/media_servers_cubit/media_servers_cubit.dart';
import 'logic/metadata_cubit/metadata_cubit.dart';
import 'logic/notes_events_cubit/notes_events_cubit.dart';
import 'logic/notifications_cubit/notifications_cubit.dart';
import 'logic/points_management_cubit/points_management_cubit.dart';
import 'logic/relay_info_cubit/relay_info_cubit.dart';
import 'logic/relays_progress_cubit/relays_progress_cubit.dart';
import 'logic/routing_cubit/routing_cubit.dart';
import 'logic/settings_cubit/settings_cubit.dart';
import 'logic/single_event_cubit/single_event_cubit.dart';
import 'logic/suggestion_box_cubit/suggestions_box_cubit.dart';
import 'logic/theme_cubit/theme_cubit.dart';
import 'logic/unsent_events_cubit/unsent_events_cubit.dart';
import 'logic/video_controller_manager_cubit/video_controller_manager_cubit.dart';
import 'logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import 'repositories/connectivity_repository.dart';
import 'repositories/localdatabase_repository.dart';
import 'repositories/nostr_data_repository.dart';

late SettingsCubit settingsCubit;

late LocalDatabaseRepository localDatabaseRepository;

late ConnectivityService connectivityService;

late NostrDataRepository nostrRepository;

late RoutingCubit routingCubit;

late RelayInfoCubit relayInfoCubit;

late MetadataCubit metadataCubit;

late PointsManagementCubit pointsManagementCubit;

late ThemeCubit themeCubit;

late SingleEventCubit singleEventCubit;

late NotesEventsCubit notesEventsCubit;

late LeadingCubit leadingCubit;

late DiscoverCubit discoverCubit;

late MediaCubit mediaCubit;

late MediaServersCubit mediaServersCubit;

late NotificationsCubit notificationsCubit;

late DmsCubit dmsCubit;

late WalletsManagerCubit walletManagerCubit;

late CashuWalletManagerCubit cashuWalletManagerCubit;

late RelaysProgressCubit relaysProgressCubit;

late NostrCore nc;

late ContactListCubit contactListCubit;

late VideoControllerManagerCubit videoControllerManagerCubit;

late LocalizationCubit localizationCubit;

late SuggestionsBoxCubit suggestionsBoxCubit;

late TransitionBuilder botToastBuilder;

late UserRelayList currentUserRelayList;

late bool isExternalSignerInstalled;

late UmamiAnalytics umamiAnalytics;

late AppSettingsManagerCubit appSettingsManagerCubit;

late CrashlyticsCubit crashlyticsCubit;

late UnsentEventsCubit unsentEventsCubit;

late BotUtilsLoadingProgressCubit botUtilsLoadingProgressCubit;

late EventSigner actionsSigner;

late BuildContext gc;

late List<CameraDescription> cameras;

RelaySet? feedRelaySet;

EventSigner? currentSigner;

final routeObserver = RouteObserver<PageRoute>();
