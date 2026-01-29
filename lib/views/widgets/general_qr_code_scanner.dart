import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import 'custom_app_bar.dart';

class GeneralQrCodeView extends StatefulWidget {
  const GeneralQrCodeView({super.key, required this.onValue});
  final Function(String) onValue;

  @override
  State<GeneralQrCodeView> createState() => _GeneralQrCodeViewState();
}

class _GeneralQrCodeViewState extends State<GeneralQrCodeView> with RouteAware {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String invoice = '';
  bool isVisible = true;
  bool isSending = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final m = ModalRoute.of(context)!;

    if (m is PageRoute) {
      routeObserver.subscribe(this, m);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    setState(() {
      isVisible = false;
      invoice = '';
    });
  }

  @override
  void didPopNext() {
    setState(() {
      isVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: context.t.qrCode,
        ),
        body: _qrCodeScan(context));
  }

  Column _qrCodeScan(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80.w,
          height: 80.w,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              kDefaultPadding + 5,
            ),
            child: QRView(
              key: qrKey,
              onQRViewCreated: (controller) => _onQRViewCreated(
                controller,
                context,
              ),
              overlay: QrScannerOverlayShape(
                borderRadius: kDefaultPadding,
                borderColor: kWhite,
                borderWidth: 5,
                cutOutSize: 80.w,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Center(
          child: Text(
            context.t.scanQrCode.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: kWhite,
                ),
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller, BuildContext context) {
    this.controller = controller;
    controller.scannedDataStream.listen(
      (scanData) {
        final res = scanData.code;

        if (res != null && res.isNotEmpty) {
          if (context.mounted) {
            widget.onValue(res);
            YNavigator.pop(context);
          }
        }
      },
    );
  }
}
