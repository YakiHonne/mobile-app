import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/points_management_view/widgets/consumable_points_view.dart';

class _ThemeCubit extends Fake implements ThemeCubit {
  _ThemeCubit(this.fluid);
  final bool fluid;

  @override
  ThemeState get state => ThemeState(
        textScaleFactor: 1,
        mode: AppThemeMode.graphite,
        isFluid: fluid,
        fluidCards: false,
        glassQuality: GlassQuality.minimal,
        theme: ThemeData.light(),
        primaryColor: Colors.orange,
      );
}

void main() {
  for (final fluid in [false, true]) {
    testWidgets('points explanation fits short desktop dialog (fluid: $fluid)',
        (tester) async {
      themeCubit = _ThemeCubit(fluid);
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: 2000, name: DESKTOP),
            ],
          ),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 400,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
                  child: ConsumablePointsView(),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
