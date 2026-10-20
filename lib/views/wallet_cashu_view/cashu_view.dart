import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../logic/main_cubit/main_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../utils/utils.dart';
import '../main_view/widgets/app_bar_widgets.dart' show SelectedWalletContainer;
import '../widgets/app_icon.dart';
import '../widgets/no_content_widgets.dart';
import 'widgets/cashu_no_wallet.dart';
import 'widgets/cashu_wallet_balance_container.dart';

class CashuWalletView extends StatelessWidget {
  const CashuWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          nostrRepository.mainCubit.updateIndex(MainViews.leading);
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: kDefaultPadding / 2,
            right: kDefaultPadding / 2,
            top: isFluid()
                ? MediaQuery.of(context).padding.top + kToolbarHeight
                : kDefaultPadding,
          ),
          child: BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
            builder: (context, state) {
              if (isDisconnected() || canRoam()) {
                return _buildDisconnectedState();
              } else if (state.isInitializing) {
                return _buildInitializingState();
              } else if (state.mints.isEmpty) {
                return _buildEmptyState();
              }

              return _buildWalletContent(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectedState() {
    return const SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VerticalViewModeWidget(),
        ],
      ),
    );
  }

  Widget _buildInitializingState() {
    return const Center(
      child: _LoadingView(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: CashuNoWallet(),
    );
  }

  Widget _buildWalletContent(BuildContext context) {
    return Column(
      children: [
        // ponytail: fluid appbar has no title slot, so the mint selector
        // lives at the top of the view.
        if (isFluid()) ...[
          const SizedBox(height: kDefaultPadding / 2),
          const SelectedWalletContainer(),
        ],
        const Expanded(
          child: CashuWallatBalanceContainer(),
        ),
        SizedBox(
          height: themeCubit.state.isFluid
              ? kBottomNavigationBarHeight +
                  kDefaultPadding * 2 +
                  MediaQuery.of(context).padding.bottom / 2
              : kDefaultPadding,
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExtendedImage.asset(
          Images.cashu,
          width: 30.w,
          height: 30.w,
          fit: BoxFit.contain,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Text(
          context.t.initializing.capitalizeFirst(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        SpinKitCircle(
          color: Theme.of(context).primaryColorDark,
          size: 30,
        ),
      ],
    );
  }
}

class WalletSwitchContainer extends StatelessWidget {
  const WalletSwitchContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isCashuWallet = context.read<MainCubit>().state.isCashuWallet;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<MainCubit>().changeWalletType();
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          spacing: kDefaultPadding / 2,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              FeatureIcons.refresh,
              size: 20,
            ),
            Text(
              isCashuWallet
                  ? context.t.nostrWalletConnect
                  : context.t.cashuWallet,
            ),
          ],
        ),
      ),
    );
  }
}
