import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import 'package:yakihonne/logic/contact_list_cubit/contact_list_cubit.dart';
import 'package:yakihonne/logic/main_cubit/main_cubit.dart';
import 'package:yakihonne/logic/metadata_cubit/metadata_cubit.dart';
import 'package:yakihonne/logic/relay_info_cubit/relay_info_cubit.dart';
import 'package:yakihonne/logic/subscription_badge_cubit/subscription_badge_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart'
    show prefs;
import 'package:yakihonne/utils/enums.dart';
import 'package:yakihonne/views/main_view/desktop/workspace_base.dart';
import 'package:yakihonne/views/main_view/desktop/workspace_feed.dart';
import 'package:yakihonne/views/main_view/desktop/workspace_sources.dart';
import 'package:yakihonne/views/widgets/fluid_source_filter_row.dart';
import 'package:yakihonne/views/widgets/user_profile_container.dart';

class _ThemeCubit extends Fake implements ThemeCubit {
  @override
  bool get isDark => true;

  @override
  ThemeState get state => ThemeState(
        textScaleFactor: 1,
        mode: AppThemeMode.graphite,
        isFluid: true,
        fluidCards: true,
        glassQuality: GlassQuality.minimal,
        theme: ThemeData.dark(),
        primaryColor: Colors.orange,
      );
}

class _CardThemeCubit extends Cubit<ThemeState> implements ThemeCubit {
  _CardThemeCubit() : super(_ThemeCubit().state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MainCubit extends Cubit<MainState> implements MainCubit {
  _MainCubit()
      : super(const MainState(
          mainView: MainViews.leading,
          refresh: false,
          image: '',
          random: '',
          name: '',
          nip05: '',
          pubKey: '',
          isMyContentShrinked: true,
          isCashuWallet: false,
          isHorizontal: true,
          isConnected: true,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MetadataCubit extends Cubit<MetadataState> implements MetadataCubit {
  _MetadataCubit(Metadata metadata)
      : super(MetadataState(metadataCache: {metadata.pubkey: metadata}));

  @override
  void requestMetadata(String pubkey) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BadgeCubit extends Cubit<SubscriptionBadgeState>
    implements SubscriptionBadgeCubit {
  _BadgeCubit() : super(const SubscriptionBadgeState());

  @override
  Future<void> fetchPlan(String pubkey) async {}
}

void main() {
  setUp(() {
    themeCubit = _ThemeCubit();
  });

  testWidgets('people loading cards adapt to the pane width', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget build(double width) => TranslationProvider(
          child: MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 800,
                child: DesktopWorkspaceBase(
                  onSearch: () {},
                  loading: true,
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(build(520));
    final cards = find.byType(DesktopWorkspaceSkeleton);
    expect(
        tester.getTopLeft(cards.at(0)).dx, tester.getTopLeft(cards.at(1)).dx);
    await tester.pumpWidget(build(900));
    expect(tester.getTopLeft(cards.at(1)).dx,
        greaterThan(tester.getTopLeft(cards.at(0)).dx));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('left and right source containers have the same dimensions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    currentSigner = null;
    final settings = AppSettingsManagerCubit()
      ..appSharedSettings = AppSharedSettings.defaultEmptySettings(pubkey: '');
    appSettingsManagerCubit = settings;
    final refresh = RefreshController();
    await tester.pumpWidget(TranslationProvider(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppSettingsManagerCubit>.value(value: settings),
          BlocProvider<RelayInfoCubit>(create: (_) => RelayInfoCubit()),
        ],
        child: MaterialApp(
          home: Scaffold(body: Builder(builder: (context) {
            gc = context;
            Widget pane(Widget child) => Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      child: child,
                    );
                  }),
                );
            return Row(children: [
              pane(Align(
                alignment: Alignment.topCenter,
                child: FluidSourceFilterRow(
                  viewType: ViewDataTypes.notes,
                  onSourceChanged: () {},
                  refreshController: refresh,
                ),
              )),
              pane(DesktopWorkspaceSources(
                account: '',
                onSearch: () {},
                following: const SizedBox(),
              )),
            ]);
          })),
        ),
      ),
    ));
    final sources = find.byType(FluidSourceContainer);
    expect(sources, findsNWidgets(2));
    expect(tester.getSize(sources.at(1)), tester.getSize(sources.at(0)));
    expect(tester.getSize(sources.at(0)).height, kFluidSourceControlHeight);
    await tester.pumpWidget(const SizedBox.shrink());
    refresh.dispose();
    await settings.close();
  });

  testWidgets('removed source selections fall back to discovery',
      (tester) async {
    for (final removed in ['following_notes', 'bookmarks', 'notifications']) {
      SharedPreferences.setMockInitialValues(
          {'desktop_workspace_source_': removed});
      prefs = await SharedPreferences.getInstance();
      currentSigner = null;
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: DesktopWorkspaceSources(
              account: '',
              onSearch: () {},
              following: const Text('People view'),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Discover'), findsOneWidget);
      expect(tester.getCenter(find.byType(FluidSourceContainer)).dx, 400);
      expect(tester.getSize(find.byType(FluidSourceContainer)).width, 380);
      expect(find.text('Search in Nostr'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('glass source menu stays inside an offset nested pane',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    currentSigner = null;
    const paneKey = Key('right-pane');
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Row(children: [
            const Expanded(child: ColoredBox(color: Colors.blue)),
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  child: SizedBox(
                    key: paneKey,
                    child: Navigator(
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => DesktopWorkspaceSources(
                          account: '',
                          onSearch: () {},
                          following: const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    ));
    final pane = tester.getRect(find.byKey(paneKey));
    await tester.tap(find.byType(FluidSourceContainer));
    await tester.pumpAndSettle();
    final items = find.byType(GlassMenuItem);
    expect(items, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      final item = tester.getRect(items.at(i));
      expect(item.left, greaterThanOrEqualTo(pane.left));
      expect(item.right, lessThanOrEqualTo(pane.right));
    }
    await tester.tap(find.text('Know people').last);
    await tester.pumpAndSettle();
    expect(prefs.getString('desktop_workspace_source_'), 'people');
  });

  testWidgets('content sources can be selected without a signed-in account',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    currentSigner = null;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: DesktopWorkspaceSources(
            account: '',
            onSearch: () {},
            following: const SizedBox(),
          ),
        ),
      ),
    ));
    for (final entry in [('Articles', 'articles'), ('Videos', 'videos')]) {
      await tester.tap(find.byType(FluidSourceContainer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.$1).last);
      await tester.pumpAndSettle();
      expect(prefs.getString('desktop_workspace_source_'), entry.$2);
      expect(find.text('Sign in'), findsOneWidget);
    }
  });

  testWidgets('source switches preserve the underlying scroll position',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'desktop_workspace_source_': 'following'});
    prefs = await SharedPreferences.getInstance();
    final controller = ScrollController();

    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: DesktopWorkspaceSources(
            account: '',
            onSearch: () {},
            following: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemBuilder: (_, index) => SizedBox(
                height: 50,
                child: Text('Person $index'),
              ),
            ),
          ),
        ),
      ),
    ));
    final sourceTop = tester.getTopLeft(find.byType(FluidSourceContainer)).dy;
    expect(tester.getTopLeft(find.byType(ListView)).dy, lessThan(sourceTop));
    controller.jumpTo(600);
    await tester.pump();
    expect(tester.getTopLeft(find.byType(FluidSourceContainer)).dy, sourceTop);
    await tester.tap(find.byType(FluidSourceContainer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FluidSourceContainer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Know people').last);
    await tester.pumpAndSettle();
    expect(controller.offset, 600);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('desktop workspace provides its contact cubit', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'desktop_workspace_source_': 'following'});
    prefs = await SharedPreferences.getInstance();
    final mainCubit = _MainCubit();
    final contacts = ContactListCubit();
    contactListCubit = contacts;
    currentSigner = null;

    await tester.pumpWidget(
      TranslationProvider(
        child: BlocProvider<MainCubit>.value(
          value: mainCubit,
          child: MaterialApp(
            home: Scaffold(body: DesktopWorkspace(onSearch: () {})),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Sign in'), findsOneWidget);
    await tester.tap(find.byType(FluidSourceContainer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();
    expect(find.text('Search in Nostr'), findsOneWidget);
    expect(prefs.getString('desktop_workspace_source_'), 'discover');
    await tester.tap(find.byType(FluidSourceContainer));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Know people').last);
    await tester.pumpAndSettle();
    expect(prefs.getString('desktop_workspace_source_'), 'people');

    await tester.pumpWidget(const SizedBox.shrink());
    expect(contacts.isClosed, isFalse);
    await contacts.close();
    await mainCubit.close();
  });

  testWidgets('following card shows profile identifier and bio',
      (tester) async {
    final metadata = Metadata.fromMap(const {
      'name': 'Alice',
      'nip05': 'alice@example.com',
      'about': 'Building useful things for people.',
      'website': 'https://example.com',
    }, pubkey: 'person');
    final metadataState = _MetadataCubit(metadata);
    final badges = _BadgeCubit();
    final cardTheme = _CardThemeCubit();
    metadataCubit = metadataState;
    subscriptionBadgeCubit = badges;
    var opened = false;
    await tester.pumpWidget(BlocProvider<ThemeCubit>.value(
        value: cardTheme,
        child: BlocProvider<MetadataCubit>.value(
          value: metadataState,
          child: MaterialApp(
            home: Scaffold(
              body: DesktopFollowingPersonCard(
                metadata: metadata,
                onOpen: () => opened = true,
              ),
            ),
          ),
        )));
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('Building useful things for people.'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);
    await tester.tap(find.text('Alice'));
    expect(opened, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await metadataState.close();
    await badges.close();
    await cardTheme.close();
  });

  testWidgets('stats and zap rows use their available desktop width',
      (tester) async {
    final metadata =
        Metadata.fromMap(const {'name': 'Alice'}, pubkey: 'person');
    final metadataState = _MetadataCubit(metadata);
    metadataCubit = metadataState;
    await tester.pumpWidget(TranslationProvider(
      child: BlocProvider<MetadataCubit>.value(
        value: metadataState,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                child: Column(children: [
                  UserNoteStatContainer(
                    pubkey: 'person',
                    currentUserPubKey: 'self',
                    isFollowing: false,
                    isDisabled: false,
                    isPending: false,
                    event: Event.partial(kind: EventKind.REPOST),
                    onClicked: () {},
                  ),
                  UserProfileContainer(
                    pubkey: 'person',
                    currentUserPubKey: 'self',
                    isFollowing: false,
                    isDisabled: false,
                    isPending: false,
                    zaps: 0,
                    onClicked: () {},
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ));
    for (final type in [UserNoteStatContainer, UserProfileContainer]) {
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(type),
            matching: find.byType(Container),
          )
          .first);
      expect(container.padding, EdgeInsets.zero);
      expect(tester.getSize(find.byWidget(container)).width, 500);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await metadataState.close();
  });

  testWidgets('base action opens a page and returns to the same base',
      (tester) async {
    final pane = GlobalKey<NavigatorState>();
    var builds = 0;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Navigator(
            key: pane,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) {
                builds++;
                return DesktopWorkspaceBase(
                  onSearch: () => pane.currentState!.push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('Search page')),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('Search in Nostr'), findsOneWidget);
    await tester.tap(find.text('Search in Nostr'));
    await tester.pumpAndSettle();
    expect(find.text('Search page'), findsOneWidget);
    pane.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Search in Nostr'), findsOneWidget);
    expect(builds, 1);
  });
}
