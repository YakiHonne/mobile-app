import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../utils/utils.dart';
import '../../wallet_cashu_view/widgets/create_cashu_wallet.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/modal_with_blur.dart';
import '../send_view/send_using_invoice.dart';
import '../widgets/wallet_options_view.dart';
import 'select_mint_modal.dart';

/// Widget for selecting between default wallet and internal/external wallets
class MultiWalletSelector extends StatelessWidget {
  const MultiWalletSelector({
    super.key,
    required this.zapPaymentMethod,
  });

  final ValueNotifier<ZapPaymentMethod> zapPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) =>
          BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
        builder: (context, cashuState) => Row(
          spacing: kDefaultPadding / 4,
          children: [
            _buildWalletSelector(context, state, cashuState),
            _buildToggleSelection(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector(
    BuildContext context,
    WalletsManagerState state,
    CashuWalletManagerState cashuState,
  ) {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getCurrentWalletSelector(context, state, cashuState),
      ),
    );
  }

  Widget _getCurrentWalletSelector(
    BuildContext context,
    WalletsManagerState state,
    CashuWalletManagerState cashuState,
  ) {
    switch (zapPaymentMethod.value) {
      case ZapPaymentMethod.cashu:
        if (cashuState.walletMints.isEmpty) {
          return CreateWalletPrompt(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => const CreateCashuWallet(),
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
            label: context.t.addCashuWallet.capitalizeFirst(),
            icon: Images.cashu,
          );
        }
        return const CashuWalletSelector();
      case ZapPaymentMethod.internal:
        if (!state.hasWallets) {
          return CreateWalletPrompt(
            onTap: () {
              showBlurredModal(
                context: context,
                view: const WalletOptions(),
              );
            },
            label: context.t.connectWithNwc.capitalizeFirst(),
            icon: FeatureIcons.nwc,
          );
        }
        return const InternalWalletSelector();
      case ZapPaymentMethod.external:
        return const ExternalWalletSelector();
    }
  }

  Widget _buildToggleSelection(
    BuildContext context,
    WalletsManagerState state,
  ) {
    final selectedMethod = zapPaymentMethod.value;
    final selectedAsset = _getAssetForMethod(selectedMethod, state);
    final isSvg = selectedAsset.endsWith('.svg');
    final isExternalWallet = selectedMethod == ZapPaymentMethod.external;

    return GestureDetector(
      onTap: () {
        _showPaymentMethodOverlay(context, state);
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Center(
          child: isSvg
              ? SvgPicture.asset(
                  selectedAsset,
                  width: 22,
                  height: 22,
                  colorFilter: isExternalWallet
                      ? ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        )
                      : null,
                )
              : Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                    image: DecorationImage(
                      image: AssetImage(
                        selectedAsset,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  String _getAssetForMethod(
      ZapPaymentMethod method, WalletsManagerState state) {
    switch (method) {
      case ZapPaymentMethod.internal:
        return FeatureIcons.nwc;
      case ZapPaymentMethod.cashu:
        return Images.cashu;
      case ZapPaymentMethod.external:
        return wallets[state.defaultExternalWallet]!['icon']!;
    }
  }

  void _showPaymentMethodOverlay(
    BuildContext context,
    WalletsManagerState state,
  ) {
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedOverlay(
        offset: offset,
        onDismiss: () => overlayEntry.remove(),
        state: state,
        zapPaymentMethod: zapPaymentMethod,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _AnimatedOverlay extends StatefulWidget {
  const _AnimatedOverlay({
    required this.offset,
    required this.onDismiss,
    required this.state,
    required this.zapPaymentMethod,
  });

  final Offset offset;
  final VoidCallback onDismiss;
  final WalletsManagerState state;
  final ValueNotifier<ZapPaymentMethod> zapPaymentMethod;

  @override
  State<_AnimatedOverlay> createState() => _AnimatedOverlayState();
}

class _AnimatedOverlayState extends State<_AnimatedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Container(color: Colors.transparent),
          Positioned(
            right: widget.offset.dx,
            top: widget.offset.dy - 115,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.bottomRight,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  child: Container(
                    width: 170,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: kDefaultPadding / 4,
                      children: [
                        _buildMethodOption(
                          context,
                          widget.state,
                          ZapPaymentMethod.internal,
                          FeatureIcons.nwc,
                          'NWC Wallets',
                          () {
                            widget.zapPaymentMethod.value =
                                ZapPaymentMethod.internal;
                            widget.onDismiss();
                          },
                          widget.zapPaymentMethod,
                        ),
                        _buildMethodOption(
                          context,
                          widget.state,
                          ZapPaymentMethod.cashu,
                          Images.cashu,
                          'Cashu Wallet',
                          () {
                            widget.zapPaymentMethod.value =
                                ZapPaymentMethod.cashu;
                            widget.onDismiss();
                          },
                          widget.zapPaymentMethod,
                        ),
                        _buildMethodOption(
                          context,
                          widget.state,
                          ZapPaymentMethod.external,
                          wallets[widget.state.defaultExternalWallet]!['icon']!,
                          'External Wallet',
                          () {
                            widget.zapPaymentMethod.value =
                                ZapPaymentMethod.external;
                            widget.onDismiss();
                          },
                          widget.zapPaymentMethod,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(
    BuildContext context,
    WalletsManagerState state,
    ZapPaymentMethod method,
    String asset,
    String label,
    VoidCallback onTap,
    ValueNotifier<ZapPaymentMethod> zapPaymentMethod,
  ) {
    final isSelected = zapPaymentMethod.value == method;
    final isSvg = asset.endsWith('.svg');
    final isExternalWallet = method == ZapPaymentMethod.external;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 3),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          spacing: kDefaultPadding / 2,
          children: [
            SizedBox(
              width: 7,
              height: 7,
              child: isSelected
                  ? DotContainer(
                      color: Theme.of(context).primaryColor,
                      isNotMarging: true,
                      size: 7,
                    )
                  : const SizedBox.shrink(),
            ),
            if (isSvg)
              SvgPicture.asset(
                asset,
                width: 22,
                height: 22,
                colorFilter: isExternalWallet
                    ? ColorFilter.mode(
                        isSelected ? kWhite : Theme.of(context).hintColor,
                        BlendMode.srcIn,
                      )
                    : null,
              )
            else
              Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  image: DecorationImage(
                    image: AssetImage(
                      asset,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateWalletPrompt extends StatelessWidget {
  const CreateWalletPrompt({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final VoidCallback onTap;
  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final isSvg = icon.endsWith('.svg');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        height: 35,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSvg)
              SvgPicture.asset(
                icon,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor,
                  BlendMode.srcIn,
                ),
              )
            else
              Image.asset(
                icon,
                width: 15,
                height: 15,
              ),
            const SizedBox(width: kDefaultPadding / 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CashuWalletSelector extends StatelessWidget {
  const CashuWalletSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => const SelectMintModal(),
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 4,
            ),
            height: 35,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: _buildMintIcon(state),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Flexible(
                  child: Text(
                    _getMintName(state),
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMintIcon(CashuWalletManagerState state) {
    if (state.activeMint.isEmpty) {
      return ExtendedImage.asset(
        Images.cashu,
        fit: BoxFit.cover,
      );
    }

    final mint = state.mints[state.activeMint];
    final iconUrl = mint?.info?.iconUrl;

    if (iconUrl != null && iconUrl.isNotEmpty) {
      return ExtendedImage.network(
        iconUrl,
        fit: BoxFit.cover,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            return ExtendedImage.asset(
              Images.cashu,
              fit: BoxFit.cover,
            );
          }
          return null;
        },
      );
    }

    return ExtendedImage.asset(
      Images.cashu,
      fit: BoxFit.cover,
    );
  }

  String _getMintName(CashuWalletManagerState state) {
    if (state.activeMint.isEmpty) {
      return 'Select Mint';
    }

    final mint = state.mints[state.activeMint];
    return mint?.info?.name ?? state.activeMint;
  }
}
