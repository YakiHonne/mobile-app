import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:numeral/numeral.dart';

import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../wallet_view/send_zaps_view/send_multi_wallet_selector.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/dotted_container.dart';

enum GiftStep { selection, payment }

class SendGiftView extends HookWidget {
  const SendGiftView({
    super.key,
    required this.receiverPubkey,
  });

  final String receiverPubkey;

  @override
  Widget build(BuildContext context) {
    final currentStep = useState(GiftStep.selection);
    final selectedCover = useState(giftCovers.first);
    final amountController = useTextEditingController(text: '21');
    final messageController = useTextEditingController();
    final refundAddressController = useTextEditingController(
      text: nostrRepository.currentMetadata.lud16,
    );
    final zapPaymentMethod = useState(ZapPaymentMethod.internal);
    final isSending = useState(false);
    final isUsingSats = useState(true);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      height: 85.h,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalBottomSheetAppbar(
            title: context.t.sendGift,
            isBack: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Text(
              context.t.sendGiftDesc,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: currentStep.value == GiftStep.selection
                  ? _CoverSelection(
                      selectedCover: selectedCover,
                      onNext: () => currentStep.value = GiftStep.payment,
                    )
                  : _GiftPaymentDetails(
                      selectedCover: selectedCover.value,
                      amountController: amountController,
                      messageController: messageController,
                      refundAddressController: refundAddressController,
                      zapPaymentMethod: zapPaymentMethod,
                      isUsingSats: isUsingSats,
                      isSending: isSending.value,
                      onPrevious: () => currentStep.value = GiftStep.selection,
                      onSend: () => _handleSendGift(
                        context,
                        selectedCover.value,
                        amountController.text,
                        messageController.text,
                        refundAddressController.text,
                        zapPaymentMethod.value,
                        isSending,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: kDefaultPadding),
        ],
      ),
    );
  }

  Future<void> _handleSendGift(
    BuildContext context,
    String cover,
    String amountStr,
    String message,
    String refundAddress,
    ZapPaymentMethod paymentMethod,
    ValueNotifier<bool> isSending,
  ) async {
    final amount = int.tryParse(amountStr) ?? 0;

    await dmsCubit.sendGift(
      receiverPubkey: receiverPubkey,
      cover: cover,
      amount: amount,
      message: message,
      refundAddress: refundAddress,
      paymentMethod: paymentMethod,
      onSuccess: () {
        Navigator.pop(context);
      },
    );
  }
}

class _CoverSelection extends StatelessWidget {
  const _CoverSelection({
    required this.selectedCover,
    required this.onNext,
  });

  final ValueNotifier<String> selectedCover;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        if (selectedCover.value.isEmpty)
                          Container(
                            width: 60.w,
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(
                                kDefaultPadding / 2,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: CommonThumbnail(
                              image: selectedCover.value,
                              width: 60.w,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              radius: kDefaultPadding / 2,
                            ),
                          ),
                        Positioned.fill(
                          child: ClipPath(
                            clipper: _GiftCoverClipper(),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft:
                                      Radius.circular(kDefaultPadding / 2),
                                  bottomRight:
                                      Radius.circular(kDefaultPadding / 2),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: constraints.maxHeight * 0.6,
                          left: 22.5.w,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kBlack.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                FeatureIcons.dmGift,
                                width: 7.w,
                                height: 7.w,
                                colorFilter: const ColorFilter.mode(
                                  kWhite,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 4),
                Text(
                  context.t.chooseCover,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            itemCount: giftCovers.length,
            separatorBuilder: (context, index) {
              return const SizedBox(
                width: kDefaultPadding / 4,
              );
            },
            itemBuilder: (context, index) {
              final cover = giftCovers[index];
              final isSelected = selectedCover.value == cover;
              return GestureDetector(
                onTap: () => selectedCover.value = cover,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? kMainColor : kTransparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  ),
                  child: cover.isEmpty
                      ? Container(
                          width: 70,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                              kDefaultPadding / 2,
                            ),
                          ),
                        )
                      : CommonThumbnail(
                          image: cover,
                          radius: kDefaultPadding / 2,
                          width: 70,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onNext,
              child: Text(
                context.t.next.capitalizeFirst(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GiftPaymentDetails extends StatelessWidget {
  const _GiftPaymentDetails({
    required this.selectedCover,
    required this.amountController,
    required this.messageController,
    required this.refundAddressController,
    required this.zapPaymentMethod,
    required this.isUsingSats,
    required this.isSending,
    required this.onPrevious,
    required this.onSend,
  });

  final String selectedCover;
  final TextEditingController amountController;
  final TextEditingController messageController;
  final TextEditingController refundAddressController;
  final ValueNotifier<ZapPaymentMethod> zapPaymentMethod;
  final ValueNotifier<bool> isUsingSats;
  final bool isSending;
  final VoidCallback onPrevious;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 2,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _amountTextfield(context),
                      _currencyButton(context),
                      _amountPreview(context),
                      const SizedBox(height: kDefaultPadding / 2),
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
                      HookBuilder(
                        builder: (context) {
                          return TextField(
                            controller: messageController,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            decoration: InputDecoration(
                              hintText: context.t.writeCommentOptional,
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
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
                        },
                      ),
                      SizedBox(
                        width: 70.w,
                        child: const Center(
                          child: Divider(
                            thickness: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 2),
                MultiWalletSelector(zapPaymentMethod: zapPaymentMethod),
                const SizedBox(height: kDefaultPadding / 4),
                TextField(
                  controller: refundAddressController,
                  decoration: InputDecoration(
                    labelText: context.t.refundWallet,
                    hintText: context.t.lightningAddress,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Row(
            spacing: kDefaultPadding / 4,
            children: [
              Expanded(
                child: SendOptionsButton(
                  onClicked: onPrevious,
                  title: context.t.previous.capitalizeFirst(),
                  icon: FeatureIcons.arrowLeft,
                ),
              ),
              Expanded(
                child: SendOptionsButton(
                  onClicked: onSend,
                  title: context.t.sendGift,
                  icon: FeatureIcons.dmGift,
                  isLoading: isSending ? isSending : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountTextfield(BuildContext context) {
    return TextField(
      controller: amountController,
      autofocus: true,
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

  Widget _currencyButton(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        useListenable(isUsingSats);
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
      },
    );
  }

  Widget _amountPreview(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        useListenable(amountController);
        useListenable(isUsingSats);
        final textAmount = int.tryParse(amountController.text);

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
}

class _GiftCoverClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final startHeight = size.height * 0.60;
    const dip = 30.0;

    path.moveTo(0, startHeight);
    path.cubicTo(
      size.width * 0.2,
      startHeight,
      size.width * 0.3,
      startHeight + dip,
      size.width * 0.5,
      startHeight + dip,
    );
    path.cubicTo(
      size.width * 0.7,
      startHeight + dip,
      size.width * 0.8,
      startHeight,
      size.width,
      startHeight,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
