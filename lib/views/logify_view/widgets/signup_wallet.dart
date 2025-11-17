import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../common/common_regex.dart';
import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/widgets/empty_wallets.dart';
import '../../wallet_view/widgets/export_wallets.dart';
import '../../widgets/modal_with_blur.dart';

class SignupWallet extends HookWidget {
  const SignupWallet({super.key});

  @override
  Widget build(BuildContext context) {
    final isWalletAvailable = useState(
      context.read<LogifyCubit>().state.wallet.isNotEmpty,
    );

    final isCreatingWallet = useState(false);
    final name = useTextEditingController(
      text: context.read<LogifyCubit>().state.name,
    );

    final errorMessage = useState('');

    final c1 = Column(
      key: const ValueKey('c1'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const WalletImage(
          removeExtra: true,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Text(
          context.t.letsGetStarted.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Text(
          context.t.createWalletSendRecSats.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: kDefaultPadding),
        Row(
          children: [
            Flexible(
              child: TextFormField(
                controller: name,
                style: Theme.of(context).textTheme.labelMedium,
                onChanged: (_) {
                  errorMessage.value = '';
                },
                decoration: InputDecoration(
                  hintText: context.t.yourName,
                  hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Text(
              '@wallet.yakihonne.com',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
        if (errorMessage.value.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                left: kDefaultPadding / 4,
              ),
              child: Text(
                errorMessage.value,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kRed,
                    ),
              ),
            ),
          ),
        ],
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        _outlinedButton(
            isCreatingWallet, name, errorMessage, context, isWalletAvailable),
      ],
    );

    final c2 = BlocBuilder<LogifyCubit, LogifyState>(
      builder: (context, state) {
        return ZoomIn(
          child: Column(
            key: const ValueKey('c2'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.t.youreAllSet.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Container(
                padding: const EdgeInsets.all(30),
                margin: const EdgeInsets.all(kDefaultPadding / 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColorLight,
                  border: Border.all(color: kGreen, width: 5),
                ),
                child: SvgPicture.asset(
                  FeatureIcons.walletAvailable,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 1.5,
                  vertical: kDefaultPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      FeatureIcons.zap,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColorDark,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    Text(
                      state.lightningAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: state.includeWallet,
                    activeColor: kGreen,
                    checkColor: kWhite,
                    onChanged: context.read<LogifyCubit>().setIncludeWallet,
                  ),
                  Text(
                    context.t.linkWalletToProfile.capitalizeFirst(),
                  ),
                ],
              ),
              Text(
                context.t.linkWalletToProfileDesc.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        );
      },
    );

    return BlocBuilder<LogifyCubit, LogifyState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isWalletAvailable.value ? c2 : c1,
          ),
        );
      },
    );
  }

  SizedBox _outlinedButton(
      ValueNotifier<bool> isCreatingWallet,
      TextEditingController name,
      ValueNotifier<String> errorMessage,
      BuildContext context,
      ValueNotifier<bool> isWalletAvailable) {
    return SizedBox(
      width: double.infinity,
      child: Builder(
        builder: (_) {
          return OutlinedButton(
            onPressed: () async {
              isCreatingWallet.value = true;

              if (name.text.isEmpty) {
                errorMessage.value =
                    context.t.usernameRequired.capitalizeFirst();
              } else if (!emailNamingRegex.hasMatch(name.text)) {
                errorMessage.value =
                    context.t.onlyLettersNumber.capitalizeFirst();
              } else {
                await context.read<LogifyCubit>().createWallet(
                      onSuccess: (la, wallet) async {
                        isWalletAvailable.value = true;

                        await Future.delayed(
                          const Duration(milliseconds: 500),
                        ).then(
                          (_) {
                            if (context.mounted) {
                              showBlurredModal(
                                context: context,
                                isDismissable: false,
                                view: ExportWalletOnCreation(
                                  wallet: NostrWalletConnectModel(
                                    id: '',
                                    kind: 0,
                                    lud16: la,
                                    connectionString: wallet,
                                    relay: '',
                                    secret: '',
                                    walletPubkey: '',
                                    permissions: const [],
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                      name: name.text,
                      onNameFailure: () {
                        errorMessage.value = context.t.usernameTaken;
                      },
                    );
              }

              isCreatingWallet.value = false;
            },
            child: isCreatingWallet.value
                ? SpinKitCircle(
                    color: Theme.of(context).primaryColor,
                    size: 21,
                  )
                : Text(
                    context.t.createWallet.capitalizeFirst(),
                  ),
          );
        },
      ),
    );
  }
}
