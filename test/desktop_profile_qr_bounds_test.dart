import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yakihonne/views/main_view/widgets/profile_share_view.dart';

void main() {
  testWidgets('desktop profile QR stays square while the pane resizes',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget app(double width) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: DesktopProfileQrBounds(
                  child: QrImageView(data: 'disposable'),
                ),
              ),
            ),
          ),
        );
    for (final width in [240.0, 320.0, 500.0]) {
      await tester.pumpWidget(app(width));
      final size = tester.getSize(find.byType(QrImageView));
      expect(size.width, width < 320 ? width : 320);
      expect(size.height, size.width);
      expect(tester.takeException(), isNull);
    }
  });
}
