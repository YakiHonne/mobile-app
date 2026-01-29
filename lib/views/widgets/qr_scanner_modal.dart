// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import 'dotted_container.dart';

class QrScannerModal extends StatefulWidget {
  const QrScannerModal({super.key, required this.onValue});
  final Function(String) onValue;

  @override
  State<QrScannerModal> createState() => _QrScannerModalState();
}

class _QrScannerModalState extends State<QrScannerModal> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrValue;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalBottomSheetAppbar(
            title: context.t.qrCode,
            isBack: false,
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              children: [
                SizedBox(
                  width: 70.w,
                  height: 70.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: (controller) {
                        this.controller = controller;
                        controller.scannedDataStream.listen((scanData) {
                          if (scanData.code != null &&
                              scanData.code!.isNotEmpty &&
                              qrValue == null) {
                            qrValue = scanData.code;
                            YNavigator.pop(context);
                            widget.onValue(scanData.code!);
                          }
                        });
                      },
                      overlay: QrScannerOverlayShape(
                        borderRadius: kDefaultPadding,
                        borderColor: Theme.of(context).primaryColor,
                        borderWidth: 5,
                        cutOutSize: 70.w,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  context.t.scanQrCode.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
