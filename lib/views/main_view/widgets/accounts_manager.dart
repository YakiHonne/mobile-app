// ignore_for_file: no_default_cases

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/keychain.dart';

import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/settings_cubit/settings_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../logify_view/logify_view.dart';
import '../../wallet_view/widgets/export_wallets.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/modal_with_blur.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/tag_container.dart';

/// Constants for the AccountManager
class _AccountManagerConstants {
  static const double initialChildSize = 0.7;
  static const double minChildSize = 0.40;
  static const double maxChildSize = 0.7;
  static const double slidableExtentRatio = 0.25;
  static const double iconSize = 20.0;
  static const double smallIconSize = 15.0;
  static const double profilePictureSize = 40.0;
  static const double radioButtonSize = 20.0;
  static const double radioButtonInnerSize = 10.0;
  static const double slidableActionSize = 35.0;
  static const double slidableIconSize = 25.0;
}

/// Main account manager widget that displays a draggable bottom sheet
/// with a list of accounts and management options
class AccountManager extends HookWidget {
  const AccountManager({
    super.key,
    required this.scaffoldContext,
  });

  final BuildContext scaffoldContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _buildContainerDecoration(context),
      child: DraggableScrollableSheet(
        initialChildSize: _AccountManagerConstants.initialChildSize,
        minChildSize: _AccountManagerConstants.minChildSize,
        maxChildSize: _AccountManagerConstants.maxChildSize,
        expand: false,
        builder: (_, controller) => _buildContent(context, controller),
      ),
    );
  }

  /// Builds the container decoration with rounded top corners
  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
    );
  }

  /// Builds the main content of the account manager
  Widget _buildContent(BuildContext context, ScrollController controller) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            children: [
              const ModalBottomSheetHandle(),
              _buildTitle(context),
              const SizedBox(height: kDefaultPadding / 2),
              Expanded(
                child: _buildAccountsList(context, state, controller),
              ),
              _buildActionButtons(context),
              const SizedBox(height: kDefaultPadding),
            ],
          ),
        );
      },
    );
  }

  /// Builds the title section
  Widget _buildTitle(BuildContext context) {
    return Text(
      context.t.manageAccounts.capitalizeFirst(),
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  /// Builds the scrollable list of accounts
  Widget _buildAccountsList(
    BuildContext context,
    SettingsState state,
    ScrollController controller,
  ) {
    return Stack(
      children: [
        ScrollShadow(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: ListView.builder(
              controller: controller,
              shrinkWrap: true,
              itemCount: state.keyMap.length,
              itemBuilder: (context, index) =>
                  _buildAccountItem(context, state, index),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds an individual account item with slidable actions
  Widget _buildAccountItem(
    BuildContext context,
    SettingsState state,
    int index,
  ) {
    final stringifiedIndex = state.keyMap.keys.elementAt(index);
    final selectedIndex = int.tryParse(stringifiedIndex);

    if (selectedIndex == null) {
      return const SizedBox.shrink();
    }

    final selectedKey = state.keyMap[stringifiedIndex]!;
    final accountData = _getAccountData(state, stringifiedIndex, selectedKey);

    final accountItem = AccountManagerItemComponent(
      pubkey: accountData.pubkey,
      isCurrent: accountData.isCurrent,
      index: selectedIndex,
      signer: accountData.signer,
      onSelected: () => _handleAccountSelection(context, selectedIndex),
      onDisconnect: () => _handleAccountDisconnect(context, selectedIndex),
    );

    return Slidable(
      key: ValueKey(selectedKey),
      endActionPane:
          _buildSlidableActions(context, selectedIndex, accountData.pubkey),
      child: accountItem,
    );
  }

  /// Gets account data for a specific key
  _AccountData _getAccountData(
    SettingsState state,
    String stringifiedIndex,
    String selectedKey,
  ) {
    final isPrivate = settingsCubit.keyIsPrivateMap[stringifiedIndex] ?? true;
    final pubkey = isPrivate ? Keychain.getPublicKey(selectedKey) : selectedKey;
    final index = int.parse(stringifiedIndex);

    final isCurrent = settingsCubit.privateKeyIndex == index;
    final signer = settingsCubit.isExternalSignerKeyIndex(index)
        ? settingsCubit.isExternalAmber(index)
            ? AppSigner.Amber
            : AppSigner.Bunker
        : settingsCubit.isPrivateKeyIndex(index)
            ? AppSigner.nSec
            : AppSigner.nPub;

    return _AccountData(
      pubkey: pubkey,
      isCurrent: isCurrent,
      signer: signer,
    );
  }

  /// Builds the slidable action panel for account deletion
  ActionPane _buildSlidableActions(
    BuildContext context,
    int selectedIndex,
    String pubkey,
  ) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: _AccountManagerConstants.slidableExtentRatio,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () =>
                _handleSlidableDisconnect(context, selectedIndex, pubkey),
            child: _buildSlidableDeleteButton(),
          ),
        ),
      ],
    );
  }

  /// Builds the delete button for the slidable action
  Widget _buildSlidableDeleteButton() {
    return Container(
      height: _AccountManagerConstants.slidableActionSize,
      width: _AccountManagerConstants.slidableActionSize,
      color: kRed,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        FeatureIcons.log,
        width: _AccountManagerConstants.slidableIconSize,
        height: _AccountManagerConstants.slidableIconSize,
        colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
      ),
    );
  }

  /// Builds the action buttons at the bottom
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        AccountManagerButton(
          icon: FeatureIcons.addRaw,
          title: context.t.addAccount.capitalizeFirst(),
          iconSize: _AccountManagerConstants.smallIconSize,
          onClicked: () => _handleAddAccount(context),
        ),
        AccountManagerButton(
          icon: FeatureIcons.log,
          title: context.t.logoutAllAccounts.capitalizeFirst(),
          onClicked: () => _handleLogoutAll(context),
        ),
      ],
    );
  }

  /// Handles account selection
  void _handleAccountSelection(BuildContext context, int selectedIndex) {
    settingsCubit.onLoginTap(selectedIndex, () => _navigateToMain(context));
  }

  /// Handles account disconnection
  void _handleAccountDisconnect(BuildContext context, int selectedIndex) {
    settingsCubit.onLogoutTap(
      selectedIndex,
      onPop: () => _navigateToMain(context),
    );
  }

  /// Handles slidable disconnect action with wallet check
  void _handleSlidableDisconnect(
    BuildContext context,
    int selectedIndex,
    String pubkey,
  ) {
    void disconnect() {
      settingsCubit.onLogoutTap(
        selectedIndex,
        onPop: () => context.read<MainCubit>().updateIndex(MainViews.leading),
      );
    }

    final isCurrentSigner = currentSigner?.getPublicKey() == pubkey;
    final wallets = walletManagerCubit.getUserWallets(
      isCurrentSigner,
      pubkey: isCurrentSigner ? null : pubkey,
    );

    _handleWalletExportOrDisconnect(context, wallets, disconnect);
  }

  /// Handles adding a new account
  void _handleAddAccount(BuildContext context) {
    YNavigator.pushReplacement(context, LogifyView());
  }

  /// Handles logging out all accounts
  void _handleLogoutAll(BuildContext context) {
    Future<void> disconnectAll() async {
      await settingsCubit.onAllLogout();

      if (context.mounted) {
        context.read<MainCubit>().setDefault();
        context.read<WalletsManagerCubit>().deleteWalletConfiguration();
        Navigator.of(context).popUntil((route) => route.isFirst);
        Scaffold.of(scaffoldContext).closeDrawer();
      }
    }

    final wallets = walletManagerCubit.getUserWallets(false);
    _handleWalletExportOrDisconnect(context, wallets, disconnectAll);
  }

  /// Handles wallet export or direct disconnect based on wallet presence
  void _handleWalletExportOrDisconnect(
    BuildContext context,
    Map<String, List<NostrWalletConnectModel>> wallets,
    VoidCallback disconnectCallback,
  ) {
    if (wallets.isNotEmpty) {
      showBlurredModal(
        context: context,
        isDismissable: false,
        view: ExportWalletOnLoginOut(
          onLogout: disconnectCallback,
          wallets: wallets,
        ),
      );
    } else {
      disconnectCallback();
    }
  }

  /// Navigates to the main view and closes modals
  void _navigateToMain(BuildContext context) {
    YNavigator.popToRoot(context);
    context.read<MainCubit>().updateIndex(MainViews.leading);
  }
}

/// Data class to hold account information
class _AccountData {
  const _AccountData({
    required this.pubkey,
    required this.isCurrent,
    required this.signer,
  });

  final String pubkey;
  final bool isCurrent;
  final AppSigner signer;
}

/// Reusable button component for account manager actions
class AccountManagerButton extends StatelessWidget {
  const AccountManagerButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onClicked,
    this.iconSize,
  });

  final String icon;
  final String title;
  final VoidCallback onClicked;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onClicked,
        icon: SvgPicture.asset(
          icon,
          width: iconSize ?? _AccountManagerConstants.iconSize,
          height: iconSize ?? _AccountManagerConstants.iconSize,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        label: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}

/// Individual account item component with profile information and actions
class AccountManagerItemComponent extends HookWidget {
  const AccountManagerItemComponent({
    super.key,
    required this.pubkey,
    required this.index,
    required this.isCurrent,
    required this.signer,
    required this.onSelected,
    required this.onDisconnect,
  });

  final String pubkey;
  final int index;
  final bool isCurrent;
  final AppSigner signer;
  final VoidCallback onSelected;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    useMemoized(() => metadataCubit.requestMetadata(pubkey));

    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, isNip05Valid) {
        return GestureDetector(
          onTap: onSelected,
          child: Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: _buildItemDecoration(context),
            child: Row(
              children: [
                _buildRadioButton(context),
                const SizedBox(width: kDefaultPadding / 2),
                _buildProfilePicture(context, metadata),
                const SizedBox(width: kDefaultPadding / 2),
                _buildAccountInfo(context, metadata),
                const SizedBox(width: kDefaultPadding / 4),
                _buildSignerTag(context),
                const SizedBox(width: kDefaultPadding / 2),
                _buildLogoutButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the item container decoration
  BoxDecoration _buildItemDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      color: isCurrent ? Theme.of(context).cardColor : null,
    );
  }

  /// Builds the radio button indicator
  Widget _buildRadioButton(BuildContext context) {
    return Container(
      width: _AccountManagerConstants.radioButtonSize,
      height: _AccountManagerConstants.radioButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? Theme.of(context).primaryColor
            : Theme.of(context).cardColor,
        border: Border.all(
          color: !isCurrent ? Theme.of(context).dividerColor : kTransparent,
        ),
      ),
      alignment: Alignment.center,
      child: isCurrent
          ? Container(
              width: _AccountManagerConstants.radioButtonInnerSize,
              height: _AccountManagerConstants.radioButtonInnerSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kWhite,
              ),
            )
          : null,
    );
  }

  /// Builds the profile picture
  Widget _buildProfilePicture(BuildContext context, dynamic metadata) {
    return ProfilePicture3(
      size: _AccountManagerConstants.profilePictureSize,
      image: metadata.picture,
      pubkey: metadata.pubkey,
      padding: 0,
      strokeWidth: 0,
      reduceSize: true,
      strokeColor: kTransparent,
      onClicked: () => openProfileFastAccess(
        context: context,
        pubkey: metadata.pubkey,
      ),
    );
  }

  /// Builds the account information section
  Widget _buildAccountInfo(BuildContext context, dynamic metadata) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.getName(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Nip05Component(
            metadata: metadata,
            removeSpace: true,
          ),
        ],
      ),
    );
  }

  /// Builds the signer tag
  Widget _buildSignerTag(BuildContext context) {
    final signerColor = _getSignerColor();

    return TagContainer(
      title: signer.name,
      isActive: true,
      onClick: onSelected,
      textColor: signerColor,
      backgroundColor: signerColor.withValues(alpha: 0.1),
    );
  }

  /// Gets the appropriate color for the signer type
  Color _getSignerColor() {
    switch (signer) {
      case AppSigner.nSec:
        return kRed;
      case AppSigner.nPub:
        return kYellow;
      case AppSigner.Amber:
        return kMainColor;
      default:
        return kGreen;
    }
  }

  /// Builds the logout button for current account
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: isCurrent
          ? CustomIconButton(
              onClicked: () => _handleCurrentAccountLogout(context),
              icon: FeatureIcons.log,
              size: _AccountManagerConstants.radioButtonSize,
              vd: -4,
              backgroundColor: Theme.of(context).cardColor,
            )
          : const SizedBox.shrink(),
    );
  }

  /// Handles logout for the current account with wallet check
  void _handleCurrentAccountLogout(BuildContext context) {
    final wallets = walletManagerCubit.getUserWallets(true);

    if (wallets.isNotEmpty) {
      showBlurredModal(
        context: context,
        isDismissable: false,
        view: ExportWalletOnLoginOut(
          onLogout: onDisconnect,
          wallets: wallets,
        ),
      );
    } else {
      onDisconnect();
    }
  }
}
