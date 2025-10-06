// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/core/nostr_core_repository.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/models/user_drafts.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/remote_event_signer.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../common/notifications/notification_helper.dart';
import '../logic/main_cubit/main_cubit.dart';
import '../models/app_models/app_customization.dart';
import '../models/app_models/diverse_functions.dart';
import '../models/bookmark_list_model.dart';
import '../models/chat_message.dart';
import '../models/filter_status.dart';
import '../models/flash_news_model.dart';
import '../models/media_manager_data.dart';
import '../models/smart_widgets_components.dart';
import '../models/topic.dart';
import '../models/video_model.dart';
import '../models/wallet_model.dart';
import '../models/wot_configuration.dart';
import '../routes/navigator.dart';
import '../utils/bot_toast_util.dart';
import '../utils/topics.dart';
import '../utils/utils.dart';
import '../views/widgets/response_snackbar.dart';
import 'http_functions_repository.dart';
import 'nostr_functions_repository.dart';

class NostrDataRepository {
  // Core dependencies
  late MainCubit mainCubit;
  late FilterStatus filterStatus;

  // Data collections
  Map<String, Map<String, WalletModel>> globalWallets = {};
  Map<String, VideoModel> videos = {};
  Map<String, String> nip04Dms = {};
  Map<String, Set<String>> mutuals = {};
  Map<String, UrlType> registeredUrlType = {};
  Map<String, double> itemHeights = {};
  Map<String, Map<String, String>> currentTranslations = {};
  Map<String, Map<String, String>> dmsDraft = {};
  Map<String, MediaManagerItem> mediaManagerItems = {};
  Map<String, WotConfiguration> wotConfigurations = {};
  Map<String, AppCustomization> appCustomizations = {};
  Map<String, RemoteEventSigner> remoteSigners = {};
  Map<String, dynamic> previewCache = {};
  Map<String, int> defaultZapAmounts = {};
  Map<String, String> defaultReactions = {};
  Map<String, BookmarkListModel> bookmarksLists = {};
  Map<String, Set<String>> loadingBookmarks = {};

  // Lists
  List<String> trending = [];
  List<String> interests = [];
  List<String> dmRelays = [];
  List<Topic> topics = [];
  List<String> userTopics = [];
  List<String> bannedPubkeys = [];
  List<ChatMessage> gptMessages = [];
  List<PendingFlashNews> pendingFlashNews = [];
  List<List<String>> muteListAdditionalData = [];

  // Sets
  Set<String> mutes = {};
  Set<String> unsentEvents = {};
  Set<String> usersMessageNotifications = {};

  // Configuration flags
  bool isCrashlyticsEnabled = true;
  bool isUsingNip44 = true;
  bool showCacheExceedsSize = true;
  bool enableOneTapZap = false;
  bool enableOneTapReaction = false;
  bool delayLeading = true;
  bool wotDataLoaded = false;
  bool isUsingExternalSigner = false;
  bool remoteSignerWebViewOpened = false;

  // Current state
  Metadata currentMetadata = Metadata.empty();
  AppCustomization? currentAppCustomization;
  UserDrafts? userDrafts;
  Timer? draftTimer;

  // Wallet and pricing configuration
  String yakihonneWallet = 'yakihonne_funds@getalby.com';
  num initNotePrice = 21;
  num initRatingPrice = 10;
  num sealedNotePrice = 100;
  num sealedRatingPrice = 90;
  num flashNewsPrice = 800;
  num importantTagPrice = 210;

  // Stream controllers
  final currentSignerController = StreamController<EventSigner?>.broadcast();
  final appCustomizationController =
      StreamController<AppCustomization?>.broadcast();
  final userDraftChangesController = StreamController<bool?>.broadcast();
  final interestsController = StreamController<List<String>>.broadcast();
  final refreshSelfArticlesController = StreamController<bool>.broadcast();
  final homeViewController = StreamController<bool>.broadcast();
  final userTopicsController = StreamController<List<String>>.broadcast();
  final contactListController = StreamController<List<String>>.broadcast();
  final loadingBookmarksController =
      StreamController<Map<String, Set<String>>>.broadcast();
  final bookmarksController =
      StreamController<Map<String, BookmarkListModel>>.broadcast();
  final mutesController = StreamController<Set<String>>.broadcast();

  // Getters
  BuildContext currentContext() => mainCubit.context;

  // Streams
  Stream<EventSigner?> get currentSignerStream =>
      currentSignerController.stream;
  Stream<AppCustomization?> get appCustomizationStream =>
      appCustomizationController.stream;
  Stream<bool?> get userDraftChangesStream => userDraftChangesController.stream;
  Stream<List<String>> get interestsStream => interestsController.stream;
  Stream<bool> get refreshSelfArticlesStream =>
      refreshSelfArticlesController.stream;
  Stream<bool> get homeViewStream => homeViewController.stream;
  Stream<List<String>> get userTopicsStream => userTopicsController.stream;
  Stream<List<String>> get contactListStream => contactListController.stream;
  Stream<Map<String, Set<String>>> get loadingBookmarksStream =>
      loadingBookmarksController.stream;
  Stream<Map<String, BookmarkListModel>> get bookmarksStream =>
      bookmarksController.stream;
  Stream<Set<String>> get mutesStream => mutesController.stream;

  // =============================================================================
  // FILTER STATUS
  // =============================================================================

  void setFilterStatus({required bool isLeading, required bool status}) {
    if (isLeading) {
      filterStatus.leadingFilter = status;
    } else {
      filterStatus.discoverFilter = status;
    }
    localDatabaseRepository.setFilterStatus(fs: filterStatus);
  }

  // =============================================================================
  // WOT (WEB OF TRUST) FUNCTIONALITY
  // =============================================================================

  void handleMuted(String pubkey) {
    if (mutes.contains(pubkey)) {
      mutes.remove(pubkey);
      mutesController.add(mutes);
    } else {
      mutes.add(pubkey);
      mutesController.add(mutes);
    }
  }
  // =============================================================================
  // WOT (WEB OF TRUST) FUNCTIONALITY
  // =============================================================================

  Future<void> loadWotData() async {
    if (canSign()) {
      wotDataLoaded = await nc.buildWotData(
        pubkey: currentSigner!.getPublicKey(),
      );
    }
  }

  void loadWotConfigurations() {
    try {
      final list = localDatabaseRepository.getWotConfigurations();
      wotConfigurations = {for (final item in list) item.pubkey: item};
    } catch (e) {
      lg.i(e);
    }
  }

  WotConfiguration getWotConfiguration(String pubkey) {
    return wotConfigurations[pubkey] ??
        WotConfiguration(
          pubkey: pubkey,
          threshold: 5,
          notifications: false,
          postActions: false,
          privateMessages: false,
        );
  }

  void setWotConfiguration({
    required String pubkey,
    required double threshold,
    required bool notifications,
    required bool postActions,
    required bool privateMessages,
  }) {
    wotConfigurations[pubkey] = WotConfiguration(
      pubkey: pubkey,
      threshold: threshold,
      notifications: notifications,
      postActions: postActions,
      privateMessages: privateMessages,
    );

    localDatabaseRepository
        .setWotConfigurations(wotConfigurations.values.toList());
  }

  // =============================================================================
  // MEDIA MANAGER
  // =============================================================================

  void loadMediaManager() {
    try {
      final list = localDatabaseRepository.getMediaManager();
      mediaManagerItems = {for (final item in list) item.pubkey: item};
    } catch (e) {
      lg.i(e);
    }
  }

  MediaManagerItem getMediaManagerItem(String pubkey) {
    return mediaManagerItems[pubkey] ??
        MediaManagerItem(
          pubkey: pubkey,
          activeRegularServer: MediaServer.nostrBuild.displayName,
          isBlossomEnabled: false,
          isMirroringEnabled: false,
        );
  }

  void setMediaManager({
    required String pubkey,
    required String activeRegularServer,
    required bool isBlossomActive,
    required bool enableMirroring,
  }) {
    mediaManagerItems[pubkey] = MediaManagerItem(
      pubkey: pubkey,
      activeRegularServer: activeRegularServer,
      isBlossomEnabled: isBlossomActive,
      isMirroringEnabled: enableMirroring,
    );

    localDatabaseRepository.setMediaManager(mediaManagerItems.values.toList());
  }

  // =============================================================================
  // DM DRAFTS MANAGEMENT
  // =============================================================================

  Future<void> routingInitData() async {
    getPricing();
    getTopics();
    loadDmsDrafts();
    pointsManagementCubit.getRecentStats();

    final localData = await Future.wait(
      [
        HttpFunctionsRepository.getBannedPubkeys(),
        localDatabaseRepository.getDefaultZapAmount(),
        localDatabaseRepository.getOneTapZap(),
        localDatabaseRepository.getDefaultReactions(),
        localDatabaseRepository.getOneTapReaction(),
      ],
    );

    bannedPubkeys = localData[0] as List<String>? ?? <String>[];

    defaultZapAmounts = Map<String, int>.from(
      localData[1] as Map<String, int>? ?? <String, int>{},
    );

    enableOneTapZap = localData[2] as bool? ?? false;

    defaultReactions = Map<String, String>.from(
      localData[3] as Map<String, String>? ?? <String, String>{},
    );

    enableOneTapReaction = localData[4] as bool? ?? false;

    if (!canSign()) {
      mutes = localDatabaseRepository.getLocalMutes().toSet();
    }
  }
  // =============================================================================
  // DM DRAFTS MANAGEMENT
  // =============================================================================

  Future<void> loadDmsDrafts() async {
    dmsDraft = await localDatabaseRepository.getDmsDrafts();
  }

  String getDmDraft({required String pubkey, required String peer}) {
    return dmsDraft[pubkey]?[peer] ?? '';
  }

  void setDmsDraft({
    required String pubkey,
    required String peer,
    required String draft,
  }) {
    if (dmsDraft[pubkey] == null) {
      dmsDraft[pubkey] = {peer: draft};
    } else {
      dmsDraft[pubkey]![peer] = draft;
    }
    localDatabaseRepository.setDmsDrafts(drafts: dmsDraft);
  }

  void deleteDmDraft({required String pubkey, required String peer}) {
    dmsDraft[pubkey]?.remove(peer);
    localDatabaseRepository.setDmsDrafts(drafts: dmsDraft);
  }

  void deleteDmsDraft({required String pubkey, required String peer}) {
    dmsDraft[pubkey]?.remove(peer);
    localDatabaseRepository.setDmsDrafts(drafts: dmsDraft);
  }

  // =============================================================================
  // CURRENT SIGNER AND METADATA
  // =============================================================================

  void setCurrentSignerState(EventSigner? signer) {
    currentSignerController.add(signer);
  }

  Future<void> loadCurrentSignerMetadata({
    required bool loadCached,
    bool checkAccountStatus = false,
  }) async {
    if (currentSigner == null) {
      currentMetadata = Metadata.empty();
    } else {
      if (loadCached) {
        currentMetadata = await metadataCubit
            .getAvailableMetadata(currentSigner!.getPublicKey());
      } else {
        currentMetadata = await metadataCubit
                .getFutureMetadata(currentSigner!.getPublicKey()) ??
            Metadata.empty().copyWith(pubkey: currentSigner!.getPublicKey());
      }

      await loadCachedMutedList(currentSigner!.getPublicKey());

      if (checkAccountStatus) {
        final index = settingsCubit.privateKeyIndex;

        if (currentMetadata.isDeleted && index != null) {
          if (gc.mounted) {
            showCupertinoAccountDeletedDialogue(
              context: mainCubit.context,
              onClicked: () {
                settingsCubit.onLogoutTap(
                  index,
                  onPop: () {
                    YNavigator.pop(gc);
                  },
                );
              },
            );
          }
        }
      }

      if (currentMetadata.nip05.isNotEmpty) {
        metadataCubit.isNip05Valid(currentMetadata);
      }
    }

    currentSignerController.add(currentSigner);
  }

  Future<void> loadCachedMutedList(String pubkey) async {
    final event = await nc.db.loadEvent(
      pubkey: pubkey,
      kind: EventKind.MUTE_LIST,
    );

    if (event != null) {
      if (event.pTags.isNotEmpty) {
        for (final tag in event.pTags) {
          mutes.add(tag);
          muteListAdditionalData.add([tag]);
        }
      }
    }
  }

  // =============================================================================
  // APP CUSTOMIZATION
  // =============================================================================

  void loadAppCustomization() {
    final ac = localDatabaseRepository.getAppCustomization();

    if (ac.isNotEmpty) {
      for (final a in ac.entries) {
        try {
          appCustomizations[a.key] = AppCustomization.fromJson(a.value);
        } catch (e) {
          lg.i(e);
        }
      }
    }
  }

  Future<void> loadRemoteSigners() async {
    final signers = await localDatabaseRepository.getRemoteSigners();
    if (signers != null) {
      final decoded = List<String>.from(jsonDecode(signers));

      final signersObjects = decoded
          .map(
            (e) => RemoteEventSigner.fromJson(
              jsonString: e,
              nc: nc,
              onAuth: (url, isAuthOpen) {
                launchRemoteSignerAuth(
                  url: url,
                  onDismissed: () {
                    isAuthOpen = false;
                  },
                );
              },
            ),
          )
          .toList();

      remoteSigners = {for (final s in signersObjects) s.publicKey: s};
    }
  }

  Future<void> addRemoteSigner(RemoteEventSigner signer) async {
    remoteSigners[signer.publicKey] = signer;
    final signers = remoteSigners.values.toList();

    localDatabaseRepository.setRemoteSigners(
      jsonEncode(
        signers
            .map(
              (e) => e.toJson(),
            )
            .toList(),
      ),
    );
  }

  void setCurrentAppCustomizationFromCache({bool broadcast = false}) {
    if (canSign()) {
      final pubkey = currentSigner!.getPublicKey();
      final cached = appCustomizations[pubkey];

      if (cached != null) {
        currentAppCustomization = cached;
      } else {
        currentAppCustomization = AppCustomization(pubkey: pubkey);
      }
    } else {
      currentAppCustomization = null;
    }

    if (broadcast) {
      broadcastCurrentAppCustomization();
    }
  }

  void broadcastCurrentAppCustomization() {
    appCustomizationController.sink.add(currentAppCustomization);

    if (currentAppCustomization != null) {
      appCustomizations[currentAppCustomization!.pubkey] =
          currentAppCustomization!;
    }
  }

  void saveAppCustomization() {
    final ac = {
      for (final item in appCustomizations.entries)
        item.key: item.value.toJson()
    };
    localDatabaseRepository.setAppCustomization(ac);
  }

  List<CommonFeedTypes> getLeadingFeedTypes() {
    if (currentAppCustomization != null) {
      final feedTypes = <CommonFeedTypes>{};

      for (final a
          in currentAppCustomization!.leadingFeedCustomization.entries) {
        if (a.value) {
          final l = getCommonFeedType(a.key);
          feedTypes.add(l);
        }
      }

      return feedTypes.isEmpty ? defaultCommenLeadingType : feedTypes.toList();
    } else {
      return [
        CommonFeedTypes.trending,
        CommonFeedTypes.highlights,
        CommonFeedTypes.paid,
        CommonFeedTypes.widgets,
      ];
    }
  }

  bool getLeadingShowSuggestions() {
    return currentAppCustomization?.showLeadingSuggestions ?? true;
  }

  CommonFeedTypes getCommonFeedType(String type) {
    return CommonFeedTypes.values.firstWhere(
      (element) => element.name == type,
      orElse: () => CommonFeedTypes.highlights,
    );
  }

  // UI visibility methods
  void hideFeedSuggestions() {
    if (canSign()) {
      currentAppCustomization?.showLeadingSuggestions = false;
      broadcastCurrentAppCustomization();
      saveAppCustomization();
    }
  }

  void hideTrendingUsers() {
    if (canSign()) {
      currentAppCustomization?.showTrendingUsers = false;
      broadcastCurrentAppCustomization();
      saveAppCustomization();
    }
  }

  void hideRelatedContent() {
    if (canSign()) {
      currentAppCustomization?.showRelatedContent = false;
      broadcastCurrentAppCustomization();
      saveAppCustomization();
    }
  }

  void hideInterests() {
    if (canSign()) {
      currentAppCustomization?.showSuggestedInterests = false;
      broadcastCurrentAppCustomization();
      saveAppCustomization();
    }
  }

  void hideDonations() {
    if (canSign()) {
      currentAppCustomization?.showDonationBox = false;
      broadcastCurrentAppCustomization();
      saveAppCustomization();
    }
  }

  void hideShare() {
    if (canSign()) {
      currentAppCustomization?.showShareBox = false;
      broadcastCurrentAppCustomization();
      saveAppCustomization();
    }
  }

  //
  // =============================================================================
  // USER DRAFTS MANAGEMENT
  // =============================================================================

  Future<void> setCurrentUserDraft() async {
    if (canSign()) {
      final pubkey = currentSigner!.getPublicKey();
      final ud = await nc.db.loadUserDrafts(pubkey);

      if (ud != null) {
        userDrafts = ud;
      } else {
        userDrafts = UserDrafts(
          pubkey: pubkey,
          articleDraft: '',
          noteDraft: '',
          replies: {},
          smartWidgetsDraft: {},
        );

        nc.db.saveUserDrafts(userDrafts!);
      }
    } else {
      userDrafts = null;
    }
  }

  void saveUserDraft() {
    if (draftTimer != null) {
      draftTimer!.cancel();
    }

    draftTimer = Timer(
      const Duration(milliseconds: 500),
      () async {
        nc.db.saveUserDrafts(userDrafts!);
      },
    );
  }

  // Smart widget draft methods
  void saveSmartWidgetDraft({required SWAutoSaveModel swsm}) {
    userDrafts!.smartWidgetsDraft[swsm.id] = swsm.toJson();
    userDraftChangesController.sink.add(true);
    saveUserDraft();
  }

  void deleteSmartWidgetDraft({required String id}) {
    userDrafts!.smartWidgetsDraft.remove(id);
    saveUserDraft();
  }

  // Article draft methods
  void saveArticleDraft({required String article}) {
    userDrafts!.articleDraft = article;
    userDraftChangesController.sink.add(true);
    saveUserDraft();
  }

  void deleteArticleDraft() {
    userDrafts!.articleDraft = '';
    saveUserDraft();
  }

  // Note draft methods
  void saveNote({required String note}) {
    userDrafts!.noteDraft = note;
    userDraftChangesController.sink.add(true);
    saveUserDraft();
  }

  void deleteNoteDraft() {
    userDrafts!.noteDraft = '';
    saveUserDraft();
  }

  // Reply draft methods
  void saveNoteReply({required String note, required String replyId}) {
    userDrafts!.replies[replyId] = note;
    userDraftChangesController.sink.add(true);
    saveUserDraft();
  }

  void deleteNoteReplyDraft({required String id}) {
    userDrafts!.replies.remove(id);
    saveUserDraft();
  }

  // =============================================================================
  // INTERESTS AND TOPICS
  // =============================================================================

  Future<bool> setInterest(String interest) async {
    final updatedInterests = Set<String>.from(interests);

    if (updatedInterests.contains(interest)) {
      updatedInterests.remove(interest);
    } else {
      updatedInterests.add(interest);
    }

    final event = await Event.genEvent(
      kind: EventKind.INTEREST_SET,
      tags: [
        ...updatedInterests.map((e) => ['t', e.toLowerCase()])
      ],
      content: '',
      signer: currentSigner,
    );

    if (event != null) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
        relays: currentUserRelayList.writes,
      );

      if (isSuccessful) {
        setInterestSet(updatedInterests);
        BotToastUtils.showSuccess(
            'Interest list has been updated successfully!');
        return true;
      } else {
        BotToastUtils.showError('Error occurred while sending event');
        return false;
      }
    } else {
      BotToastUtils.showError('Error occurred while generating event');
      return false;
    }
  }

  void setInterestSet(Set<String> interests) {
    this.interests = interests.map((e) => e.toLowerCase()).toList();
    interestsController.sink.add(this.interests);
  }

  void getTopics() {
    topics = topicsFromMaps(topicsDefaultList);
  }

  List<String> getFilteredTopics() {
    final Set<String> suggestions = {};
    for (final topic in nostrRepository.topics) {
      suggestions.addAll([topic.topic, ...topic.subTopics]);
      suggestions.addAll(nostrRepository.userTopics);
    }
    return suggestions.where((element) => !element.contains(' ')).toList();
  }

  Future<void> setTopics(List<String> topics) async {
    userTopics = topics;
    userTopicsController.add(topics);
  }

  // =============================================================================
  // VIDEOS
  // =============================================================================

  List<VideoModel> getVideoSuggestions(String? currentIdentifier) {
    if (videos.isEmpty) {
      return [];
    }
    final filtered = videos.values
        .where((element) => element.id != currentIdentifier)
        .toList();

    return getRandomVideos(list: filtered);
  }

  List<VideoModel> getRandomVideos({required List<VideoModel> list}) {
    List<VideoModel> randomList = [];

    if (list.length >= 3) {
      list.shuffle();
      randomList = list.sublist(0, 3);
    }

    return randomList;
  }

  // =============================================================================
  // BOOKMARKS
  // =============================================================================

  void deleteBookmarkList(String bookmarkIdentifier) {
    bookmarksLists.removeWhere((key, value) => key == bookmarkIdentifier);
    bookmarksController.add(bookmarksLists);
  }

  void addBookmarkList(BookmarkListModel bookmarkListModel) {
    bookmarksLists[bookmarkListModel.identifier] = bookmarkListModel;
    bookmarksController.add(bookmarksLists);
  }

  // =============================================================================
  // GLOBAL WALLETS
  // =============================================================================

  Future<void> loadGlobalWallets() async {
    localDatabaseRepository.getWallets();
  }

  // =============================================================================
  // RELAYS AND NETWORK
  // =============================================================================

  Future<List<String>> getOnlineRelays() async {
    try {
      final response = await HttpFunctionsRepository.get(relaysUrl);
      return List<String>.from(response!['data'] ?? []);
    } catch (e) {
      Logger().i(e);
      return [];
    }
  }

  Future<void> resetRelaysConnection() async {
    await nc.closeConnect(nc.relays());
    await nc.connectRelays(currentUserRelayList.urls.toList());
  }

  // =============================================================================
  // PRICING
  // =============================================================================

  Future<void> getPricing() async {
    try {
      final result = await HttpFunctionsRepository.getRewardsPrices();

      for (final item in result) {
        if (item['kind'] == EventKind.REACTION) {
          initRatingPrice = item['amount'];
        } else if (item['kind'] == EventKind.TEXT_NOTE) {
          initNotePrice = item['uncensored_notes']['amount'];
          flashNewsPrice = item['flash_news']['amount'];
          importantTagPrice = item['flash_news_important_flag']['amount'];
        } else {
          sealedRatingPrice = item['is_rater']['amount'];
          sealedNotePrice = item['is_author']['amount'];
        }
      }
    } catch (e) {
      lg.i(e);
    }
  }

  // =============================================================================
  // CRASHLYTICS
  // =============================================================================

  Future<void> setCurrentCrashlytics() async {
    nostrRepository.isCrashlyticsEnabled =
        localDatabaseRepository.getCrashlyticsDataCollection();
  }

  // =============================================================================
  // INITIALIZATION AND DATA LOADING
  // =============================================================================

  Future<void> loadCurrentUserRelatedData({
    bool checkAccountStatus = false,
  }) async {
    await loadCurrentSignerMetadata(
      loadCached: false,
      checkAccountStatus: checkAccountStatus,
    );

    await Future.wait([
      notificationsCubit.initNotifications(),
      dmsCubit.initDmSessions(),
      mediaServersCubit.init(),
      getCurrentUserRelatedData(),
    ]);
  }

  Future<void> getCurrentUserRelatedData() async {
    final completer = Completer();
    bookmarksLists.clear();
    mutes.clear();
    userTopics.clear();
    dmRelays.clear();

    int kind10000Date = 0;

    NostrFunctionsRepository.getCurrentUserRelatedData().listen(
      (event) {
        if (event.kind == EventKind.CATEGORIZED_BOOKMARK) {
          final bookmark = BookmarkListModel.fromEvent(event);

          final canBeAdded = bookmarksLists[bookmark.identifier] == null ||
              bookmarksLists[bookmark.identifier]!
                      .createdAt
                      .toSecondsSinceEpoch()
                      .compareTo(bookmark.createdAt.toSecondsSinceEpoch()) <
                  1;

          if (canBeAdded) {
            bookmarksLists[bookmark.identifier] = bookmark;
            bookmarksController.add(bookmarksLists);
          }
        } else if (event.kind == EventKind.MUTE_LIST) {
          if (kind10000Date < event.createdAt) {
            muteListAdditionalData.clear();
            kind10000Date = event.createdAt;

            if (event.pTags.isNotEmpty) {
              for (final tag in event.pTags) {
                mutes.add(tag);
                muteListAdditionalData.add([tag]);
              }

              mutesController.add(nostrRepository.mutes);
            }

            nc.db.saveEvent(event);
          }
        } else if (event.kind == EventKind.INTEREST_SET) {
          setInterestSet(interestsFromEvent(event).toSet());
        } else if (event.kind == EventKind.DM_RELAYS) {
          for (final t in event.tags) {
            if (t[0] == 'relay' && t.length > 1 && !dmRelays.contains(t[1])) {
              dmRelays.add(t[1]);
            }
          }
        }
      },
      onDone: () {
        nc.connectRelays(dmRelays);
        dmsCubit.showDmsRelayMessage = dmRelays.isEmpty;
        completer.complete();
      },
    );

    return completer.future;
  }

  // =============================================================================
  // CLEANUP AND LOGOUT
  // =============================================================================

  Future<void> clearData() async {
    if (currentSigner is RemoteEventSigner) {
      NotificationHelper.sharedInstance.logout();
    } else {
      await NotificationHelper.sharedInstance.logout();
    }

    bookmarksLists.clear();
    loadingBookmarks.clear();
    bookmarksController.add({});
    mutes.clear();
    mutes = localDatabaseRepository.getLocalMutes().toSet();
    muteListAdditionalData.clear();
    localDatabaseRepository.removeTopicsStatus();
    localDatabaseRepository.clearPendingFlashNews();
    pointsManagementCubit.logout();
    isUsingExternalSigner = false;
    pendingFlashNews.clear();
    mutesController.add(mutes);
    userTopics.clear();
    gptMessages.clear();
    userTopicsController.add([]);
    contactListCubit.clear();
    notificationsCubit.clear();
    dmsCubit.clear();
    interests = [];
    currentMetadata = Metadata.empty();
    appSettingsManagerCubit.reset();
    relayInfoCubit.clear();

    currentUserRelayList = UserRelayList(
      pubkey: currentSigner?.getPublicKey() ?? '',
      relays: {
        for (final String url in DEFAULT_BOOTSTRAP_RELAYS)
          url: ReadWriteMarker.readWrite
      },
      createdAt: Helpers.now,
      refreshedTimestamp: Helpers.now,
    );

    await resetRelaysConnection();
  }
}
