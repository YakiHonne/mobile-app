// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../utils/utils.dart';
import '../send_view/send_main_view.dart';
import '../send_view/send_using_invoice.dart';

class RedeemCodeOptions extends HookWidget {
  const RedeemCodeOptions({
    super.key,
    required this.isQrCode,
    required this.code,
    required this.onRedeem,
    required this.redeemCode,
  });

  final ValueNotifier<bool> isQrCode;
  final ValueNotifier<String> code;
  final Function() onRedeem;
  final TextEditingController redeemCode;

  @override
  Widget build(BuildContext context) {
    final qrKey = useMemoized(() => GlobalKey(debugLabel: 'QR'));
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final controller = useState<QRViewController?>(null);

    useEffect(() {
      return () {
        controller.value?.dispose();
      };
    }, const []);

    return Column(
      children: [
        Text(
          context.t.redeemAndEarn,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 3,
        ),
        Text(
          context.t.redeemCodeMessage,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: isQrCode.value
              ? _qrCodeScan(
                  context: context,
                  qrKey: qrKey,
                  controllerState: controller,
                  code: code,
                )
              : _codeTextfield(
                  context: context,
                  code: code,
                  formKey: formKey,
                ),
        ),
        _buildActionSection(
          context: context,
          isQrCode: isQrCode,
        )
      ],
    );
  }

  Widget _codeTextfield({
    required BuildContext context,
    required ValueNotifier<String> code,
    required GlobalKey<FormState> formKey,
  }) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: redeemCode,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: context.t.redeemCodeDesc,
            ),
            onChanged: (value) {
              code.value = value;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.t.redeemCodeRequired;
              }
              if (!value.startsWith('YR-')) {
                return context.t.redeemCodeInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: kDefaultPadding / 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  onRedeem();
                }
              },
              child: Text(context.t.redeemCode),
            ),
          ),
        ],
      ),
    );
  }

  Column _qrCodeScan({
    required BuildContext context,
    required GlobalKey<State<StatefulWidget>> qrKey,
    required ValueNotifier<QRViewController?> controllerState,
    required ValueNotifier<String> code,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(kDefaultPadding + 5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              kDefaultPadding + 5,
            ),
            child: QRView(
              key: qrKey,
              onQRViewCreated: (controller) => _onQRViewCreated(
                controller: controller,
                context: context,
                controllerState: controllerState,
                code: code,
              ),
              overlay: QrScannerOverlayShape(
                borderRadius: kDefaultPadding,
                borderColor: kTransparent,
                borderWidth: 5,
                overlayColor: kTransparent,
                cutOutSize: 80.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated({
    required QRViewController controller,
    required ValueNotifier<QRViewController?> controllerState,
    required BuildContext context,
    required ValueNotifier<String> code,
  }) {
    controllerState.value = controller;
    controller.scannedDataStream.listen(
      (scanData) {
        final res = scanData.code;

        final setCode = res != null &&
            res.isNotEmpty &&
            res.startsWith('YR-') &&
            code.value.isEmpty;

        if (setCode) {
          code.value = res;
          onRedeem();
        }
      },
    );
  }

  Widget _buildActionSection({
    required BuildContext context,
    required ValueNotifier<bool> isQrCode,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
      ),
      child: Column(
        children: [
          Text(
            context.t.selectReceivingWallet,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(height: kDefaultPadding / 3),
          const InternalWalletSelector(),
          const SizedBox(height: kDefaultPadding / 4),
          Row(
            spacing: kDefaultPadding / 4,
            children: [
              Expanded(
                child: SendOptionsButton(
                  onClicked: () {
                    isQrCode.value = true;
                  },
                  title: context.t.scanCode,
                  icon: FeatureIcons.qr,
                  borderColor: isQrCode.value ? kMainColor : null,
                ),
              ),
              Expanded(
                child: SendOptionsButton(
                  onClicked: () {
                    isQrCode.value = false;
                  },
                  title: context.t.enterCode,
                  icon: FeatureIcons.codeText,
                  borderColor: !isQrCode.value ? kMainColor : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
