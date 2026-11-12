import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yakihonne/views/wallet_view/receive_view/lightning_address_qr_code.dart';

void main() {
  testWidgets('lightning address QR stays square within desktop pane',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [240.0, 320.0, 600.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: const ShareLightningAddress(
                lightningAddress: 'fixture@example.invalid',
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // The QR has ten points of padding and a five-point border on each side.
      final size = tester.getSize(find.byType(QrImageView));
      expect(size.width, width.clamp(0, 320) - 30);
      expect(size.height, size.width);
      expect(tester.takeException(), isNull);
    }
  });
}
