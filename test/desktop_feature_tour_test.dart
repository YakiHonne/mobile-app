import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/main_view/widgets/feature_tour.dart';

void main() {
  testWidgets('tour reveals an offscreen rail target before highlighting it',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BuildContext pageContext;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            pageContext = context;
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 150,
                height: 160,
                child: SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 400),
                    Container(
                        key: TourKeys.home, height: 44, color: Colors.red),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    ));
    final before = tester.getTopLeft(find.byKey(TourKeys.home)).dy;
    expect(before, greaterThan(160));
    showFeatureTour(pageContext);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(seconds: 1));
    final after = tester.getTopLeft(find.byKey(TourKeys.home)).dy;
    expect(after, lessThan(160));
    expect(after, greaterThanOrEqualTo(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
