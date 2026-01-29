// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import 'qr_code_scanner.dart';
import 'send_manual_selection.dart';
import 'send_search_user.dart';
import 'send_using_invoice.dart';
import 'send_using_lightning_address.dart';

class SendMainView extends HookWidget {
  const SendMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.send,
      ),
      body: Column(
        spacing: kDefaultPadding / 4,
        children: [
          const Expanded(
            child: SendManualSelection(),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
              left: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
            ),
            child: Row(
              spacing: kDefaultPadding / 4,
              children: [
                _scan(context),
                _contacts(context),
                _paste(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Expanded _paste(BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () async {
          final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
          final clipboardText = clipboardData?.text;

          if (clipboardText != null &&
              clipboardText.isNotEmpty &&
              context.mounted) {
            final isLnAddress = isLightningAddress(clipboardText);

            if (isLnAddress != null) {
              if (isLnAddress) {
                YNavigator.pushPage(
                  context,
                  (context) => SendUsingLightningAddress(
                    lnLnurl: clipboardText,
                    isManual: false,
                  ),
                );
              } else {
                YNavigator.pushPage(
                  context,
                  (context) => SendUsingInvoice(invoice: clipboardText),
                );
              }
            } else {
              BotToastUtils.showError(
                context.t.useValidPaymentRequest,
              );
            }
          }
        },
        title: context.t.paste,
        icon: FeatureIcons.addNote,
      ),
    );
  }

  Expanded _contacts(BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () {
          YNavigator.pushPage(
            context,
            (context) => const SendByUserSearch(),
          );
        },
        title: context.t.contacts,
        icon: FeatureIcons.user,
      ),
    );
  }

  Expanded _scan(BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () {
          YNavigator.pushPage(
            context,
            (context) => const WalletQrCodeView(),
          );
        },
        title: context.t.scan,
        icon: FeatureIcons.qr,
      ),
    );
  }
}

class SendOptionsButton extends StatelessWidget {
  const SendOptionsButton({
    super.key,
    required this.onClicked,
    required this.title,
    required this.icon,
    this.isLoading,
    this.textColor,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth,
  });

  final Function() onClicked;
  final String title;
  final String icon;
  final bool? isLoading;
  final Color? textColor;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading != null,
      child: Opacity(
        opacity: isLoading != null && !isLoading! ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: () {
            onClicked.call();
            HapticFeedback.mediumImpact();
          },
          behavior: HitTestBehavior.translucent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: backgroundColor ?? Theme.of(context).cardColor,
              border: Border.all(
                color: borderColor ?? Theme.of(context).dividerColor,
                width: borderWidth ?? 0.5,
              ),
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLoading != null && isLoading!
                  ? _loading(context)
                  : _content(context),
            ),
          ),
        ),
      ),
    );
  }

  Column _content(BuildContext context) {
    return Column(
      key: const ValueKey('data'),
      spacing: kDefaultPadding / 4,
      children: [
        SvgPicture.asset(
          icon,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            textColor ?? Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: textColor ?? Theme.of(context).primaryColorDark,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
      ],
    );
  }

  Padding _loading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: SpinKitCircle(
        key: const ValueKey('loading'),
        color: Theme.of(context).primaryColorDark,
        size: 19,
      ),
    );
  }
}
