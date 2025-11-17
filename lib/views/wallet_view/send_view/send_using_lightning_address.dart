import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/zaps/zap.dart';
import 'package:numeral/numeral.dart';

import '../../../common/common_regex.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import 'send_success_view.dart';
import 'send_using_invoice.dart';

class SendUsingLightningAddress extends HookWidget {
  const SendUsingLightningAddress({
    super.key,
    required this.lnLnurl,
    required this.isManual,
    this.metadata,
  });

  final String lnLnurl;
  final bool isManual;
  final Metadata? metadata;

  @override
  Widget build(BuildContext context) {
    final isUsingSats = useState(true);
    final ln = useState('-');
    final amount = useState('');
    final message = useState('');

    useMemoized(
      () {
        if (emailRegExp.hasMatch(lnLnurl)) {
          ln.value = lnLnurl;
        } else if (lnLnurl.toUpperCase().startsWith('lnurl')) {
          ln.value = Zap.getLud16LinkFromLud16(lnLnurl) ?? '-';
        }
      },
    );

    final t = BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return TextButton(
          onPressed: () async {
            if (ln.value == '-') {
              BotToastUtils.showError(context.t.invalidLightningAddress);
              return;
            }

            final textAmount = int.tryParse(amount.value);

            int t = 0;

            if (textAmount != null) {
              t = isUsingSats.value
                  ? textAmount
                  : walletManagerCubit
                      .getFiatInBtcFromAmount(textAmount)
                      .toInt();
            }

            if (t == 0) {
              BotToastUtils.showError(context.t.validSatsAmount);
              return;
            }

            await walletManagerCubit.sendUsingLightningAddress(
              lightningAddress: ln.value,
              sats: t,
              message: message.value,
              user: metadata,
              removeSuccess: true,
              onSuccess: () {
                YNavigator.pushReplacement(
                  context,
                  SendSuccessView(
                    amount: t,
                    ln: ln.value,
                  ),
                );
              },
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            side: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !state.isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    key: const ValueKey(1),
                    spacing: kDefaultPadding / 4,
                    children: [
                      SvgPicture.asset(
                        FeatureIcons.zapFilled,
                        width: 15,
                        height: 15,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                      Text(
                        key: const ValueKey(1),
                        context.t.pay.capitalizeFirst(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  )
                : const SpinKitCircle(
                    key: ValueKey(2),
                    color: kWhite,
                    size: 20,
                  ),
          ),
        );
      },
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.lightningAddress,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: _contentColumn(
                        amount, context, isUsingSats, message, ln),
                  ),
                ),
              ),
            ),
            const InternalWalletSelector(),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
              ),
              child: SizedBox(
                width: double.infinity,
                child: t,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IntrinsicHeight _contentColumn(
      ValueNotifier<String> amount,
      BuildContext context,
      ValueNotifier<bool> isUsingSats,
      ValueNotifier<String> message,
      ValueNotifier<String> ln) {
    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: kDefaultPadding / 2,
        children: [
          _amountTextfield(amount, context),
          _currencyButton(isUsingSats, context),
          _amount(amount, isUsingSats),
          SizedBox(
            width: 70.w,
            child: const Center(
              child: Divider(
                thickness: 0.5,
              ),
            ),
          ),
          Text(
            context.t.comment.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          TextFormField(
            onChanged: (value) {
              message.value = value;
            },
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            decoration: InputDecoration(
              hintText: context.t.writeCommentOptional,
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          SizedBox(
            width: 70.w,
            child: const Center(
              child: Divider(
                thickness: 0.5,
              ),
            ),
          ),
          Text(
            context.t.lightningAddress.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          if (isManual)
            TextFormField(
              initialValue: ln.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
              onChanged: (lightningAddress) {
                ln.value = lightningAddress;
              },
              decoration: InputDecoration(
                hintText: context.t.writeCommentOptional,
                hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).dividerColor,
                    ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            )
          else
            Text(
              ln.value,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
        ],
      ),
    );
  }

  Builder _amount(
      ValueNotifier<String> amount, ValueNotifier<bool> isUsingSats) {
    return Builder(
      builder: (context) {
        final textAmount = int.tryParse(amount.value);

        String t = '0';

        if (textAmount != null) {
          t = isUsingSats.value
              ? walletManagerCubit
                  .getBtcInFiatFromAmount(textAmount)
                  .numeral(digits: 2)
              : walletManagerCubit
                  .getFiatInBtcFromAmount(textAmount)
                  .numeral(digits: 2);
        }

        return Text(
          '$t ${!isUsingSats.value ? 'SATS' : walletManagerCubit.state.activeCurrency.toUpperCase()}',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).highlightColor,
              ),
        );
      },
    );
  }

  GestureDetector _currencyButton(
      ValueNotifier<bool> isUsingSats, BuildContext context) {
    return GestureDetector(
      onTap: () => isUsingSats.value = !isUsingSats.value,
      behavior: HitTestBehavior.translucent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: kDefaultPadding / 2,
        children: [
          Text(
            isUsingSats.value
                ? 'SATS'
                : walletManagerCubit.state.activeCurrency.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SvgPicture.asset(
            FeatureIcons.repost,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _amountTextfield(
      ValueNotifier<String> amount, BuildContext context) {
    return TextFormField(
      initialValue: amount.value,
      autofocus: true,
      onChanged: (value) {
        amount.value = value;
      },
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayLarge!.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: Theme.of(context).textTheme.displayLarge!.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).dividerColor,
            ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
