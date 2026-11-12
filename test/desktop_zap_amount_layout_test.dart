import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/enums.dart';
import 'package:yakihonne/views/wallet_view/send_zaps_view/send_amount_set.dart';

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

class _Nostr extends Fake implements NostrDataRepository {
  @override
  Metadata get currentMetadata => Metadata.empty();
}

class _WalletState extends Fake implements WalletsManagerState {
  @override
  bool get hasWallets => false;
  @override
  bool get areInvoicesAvailable => false;
  @override
  String get activeCurrency => 'usd';
}

class _WalletCubit extends Cubit<WalletsManagerState>
    implements WalletsManagerCubit {
  _WalletCubit() : super(_WalletState());
  @override
  double getBtcInFiatFromAmount(int amount) => 0;
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
            recommendedMints: []));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop zap amount form fits short dialog at double text size',
      (tester) async {
    themeCubit = _ThemeCubit();
    nostrRepository = _Nostr();
    final wallet = _WalletCubit();
    final cashu = _CashuCubit();
    walletManagerCubit = wallet;
    addTearDown(wallet.close);
    addTearDown(cashu.close);
    final method = ValueNotifier(ZapPaymentMethod.internal);
    addTearDown(method.dispose);
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
            child: MaterialApp(
                home: Scaffold(
                    body: Center(
                        child: SizedBox(
              width: 320,
              height: 300,
              child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: SendAmountSet(
                      metadata: Metadata.empty(),
                      isZapSplit: false,
                      zapSplits: const [],
                      zapPaymentMethod: method,
                      lockAmount: true,
                      onSuccess: (_) {},
                      onFailure: (_) {},
                      onInvoiceGenerated: (_) {})),
            )))))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
