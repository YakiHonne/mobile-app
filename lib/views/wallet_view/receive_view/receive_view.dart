import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/fluid_scaffold.dart';
import '../send_view/send_main_view.dart';
import '../send_view/send_using_invoice.dart';
import 'lightning_address_qr_code.dart';
import 'receive_generate_invoice.dart';

class ReceiveMainView extends HookWidget {
  const ReceiveMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        final wallet = state.wallets[state.selectedWalletId];
        final walletId = wallet?.lud16 ?? 'wallet';

        return FluidScaffold(
          title: context.t.receive.capitalizeFirst(),
          body: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Column(
              children: [
                SizedBox(height: fluidScaffoldTopInset(context)),
                Expanded(
                  child: LightningtAddressQrCode(
                    lightningAddress: walletId,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    spacing: kDefaultPadding / 4,
                    children: [
                      const InternalWalletSelector(),
                      _actionsRow(context, walletId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Row _actionsRow(BuildContext context, String walletId) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: SendOptionsButton(
            onClicked: () {
              YNavigator.pushReplacement(
                context,
                const ReceiveGenerateInvoice(),
              );
            },
            title: context.t.invoice,
            icon: FeatureIcons.zapFilled,
          ),
        ),
        Expanded(
          child: SendOptionsButton(
            onClicked: () {
              getQrImageBytes(
                context: context,
                lightningAddress: walletId,
              ).then(
                (byteData) async {
                  if (byteData != null) {
                    final image = XFile.fromData(
                      byteData.buffer.asUint8List(),
                      mimeType: 'image/png',
                    );
                    await shareContent(
                      files: [image],
                      subject: "Share YakiHonne's content with the others",
                    );
                  }
                },
              );
            },
            title: context.t.share,
            icon: FeatureIcons.shareGlobal,
          ),
        ),
      ],
    );
  }
}
