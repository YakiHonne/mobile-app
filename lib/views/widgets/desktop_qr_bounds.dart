import 'package:flutter/material.dart';

/// Keeps a desktop QR square within its locally available width.
class DesktopQrBounds extends StatelessWidget {
  const DesktopQrBounds({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: AspectRatio(aspectRatio: 1, child: child),
      );
}

/// Fits a QR and its label inside a scrollable desktop dialog.
class DesktopQrDialogContent extends StatelessWidget {
  const DesktopQrDialogContent(
      {super.key, required this.qr, required this.label});

  final Widget qr;
  final Widget label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesktopQrBounds(
              child: SizedBox(width: 320, height: 320, child: qr),
            ),
            label,
          ],
        ),
      );
}
