import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_restore_proofs.dart';

class _ThemeCubit extends Fake implements ThemeCubit {
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

void main() {
  testWidgets(
      'desktop restore fields fit and retain placeholder while resizing',
      (tester) async {
    themeCubit = _ThemeCubit();
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(320.0);
    addTearDown(width.dispose);
    await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
            home: Scaffold(
                body: Center(
      child: ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, child) =>
            SizedBox(width: value, height: 500, child: child),
        child: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: CashuRestoreProofs(mintUrl: 'fixture.invalid')),
      ),
    )))));
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    final grid = find.byType(GridView);
    SliverGridDelegateWithFixedCrossAxisCount delegate() =>
        tester.widget<GridView>(grid).gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate().crossAxisCount, 1);
    final field = find.byType(TextFormField).first;
    await tester.ensureVisible(field);
    await tester.enterText(field, 'placeholder');
    await tester.pump();
    width.value = 700;
    await tester.pump();
    expect(delegate().crossAxisCount, 3);
    expect(tester.widget<TextFormField>(field).controller!.text, 'placeholder');
    expect(tester.takeException(), isNull);
  });
}
