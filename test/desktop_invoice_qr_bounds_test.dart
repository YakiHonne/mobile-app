import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yakihonne/views/widgets/desktop_qr_bounds.dart';

void main() {
  testWidgets('invoice QR fits local width inside an intrinsic scroll layout',
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
              height: 400,
              child: SingleChildScrollView(
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      DesktopQrBounds(
                        child: QrImageView(data: 'disposable-placeholder'),
                      ),
                      const Text('Amount and status'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(QrImageView));
      expect(size.width, width.clamp(0, 320));
      expect(size.height, size.width);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('desktop QR dialog scrolls in a short window with large text',
      (tester) async {
    tester.view.physicalSize = const Size(380, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              scrollable: true,
              content: DesktopQrDialogContent(
                qr: QrImageView(data: 'disposable-placeholder'),
                label: const Text('Scan this disposable QR code'),
              ),
            ),
          ),
          child: const Text('Open'),
        );
      })),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final qr = tester.getSize(find.byType(QrImageView));
    expect(qr.width, lessThanOrEqualTo(320));
    expect(qr.height, qr.width);
    await tester.ensureVisible(find.text('Scan this disposable QR code'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
