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
import 'package:yakihonne/models/wallet_model.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_deposit_view.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_nutzap_amount_view.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_pay_view.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_send_ecash_view.dart';
import 'package:yakihonne/views/wallet_cashu_view/widgets/cashu_swap_view.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const recipient = Metadata(
  pubkey: 'disposable',
  name: 'Fixture',
  displayName: 'Fixture',
  picture: '',
  banner: '',
  website: '',
  about: '',
  nip05: '',
  lud16: '',
  lud06: '',
  createdAt: 0,
  isDeleted: false,
);

void main() {
  for (final entry in <(String, Widget)>[
    ('pay', const CashuPayView()),
    ('deposit', const CashuDepositView()),
    ('send', const CashuSendECashView()),
    ('swap', const CashuSwapView()),
    ('nutzap', const CashuNutZapAmountView(metadata: recipient)),
  ]) {
    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      for (final scale in [1.5, 2.0]) {
        testWidgets(
            'desktop ${entry.$1} form scrolls at ${scale}x in $direction',
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
              child: MaterialApp(
                  home: Scaffold(
                      body: Center(
                          child: SizedBox(
                width: 320,
                height: 350,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child:
                      Directionality(textDirection: direction, child: entry.$2),
                ),
              )))),
            ),
          ));
          await tester.pump();
          final form = find.byType(DesktopScrollableForm);
          final scroll = find
              .descendant(
                  of: form, matching: find.byType(SingleChildScrollView))
              .first;
          final state = tester.state<ScrollableState>(find
              .descendant(of: scroll, matching: find.byType(Scrollable))
              .first);
          expect(state.position.maxScrollExtent, greaterThan(0));
          final field = find.byType(TextField).first;
          await tester.ensureVisible(field);
          await tester.enterText(
              field, entry.$1 == 'pay' ? 'fixture@example.test' : '1');
          await tester.pump();
          await tester.drag(scroll, const Offset(0, -1500));
          await tester.pumpAndSettle();
          expect(state.position.pixels, greaterThan(0));
          final cancel = find.text('Cancel');
          expect(cancel, findsOneWidget);
          expect(tester.getRect(scroll).contains(tester.getCenter(cancel)),
              isTrue);
          if (entry.$1 == 'pay') {
            await tester.tap(find.text('Next'));
            await tester.pumpAndSettle();
            final amount = find.byType(TextField).first;
            await tester.ensureVisible(amount);
            await tester.enterText(amount, '1');
            await tester.pump();
            expect(tester.widget<TextField>(amount).controller!.text, '1');
          } else {
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            expect(tester.widget<TextField>(field).controller!.text, '1');
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
