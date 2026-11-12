import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/common/tracker/umami_tracker.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';

class _Analytics extends Fake implements UmamiAnalytics {
  @override
  Future<void> trackEvent({String? screenName}) async {}
}

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
  testWidgets('checker follows the desktop pane width while resizing',
      (tester) async {
    umamiAnalytics = _Analytics();
    themeCubit = _ThemeCubit();
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(320.0);
    addTearDown(width.dispose);
    final checker = SmartWidgetChecker();
    await tester.pumpWidget(TranslationProvider(
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
            child: ValueListenableBuilder<double>(
              valueListenable: width,
              builder: (context, value, child) => SizedBox(
                width: value,
                height: 600,
                child: MediaQuery(
                  data:
                      const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                  child: child!,
                ),
              ),
              child: checker,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    var positions = tester
        .widgetList<AnimatedPositioned>(find.byType(AnimatedPositioned))
        .toList();
    expect(positions, hasLength(2));
    expect(positions.last.left, 320);
    expect(positions.last.width, closeTo(281.6, 0.01));
    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(WidgetCheckerComponent), const Offset(-100, 0));
    await tester.pumpAndSettle();
    positions = tester
        .widgetList<AnimatedPositioned>(find.byType(AnimatedPositioned))
        .toList();
    expect(positions.last.left, 32);
    width.value = 800;
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedPositioned), findsNothing);
    expect(find.byType(WidgetCheckerComponent), findsOneWidget);
    final absorber = find
        .ancestor(
          of: find.byType(WidgetCheckerComponent),
          matching: find.byType(AbsorbPointer),
        )
        .first;
    expect(tester.widget<AbsorbPointer>(absorber).absorbing, isFalse);
    expect(tester.takeException(), isNull);
    width.value = 400;
    await tester.pumpAndSettle();
    positions = tester
        .widgetList<AnimatedPositioned>(find.byType(AnimatedPositioned))
        .toList();
    expect(positions.last.left, 40);
    expect(tester.takeException(), isNull);
  });
}
