import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/wallet_view/redeem_code_view/redeem_code_result.dart';
import 'package:yakihonne/views/wallet_view/send_zaps_view/send_zaps_results.dart';

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
  for (final entry in <(String, Widget)>[
    (
      'zap',
      SendZapsResult(onSwitchToSend: () {}, data: const {
        'success': false,
        'message':
            'A disposable error message that is deliberately long enough to wrap across multiple lines.'
      })
    ),
    (
      'redeem',
      RedeemCodeResults(
          onSwitchToOptions: () {},
          data: const {'status': false, 'resultCode': 'codeNotFound'})
    ),
    (
      'successful zap',
      SendZapsResult(onSwitchToSend: () {}, data: const {'success': true})
    ),
    (
      'successful redeem',
      RedeemCodeResults(
          onSwitchToOptions: () {},
          data: const {'status': true, 'resultCode': 'codeRedeemed'})
    ),
  ]) {
    testWidgets('desktop ${entry.$1} result fits short dialog', (tester) async {
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
                height: 300,
                child: MediaQuery(
                    data:
                        const MediaQueryData(textScaler: TextScaler.linear(2)),
                    child: entry.$2))),
      ))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
