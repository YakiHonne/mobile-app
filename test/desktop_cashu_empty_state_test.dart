import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_no_wallet.dart';
import 'package:yakihonne/views/widgets/wallet_type_switch.dart';

class _ThemeCubit extends Fake implements ThemeCubit {
  _ThemeCubit({this.fluid = false});

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
    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets('empty wallet fits short pane (fluid: $fluid, $direction)',
          (tester) async {
        themeCubit = _ThemeCubit(fluid: fluid);
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
                    data: const MediaQueryData(
                        textScaler: TextScaler.linear(1.5)),
                    child: Directionality(
                      textDirection: direction,
                      child: const CashuNoWallet(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final size = tester.getSize(find.byType(ExtendedImage));
        expect(size, const Size(160, 160));
        final button = find.byType(TextButton);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        final pane = tester.getRect(find.byType(CashuNoWallet));
        expect(pane.contains(tester.getCenter(button)), isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('both wallet switch labels fit narrow desktop width',
      (tester) async {
    for (final isCashu in [false, true]) {
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: MediaQuery(
                  data:
                      const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                  child: WalletTypeSwitch(isCashu: isCashu, onTap: () {}),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
