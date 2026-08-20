// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';

class SignupWallet extends HookWidget {
  const SignupWallet({
    super.key,
    this.nameCtrl,
    this.isWalletCreated,
    this.errorMessage,
  });

  final TextEditingController? nameCtrl;
  final ValueNotifier<bool>? isWalletCreated;
  final ValueNotifier<String>? errorMessage;

  @override
  Widget build(BuildContext context) {
    // Fall back to internal state when params are not provided (non-fluid flow)
    final internalNameCtrl = useTextEditingController(
      text: context.read<LogifyCubit>().state.name,
    );
    final internalWalletCreated = useState(
      context.read<LogifyCubit>().state.wallet.isNotEmpty,
    );
    final internalError = useState('');

    final effectiveNameCtrl = nameCtrl ?? internalNameCtrl;
    final effectiveWalletCreated = isWalletCreated ?? internalWalletCreated;
    final effectiveError = errorMessage ?? internalError;

    final c1 = Column(
      key: const ValueKey('c1'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.t.dontHaveWallet.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w900,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding * 1.5),
        // Glowing circle with sats icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColorLight,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.45),
                blurRadius: 10,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: const Center(
            child: AppIcon(
              FeatureIcons.sats,
              size: 60,
              color: kWhite,
            ),
          ),
        ),
        const SizedBox(height: kDefaultPadding * 1.5),
        // Username + domain row
        Row(
          children: [
            Flexible(
              child: TextFormField(
                controller: effectiveNameCtrl,
                style: Theme.of(context).textTheme.labelLarge,
                onChanged: (_) => effectiveError.value = '',
                decoration: InputDecoration(
                  hintText: context.t.yourName,
                  hintStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Text(
              '@wallet.yakihonne.com',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
        if (effectiveError.value.isNotEmpty) ...[
          const SizedBox(height: kDefaultPadding / 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              effectiveError.value,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kRed,
                  ),
            ),
          ),
        ],
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
              const SizedBox(height: kDefaultPadding),
              Container(
                padding: const EdgeInsets.all(30),
                margin: const EdgeInsets.all(kDefaultPadding / 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColorLight,
                  border: Border.all(color: kGreen, width: 5),
                ),
                child: AppIcon(
                  FeatureIcons.walletAvailable,
                  color: Theme.of(context).primaryColorDark,
                  size: 80,
                ),
              ),
              const SizedBox(height: kDefaultPadding),
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
                    AppIcon(
                      FeatureIcons.zap,
                      size: 22,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    const SizedBox(width: kDefaultPadding / 4),
                    Text(state.lightningAddress),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: state.includeWallet,
                    activeColor: kGreen,
                    checkColor: kWhite,
                    onChanged: context.read<LogifyCubit>().setIncludeWallet,
                  ),
                  Text(context.t.linkWalletToProfile.capitalizeFirst()),
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
          padding: EdgeInsets.symmetric(
            horizontal: isFluid() ? 0 : kDefaultPadding,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: effectiveWalletCreated.value ? c2 : c1,
          ),
        );
      },
    );
  }
}
