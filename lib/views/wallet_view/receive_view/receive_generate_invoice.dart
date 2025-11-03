// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:numeral/numeral.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../send_view/send_main_view.dart';
import '../send_view/send_success_view.dart';
import '../send_view/send_using_invoice.dart';
import 'receive_view.dart';

class ReceiveGenerateInvoice extends HookWidget {
  const ReceiveGenerateInvoice({super.key});

  @override
  Widget build(BuildContext context) {
    final invoice = useState('');

    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.invoice.capitalize(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Column(
          spacing: kDefaultPadding / 4,
          children: [
            _invoice(invoice),
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
              ),
              child: invoice.value.isEmpty
                  ? SizedBox(
                      width: double.infinity,
                      child: SendOptionsButton(
                        onClicked: () {
                          HapticFeedback.mediumImpact();
                          YNavigator.pushReplacement(
                            context,
                            const ReceiveMainView(),
                          );
                        },
                        title: context.t.qrCode,
                        icon: FeatureIcons.qr,
                      ),
                    )
                  : _actionsColumn(invoice, context),
            ),
          ],
        ),
      ),
    );
  }

  Column _actionsColumn(ValueNotifier<String> invoice, BuildContext context) {
    return Column(
      spacing: kDefaultPadding / 4,
      children: [
        Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: SendOptionsButton(
                onClicked: () {
                  shareContent(text: invoice.value);
                },
                title: context.t.share.capitalizeFirst(),
                icon: FeatureIcons.shareGlobal,
              ),
            ),
            Expanded(
              child: SendOptionsButton(
                onClicked: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(
                    ClipboardData(
                      text: invoice.value,
                    ),
                  );

                  BotToastUtils.showSuccess(
                    context.t.invoiceCopied.capitalizeFirst(),
                  );
                },
                title: context.t.copy.capitalizeFirst(),
                icon: FeatureIcons.copy,
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () async {
              invoice.value = '';
            },
            style: TextButton.styleFrom(
              backgroundColor: kRed.withValues(alpha: 0.2),
              side: const BorderSide(
                color: kRed,
                width: 0.5,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                key: const ValueKey(1),
                context.t.cancel.capitalizeFirst(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: kRed,
                    ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Expanded _invoice(ValueNotifier<String> invoice) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: invoice.value.isNotEmpty
            ? ReceiveInvoiceQrCode(
                key: const ValueKey('receive_invoice_qr'),
                invoice: invoice.value,
              )
            : ReceiveGenInvoice(
                key: const ValueKey('receive_gen_invoice'),
                setInvoice: (invc) {
                  invoice.value = invc;
                },
              ),
      ),
    );
  }
}

class ReceiveInvoiceQrCode extends HookWidget {
  const ReceiveInvoiceQrCode({
    super.key,
    required this.invoice,
  });

  final String invoice;

  @override
  Widget build(BuildContext context) {
    final amount = useState(getlnbcValue(invoice).toInt());
    final amountInUsd =
        useState(walletManagerCubit.getBtcInFiatFromAmount(amount.value));

    final zapSub = useMemoized(() {
      return NostrFunctionsRepository.getZapEventStream(invoice: invoice);
    });

    // Run async task
    useEffect(() {
      bool mounted = true;
      zapSub.future.then((event) {
        if (mounted && context.mounted && event != null) {
          YNavigator.pushReplacement(
            context,
            SendSuccessView(amount: amount.value),
          );
        }
      });

      // cleanup when view is dismissed
      return () {
        mounted = false;
        zapSub.cancel();
      };
    }, []);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: _contentColumn(context, amount, amountInUsd),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IntrinsicHeight _contentColumn(BuildContext context,
      ValueNotifier<int> amount, ValueNotifier<double> amountInUsd) {
    return IntrinsicHeight(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: kDefaultPadding,
        children: [
          _qrCode(context),
          Builder(
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _amount(amount, context),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  _amountUsd(amountInUsd, context),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: kDefaultPadding / 2,
            children: [
              const SpinKitCircle(
                size: 20,
                color: kMainColor,
              ),
              Text(
                context.t.waitingPayment.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Row _amountUsd(ValueNotifier<double> amountInUsd, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '~ \$${amountInUsd.value == -1 ? 'N/A' : amountInUsd.value.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          ' USD',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }

  Row _amount(ValueNotifier<int> amount, BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${amount.value != -1 ? amount.value : 'N/A'}',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: kMainColor,
              ),
        ),
        Text(
          'sats',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }

  Container _qrCode(BuildContext context) {
    return Container(
      width: 70.w,
      height: 70.w,
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
        data: invoice,
        dataModuleStyle: QrDataModuleStyle(
          color: Theme.of(context).primaryColorDark,
          dataModuleShape: QrDataModuleShape.circle,
        ),
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }
}

class ReceiveGenInvoice extends HookWidget {
  const ReceiveGenInvoice({
    super.key,
    required this.setInvoice,
  });

  final Function(String) setInvoice;

  @override
  Widget build(BuildContext context) {
    final isUsingSats = useState(true);
    final amount = useState('');
    final message = useState('');

    final t = BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return TextButton(
          onPressed: () async {
            final ln = walletManagerCubit.getCurrentWalletLightningAddress();

            if (ln == null) {
              BotToastUtils.showError(context.t.invalidInvoiceLnurl);
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
              BotToastUtils.showError(context.t.invalidInvoiceLnurl);
              return;
            }

            await walletManagerCubit.generateZapInvoice(
              comment: message.value,
              user: nostrRepository.currentMetadata.copyWith(lud16: ln),
              onFailure: (p0) {},
              sats: t,
              onSuccess: setInvoice,
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
                ? Text(
                    key: const ValueKey(1),
                    context.t.generateInvoice.capitalizeFirst(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: kDefaultPadding / 2,
                    children: [
                      _amountTextfield(amount, context),
                      _toggleCurrency(isUsingSats, context),
                      _exchange(amount, isUsingSats),
                      SizedBox(
                        width: 70.w,
                        child: const Center(
                          child: Divider(
                            thickness: 0.5,
                          ),
                        ),
                      ),
                      _comment(context),
                      _commentTextfield(message, context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const InternalWalletSelector(),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        SizedBox(
          width: double.infinity,
          child: t,
        ),
      ],
    );
  }

  TextFormField _commentTextfield(
      ValueNotifier<String> message, BuildContext context) {
    return TextFormField(
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
    );
  }

  Text _comment(BuildContext context) {
    return Text(
      context.t.comment.capitalizeFirst(),
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).highlightColor,
          ),
    );
  }

  Builder _exchange(
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

  GestureDetector _toggleCurrency(
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
            color: kMainColor,
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
