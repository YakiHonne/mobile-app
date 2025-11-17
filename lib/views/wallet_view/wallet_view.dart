// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../utils/utils.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/data_providers.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/profile_picture.dart';
import 'widgets/empty_wallets.dart';
import 'widgets/wallet_balance_container.dart';

class InternalWalletsView extends HookWidget {
  InternalWalletsView({
    super.key,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Wallets manager view');
  }

  final gK = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    final iwto = useState(InternalWalletTransactionOption.none);

    final isRefreshing = useState(false);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final animation = useMemoized(
      () {
        return Tween<double>(begin: 0, end: 60).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        );
      },
    );

    // Define the refresh logic
    Future<void> onRefresh() async {
      if (controller != null) {
        isRefreshing.value = true;
        controller.forward();
        walletManagerCubit.requestBalance();
        walletManagerCubit.getBtcInFiat();

        await Future.delayed(
          const Duration(seconds: 1),
        ).then(
          (value) {
            if (controller != null) {
              controller.reverse();
            }
          },
        );
        isRefreshing.value = false;
      }
    }

    void onVerticalDragUpdate(DragUpdateDetails details) {
      if (details.primaryDelta! > 10 && !isRefreshing.value) {
        onRefresh();
      }
    }

    return FadeIn(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          nostrRepository.mainCubit.updateIndex(MainViews.leading);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
            builder: (context, state) {
              if (isDisconnected() || canRoam()) {
                return const SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VerticalViewModeWidget(),
                    ],
                  ),
                );
              } else if (state.wallets.isEmpty) {
                return const Center(
                  child: DisconnectedWallet(),
                );
              }

              return _refreshable(
                  context, onVerticalDragUpdate, animation, isRefreshing, iwto);
            },
          ),
        ),
      ),
    );
  }

  RefreshIndicator _refreshable(
      BuildContext context,
      Function(DragUpdateDetails) onVerticalDragUpdate,
      Animation<double> animation,
      ValueNotifier<bool> isRefreshing,
      ValueNotifier<InternalWalletTransactionOption> iwto) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: Theme.of(context).primaryColorDark,
      child: GestureDetector(
        onVerticalDragUpdate: onVerticalDragUpdate,
        child: Column(
          children: [
            _loadingCircle(animation, isRefreshing),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _selectedWallet(),
            Expanded(
              child: WallatBalanceContainer(
                setOption: (option) => iwto.value = option,
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
      ),
    );
  }

  Builder _selectedWallet() {
    return Builder(
      builder: (context) {
        final m = nostrRepository.currentMetadata;
        final hasWallet = m.lud06.isNotEmpty || m.lud16.isNotEmpty;

        if (hasWallet) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Center(
            child: Column(
              children: [
                Text(
                  context.t.noWalletLinked.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AnimatedBuilder _loadingCircle(
      Animation<double> animation, ValueNotifier<bool> isRefreshing) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: animation.value,
          alignment: Alignment.center,
          child: isRefreshing.value
              ?  SizedBox(
                  height: 20,
                  width: 20,
                  child: SpinKitFadingCircle(
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class InternalWalletZapContainer extends HookWidget {
  const InternalWalletZapContainer({
    super.key,
    required this.zap,
  });

  final WalletTransactionModel zap;

  @override
  Widget build(BuildContext context) {
    final isMessageHidden = useState(true);

    return MetadataProvider(
      pubkey: zap.pubkey,
      child: (metadata, isNip05Valid) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _userProfile(context, metadata),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                _transactionInfo(context, metadata),
                if (zap.message.isNotEmpty) ...[
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  CustomIconButton(
                    onClicked: () {
                      isMessageHidden.value = !isMessageHidden.value;
                    },
                    icon: FeatureIcons.messageNotif,
                    size: 20,
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                ]
              ],
            ),
            if (!isMessageHidden.value) ...[
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _toggleComment(context),
            ],
          ],
        );
      },
    );
  }

  Container _toggleComment(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 65),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).cardColor,
        border: Border.all(width: 0.3, color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.comment.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            zap.message,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
        ],
      ),
    );
  }

  Expanded _transactionInfo(BuildContext context, Metadata metadata) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t
                .onDate(
                  date: dateFormat4.format(zap.createdAt),
                )
                .capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          Text(
            zap.pubkey.isNotEmpty
                ? zap.isIncoming
                    ? context.t
                        .userSentSat(
                          name: metadata.getName(),
                          number: zap.amount.toStringAsFixed(0),
                        )
                        .capitalizeFirst()
                    : context.t
                        .userReceivedSat(
                          name: metadata.getName(),
                          number: zap.amount.toStringAsFixed(0),
                        )
                        .capitalizeFirst()
                : zap.isIncoming
                    ? context.t
                        .ownReceivedSat(
                          number: zap.amount.toStringAsFixed(0),
                        )
                        .capitalizeFirst()
                    : context.t
                        .ownSentSat(
                          number: zap.amount.toStringAsFixed(0),
                        )
                        .capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }

  Stack _userProfile(BuildContext context, Metadata metadata) {
    return Stack(
      children: [
        Container(
          margin: zap.pubkey.isNotEmpty
              ? const EdgeInsets.only(bottom: 5, right: 5)
              : null,
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardColor,
          ),
          child: zap.pubkey.isNotEmpty
              ? ProfilePicture2(
                  size: 50,
                  image: metadata.picture,
                  pubkey: metadata.pubkey,
                  padding: 0,
                  strokeWidth: 0,
                  reduceSize: true,
                  strokeColor: kTransparent,
                  onClicked: () {
                    openProfileFastAccess(
                      context: context,
                      pubkey: metadata.pubkey,
                    );
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                  ),
                  child: Center(
                    child: Icon(
                      zap.isIncoming
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: zap.isIncoming ? kGreen : kRed,
                      size: 25,
                    ),
                  ),
                ),
        ),
        if (zap.pubkey.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
              ),
              child: Center(
                child: Icon(
                  zap.isIncoming
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: zap.isIncoming ? kGreen : kRed,
                  size: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
