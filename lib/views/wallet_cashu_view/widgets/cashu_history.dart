import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/cashu/models/cashu_encoded_token.dart';
import 'package:nostr_core_enhanced/cashu/models/cashu_spending_data.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../models/cashu/nutzap.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/profile_picture.dart';
import 'cashu_operation_success_view.dart';
import 'cashu_token_details_view.dart';

class CashuHistory extends HookWidget {
  const CashuHistory({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(
      initialLength: 3,
      initialIndex: initialIndex,
    );
    final isLoading = useState(true);
    final history = useState<List<CashuSpendingData>>([]);
    final nutzaps = useState<List<NutZap>>([]);
    final tokens = useState<List<CashuEncodedToken>>([]);

    final refresh = useCallback(() async {
      isLoading.value = true;
      final results = await Future.wait([
        cashuWalletManagerCubit.getHistory(),
        cashuWalletManagerCubit.getReceivedNutzaps(),
      ]);

      if (context.mounted) {
        history.value = results[0] as List<CashuSpendingData>;
        nutzaps.value = results[1] as List<NutZap>;
        tokens.value = cashuWalletManagerCubit.getCreatedTokens();
        isLoading.value = false;
      }
    }, []);

    useEffect(() {
      refresh();
      return null;
    }, []);

    return Material(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(kDefaultPadding),
        topRight: Radius.circular(kDefaultPadding),
      ),
      child: Container(
        width: double.infinity,
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
        child: DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          initialChildSize: 0.9,
          builder: (context, scrollController) => Column(
            children: [
              const ModalBottomSheetHandle(),
              const SizedBox(height: kDefaultPadding / 2),
              TabBar(
                controller: tabController,
                dividerHeight: 0,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: Theme.of(context).primaryColor,
                labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                tabs: [
                  Tab(
                    text: context.t.history,
                  ),
                  Tab(
                    text: context.t.eCash,
                  ),
                  Tab(
                    text: context.t.nutzaps,
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding / 2),
              Expanded(
                child: isLoading.value
                    ? Center(
                        child: SpinKitCircle(
                          color: Theme.of(context).primaryColorDark,
                          size: 20,
                        ),
                      )
                    : TabBarView(
                        controller: tabController,
                        children: [
                          _HistoryList(
                            history: history.value,
                            scrollController: scrollController,
                          ),
                          _TokensList(
                            tokens: tokens.value,
                            scrollController: scrollController,
                            onRefresh: refresh,
                          ),
                          _NutzapsList(
                            nutzaps: nutzaps.value,
                            scrollController: scrollController,
                            onRefresh: refresh,
                          ),
                        ],
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends HookWidget {
  const _HistoryList({
    required this.history,
    required this.scrollController,
  });

  final List<CashuSpendingData> history;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return history.isEmpty
        ? Center(
            child: EmptyList(
              description: context.t.noTransactionCanBeFound,
              icon: FeatureIcons.transactions,
            ),
          )
        : isTablet
            ? _itemsGrid(history)
            : _itemsList(history);
  }

  Widget _itemsGrid(List<CashuSpendingData> history) {
    return GridView.builder(
      controller: scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: kDefaultPadding,
        mainAxisSpacing: kDefaultPadding,
      ),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _historyItem(
          item: item,
          context: context,
        );
      },
    );
  }

  Widget _itemsList(List<CashuSpendingData> history) {
    return ListView.separated(
      controller: scrollController,
      itemCount: history.length,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 2),
      itemBuilder: (context, index) {
        final id = history[index];
        return _historyItem(
          item: id,
          context: context,
        );
      },
    );
  }

  Widget _historyItem({
    required CashuSpendingData item,
    required BuildContext context,
  }) {
    return MetadataProvider(
      pubkey: item.senderPubkey,
      child: (metadata, nip05) => Row(
        spacing: kDefaultPadding / 2,
        children: [
          _userProfile(
            context: context,
            metadata: metadata,
            direction: item.direction,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat4.format(
                    DateTime.fromMillisecondsSinceEpoch(item.createdAt * 1000),
                  ),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
                Text(
                  item.direction == CashuSpendingDirection.incoming
                      ? item.senderPubkey.isNotEmpty
                          ? context.t.userSentSat(
                              name: metadata.name, number: item.amount)
                          : context.t.ownReceivedSat(number: item.amount)
                      : context.t.ownSentSat(
                          number: item.amount,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stack _userProfile({
    required BuildContext context,
    required Metadata metadata,
    required CashuSpendingDirection direction,
  }) {
    return Stack(
      children: [
        Container(
          margin: metadata.pubkey.isNotEmpty
              ? const EdgeInsets.only(bottom: 5, right: 5)
              : null,
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardColor,
          ),
          child: metadata.pubkey.isNotEmpty
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
                      direction == CashuSpendingDirection.incoming
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: direction == CashuSpendingDirection.incoming
                          ? kGreen
                          : kRed,
                      size: 25,
                    ),
                  ),
                ),
        ),
        if (metadata.pubkey.isNotEmpty)
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
                  direction == CashuSpendingDirection.incoming
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: direction == CashuSpendingDirection.incoming
                      ? kGreen
                      : kRed,
                  size: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TokensList extends HookWidget {
  const _TokensList({
    required this.tokens,
    required this.scrollController,
    required this.onRefresh,
  });

  final List<CashuEncodedToken> tokens;
  final ScrollController scrollController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final usedTokens = tokens.reversed.toList();
    return tokens.isEmpty
        ? Center(
            child: EmptyList(
              description: context.t.noTokenCanBeFound,
              icon: FeatureIcons.sendEcash,
            ),
          )
        : ListView.separated(
            controller: scrollController,
            itemCount: usedTokens.length,
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            separatorBuilder: (context, index) =>
                const SizedBox(height: kDefaultPadding / 2),
            itemBuilder: (context, index) {
              final token = usedTokens[index];
              void onClicked() {
                YNavigator.presentPage(
                  context,
                  (_) => CashuTokenDetailsView(
                    token: token,
                    onRefresh: onRefresh,
                  ),
                );
              }

              return GestureDetector(
                onTap: onClicked,
                child: Container(
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: Center(
                          child: ExtendedImage.asset(
                            Images.cashu,
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: kDefaultPadding / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dateFormat4.format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      token.createdAt,
                                    ),
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: Theme.of(context).highlightColor,
                                      ),
                                ),
                                DotContainer(
                                  color: Theme.of(context).highlightColor,
                                ),
                                Text(
                                  '${token.amount} sats',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            Text(
                              token.encodedToken,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      CustomIconButton(
                        onClicked: onClicked,
                        icon: FeatureIcons.arrowRight,
                        size: 20,
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class _NutzapsList extends HookWidget {
  const _NutzapsList({
    required this.nutzaps,
    required this.scrollController,
    required this.onRefresh,
  });

  final List<NutZap> nutzaps;
  final ScrollController scrollController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (nutzaps.isEmpty) {
      return Center(
        child: EmptyList(
          title: context.t.noNutzapsFound,
          description: context.t.noNutzapsFoundDesc,
          icon: FeatureIcons.wallet,
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 2),
      itemCount: nutzaps.length,
      itemBuilder: (context, index) {
        final nutzap = nutzaps[index];
        return MetadataProvider(
          pubkey: nutzap.senderPubkey,
          child: (metadata, isNip05Valid) {
            return Container(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  ProfilePicture2(
                    size: 45,
                    image: metadata.picture,
                    pubkey: metadata.pubkey,
                    padding: 0,
                    strokeWidth: 0,
                    strokeColor: kTransparent,
                    onClicked: () {
                      openProfileFastAccess(
                        context: context,
                        pubkey: metadata.pubkey,
                      );
                    },
                  ),
                  const SizedBox(width: kDefaultPadding / 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metadata.getName(),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${nutzap.amount} sats',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: kMainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: kDefaultPadding / 4),
                            Text(
                              '•',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(width: kDefaultPadding / 4),
                            Text(
                              dateFormat6.format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    nutzap.createdAt * 1000),
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        if (nutzap.memo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            nutzap.memo,
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding / 2),
                  SizedBox(
                    height: 35,
                    child: nutzap.isClaimed
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: kDefaultPadding,
                            ),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              color: kGreen,
                              size: 25,
                            ),
                          )
                        : StatusButton(
                            onClicked: () async {
                              final success = await cashuWalletManagerCubit
                                  .claimNutzap(nutzap);
                              if (success && context.mounted) {
                                onRefresh();
                                YNavigator.presentPage(
                                  nostrRepository.ctx,
                                  (_) => CashuOperationSuccessView(
                                    amount: nutzap.amount,
                                    title: nostrRepository
                                        .ctx.t.nutzapClaimedSuccessful,
                                  ),
                                );
                              }
                            },
                            text: context.t.claim,
                            isDisabled: false,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
