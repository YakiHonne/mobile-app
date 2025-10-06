import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../common/common_regex.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/global_keys.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/modal_with_blur.dart';
import '../../widgets/response_snackbar.dart';
import 'export_wallets.dart';
import 'wallet_options_view.dart';

// =============================================================================
// MAIN WIDGET
// =============================================================================

class InternalWalletsListView extends HookWidget {
  const InternalWalletsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding),
              topRight: Radius.circular(kDefaultPadding),
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

// =============================================================================
// MAIN CONTENT WIDGET
// =============================================================================

class _WalletListContent extends StatelessWidget {
  const _WalletListContent({
    required this.state,
    required this.scrollController,
  });

  final WalletsManagerState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: Column(
        children: [
          const _WalletListHeader(),
          const SizedBox(height: kDefaultPadding / 4),
          _WalletConnectionStatus(state: state),
          const SizedBox(height: kDefaultPadding / 2),
          _WalletListBody(
            state: state,
            scrollController: scrollController,
          ),
          const SizedBox(height: kDefaultPadding / 2),
          const _AddWalletButton(),
          const SizedBox(height: kDefaultPadding * 1.5),
        ],
      ),
    );
  }
}

// =============================================================================
// HEADER SECTION
// =============================================================================

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

// =============================================================================
// WALLET CONNECTION STATUS
// =============================================================================

class _WalletConnectionStatus extends StatelessWidget {
  const _WalletConnectionStatus({required this.state});

  final WalletsManagerState state;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getWalletStatusInfo(context);

    if (statusInfo == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: SizedBox(
        width: double.infinity,
        child: DottedBorder(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          radius: const Radius.circular(kDefaultPadding / 2),
          color: Theme.of(context).dividerColor,
          borderType: BorderType.rRect,
          child: Center(
            child: Column(
              children: [
                Text(
                  statusInfo.message,
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding / 4),
                _buildInstructionText(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _WalletStatusInfo? _getWalletStatusInfo(BuildContext context) {
    final metadata = nostrRepository.currentMetadata;
    final hasNoWallet = metadata.lud06.isEmpty && metadata.lud16.isEmpty;

    if (hasNoWallet) {
      return _WalletStatusInfo(
        message: context.t.noWalletLinkedToYouProfile.capitalizeFirst(),
      );
    }

    final hasConnectedWalletLinked =
        state.wallets.values.any((wallet) => wallet.lud16 == metadata.lud16);

    if (!hasConnectedWalletLinked) {
      return _WalletStatusInfo(
        message: context.t.noWalletConnectedToYourProfile.capitalizeFirst(),
      );
    }

    return null;
  }

  Widget _buildInstructionText(BuildContext context) {
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        children: [
          TextSpan(text: '${context.t.click.capitalizeFirst()} '),
          WidgetSpan(
            child: SvgPicture.asset(
              FeatureIcons.more,
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          TextSpan(text: ' ${context.t.onSelectedWalletLinkIt}'),
        ],
      ),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class _WalletStatusInfo {
  const _WalletStatusInfo({required this.message});
  final String message;
}

// =============================================================================
// WALLET LIST BODY
// =============================================================================

class _WalletListBody extends StatelessWidget {
  const _WalletListBody({
    required this.state,
    required this.scrollController,
  });

  final WalletsManagerState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state.wallets.isEmpty) {
      return Expanded(
        child: EmptyList(
          description: context.t.noWalletCanBeFound.capitalizeFirst(),
          icon: FeatureIcons.wallet,
        ),
      );
    }

    final wallets = state.wallets.entries.toList();

    return Expanded(
      child: ListView.separated(
        controller: scrollController,
        separatorBuilder: (context, index) => const SizedBox(
          height: kDefaultPadding / 4,
        ),
        itemBuilder: (context, index) => _WalletListItem(
          wallet: wallets[index],
          isSelected: state.selectedWalletId == wallets[index].key,
        ),
        itemCount: wallets.length,
      ),
    );
  }
}

// =============================================================================
// INDIVIDUAL WALLET ITEM
// =============================================================================

class _WalletListItem extends StatelessWidget {
  const _WalletListItem({
    required this.wallet,
    required this.isSelected,
  });

  final MapEntry<String, WalletModel> wallet;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final walletInfo = _WalletItemInfo.fromWallet(wallet.value);

    return GestureDetector(
      onTap: () => _handleWalletSelection(context),
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: _buildItemDecoration(context),
        child: Row(
          children: [
            Expanded(
              child: _WalletItemContent(
                walletInfo: walletInfo,
                isSelected: isSelected,
              ),
            ),
            _WalletItemActions(
              wallet: wallet.value,
              isLinked: walletInfo.isLinked,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildItemDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
      color: Theme.of(context).cardColor,
    );
  }

  void _handleWalletSelection(BuildContext context) {
    walletManagerCubit.setSelectedWallet(
      wallet.key,
      () => YNavigator.pop(context),
    );
  }
}

// =============================================================================
// WALLET ITEM CONTENT
// =============================================================================

class _WalletItemContent extends StatelessWidget {
  const _WalletItemContent({
    required this.walletInfo,
    required this.isSelected,
  });

  final _WalletItemInfo walletInfo;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SelectionIndicator(isSelected: isSelected),
        const SizedBox(width: kDefaultPadding / 2),
        _WalletIcon(isAlby: walletInfo.isAlby),
        const SizedBox(width: kDefaultPadding / 2),
        Expanded(
          child: Text(
            walletInfo.displayAddress,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (walletInfo.isLinked) ...[
          const SizedBox(width: kDefaultPadding / 2),
          const _LinkedBadge(),
        ],
      ],
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Center(
        child: Opacity(
          opacity: isSelected ? 1 : 0,
          child: Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kGreen.withValues(alpha: 0.3),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: kWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletIcon extends StatelessWidget {
  const _WalletIcon({required this.isAlby});

  final bool isAlby;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: SvgPicture.asset(
        isAlby ? FeatureIcons.alby : FeatureIcons.nwc,
      ),
    );
  }
}

class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.t.currentlyLinkedMessage.capitalizeFirst(),
      triggerMode: TooltipTriggerMode.tap,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 4),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).primaryColorDark,
          ),
      enableFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 3),
          border: Border.all(color: kGreen),
          color: kGreen.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 6,
        ),
        child: Text(
          context.t.linked.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: kGreen,
              ),
        ),
      ),
    );
  }
}

// =============================================================================
// WALLET ITEM ACTIONS
// =============================================================================

class _WalletItemActions extends StatelessWidget {
  const _WalletItemActions({
    required this.wallet,
    required this.isLinked,
  });

  final WalletModel wallet;
  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) => _buildMenuItems(context),
      buttonBuilder: (context, showMenu) => CustomIconButton(
        backgroundColor: Theme.of(context).cardColor,
        onClicked: showMenu,
        size: 16,
        vd: -2,
        icon: FeatureIcons.more,
      ),
    );
  }

  List<PullDownMenuItem> _buildMenuItems(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium;
    final menuItems = <PullDownMenuItem>[];

    // Link wallet action
    if (!isLinked) {
      menuItems.add(_buildLinkWalletMenuItem(context, textStyle));
    }

    // Copy lightning address action
    if (emailRegExp.hasMatch(wallet.lud16)) {
      menuItems.add(_buildCopyLightningAddressMenuItem(context, textStyle));
    }

    // NWC specific actions
    if (wallet is NostrWalletConnectModel) {
      menuItems.addAll(_buildNwcMenuItems(context, textStyle));
    }

    // Delete wallet action
    menuItems.add(_buildDeleteWalletMenuItem(context, textStyle));

    return menuItems;
  }

  PullDownMenuItem _buildLinkWalletMenuItem(
    BuildContext context,
    TextStyle? textStyle,
  ) {
    return PullDownMenuItem(
      title: context.t.linkWallet.capitalizeFirst(),
      onTap: () => _handleLinkWallet(context),
      itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
      iconWidget: SvgPicture.asset(
        FeatureIcons.link,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  PullDownMenuItem _buildCopyLightningAddressMenuItem(
    BuildContext context,
    TextStyle? textStyle,
  ) {
    return PullDownMenuItem(
      title: context.t.copyLn.capitalizeFirst(),
      onTap: () => _handleCopyLightningAddress(context),
      itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
      iconWidget: SvgPicture.asset(
        FeatureIcons.copy,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  List<PullDownMenuItem> _buildNwcMenuItems(
    BuildContext context,
    TextStyle? textStyle,
  ) {
    return [
      PullDownMenuItem(
        title: context.t.copyNwc.capitalizeFirst(),
        onTap: () => _handleCopyNwc(context),
        itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
        iconWidget: SvgPicture.asset(
          FeatureIcons.copy,
          height: 20,
          width: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
      PullDownMenuItem(
        title: context.t.export.capitalizeFirst(),
        onTap: () => _handleExportWallet(context),
        itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
        iconWidget: SvgPicture.asset(
          FeatureIcons.export,
          height: 20,
          width: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    ];
  }

  PullDownMenuItem _buildDeleteWalletMenuItem(
    BuildContext context,
    TextStyle? textStyle,
  ) {
    return PullDownMenuItem(
      title: context.t.deleteWallet.capitalizeFirst(),
      onTap: () => _handleDeleteWallet(context),
      itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
      isDestructive: true,
      iconWidget: SvgPicture.asset(
        FeatureIcons.trash,
        height: 20,
        width: 20,
        colorFilter: const ColorFilter.mode(kRed, BlendMode.srcIn),
      ),
    );
  }

  // =============================================================================
  // ACTION HANDLERS
  // =============================================================================

  void _handleLinkWallet(BuildContext context) {
    if (emailRegExp.hasMatch(wallet.lud16)) {
      showCupertinoCustomDialogue(
        context: context,
        title: context.t.linkWallet.capitalizeFirst(),
        description: context.t.linkWalletDesc.capitalizeFirst(),
        buttonText: context.t.link.capitalizeFirst(),
        buttonTextColor: kGreen,
        onClicked: () {
          YNavigator.pop(context);
          walletManagerCubit.linkWallet(wallet);
        },
      );
    } else {
      BotToastUtils.showError(
        context.t.noLnInNwc.capitalizeFirst(),
      );
    }
  }

  void _handleCopyLightningAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: wallet.lud16));
    BotToastUtils.showSuccess(
      context.t.lnCopied.capitalizeFirst(),
    );
  }

  void _handleCopyNwc(BuildContext context) {
    final nwcWallet = wallet as NostrWalletConnectModel;
    Clipboard.setData(ClipboardData(text: nwcWallet.connectionString));
    BotToastUtils.showSuccess(
      context.t.nwcCopied.capitalizeFirst(),
    );
  }

  void _handleExportWallet(BuildContext context) {
    showBlurredModal(
      context: GlobalKeys.navigatorKey.currentState!.overlay!.context,
      isDismissable: false,
      view: ExportWalletOnCreation(
        wallet: wallet as NostrWalletConnectModel,
      ),
    );
  }

  void _handleDeleteWallet(BuildContext context) {
    showCupertinoDeletionDialogue(
      context: context,
      title: context.t.deleteWallet.capitalizeFirst(),
      description: context.t.deleteWalletDesc.capitalizeFirst(),
      buttonText: context.t.delete.capitalizeFirst(),
      toBeCopied: wallet is NostrWalletConnectModel
          ? (wallet as NostrWalletConnectModel).connectionString
          : null,
      onDelete: () {
        walletManagerCubit.removeWallet(
          (wallet as dynamic).id, // Assuming wallet has an id property
          () {},
        );
        YNavigator.pop(context);
      },
    );
  }
}

// =============================================================================
// ADD WALLET BUTTON
// =============================================================================

class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          showBlurredModal(
            context: context,
            view: const WalletOptions(),
          );
        },
        child: Text(context.t.addWallet.capitalizeFirst()),
      ),
    );
  }
}

// =============================================================================
// HELPER CLASSES
// =============================================================================

class _WalletItemInfo {
  const _WalletItemInfo({
    required this.isAlby,
    required this.isLinked,
    required this.displayAddress,
  });

  factory _WalletItemInfo.fromWallet(WalletModel wallet) {
    final metadata = nostrRepository.currentMetadata;
    bool linked = false;

    if (metadata.lud16.isNotEmpty) {
      linked = metadata.lud16 == wallet.lud16;
    } else if (metadata.lud06.isNotEmpty) {
      final lud06 = Zap.getLnurlFromLud16(wallet.lud16);
      linked = metadata.lud06 == lud06;
    }

    return _WalletItemInfo(
      isAlby: wallet is AlbyConnectModel,
      isLinked: linked,
      displayAddress: wallet.lud16,
    );
  }
  final bool isAlby;
  final bool isLinked;
  final String displayAddress;
}
