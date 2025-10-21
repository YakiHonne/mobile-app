import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

class LightningtAddressQrCode extends StatelessWidget {
  const LightningtAddressQrCode({super.key, required this.lightningAddress});

  final String lightningAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kDefaultPadding,
      children: [
        ShareLightningAddress(lightningAddress: lightningAddress),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            HapticFeedback.mediumImpact();
            Clipboard.setData(
              ClipboardData(
                text: lightningAddress,
              ),
            );

            BotToastUtils.showSuccess(
              context.t.lnCopied.capitalizeFirst(),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: kDefaultPadding / 2,
            children: [
              Flexible(
                child: Text(
                  lightningAddress,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SvgPicture.asset(
                FeatureIcons.copy,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

class ShareLightningAddress extends StatelessWidget {
  const ShareLightningAddress({
    super.key,
    required this.lightningAddress,
  });

  final String lightningAddress;

  @override
  Widget build(BuildContext context) {
    lg.i(lightningAddress);
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          _save(context, textStyle),
          _share(context, textStyle),
        ];
      },
      buttonBuilder: (context, showMenu) => GestureDetector(
        onLongPress: showMenu,
        behavior: HitTestBehavior.translucent,
        child: Container(
          width: 65.w,
          height: 65.w,
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            border: Border.all(
              color: Theme.of(context).primaryColorDark,
              width: 5,
            ),
          ),
          child: QrImageView(
            data: lightningAddress,
            dataModuleStyle: QrDataModuleStyle(
              color: Theme.of(context).primaryColorDark,
              dataModuleShape: QrDataModuleShape.circle,
            ),
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
      ),
    );
  }

  PullDownMenuItem _share(BuildContext context, TextStyle? textStyle) {
    return PullDownMenuItem(
      title: context.t.share.capitalizeFirst(),
      onTap: () async {
        getQrImageBytes(
          context: context,
          lightningAddress: lightningAddress,
        ).then(
          (byteData) async {
            if (byteData != null) {
              final image = XFile.fromData(
                byteData.buffer.asUint8List(),
                mimeType: 'image/png',
              );
              await Share.shareXFiles(
                [image],
                subject: "Share YakiHonne's content with the others",
              );
            }
          },
        );
      },
      itemTheme: PullDownMenuItemTheme(
        textStyle: textStyle,
      ),
      iconWidget: SvgPicture.asset(
        FeatureIcons.shareGlobal,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  PullDownMenuItem _save(BuildContext context, TextStyle? textStyle) {
    return PullDownMenuItem(
      title: context.t.save.capitalizeFirst(),
      onTap: () {
        getQrImageBytes(
          context: context,
          lightningAddress: lightningAddress,
        ).then(
          (byteData) {
            if (byteData != null) {
              saveByteDataImage(byteData);
            }
          },
        );
      },
      itemTheme: PullDownMenuItemTheme(
        textStyle: textStyle,
      ),
      iconWidget: SvgPicture.asset(
        FeatureIcons.download,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

Future<ByteData?> getQrImageBytes({
  required BuildContext context,
  required String lightningAddress,
}) async {
  final qrCode = QrCode.fromData(
    data: lightningAddress,
    errorCorrectLevel: QrErrorCorrectLevel.H,
  );

  final qrImage = QrImage(qrCode);

  return qrImage.toImageAsBytes(
    size: 1024,
    decoration: const PrettyQrDecoration(
      background: kWhite,
      shape: PrettyQrRoundedSymbol(),
      image: PrettyQrDecorationImage(
        padding: EdgeInsets.all(kDefaultPadding / 2),
        image: AssetImage(
          Images.logo,
        ),
      ),
    ),
  );
}
