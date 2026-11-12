import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/views/add_content_view/related_adding_views/article_widgets/article_image_selector.dart';

class _Signer extends Fake implements EventSigner {
  @override
  String getPublicKey() => 'disposable';
}

class _LocalRepository extends Fake implements LocalDatabaseRepository {
  var links = <String>[];

  @override
  Future<List<String>> getImagesLinks(String pubkey) async => links;
}

class _NostrRepository extends Fake implements NostrDataRepository {}

class _ThemeCubit extends Fake implements ThemeCubit {
  @override
  ThemeState get state => ThemeState(
        textScaleFactor: 1,
        mode: AppThemeMode.graphite,
        isFluid: false,
        fluidCards: false,
        glassQuality: GlassQuality.minimal,
        theme: ThemeData.light(),
        primaryColor: Colors.orange,
      );
}

void main() {
  testWidgets('image selector fits a narrow desktop dialog with large text',
      (tester) async {
    currentSigner = _Signer();
    themeCubit = _ThemeCubit();
    addTearDown(() => currentSigner = null);
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final local = _LocalRepository();
    Widget app(Key key, {double height = 620, double scale = 1.5}) =>
        TranslationProvider(
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LocalDatabaseRepository>.value(value: local),
              RepositoryProvider<NostrDataRepository>.value(
                  value: _NostrRepository()),
            ],
            child: MaterialApp(
              builder: (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: const [
                  Breakpoint(start: 0, end: 450, name: MOBILE),
                  Breakpoint(start: 451, end: 2000, name: DESKTOP),
                ],
              ),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 320,
                    height: height,
                    child: MediaQuery(
                      data:
                          MediaQueryData(textScaler: TextScaler.linear(scale)),
                      child: ImageSelector(key: key, onTap: (_, {imeta}) {}),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(app(const ValueKey('empty')));
    await tester.pumpAndSettle();
    expect(find.text('No images history has been found'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Container && widget.constraints?.maxHeight == 180),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    local.links = ['', '', ''];
    await tester.pumpWidget(app(const ValueKey('history')));
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(tester.takeException(), isNull);
    await tester
        .pumpWidget(app(const ValueKey('short'), height: 350, scale: 2));
    await tester.pumpAndSettle();
    final upload = find.text('Upload & use');
    expect(upload, findsOneWidget);
    final button = find.ancestor(of: upload, matching: find.byType(TextButton));
    expect(
        tester.getSize(button).height, greaterThan(kBottomNavigationBarHeight));
    expect(tester.getRect(upload).bottom,
        lessThanOrEqualTo(tester.getRect(button).bottom));
    expect(tester.getRect(upload).right,
        lessThanOrEqualTo(tester.getRect(button).right));
    expect(tester.takeException(), isNull);
  });
}
