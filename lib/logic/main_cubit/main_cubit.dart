// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:share_handler/share_handler.dart';

// Local imports
import '../../initializers.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/app_models/extended_model.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/article_view/article_view.dart';
import '../../views/curation_view/curation_view.dart';
import '../../views/note_view/note_view.dart';
import '../../views/profile_view/profile_view.dart';
import '../../views/relay_feed_view/relay_feed_view.dart';
import '../../views/smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import '../../views/version_news/app_news_popup.dart';
import '../../views/widgets/received_share_intent.dart';
import '../../views/widgets/video_components/horizontal_video_view.dart';
import '../../views/widgets/video_components/vertical_video_view.dart';

part 'main_state.dart';

class MainCubit extends Cubit<MainState> {
  MainCubit({
    required this.context,
  }) : super(
          MainState(
            mainView: MainViews.leading,
            refresh: false,
            image: nostrRepository.currentMetadata.picture,
            random: '',
            nip05: nostrRepository.currentMetadata.nip05,
            name: nostrRepository.currentMetadata.getName(),
            pubKey: nostrRepository.currentMetadata.pubkey,
            isMyContentShrinked: true,
            isHorizontal: true,
            isConnected: connectivityService.isConnected,
          ),
        ) {
    initView();
    initUniLinks();
    initShareIntent();
    checkCurrentVersionNews();
    _setupSubscriptions();
    walletManagerCubit.init();
  }
  // Dependencies
  final BuildContext context;

  // Stream subscriptions
  late StreamSubscription currentSignerStream;
  late StreamSubscription homeViewSubcription;
  late StreamSubscription connectivityStream;
  StreamSubscription? _deepLinksSub;
  StreamSubscription? _shareIntentSub;

  // Initialization methods
  void _setupSubscriptions() {
    homeViewSubcription = nostrRepository.homeViewStream.listen(
      (bool hasConnection) {
        if (!isClosed) {
          emit(state.copyWith(
            mainView: MainViews.leading,
          ));
        }
      },
    );

    connectivityStream = connectivityService.onConnectivityChanged.listen(
      (bool hasConnection) {
        if (hasConnection) {
          AppInitializer.initRelays();
        }

        emit(state.copyWith(isConnected: hasConnection));
      },
    );

    currentSignerStream = nostrRepository.currentSignerStream.listen(
      (EventSigner? signer) {
        final metadata = nostrRepository.currentMetadata;

        if (!isClosed) {
          if (signer == null) {
            emit(state.copyWith(
              refresh: !state.refresh,
              image: '',
              pubKey: '',
              name: '',
            ));
          } else {
            emit(state.copyWith(
              refresh: !state.refresh,
              image: metadata.picture,
              name: metadata.name,
              nip05: metadata.nip05,
              pubKey: metadata.pubkey,
            ));
          }
        }
      },
    );
  }

  Future<void> initView() async {
    if (currentSigner == null && !isClosed) {
      emit(state.copyWith(
        refresh: !state.refresh,
        image: '',
        pubKey: '',
        name: '',
        nip05: '',
      ));
    }
  }

  Future<void> checkCurrentVersionNews() async {
    final status = localDatabaseRepository.canDisplayVersionNews(appVersion);

    if (status) {
      await Future.delayed(const Duration(seconds: 5)).then(
        (_) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => const AppNewsPopup(),
            );
          }
        },
      );
    }
  }

  // Share intent
  Future<void> initShareIntent() async {
    final handler = ShareHandlerPlatform.instance;
    final media = await handler.getInitialSharedMedia();

    if (_shareIntentSub == null && media != null) {
      openReceivedShareIntent(media);
    }

    _shareIntentSub = handler.sharedMediaStream.listen((SharedMedia media) {
      openReceivedShareIntent(media);
    });
  }

  void openReceivedShareIntent(SharedMedia media) {
    showModalBottomSheet(
      context: context,
      elevation: 0,
      builder: (_) {
        return ReceivedShareIntent(media: media);
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  // Deep linking
  Future<void> initUniLinks() async {
    final appLinks = AppLinks();
    final initial = await appLinks.getLatestLinkString();

    if (_deepLinksSub == null && initial != null) {
      if (!initial.startsWith('nostr+walletconnect') &&
          !initial.contains('yakihonne.com/wallet/alby')) {
        if (initial.contains('njump.me')) {
          handleNostrEntity(initial.split('/').last, '');
        } else {
          forwardView(
            uriString: initial,
            isNostrScheme: initial.startsWith('nostr:'),
            skipDelay: false,
          );
        }
      }
    }

    _deepLinksSub = appLinks.uriLinkStream.listen(
      (Uri uri) => _handleUriLink(uri),
      onError: (err) => Logger().i(err),
    );
  }

  void _handleUriLink(Uri uri) {
    final uriString = uri.toString();

    if (uriString.isNotEmpty) {
      if (uriString.startsWith('nostr+walletconnect')) {
        if (context.mounted) {
          walletManagerCubit.addNwc(uriString);
        }
      } else if (uriString.contains('yakihonne.com/wallet/alby')) {
        if (context.mounted) {
          walletManagerCubit.addAlby(uriString);
        }
      } else {
        forwardView(
          uriString: uriString,
          isNostrScheme: uriString.startsWith('nostr:'),
          skipDelay: false,
        );
      }
    }
  }

  Future<void> forwardView({
    required String uriString,
    required bool isNostrScheme,
    required bool skipDelay,
  }) async {
    if (!skipDelay) {
      await Future.delayed(const Duration(seconds: 2));
    }

    final nostrUri = (isNostrScheme
            ? uriString.split('nostr:').last
            : uriString.split('/').last)
        .trim();

    if (uriString.contains('yakihonne.com/article')) {
      if (nostrUri.startsWith('naddr')) {
        await _handleArticleLink(nostrUri);
      } else {
        await handleNaddrFromNip05(url: uriString);
      }
    } else if (uriString.contains('yakihonne.com/curation')) {
      if (nostrUri.startsWith('naddr')) {
        await _handleCurationLink(nostrUri);
      } else {
        await handleNaddrFromNip05(url: uriString);
      }
    } else if (uriString.contains('yakihonne.com/smart-widget')) {
      if (nostrUri.startsWith('naddr')) {
        await _handleSmartWidgetLink(nostrUri);
      } else {
        await handleNaddrFromNip05(url: uriString);
      }
    } else if (uriString.contains('yakihonne.com/r/discover/') ||
        uriString.contains('yakihonne.com/r/notes/') ||
        uriString.contains('yakihonne.com/r/content/')) {
      final uri = Uri.parse(uriString);
      final relay = uri.queryParameters['r'];

      if (relay != null) {
        YNavigator.pushPage(
          context,
          (context) => RelayFeedView(
            relay: relay,
          ),
        );
      }
    } else {
      await handleNostrEntity(nostrUri, uriString);
    }
  }

  Future<void> handleNaddrFromNip05({
    required String url,
  }) async {
    final splits = url.split('/');

    if (splits.length >= 6) {
      final identifier = splits.last;
      final nip05 = splits[splits.length - 2];
      final type = splits[splits.length - 4];

      final pubkey = await metadataCubit.getNip05Pubkey(nip05);

      if (pubkey != null) {
        final kind = type == 'article'
            ? EventKind.LONG_FORM
            : type == 'curation'
                ? EventKind.CURATION_ARTICLES
                : type == 'video'
                    ? EventKind.VIDEO_HORIZONTAL
                    : EventKind.SMART_WIDGET_ENH;

        final List<int> charCodes = identifier.runes.toList();
        final special = charCodes.map((code) => code.toRadixString(16)).join();

        final naddr = Nip19.encodeShareableEntity(
          'naddr',
          special,
          [],
          pubkey,
          kind,
        );

        if (kind == EventKind.LONG_FORM) {
          await _handleArticleLink(naddr);
          return;
        } else if (kind == EventKind.CURATION_ARTICLES ||
            kind == EventKind.CURATION_VIDEOS) {
          await _handleCurationLink(naddr);
          return;
        } else if (kind == EventKind.VIDEO_HORIZONTAL ||
            kind == EventKind.VIDEO_VERTICAL) {
          await _handleVideoLink(naddr);
          return;
        } else {
          await _handleSmartWidgetLink(naddr);
          return;
        }
      }
    }

    BotToastUtils.showError(gc.t.eventNotFound);
  }

  // Content type handlers
  Future<void> _handleArticleLink(String nostrUri) async {
    String special = '';
    String author = '';
    List<String> relays = [];

    if (nostrUri.startsWith('naddr')) {
      final nostrDecode = Nip19.decodeShareableEntity(nostrUri);

      final hexCode = hex.decode(nostrDecode['special']);
      author = nostrDecode['author'];
      special = String.fromCharCodes(hexCode);
      relays = List<String>.from(nostrDecode['relays']);
    } else {
      special = nostrUri;
    }

    final event = await getForwardedEvent(
      kinds: <int>[EventKind.LONG_FORM],
      identifier: special,
      pubkey: author,
      relays: relays,
    );

    if (event == null) {
      BotToastUtils.showError(context.t.articleNotFound.capitalizeFirst());
    } else if (!isUserMuted(event.pubkey) && context.mounted) {
      final Article article = Article.fromEvent(event);
      Navigator.pushNamed(context, ArticleView.routeName, arguments: article);
    }
  }

  Future<void> _handleCurationLink(String nostrUri) async {
    if (nostrUri == 'curation') {
      updateIndex(MainViews.discover);
      return;
    }

    String author = '';
    String special = '';
    List<String> relays = [];

    if (nostrUri.startsWith('naddr')) {
      final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
      final List<int> hexCode = hex.decode(nostrDecode['special']);
      special = String.fromCharCodes(hexCode);
      author = nostrDecode['author'];
      relays = List<String>.from(nostrDecode['relays']);
    } else {
      special = nostrUri;
    }

    final event = await getForwardedEvent(
      kinds: <int>[EventKind.CURATION_ARTICLES],
      identifier: special,
      pubkey: author,
      relays: relays,
    );

    if (event == null) {
      BotToastUtils.showError(context.t.curationNotFound.capitalizeFirst());
    } else if (!isUserMuted(event.pubkey) && context.mounted) {
      final curation = Curation.fromEvent(event, '');
      Navigator.pushNamed(context, CurationView.routeName, arguments: curation);
    }
  }

  Future<void> _handleSmartWidgetLink(String nostrUri) async {
    String special = '';
    String author = '';
    List<String> relays = [];

    if (nostrUri.startsWith('naddr')) {
      final String naddr = nostrUri.split('?').last.replaceAll('naddr=', '');
      final nostrDecode = Nip19.decodeShareableEntity(naddr);
      final List<int> hexCode = hex.decode(nostrDecode['special']);
      author = nostrDecode['author'];
      special = String.fromCharCodes(hexCode);
      relays = List<String>.from(nostrDecode['relays']);
    } else {
      special = nostrUri;
    }

    final event = await getForwardedEvent(
      kinds: <int>[EventKind.SMART_WIDGET_ENH],
      identifier: special,
      pubkey: author,
      relays: relays,
    );

    if (event == null) {
      BotToastUtils.showError(context.t.smartWidgetNotFound.capitalizeFirst());
    } else if (!isUserMuted(event.pubkey) && context.mounted) {
      final smartWidgetModel = SmartWidget.fromEvent(event);

      Navigator.pushNamed(
        context,
        SmartWidgetChecker.routeName,
        arguments: [
          smartWidgetModel.getNaddr(),
          smartWidgetModel,
          true,
        ],
      );
    }
  }

  Future<void> _handleVideoLink(String nostrUri) async {
    if (nostrUri == 'video') {
      updateIndex(MainViews.discover);
      return;
    }

    String special = '';
    String author = '';
    List<String> relays = [];

    if (nostrUri.startsWith('naddr')) {
      final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
      final List<int> hexCode = hex.decode(nostrDecode['special']);
      special = String.fromCharCodes(hexCode);
      author = nostrDecode['author'];
      relays = List<String>.from(nostrDecode['relays']);
    } else {
      special = nostrUri;
    }

    final event = await getForwardedEvent(
      kinds: <int>[EventKind.VIDEO_HORIZONTAL, EventKind.VIDEO_VERTICAL],
      identifier: special,
      pubkey: author,
      relays: relays,
    );

    if (event == null) {
      BotToastUtils.showError(context.t.videoNotFound.capitalizeFirst());
    } else if (!isUserMuted(event.pubkey) && context.mounted) {
      final VideoModel video = VideoModel.fromEvent(event);
      Navigator.pushNamed(
        context,
        video.kind == EventKind.VIDEO_HORIZONTAL
            ? HorizontalVideoView.routeName
            : VerticalVideoView.routeName,
        arguments: <VideoModel>[video],
      );
    }
  }

  Future<void> handleNostrEntity(String nostrUri, String uriString) async {
    if (nostrUri.startsWith('nprofile') || nostrUri.startsWith('npub1')) {
      await _handleProfile(nostrUri);
    } else if (nostrUri.startsWith('note1')) {
      await _handleNote(nostrUri);
    } else if (nostrUri.startsWith('nevent')) {
      await _handleEvent(nostrUri, uriString);
    } else if (nostrUri.startsWith('naddr')) {
      await _handleAddress(nostrUri);
    } else if (nostrUri == 'uncensored-notes') {
      updateIndex(MainViews.uncensoredNotes);
    }
  }

  Future<void> _handleProfile(String nostrUri) async {
    String pubkey = '';
    List<String> relays = [];

    if (nostrUri.startsWith('nprofile')) {
      final decode = Nip19.decodeShareableEntity(nostrUri);
      pubkey = decode['special'];
      relays = List<String>.from(decode['relays']);
    } else {
      pubkey = Nip19.decodePubkey(nostrUri);
    }

    if (isUserMuted(pubkey)) {
      return;
    }

    final user = await metadataCubit.getCachedMetadata(pubkey);

    if (user != null && context.mounted) {
      Navigator.pushNamed(
        context,
        ProfileView.routeName,
        arguments: [user.pubkey],
      );
    } else {
      final event = await getForwardedEvent(
        kinds: <int>[EventKind.METADATA],
        pubkey: pubkey,
        relays: relays,
      );

      if (event == null) {
        BotToastUtils.showError(context.t.userCannotBeFound.capitalizeFirst());
      } else {
        final newUser = Metadata.fromEvent(event);

        if (newUser != null && context.mounted) {
          metadataCubit.saveMetadata(newUser);
          Navigator.pushNamed(
            context,
            ProfileView.routeName,
            arguments: [newUser.pubkey],
          );
        }
      }
    }
  }

  Future<void> _handleNote(String nostrUri) async {
    final id = Nip19.decodeNote(nostrUri);
    final event = await getForwardedEvent(
        kinds: <int>[EventKind.TEXT_NOTE], identifier: id);

    if (event == null) {
      BotToastUtils.showError(context.t.noteNotFound.capitalizeFirst());
    } else if (!isUserMuted(event.pubkey) && context.mounted) {
      final note = DetailedNoteModel.fromEvent(event);
      Navigator.pushNamed(context, NoteView.routeName, arguments: [note]);
    }
  }

  Future<void> _handleEvent(String nostrUri, String uriString) async {
    final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
    metadataCubit.requestMetadata(nostrDecode['author'] ?? '');

    final ev = await getForwardedEvent(
      kinds: nostrDecode['kind'] != null ? <int>[nostrDecode['kind']] : null,
      identifier: nostrDecode['special'],
      pubkey: nostrDecode['author'],
      relays: nostrDecode['relays'],
    );

    if (ev == null) {
      BotToastUtils.showError(context.t.eventNotFound.capitalizeFirst());
    } else if (!isUserMuted(ev.pubkey) && context.mounted) {
      final event = ExtendedEvent.fromEv(ev);
      if (event.isFlashNews() &&
          uriString.contains('yakihonne.com/uncensored-notes')) {
        final unFlashNews =
            await HttpFunctionsRepository.getUnFlashNews(event.id);
        if (unFlashNews != null) {
          Navigator.pushNamed(
            context,
            UnFlashNewsDetails.routeName,
            arguments: unFlashNews,
          );
        } else {
          BotToastUtils.showError(
            context.t.verifiedNoteNotFound.capitalizeFirst(),
          );
        }
      } else if (event.kind == EventKind.TEXT_NOTE) {
        final note = DetailedNoteModel.fromEvent(event);
        Navigator.pushNamed(context, NoteView.routeName, arguments: [note]);
      } else if (event.kind == EventKind.LONG_FORM) {
        final article = Article.fromEvent(event);
        Navigator.pushNamed(context, ArticleView.routeName, arguments: article);
      } else if (event.kind == EventKind.CURATION_ARTICLES ||
          event.kind == EventKind.CURATION_VIDEOS) {
        final curation = Curation.fromEvent(event, '');

        Navigator.pushNamed(
          context,
          CurationView.routeName,
          arguments: curation,
        );
      } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
          event.kind == EventKind.VIDEO_VERTICAL) {
        final video = VideoModel.fromEvent(event);
        Navigator.pushNamed(
          context,
          video.kind == EventKind.VIDEO_HORIZONTAL
              ? HorizontalVideoView.routeName
              : VerticalVideoView.routeName,
          arguments: [video],
        );
      } else if (event.kind == EventKind.SMART_WIDGET_ENH) {
        final smartWidget = SmartWidget.fromEvent(event);

        YNavigator.pushPage(
          context,
          (context) => SmartWidgetChecker(
            naddr: smartWidget.getNaddr(),
            swm: smartWidget,
            viewMode: true,
          ),
        );
      }
    }
  }

  Future<void> _handleAddress(String nostrUri) async {
    final Map<String, dynamic> nostrDecode =
        Nip19.decodeShareableEntity(nostrUri);
    metadataCubit.requestMetadata(nostrDecode['author'] ?? '');
    final List<int> hexCode = hex.decode(nostrDecode['special']);
    final String special = String.fromCharCodes(hexCode);
    final List<String> relays = List<String>.from(nostrDecode['relays']);

    final event = await getForwardedEvent(
      kinds: nostrDecode['kind'] != null ? <int>[nostrDecode['kind']] : null,
      identifier: special,
      pubkey: nostrDecode['author'],
      relays: relays,
    );

    if (event == null) {
      BotToastUtils.showError(context.t.eventNotFound.capitalizeFirst());
    } else if (!isUserMuted(event.pubkey) && context.mounted) {
      _navigateToContent(event);
    }
  }

  void _navigateToContent(Event event) {
    if (event.kind == EventKind.VIDEO_HORIZONTAL ||
        event.kind == EventKind.VIDEO_VERTICAL) {
      final VideoModel video = VideoModel.fromEvent(event);
      Navigator.pushNamed(
        context,
        video.kind == EventKind.VIDEO_HORIZONTAL
            ? HorizontalVideoView.routeName
            : VerticalVideoView.routeName,
        arguments: <VideoModel>[video],
      );
    } else if (event.kind == EventKind.LONG_FORM) {
      final Article article = Article.fromEvent(event);
      Navigator.pushNamed(context, ArticleView.routeName, arguments: article);
    } else if (event.kind == EventKind.CURATION_ARTICLES ||
        event.kind == EventKind.CURATION_VIDEOS) {
      final Curation curation = Curation.fromEvent(event, '');
      Navigator.pushNamed(context, CurationView.routeName, arguments: curation);
    } else if (event.kind == EventKind.SMART_WIDGET_ENH) {
      final smartWidgetModel = SmartWidget.fromEvent(event);
      Navigator.pushNamed(
        context,
        SmartWidgetChecker.routeName,
        arguments: <Object>[smartWidgetModel.getNaddr(), smartWidgetModel],
      );
    } else {
      BotToastUtils.showError(context.t.eventNotRecognized.capitalizeFirst());
    }
  }

  // Event fetching
  Future<Event?> getForwardEvent({
    List<int>? kinds,
    String? identifier,
    String? author,
    List<String>? relays,
  }) async {
    if (identifier != null) {
      final e = await nc.db.loadEventById(
        identifier,
        kinds != null && isReplaceable(kinds.first),
      );

      if (e != null) {
        return e;
      }
    }

    showInformatinMessage(kinds?.first);

    final isIdentifier =
        identifier != null && kinds != null && isReplaceable(kinds.first);

    final ev = await NostrFunctionsRepository.getEventById(
      isIdentifier: isIdentifier,
      author: author,
      eventId: identifier,
      kinds: kinds,
      relays: relays,
    );

    return ev;
  }

  Future<Event?> getForwardedEvent({
    List<int>? kinds,
    String? identifier,
    String? pubkey,
    List<String>? relays,
  }) async {
    final event = await getForwardEvent(
      author: pubkey,
      identifier: identifier,
      kinds: kinds,
      relays: relays,
    );

    if (event != null) {
      return event;
    }

    if (pubkey != null && pubkey.isNotEmpty) {
      final relayList = await nc.getSingleUserRelayList(pubkey);

      if (relayList != null) {
        final set = relayList.reads.length > 2
            ? relayList.reads.sublist(0, 1).toSet()
            : relayList.reads.toSet();

        if (set.isNotEmpty) {
          BotToastUtils.showInformation(
            context.t.fetchingEventUserRelays.capitalizeFirst(),
          );

          return getForwardEvent(
            author: pubkey,
            identifier: identifier,
            kinds: kinds,
            relays: set.toList(),
          );
        }
      }
    }

    return null;
  }

  void showInformatinMessage(int? kind) {
    String message = '';
    switch (kind) {
      case EventKind.LONG_FORM:
        message = context.t.fetchingArticle.capitalizeFirst();
      case EventKind.CURATION_ARTICLES:
        message = context.t.fetchingCuration.capitalizeFirst();
      case EventKind.CURATION_VIDEOS:
        message = context.t.fetchingCuration.capitalizeFirst();
      case EventKind.VIDEO_HORIZONTAL:
        message = context.t.fetchingVideo.capitalizeFirst();
      case EventKind.VIDEO_VERTICAL:
        message = context.t.fetchingVideo.capitalizeFirst();
      case EventKind.SMART_WIDGET_ENH:
        message = context.t.fetchingSmartWidget.capitalizeFirst();
      case EventKind.TEXT_NOTE:
        message = context.t.fetchingNote.capitalizeFirst();
      case EventKind.METADATA:
        message = context.t.fetchingProfile.capitalizeFirst();
      default:
        message = context.t.fetchingEvent.capitalizeFirst();
    }
    BotToastUtils.showInformation(message);
  }

  // State management
  void toggleVideo() {
    if (!isClosed) {
      emit(state.copyWith(isHorizontal: !state.isHorizontal));
    }
  }

  void toggleMyContentShrink() {
    if (!isClosed) {
      emit(state.copyWith(isMyContentShrinked: !state.isMyContentShrinked));
    }
  }

  void updateIndex(MainViews mainView) {
    notificationsCubit.setNotificationView(mainView == MainViews.notifications);
    dmsCubit.isDmsView = mainView == MainViews.dms;

    if (!isClosed) {
      emit(state.copyWith(mainView: mainView));
    }
  }

  void disconnect() {
    settingsCubit.onLogoutTap(settingsCubit.privateKeyIndex!, onPop: () {});
    if (!isClosed) {
      emit(state.copyWith(
        mainView: MainViews.leading,
        pubKey: '',
      ));
    }
  }

  void setDefault() {
    if (!isClosed) {
      emit(state.copyWith(
        mainView: MainViews.leading,
        pubKey: currentSigner?.getPublicKey() ?? '',
      ));
    }
  }

  @override
  Future<void> close() async {
    await currentSignerStream.cancel();
    await homeViewSubcription.cancel();
    await connectivityStream.cancel();
    await _deepLinksSub?.cancel();
    await _shareIntentSub?.cancel();
    return super.close();
  }
}
