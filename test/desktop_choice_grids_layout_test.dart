import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import 'package:yakihonne/views/settings_view/widgets/property_appearance.dart';
import 'package:yakihonne/views/wallet_view/widgets/external_wallets_list_view.dart';

class _ThemeCubit extends Cubit<ThemeState> implements ThemeCubit {
  _ThemeCubit()
      : super(ThemeState(
            textScaleFactor: 1,
            mode: AppThemeMode.graphite,
            isFluid: false,
            fluidCards: false,
            glassQuality: GlassQuality.minimal,
            theme: ThemeData.light(),
            primaryColor: Colors.orange));
  @override
  bool checkThemeDarkness(AppThemeMode mode) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WalletState extends Fake implements WalletsManagerState {
  @override
  bool get useDefaultWallet => false;
  @override
  String get defaultExternalWallet => 'satoshi';
}

class _WalletCubit extends Cubit<WalletsManagerState>
    implements WalletsManagerCubit {
  _WalletCubit() : super(_WalletState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop appearance choices fit narrow pane at double text size',
      (tester) async {
    final theme = _ThemeCubit();
    themeCubit = theme;
    addTearDown(theme.close);
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TranslationProvider(
        child: BlocProvider<ThemeCubit>.value(
      value: theme,
      child: const MaterialApp(
          home: Scaffold(
              body: Center(
                  child: SizedBox(
        width: 320,
        height: 400,
        child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SingleChildScrollView(
                child:
                    Column(children: [GlassQualityBox(), AppThemeModeBox()]))),
      )))),
    )));
    await tester.pumpAndSettle();
    final grids = tester.widgetList<GridView>(find.byType(GridView)).toList();
    expect(grids, hasLength(2));
    for (final grid in grids) {
      expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          1);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop wallet choices scroll in a narrow short dialog',
      (tester) async {
    final theme = _ThemeCubit();
    final wallet = _WalletCubit();
    themeCubit = theme;
    walletManagerCubit = wallet;
    addTearDown(theme.close);
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
            child: ExternalWalletsListView()),
      )))),
    )));
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        1);
    final scroll = find.byType(SingleChildScrollView).first;
    await tester.drag(scroll, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
