import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/logic/main_cubit/main_cubit.dart';
import 'package:yakihonne/logic/metadata_cubit/metadata_cubit.dart';
import 'package:yakihonne/logic/notifications_cubit/notifications_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';
import 'package:yakihonne/utils/enums.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_more_dialog.dart';
import 'package:yakihonne/views/main_view/widgets/desktop_sidebar.dart';
import 'package:yakihonne/views/main_view/widgets/feature_tour.dart';

class _StubConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [];
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Signer extends Fake implements EventSigner {
  @override
  bool canSign() => true;
}

class _Theme extends Fake implements ThemeCubit {
  @override
  ThemeState get state => ThemeState(
      textScaleFactor: 1,
      mode: AppThemeMode.graphite,
      isFluid: false,
      fluidCards: false,
      glassQuality: GlassQuality.minimal,
      theme: ThemeData.light(),
      primaryColor: Colors.orange);
}

class _Main extends Cubit<MainState> implements MainCubit {
  _Main()
      : super(const MainState(
            mainView: MainViews.leading,
            refresh: false,
            image: '',
            random: '',
            name: '',
            nip05: '',
            pubKey: '',
            isMyContentShrinked: false,
            isCashuWallet: false,
            isHorizontal: false,
            isConnected: true));
  @override
  void updateIndex(MainViews view) => emit(state.copyWith(mainView: view));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Dms extends Cubit<DmsState> implements DmsCubit {
  _Dms()
      : super(const DmsState(
            dmSessionDetails: {},
            isUsingNip44: false,
            index: 0,
            rebuild: false,
            mutes: [],
            isSendingMessage: false,
            selectedTime: 0,
            isLoadingHistory: false,
            dmDataState: DmDataState.enabled,
            pendingEventIds: {}));
  @override
  Future<void> markAllAsRead() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications extends Cubit<NotificationsState>
    implements NotificationsCubit {
  _Notifications()
      : super(const NotificationsState(
            events: [],
            index: 0,
            isRead: false,
            refresh: false,
            isLoading: false));
  var reads = 0;
  @override
  void markRead() {
    reads++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet extends Fake implements WalletsManagerCubit {
  var balanceRequests = 0;
  @override
  void requestBalance() {
    balanceRequests++;
  }
}

class _Core implements NostrCore {
  @override
  final Map<String, int> connectStatus = {};
  @override
  void addConnectStatusListener(ConnectStatusCallBack callback) {}
  @override
  void removeConnectStatusListener(ConnectStatusCallBack callback) {}
  @override
  bool isWebSocketOpen(String url) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    connectivityService = ConnectivityService(
      repository: ConnectivityRepository(
        connectivity: _StubConnectivity(),
      ),
    );
    nc = _Core();
    currentUserRelayList = UserRelayList(
      pubkey: '',
      relays: {},
      createdAt: 0,
      refreshedTimestamp: 0,
    );
  });

  testWidgets('signed-out rail selects destinations and exposes tour targets',
      (tester) async {
    final main = _Main();
    final dms = _Dms();
    final notifications = _Notifications();
    final wallet = _Wallet();
    themeCubit = _Theme();
    currentSigner = null;
    dmsCubit = dms;
    notificationsCubit = notifications;
    walletManagerCubit = wallet;
    addTearDown(main.close);
    addTearDown(dms.close);
    addTearDown(notifications.close);
    var scrolls = 0;
    await tester.pumpWidget(TranslationProvider(
        child: MultiBlocProvider(
      providers: [
        BlocProvider<MainCubit>.value(value: main),
        BlocProvider<DmsCubit>.value(value: dms),
        BlocProvider<NotificationsCubit>.value(value: notifications)
      ],
      child: MaterialApp(
          home: Scaffold(
              body: DesktopSidebar(
                  compact: false, onScrollTop: () => scrolls++))),
    )));
    await tester.pumpAndSettle();
    for (final key in [
      TourKeys.search,
      TourKeys.home,
      TourKeys.media,
      TourKeys.dms,
      TourKeys.notifications,
      TourKeys.wallet,
      TourKeys.create
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(find.byKey(TourKeys.drawer), findsNothing);
    await tester.tap(find.byKey(TourKeys.home));
    expect(scrolls, 1);
    await tester.tap(find.byKey(TourKeys.media));
    await tester.pumpAndSettle();
    expect(main.state.mainView, MainViews.media);
    await tester.tap(find.byKey(TourKeys.notifications));
    await tester.pumpAndSettle();
    expect(main.state.mainView, MainViews.notifications);
    expect(notifications.reads, 1);
    await tester.tap(find.byKey(TourKeys.wallet));
    await tester.pumpAndSettle();
    expect(main.state.mainView, MainViews.wallet);
    expect(wallet.balanceRequests, 1);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Articles'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    await tester.tap(find.text('Articles'));
    await tester.pumpAndSettle();
    expect(main.state.mainView, MainViews.articles);
    expect(tester.takeException(), isNull);
  });
  testWidgets('signed-in More exposes account destinations', (tester) async {
    final main = _Main();
    final dms = _Dms();
    final notifications = _Notifications();
    final metadata = MetadataCubit();
    themeCubit = _Theme();
    currentSigner = _Signer();
    dmsCubit = dms;
    notificationsCubit = notifications;
    walletManagerCubit = _Wallet();
    addTearDown(() => currentSigner = null);
    addTearDown(main.close);
    addTearDown(dms.close);
    addTearDown(notifications.close);
    addTearDown(metadata.close);
    await tester.pumpWidget(TranslationProvider(
        child: MultiBlocProvider(
      providers: [
        BlocProvider<MainCubit>.value(value: main),
        BlocProvider<DmsCubit>.value(value: dms),
        BlocProvider<NotificationsCubit>.value(value: notifications),
        BlocProvider<MetadataCubit>.value(value: metadata)
      ],
      child: MaterialApp(
          home: Scaffold(
              body: DesktopSidebar(compact: false, onScrollTop: () {}))),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(TourKeys.drawer), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    final dialog =
        tester.widget<DesktopMoreDialog>(find.byType(DesktopMoreDialog));
    expect(
        dialog.entries.map((entry) => entry.label),
        containsAll(
            ['Articles', 'Dashboard', 'Pricing', 'Yaki Points', 'Yaki Pro']));
    expect(tester.takeException(), isNull);
  });
}
