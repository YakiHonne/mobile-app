import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/contact_list_cubit/contact_list_cubit.dart';
import 'package:yakihonne/logic/share_content_cubit/share_content_cubit.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/views/widgets/content_zap_splits.dart';
import 'package:yakihonne/views/widgets/qr_scanner_modal.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

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

class _ContactListCubit extends Fake implements ContactListCubit {
  @override
  Set<String> getRandomPubkeys({required int number}) => {};
}

void main() {
  testWidgets('shared desktop dialog content fits a narrow pane',
      (tester) async {
    themeCubit = _ThemeCubit();
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
        TranslationProvider(
          child: MaterialApp(
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 2000, name: DESKTOP),
              ],
            ),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  height: 500,
                  child: MediaQuery(
                    data: const MediaQueryData(
                        textScaler: TextScaler.linear(1.5)),
                    child:
                        Directionality(textDirection: direction, child: child),
                  ),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(app(QrScannerModal(onValue: (_) {})));
    await tester.pumpAndSettle();
    expect(find.textContaining('QR scanning is unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);

    var enabled = false;
    await tester.pumpWidget(app(ContentZapSplits(
      kind: 'article',
      zaps: const [],
      isZapSplitEnabled: false,
      onToggleZapSplit: () => enabled = true,
      onAddZapSplitUser: (_) {},
      onRemoveZapSplitUser: (_) {},
      onSetZapProportions: (_, __, ___) {},
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    expect(enabled, isTrue);
    expect(tester.takeException(), isNull);

    contactListCubit = _ContactListCubit();
    final cubit =
        ShareContentCubit(color: Colors.black, url: 'https://example.com');
    final controller = ScrollController();
    await tester.pumpWidget(app(BlocProvider.value(
      value: cubit,
      child: ShareQrCode(url: 'https://example.com', controller: controller),
    )));
    await tester.pumpAndSettle();
    final qrSize = tester.getSize(find.byType(QrImageView));
    expect(qrSize.width, lessThanOrEqualTo(280));
    expect(qrSize.height, qrSize.width);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(
      BlocProvider.value(
        value: cubit,
        child: ShareQrCode(url: 'https://example.com', controller: controller),
      ),
      direction: TextDirection.rtl,
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(QrImageView)).width, qrSize.width);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await cubit.close();
  });
}
