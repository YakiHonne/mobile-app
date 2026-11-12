import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import 'package:yakihonne/models/wallet_model.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_deposit_view.dart';

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
  Map<String, WalletModel> get wallets => {};
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

class _CashuCubit extends Cubit<CashuWalletManagerState>
    implements CashuWalletManagerCubit {
  _CashuCubit()
      : super(const CashuWalletManagerState(
          activeMint: '',
          balance: 0,
          mints: {},
          walletMints: [],
          activeMintBalance: 0,
          recommendedMints: [],
        ));
  @override
  Future<Map<String, dynamic>?> createDepositQuote(int amount) async =>
      {'invoice': 'placeholder-not-a-payable-invoice', 'quote': 'placeholder'};
  @override
  Future<StreamSubscription?> listenToQuoteStatus(String quoteId, int amount,
          {VoidCallback? onPaid}) async =>
      null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop deposit invoice fits and scrolls in a short dialog',
      (tester) async {
    themeCubit = _ThemeCubit();
    final wallet = _WalletCubit();
    final cashu = _CashuCubit();
    walletManagerCubit = wallet;
    addTearDown(wallet.close);
    addTearDown(cashu.close);
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WalletsManagerCubit>.value(value: wallet),
          BlocProvider<CashuWalletManagerCubit>.value(value: cashu),
        ],
        child: const MaterialApp(
          home: Scaffold(
              body: Center(
                  child: SizedBox(
            width: 320,
            height: 400,
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: CashuDepositView(),
            ),
          ))),
        ),
      ),
    ));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();
    await tester.ensureVisible(find.text('Invoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invoice'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final qr = tester.getSize(find.byType(QrImageView));
    expect(qr.width, lessThanOrEqualTo(260));
    expect(qr.width, qr.height);
    final scroll = find.byType(SingleChildScrollView);
    expect(scroll, findsOneWidget);
    expect(
        tester
            .state<ScrollableState>(
                find.descendant(of: scroll, matching: find.byType(Scrollable)))
            .position
            .maxScrollExtent,
        greaterThan(0));
    await tester.drag(scroll, const Offset(0, -300));
    await tester.pump();
    expect(find.text('Check Payment Status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
