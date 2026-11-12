import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nostr_core_enhanced/cashu/models/cashu_encoded_token.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yakihonne/common/functions/functions_set.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_token_details_view.dart';
import 'package:yakihonne/views/wallet_view/send_view/send_main_view.dart';

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
  testWidgets('desktop token QR fits its dialog and stays square',
      (tester) async {
    themeCubit = _ThemeCubit();
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final token = CashuEncodedToken(
      encodedToken: 'disposable-placeholder-not-a-cashu-token',
      amount: 0,
      mint: 'https://example.invalid',
      createdAt: 0,
    );
    for (final width in [240.0, 320.0, 600.0]) {
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                  child: CashuTokenDetailsView(token: token, onRefresh: () {}),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final qr = tester.getSize(find.byType(QrImageView));
      expect(qr.width, (width - 81).clamp(0, 320));
      expect(qr.height, qr.width);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('token dialog fits a short desktop window at large text',
      (tester) async {
    themeCubit = _ThemeCubit();
    tester.view.physicalSize = const Size(600, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final token = CashuEncodedToken(
      encodedToken: 'disposable-placeholder-not-a-cashu-token',
      amount: 0,
      mint: 'https://example.invalid',
      createdAt: 0,
    );
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => showAdaptiveModal<void>(
              context,
              builder: (_) => CashuTokenDetailsView(
                token: token,
                onRefresh: () {},
              ),
            ),
            child: const Text('Open'),
          );
        })),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    final action = find.byType(SendOptionsButton).last;
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(tester.getRect(action).bottom, lessThanOrEqualTo(490));
    expect(tester.takeException(), isNull);
  });
}
