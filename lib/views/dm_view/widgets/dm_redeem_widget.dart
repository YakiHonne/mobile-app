import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../utils/utils.dart';
import '../../wallet_view/redeem_code_view/redeem_code_result.dart';

/// Only the YakiHonne gateway may render a redeem card.
// ponytail: single pubkey; make it a Set if more gateways appear.
String get redeemTrustedSender => dotenv.env['YAKI_GATEWAY_PUBKEY'] ?? '';

final _codeRegex = RegExp(r'\bYR-[A-Z0-9]{6,}\b');

/// Returns the YakiHonne redeem code contained in [text], or null.
String? extractRedeemCode(String text) => _codeRegex.firstMatch(text)?.group(0);

class DMRedeemWidget extends HookWidget {
  const DMRedeemWidget({
    super.key,
    required this.text,
    required this.code,
  });

  final String text;
  final String code;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final resultCode = useState<String?>(null);
    final isDone = resultCode.value == 'codeRedeemed' ||
        resultCode.value == 'codeAlreadyRedeemed';

    return Container(
      width: 70.w,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: kDefaultPadding / 4,
        children: [
          Row(
            spacing: kDefaultPadding / 4,
            children: [
              Icon(
                LucideIcons.gift,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              Expanded(
                child: Text(
                  context.t.redeemCode,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          Text(
            code,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (isDone)
            Row(
              spacing: kDefaultPadding / 4,
              children: [
                Icon(
                  LucideIcons.circleCheck,
                  size: 16,
                  color: resultCode.value == 'codeRedeemed'
                      ? kGreen
                      : Theme.of(context).highlightColor,
                ),
                Flexible(
                  child: Text(
                    resultCode.value == 'codeRedeemed'
                        ? context.t.points_code_redeemed
                        : context.t.codeAlreadyRedeemed,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: resultCode.value == 'codeRedeemed'
                              ? kGreen
                              : Theme.of(context).highlightColor,
                        ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: isLoading.value
                  ? Center(
                      child: SpinKitCircle(
                        color: Theme.of(context).primaryColorDark,
                        size: 20,
                      ),
                    )
                  : TextButton(
                      onPressed: () async {
                        isLoading.value = true;
                        final res = await walletManagerCubit.redeemCode(code);
                        isLoading.value = false;

                        resultCode.value = res['resultCode'] as String;
                      },
                      child: Text(context.t.redeem),
                    ),
            ),
          if (resultCode.value != null && !isDone)
            Text(
              redeemResultMessage(context, resultCode.value!),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(color: kRed),
            ),
        ],
      ),
    );
  }
}
