import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import 'send_using_invoice.dart';
import 'send_using_lightning_address.dart';

class SendManualSelection extends HookWidget {
  const SendManualSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final tec = useTextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: Column(
        spacing: kDefaultPadding / 2,
        children: [
          _lightningAddress(context, tec),
          _next(tec, context),
        ],
      ),
    );
  }

  SizedBox _next(TextEditingController tec, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          final isLnAddress = isLightningAddress(tec.text);

          if (isLnAddress != null) {
            if (isLnAddress) {
              YNavigator.pushReplacement(
                context,
                SendUsingLightningAddress(
                  lnLnurl: tec.text,
                  isManual: true,
                ),
              );
            } else {
              YNavigator.pushReplacement(
                context,
                SendUsingInvoice(invoice: tec.text),
              );
            }
          } else {
            BotToastUtils.showError(
              context.t.useValidPaymentRequest,
            );
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          side: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Text(
          context.t.next.capitalize(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Expanded _lightningAddress(BuildContext context, TextEditingController tec) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kDefaultPadding / 2,
          children: [
            Text(
              context.t.typeManualDesc,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            TextFormField(
              controller: tec,
              autofocus: true,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              decoration: InputDecoration(
                hintText: 'john.doe@yakihonne.com',
                hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).dividerColor,
                    ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
