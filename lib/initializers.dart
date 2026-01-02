import 'dart:async';
import 'dart:io';

import 'package:amberflutter/amberflutter.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/notifications/local_notification_manager.dart';
import 'common/tracker/umami_tracker.dart';
import 'logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
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
import 'models/filter_status.dart';
import 'repositories/connectivity_repository.dart';
import 'repositories/localdatabase_repository.dart';
import 'repositories/nostr_data_repository.dart';
import 'utils/utils.dart';

class AppInitializer {
  AppInitializer._();

  static Future<void> initApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    // print('===============> intializing core dependencies');
    // Initialize core dependencies
    await _initializeCoreDependencies();

    // print('===============> intializing authentication and signing');
    // Initialize Firebase and database
    _initializeLocalDatabase();
    // Initialize Nostr core

    // print('Nostr core initialized');
    await _initializeNostrCore();
    // Setup cubits and global state

    // print('Cubits and global state initialized');
    await _setupCubitsAndGlobals();

    // print('Notifications initialized');
    // Initialize notifications (critical: must be right after cubits)
    _initializeNotifications();

    // Configure system UI
    _configureSystemUI();

    // Start background services
    _startBackgroundServices();
  }

  /// Initialize core dependencies in parallel
  static Future<void> _initializeCoreDependencies() async {
    final results = await Future.wait<dynamic>([
      SharedPreferences.getInstance(),
      dotenv.load(),
    ]);

    prefs = results[0];
  }

  /// Initialize Firebase services
  static void _initializeLocalDatabase() {
    localDatabaseRepository = LocalDatabaseRepository();
  }

  /// Initialize Nostr core
  static Future<void> _initializeNostrCore() async {
    nc = NostrCore(loadRemoteCache: false);
    await nc.initRemoteCache();
    nc.remoteCacheService.connectCache();
    await nc.db.init();
  }

  /// Setup all cubits and global state
  static Future<void> _setupCubitsAndGlobals() async {
    // Initialize basic services
    _initializeBasicServices();

    // Initialize core settings
    await _initializeSettings();

    // Initialize repositories
    await _initializeRepositories();

    // Initialize all cubits
    _initializeCubits();

    // Setup authentication and signing
    await _setupAuthAndSigning();

    // Initialize relay system
    await _initializeRelaySystem();

    _initFeedCubits();
  }

  /// Initialize basic services
  static Future<void> _initializeBasicServices() async {
    botToastBuilder = BotToastInit();
    _initializeActionsSigner();

    // Initialize analytics (non-critical)
    try {
      umamiAnalytics = UmamiAnalytics();
      await umamiAnalytics.getUserAgent();
    } catch (e) {
      if (kDebugMode) {
        print('Analytics initialization failed: $e');
      }
    }
  }

  /// Initialize settings cubit first (other cubits depend on it)
  static Future<void> _initializeSettings() async {
    settingsCubit = SettingsCubit();
    await settingsCubit.init();
    initCameras();
  }

  static Future<void> initCameras() async {
    cameras = await availableCameras();
  }

  /// Initialize repositories
  static Future<void> _initializeRepositories() async {
    connectivityService = ConnectivityService();
    connectivityService.startPeriodicChecks();

    nostrRepository = NostrDataRepository();
    nostrRepository.loadAppCustomization();

    nostrRepository.filterStatus = localDatabaseRepository.getFilterStatus() ??
        FilterStatus(
          leadingFilter: true,
          discoverFilter: true,
          mediaFilter: true,
        );

    nostrRepository.setCurrentCrashlytics();
    await nostrRepository.loadRemoteSigners();
  }

  /// Initialize all cubits
  static void _initializeCubits() {
    // Initialize localization cubit
    localizationCubit = LocalizationCubit();
    localizationCubit.init();

    // Initialize unsent events cubit

    unsentEventsCubit = UnsentEventsCubit();
    unsentEventsCubit.init();

    // Initialize all other cubits
    metadataCubit = MetadataCubit();
    themeCubit = ThemeCubit();
    singleEventCubit = SingleEventCubit();
    notesEventsCubit = NotesEventsCubit();
    notificationsCubit = NotificationsCubit();
    dmsCubit = DmsCubit();
    walletManagerCubit = WalletsManagerCubit();
    pointsManagementCubit = PointsManagementCubit();
    relaysProgressCubit = RelaysProgressCubit();
    suggestionsBoxCubit = SuggestionsBoxCubit();
    contactListCubit = ContactListCubit();
    appSettingsManagerCubit = AppSettingsManagerCubit();
    mediaServersCubit = MediaServersCubit();
    relayInfoCubit = RelayInfoCubit();
    crashlyticsCubit = CrashlyticsCubit();
    videoControllerManagerCubit = VideoControllerManagerCubit();
    routingCubit = RoutingCubit();
    routingCubit.routingViewInit();
  }

  static void _initFeedCubits() {
    discoverCubit = DiscoverCubit();
    leadingCubit = LeadingCubit();
    mediaCubit = MediaCubit();
  }

  /// Setup authentication and signing
  static Future<void> _setupAuthAndSigning() async {
    // Check for external signer
    isExternalSignerInstalled =
        Platform.isAndroid && await Amberflutter().isAppInstalled();

    // Setup user signer if key exists
    final String? key = settingsCubit.key;
    if (StringUtil.isNotBlank(key)) {
      try {
        final isPrivate = settingsCubit.isPrivateKey;
        final publicKey = isPrivate ? Keychain.getPublicKey(key!) : key!;

        if (settingsCubit.isExternalSignerKey && isExternalSignerInstalled) {
          currentSigner = AmberEventSigner(publicKey);
        } else if (settingsCubit.isExternalSignerKey &&
            nostrRepository.remoteSigners[publicKey] != null) {
          currentSigner = nostrRepository.remoteSigners[publicKey];
        } else if (!settingsCubit.isExternalSignerKey) {
          currentSigner = Bip340EventSigner(isPrivate ? key : null, publicKey);
        }

        nc.setSigner(currentSigner);
      } catch (e) {
        if (kDebugMode) {
          print('Signer setup failed: $e');
        }
      }
    }
  }

  /// Initialize relay system
  static Future<void> _initializeRelaySystem() async {
    // Setup default relay list
    final pubkey = currentSigner?.getPublicKey() ?? '';
    UserRelayList? relayList;

    if (pubkey.isNotEmpty) {
      relayList = await nc.db.loadUserRelayList(pubkey);
    }

    currentUserRelayList = relayList ??
        UserRelayList(
          pubkey: currentSigner?.getPublicKey() ?? '',
          relays: {
            for (final String url in DEFAULT_BOOTSTRAP_RELAYS)
              url: ReadWriteMarker.readWrite
          },
          createdAt: Helpers.now,
          refreshedTimestamp: Helpers.now,
        );

    // Load cached data
    nostrRepository.setCurrentAppCustomizationFromCache();
    nostrRepository.setCurrentUserDraft();
    nostrRepository.loadWotConfigurations();
    nostrRepository.loadMediaManager();
    await nostrRepository.routingInitData();
    await appSettingsManagerCubit.loadAppSharedSettings();
    await relayInfoCubit.initRelays();

    // Connect to relays
    if (currentSigner != null) {
      currentUserRelayList.pubkey = currentSigner!.getPublicKey();

      initRelays();
      _scheduleDelayedDataLoading();
    } else {
      nc.connectRelays(currentUserRelayList.urls.toList());
    }
  }

  /// Initialize notifications (critical timing: right after cubits)
  static void _initializeNotifications() {
    LocalNotificationManager.instance.initNotifications();

    notificationsCubit.loadNotifications();
  }

  /// Configure system UI settings
  static void _configureSystemUI() {
    final view = PlatformDispatcher.instance.views.first;
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    final logicalShortestSide = physicalSize.shortestSide / devicePixelRatio;
    final isTablet = logicalShortestSide >= 600;

    if (isTablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 100; // adjust for your feed
    imageCache.maximumSizeBytes = 100 << 20; // 100MB
  }

  /// Start background services
  static void _startBackgroundServices() {
    onStart();
  }

  /// Schedule delayed loading of user data
  static void _scheduleDelayedDataLoading() {
    Future.delayed(const Duration(seconds: 2)).then((_) {
      nostrRepository.loadCurrentUserRelatedData();
      settingsCubit.getYakiHonneApp();
    });
  }

  /// Initialize actions signer
  static void _initializeActionsSigner() {
    final keys = Keychain.generate();
    actionsSigner = Bip340EventSigner(keys.private, keys.public);
  }

  /// Initialize relays with enhanced error handling
  static Future<void> initRelays({bool newKey = false}) async {
    try {
      // Load metadata for existing users
      if (!newKey) {
        nostrRepository.loadCurrentSignerMetadata();
      }

      // Connect to relays
      await nc.connectRelays(currentUserRelayList.urls.toList());

      // Get user relay list for existing users
      if (!newKey) {
        final userRelayList = await nc.getSingleUserRelayList(
          currentSigner!.getPublicKey(),
          forceRefresh: true,
        );
        if (userRelayList != null) {
          currentUserRelayList = userRelayList;
        }
      }

      // Connect to additional relays
      await nc.connectNonConnectedRelays(currentUserRelayList.urls.toSet());

      // Load contact list and setup gossip
      await _setupContactListAndGossip(newKey);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Relay initialization failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Setup contact list and gossip functionality
  static Future<void> _setupContactListAndGossip(bool newKey) async {
    if (newKey) {
      return;
    }

    try {
      if (kDebugMode) {
        print('Loading contact list...');
      }

      final contactList = await nc.loadContactList(
        currentSigner!.getPublicKey(),
        forceRefresh: true,
      );

      if (contactList != null) {
        if (settingsCubit.gossip ?? false) {
          feedRelaySet = await nc.getRelaySet(
            'feed',
            currentSigner!.getPublicKey(),
          );

          if (feedRelaySet == null) {
            feedRelaySet = await nc.calculateRelaySet(
              name: 'feed',
              ownerPubKey: currentSigner!.getPublicKey(),
              pubKeys: contactList.contacts,
              direction: RelayDirection.outbox,
              relayMinCountPerPubKey: 2,
            );

            await nc.saveRelaySet(feedRelaySet!);
          }

          await nc
              .connectNonConnectedRelays(feedRelaySet!.relaysMap.keys.toSet());
        } else {
          if (contactList.contacts.isNotEmpty) {
            nc.loadMissingRelayListsFromNip65OrNip02(contactList.contacts);
          }
        }
      }
    } catch (e, stack) {
      lg.i(stack);
      if (kDebugMode) {
        print('Contact list setup failed: $e');
      }
    }
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static Future<void> onStart() async {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      try {
        nc.relaysAutoReconnect();
      } catch (e) {
        if (kDebugMode) {
          print('Relay reconnection failed: $e');
        }
      }
    });
  }
}
