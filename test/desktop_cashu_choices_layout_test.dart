import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_receive_view.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_send_view.dart';

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
  for (final entry in <(String, Widget, String)>[
    ('send', const CashuSendView(), 'Lightning Network'),
    ('receive', const CashuReceiveView(), 'Deposit'),
  ]) {
    testWidgets('desktop Cashu ${entry.$1} choices scroll in a short dialog',
        (tester) async {
      themeCubit = _ThemeCubit();
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
            home: Scaffold(
                body: Center(
                    child: SizedBox(
          width: 320,
          height: 220,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: entry.$2,
          ),
        )))),
      ));
      await tester.pump();
      final scroll = find.byType(SingleChildScrollView);
      expect(scroll, findsOneWidget);
      final scrollable = tester.state<ScrollableState>(find.descendant(
        of: scroll,
        matching: find.byType(Scrollable),
      ));
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      await tester.drag(scroll, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));
      final target = find.text(entry.$3);
      expect(target, findsOneWidget);
      expect(tester.getRect(scroll).contains(tester.getCenter(target)), isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
