import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';

class ExternalWalletsListView extends StatelessWidget {
  const ExternalWalletsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.40,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) => _WalletListContent(
              state: state,
              scrollController: scrollController,
            ),
          ),
        );
      },
    );
  }
}

class _WalletListContent extends StatelessWidget {
  const _WalletListContent({
    required this.state,
    required this.scrollController,
  });

  final WalletsManagerState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: Column(
            children: [
              const _WalletListHeader(),
              const SizedBox(height: kDefaultPadding),
              _itemsGrid(context, state),
              const SizedBox(height: kDefaultPadding),
              _useDefaultWallet(context, state),
            ],
          ),
        );
      },
    );
  }

  Row _useDefaultWallet(BuildContext context, WalletsManagerState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: kDefaultPadding / 4,
            children: [
              Text(
                context.t.alwaysUseExternal.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                context.t.alwaysUseExternalDesc,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.useDefaultWallet,
            activeTrackColor: Theme.of(context).primaryColor,
            onChanged: (isToggled) {
              walletManagerCubit.setUseDefaultWallet(isToggled);
            },
          ),
        ),
      ],
    );
  }

  MediaQuery _itemsGrid(BuildContext context, WalletsManagerState state) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: kDefaultPadding / 4,
          mainAxisSpacing: kDefaultPadding / 4,
        ),
        shrinkWrap: true,
        primary: false,
        itemBuilder: (context, index) {
          final wallet = wallets.entries.elementAt(index);

          return GestureDetector(
            onTap: () {
              context.read<WalletsManagerCubit>().setDefaultWallet(wallet.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: wallet.key == state.defaultExternalWallet
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: wallet.key == state.defaultExternalWallet ? 1 : 0.5,
                ),
              ),
              padding: const EdgeInsets.all(kDefaultPadding / 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: kDefaultPadding / 4,
                children: [
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                      image: DecorationImage(
                        image: AssetImage(wallet.value['icon']!),
                      ),
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding / 2),
                  Text(
                    wallet.value['name']!,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        itemCount: wallets.length,
      ),
    );
  }
}

class _WalletListHeader extends StatelessWidget {
  const _WalletListHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(child: ModalBottomSheetHandle()),
        const SizedBox(height: kDefaultPadding / 4),
        Center(
          child: Text(
            context.t.wallets.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
        ),
      ],
    );
  }
}
