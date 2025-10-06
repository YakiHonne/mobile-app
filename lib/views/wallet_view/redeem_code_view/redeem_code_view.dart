import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import 'redeem_code_options.dart';
import 'redeem_code_result.dart';

class RedeemCodeView extends HookWidget {
  const RedeemCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    final type = useState(RedeemCodeStatus.options);
    final isQrCode = useState(true);
    final resultData = useState<Map<String, dynamic>>({});
    final redeemCode = useTextEditingController();
    final code = useState('');

    return Container(
      width: double.infinity,
      height: 90.h,
      padding: MediaQuery.of(context).viewInsets.copyWith(
            left: kDefaultPadding / 2,
            right: kDefaultPadding / 2,
          ),
      decoration: _buildContainerDecoration(context),
      child: Column(
        children: [
          const ModalBottomSheetHandle(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              child: _getCurrentWidget(
                context: context,
                type: type,
                isQrCode: isQrCode,
                resultData: resultData,
                redeemCode: redeemCode,
                code: code,
                onSwitchToOptions: () {
                  type.value = RedeemCodeStatus.options;
                },
                onRedeem: () async {
                  if (type.value == RedeemCodeStatus.options) {
                    type.value = RedeemCodeStatus.loading;

                    resultData.value = await walletManagerCubit.redeemCode(
                      code.value,
                    );

                    if (resultData.value['status'] == true) {
                      redeemCode.clear();
                      code.value = '';
                    }

                    type.value = RedeemCodeStatus.result;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentWidget({
    required BuildContext context,
    required ValueNotifier<RedeemCodeStatus> type,
    required ValueNotifier<bool> isQrCode,
    required ValueNotifier<String> code,
    required ValueNotifier<Map<String, dynamic>> resultData,
    required TextEditingController redeemCode,
    required Function() onRedeem,
    required Function() onSwitchToOptions,
  }) {
    switch (type.value) {
      case RedeemCodeStatus.options:
        return _buildOptionsWidget(
          isQrCode: isQrCode,
          code: code,
          onRedeem: onRedeem,
          redeemCode: redeemCode,
        );
      case RedeemCodeStatus.loading:
        return _buildLoadingWidget(context: context);
      case RedeemCodeStatus.result:
        return _buildResultWidget(
          onSwitchToOptions: onSwitchToOptions,
          data: resultData.value,
        );
    }
  }

  Widget _buildOptionsWidget({
    required ValueNotifier<bool> isQrCode,
    required ValueNotifier<String> code,
    required TextEditingController redeemCode,
    required Function() onRedeem,
  }) {
    return RedeemCodeOptions(
      key: const Key('redeem_code_options'),
      isQrCode: isQrCode,
      code: code,
      onRedeem: onRedeem,
      redeemCode: redeemCode,
    );
  }

  Widget _buildLoadingWidget({
    required BuildContext context,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: kDefaultPadding / 2,
        children: [
          SpinKitCircle(
            color: Theme.of(context).primaryColorDark,
            size: 30.0,
          ),
          Text(
            context.t.redeemInProgress,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultWidget({
    required Map<String, dynamic> data,
    required Function() onSwitchToOptions,
  }) {
    return RedeemCodeResults(onSwitchToOptions: onSwitchToOptions, data: data);
  }

  /// Build container decoration
  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(kDefaultPadding),
        topRight: Radius.circular(kDefaultPadding),
      ),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
    );
  }
}
