import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import 'package:yakihonne/models/wallet_model.dart';
import 'package:yakihonne/views/wallet_view/redeem_code_view/redeem_code_options.dart';
import 'package:yakihonne/views/wallet_view/send_view/qr_code_scanner.dart';

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

class _WalletState extends Fake implements WalletsManagerState {
  @override
  Map<String, WalletModel> get wallets => {};
  @override
  String get selectedWalletId => '';
}

class _WalletCubit extends Cubit<WalletsManagerState>
    implements WalletsManagerCubit {
  _WalletCubit() : super(_WalletState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('wallet scanner fallback fits a narrow desktop pane',
      (tester) async {
    themeCubit = _ThemeCubit();
    final wallet = _WalletCubit();
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
        height: 400,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: WalletQrCodeView(),
        ),
      )))),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('QR scanning is unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('redeem scanner fallback fits without accessing a camera',
      (tester) async {
    themeCubit = _ThemeCubit();
    final wallet = _WalletCubit();
    addTearDown(wallet.close);
    final isQr = ValueNotifier(true);
    final code = ValueNotifier('');
    final controller = TextEditingController();
    addTearDown(isQr.dispose);
    addTearDown(code.dispose);
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
        child: BlocProvider<WalletsManagerCubit>.value(
      value: wallet,
      child: MaterialApp(
          home: Scaffold(
              body: Center(
                  child: SizedBox(
        width: 320,
        height: 500,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: RedeemCodeOptions(
              isQrCode: isQr,
              code: code,
              onRedeem: () {},
              redeemCode: controller),
        ),
      )))),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('QR scanning is unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
