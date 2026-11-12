import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_operation_success_view.dart';

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

class _WalletState extends Fake implements WalletsManagerState {
  @override
  String get activeCurrency => 'usd';
}

class _WalletCubit extends Cubit<WalletsManagerState>
    implements WalletsManagerCubit {
  _WalletCubit() : super(_WalletState());

  @override
  double getBtcInFiatFromAmount(int amount) => -1;

  @override
  String getCurrencySymbol() => r'$';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop Cashu result QR fits and its close action is reachable',
      (tester) async {
    themeCubit = _ThemeCubit();
    final wallet = _WalletCubit();
    walletManagerCubit = wallet;
    addTearDown(wallet.close);
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
      child: BlocProvider<WalletsManagerCubit>.value(
        value: wallet,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 350,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
                  child: CashuOperationSuccessView(
                    amount: 0,
                    title: 'Disposable result',
                    token: 'placeholder-not-a-redeemable-token',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final qr = tester.getSize(find.byType(QrImageView));
    expect(qr.width, lessThanOrEqualTo(280));
    expect(qr.height, qr.width);
    final close = find.widgetWithText(TextButton, 'Close');
    await tester.ensureVisible(close);
    await tester.pump();
    expect(
        tester
            .getRect(find.byType(CashuOperationSuccessView))
            .contains(tester.getCenter(close)),
        isTrue);
    expect(tester.takeException(), isNull);
  });
}
