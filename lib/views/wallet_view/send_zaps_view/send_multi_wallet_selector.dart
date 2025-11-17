import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/modal_with_blur.dart';
import '../send_view/send_using_invoice.dart';
import '../widgets/wallet_options_view.dart';

/// Widget for selecting between default wallet and internal/external wallets
class MultiWalletSelector extends StatelessWidget {
  const MultiWalletSelector({
    super.key,
    required this.useDefaultWallet,
  });

  final ValueNotifier<bool> useDefaultWallet;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) => Row(
        spacing: kDefaultPadding / 4,
        children: [
          _buildWalletSelector(state),
          _buildToggleButton(context, state),
        ],
      ),
    );
  }

  /// Build the main wallet selector widget
  Widget _buildWalletSelector(WalletsManagerState state) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _shouldShowExternalWallet(state)
            ? const ExternalWalletSelector()
            : const InternalWalletSelector(),
      ),
    );
  }

  /// Build the toggle button for switching between wallet types
  Widget _buildToggleButton(BuildContext context, WalletsManagerState state) {
    return GestureDetector(
      onTap: () => _handleToggleTap(context, state),
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 36,
        width: 36,
        decoration: _buildToggleButtonDecoration(context, state),
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: _buildToggleButtonIcon(context, state),
      ),
    );
  }

  /// Build the decoration for the toggle button
  BoxDecoration _buildToggleButtonDecoration(
    BuildContext context,
    WalletsManagerState state,
  ) {
    return BoxDecoration(
      color: !state.hasWallets
          ? Theme.of(context).primaryColor
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      border: Border.all(color: Theme.of(context).dividerColor),
    );
  }

  /// Build the icon for the toggle button
  Widget _buildToggleButtonIcon(
    BuildContext context,
    WalletsManagerState state,
  ) {
    if (_shouldShowExternalWalletIcon(state)) {
      return _buildExternalWalletIcon(state);
    }
    return _buildInternalWalletIcon(context, state);
  }

  /// Build external wallet icon
  Widget _buildExternalWalletIcon(WalletsManagerState state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 4),
        image: DecorationImage(
          image: AssetImage(
            wallets[state.defaultExternalWallet]!['icon']!,
          ),
        ),
      ),
    );
  }

  /// Build internal wallet icon
  Widget _buildInternalWalletIcon(
    BuildContext context,
    WalletsManagerState state,
  ) {
    return SizedBox(
      width: 25,
      height: 25,
      child: Center(
        child: SvgPicture.asset(
          _getInternalWalletIconPath(state),
          width: 20,
          height: 20,
          fit: BoxFit.scaleDown,
          colorFilter: _getIconColorFilter(context, state),
        ),
      ),
    );
  }

  /// Handle toggle button tap
  void _handleToggleTap(BuildContext context, WalletsManagerState state) {
    if (state.hasWallets) {
      useDefaultWallet.value = !useDefaultWallet.value;
    } else {
      _showWalletOptionsModal(context);
    }
  }

  /// Show wallet options modal
  void _showWalletOptionsModal(BuildContext context) {
    showBlurredModal(
      context: context,
      view: const WalletOptions(),
    );
  }

  /// Determine if external wallet should be shown
  bool _shouldShowExternalWallet(WalletsManagerState state) {
    return useDefaultWallet.value ||
        (!useDefaultWallet.value && !state.hasWallets);
  }

  /// Determine if external wallet icon should be shown
  bool _shouldShowExternalWalletIcon(WalletsManagerState state) {
    return !useDefaultWallet.value && state.hasWallets;
  }

  /// Get the appropriate icon path for internal wallet
  String _getInternalWalletIconPath(WalletsManagerState state) {
    if (!state.hasWallets) {
      return FeatureIcons.addRaw;
    }

    final wallet = state.wallets[state.selectedWalletId];
    final isNwc = wallet is NostrWalletConnectModel;

    return isNwc ? FeatureIcons.nwc : FeatureIcons.alby;
  }

  /// Get the appropriate color filter for the icon
  ColorFilter? _getIconColorFilter(
    BuildContext context,
    WalletsManagerState state,
  ) {
    if (!state.hasWallets) {
      return ColorFilter.mode(
        Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      );
    }
    return null;
  }
}
