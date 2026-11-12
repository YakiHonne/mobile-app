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
import 'package:yakihonne/views/dm_view/widgets/send_gift_view.dart';
import 'package:yakihonne/views/widgets/desktop_scrollable_form.dart';

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
  String get activeCurrency => 'usd';
}

class _WalletCubit extends Cubit<WalletsManagerState>
    implements WalletsManagerCubit {
  _WalletCubit() : super(_WalletState());
  @override
  Future<void> ensureBtcInFiat() async {}
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
  testWidgets('desktop gift composer fits and retains draft across steps',
      (tester) async {
    themeCubit = _ThemeCubit();
    nostrRepository = _Nostr();
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
        BlocProvider<CashuWalletManagerCubit>.value(value: cashu)
      ],
      child: const MaterialApp(
          home: Scaffold(
              body: Center(
                  child: SizedBox(
        width: 320,
        height: 350,
        child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: SendGiftView(receiverPubkey: 'disposable')),
      )))),
    )));
    await tester.pump();
    final form = find.byType(DesktopScrollableForm);
    expect(form, findsOneWidget);
    final next = find.text('Next');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), 'Disposable draft');
    await tester.pump();
    final previous = find.text('Previous');
    await tester.ensureVisible(previous);
    await tester.pumpAndSettle();
    await tester.tap(previous);
    await tester.pumpAndSettle();
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        'Disposable draft');
    expect(tester.takeException(), isNull);
  });
}
