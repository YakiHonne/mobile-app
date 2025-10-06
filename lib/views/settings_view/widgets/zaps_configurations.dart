// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../utils/utils.dart';

class ExternalWalletContainer extends StatelessWidget {
  const ExternalWalletContainer({
    super.key,
    required this.isWalletListCollapsed,
  });

  final ValueNotifier<bool> isWalletListCollapsed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        isWalletListCollapsed.value = !isWalletListCollapsed.value;
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding / 1.5,
              ),
              child: BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
                buildWhen: (previous, current) =>
                    previous.defaultExternalWallet !=
                    current.defaultExternalWallet,
                builder: (context, state) {
                  String title = '';
                  String icon = '';

                  title = wallets[state.defaultExternalWallet]!['name']!;
                  icon = wallets[state.defaultExternalWallet]!['icon']!;
                  final isDefault = icon == WalletsLogos.local;

                  return _walletRow(isDefault, icon, context, title);
                },
              ),
            ),
            _wallets(),
          ],
        ),
      ),
    );
  }

  BlocBuilder<WalletsManagerCubit, WalletsManagerState> _wallets() {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        if (isWalletListCollapsed.value) {
          return const SizedBox.shrink();
        } else {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: Divider(
                  height: 0,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              ...wallets.keys.map(
                (wallet) {
                  if (wallet.isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    final title = wallets[wallet]!['name']!;
                    final icon = wallets[wallet]!['icon']!;
                    return WalletContainer(
                      title: title,
                      icon: icon,
                      isSelected: wallet == state.defaultExternalWallet,
                      onClicked: () {
                        context
                            .read<WalletsManagerCubit>()
                            .setDefaultWallet(wallet);

                        isWalletListCollapsed.value =
                            !isWalletListCollapsed.value;
                      },
                    );
                  }
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ],
          );
        }
      },
    );
  }

  Row _walletRow(
      bool isDefault, String icon, BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: isDefault
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding / 4,
                  ),
                  image: DecorationImage(
                    image: AssetImage(
                      icon,
                    ),
                  ),
                ),
          child: isDefault
              ? SvgPicture.asset(
                  FeatureIcons.selectExternalWallet,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                )
              : null,
        ),
        const SizedBox(
          width: kDefaultPadding / 1.5,
        ),
        Expanded(
          child: Text(
            title.isEmpty
                ? context.t.defaultKey.capitalizeFirst()
                : title == 'Select wallet'
                    ? context.t.wallet
                    : title,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Icon(
          isWalletListCollapsed.value
              ? Icons.keyboard_arrow_down_outlined
              : Icons.keyboard_arrow_up_outlined,
          color: Theme.of(context).primaryColorDark,
        ),
      ],
    );
  }
}

class WalletContainer extends StatelessWidget {
  const WalletContainer({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onClicked,
  });

  final String title;
  final String icon;
  final bool isSelected;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        child: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                image: DecorationImage(
                  image: AssetImage(
                    icon,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 1.5,
            ),
            Expanded(
              child: Text(
                title.isEmpty ? context.t.defaultKey.capitalizeFirst() : title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            if (isSelected)
              SvgPicture.asset(
                ToastsIcons.check,
                width: 20,
                height: 20,
              ),
          ],
        ),
      ),
    );
  }
}
