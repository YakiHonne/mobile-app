import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../common/common_regex.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../receive_view/lightning_address_qr_code.dart';
import 'send_using_invoice.dart';
import 'send_using_lightning_address.dart';

class QrCodeView extends StatefulWidget {
  const QrCodeView({super.key});

  @override
  State<QrCodeView> createState() => _QrCodeViewState();
}

class _QrCodeViewState extends State<QrCodeView> with RouteAware {
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
      body: Visibility(
        visible: isVisible,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: Column(
            children: [
              _qrLnBox(),
              BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
                builder: (context, state) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom +
                        kDefaultPadding / 2,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        _receiveButton(context),
                        _sendButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _sendButton(BuildContext context) {
    return Expanded(
      child: AbsorbPointer(
        absorbing: isSending,
        child: Opacity(
          opacity: isSending ? 0.5 : 1,
          child: TextButton(
            onPressed: () {
              setState(() {
                isSending = true;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              side: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Text(
              context.t.send.capitalize(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _receiveButton(BuildContext context) {
    return Expanded(
      child: AbsorbPointer(
        absorbing: !isSending,
        child: Opacity(
          opacity: isSending ? 1 : 0.5,
          child: TextButton(
            onPressed: () {
              setState(() {
                isSending = false;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              side: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Text(
              context.t.receive.capitalize(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _qrLnBox() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isSending
                    ? _qrCodeScan(context)
                    : BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
                        builder: (context, state) {
                          final wallet = state.wallets[state.selectedWalletId];
                          final lightningAddress = wallet?.lud16 ?? 'wallet';

                          return LightningtAddressQrCode(
                            lightningAddress: lightningAddress,
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
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
    controller.scannedDataStream.listen((scanData) {
      final res = scanData.code;

      if (res != null && res.isNotEmpty) {
        if (context.mounted) {
          if (res.toLowerCase().startsWith('lnbc')) {
            if (invoice.isEmpty) {
              invoice = res;

              YNavigator.pushPage(
                context,
                (context) => SendUsingInvoice(invoice: res),
              );
            }
          } else if (res.toLowerCase().startsWith('lnurl') ||
              emailRegExp.hasMatch(res)) {
            if (invoice.isEmpty) {
              invoice = res;

              YNavigator.pushReplacement(
                context,
                SendUsingLightningAddress(
                  lnLnurl: res,
                  isManual: false,
                ),
              );
            }
          }
        }
      }
    });
  }
}
