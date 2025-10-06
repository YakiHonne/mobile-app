import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/article_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import '../wallet_view.dart';

class TransactionsList extends HookWidget {
  const TransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    useMemoized(() {
      walletManagerCubit.getTransactions();
    });

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
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.40,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              _header(context),
              _content(isTablet),
            ],
          ),
        ),
      ),
    );
  }

  BlocBuilder<WalletsManagerCubit, WalletsManagerState> _content(
      bool isTablet) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        if (state.searchResultsType == SearchResultsType.loading) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
              child: Lottie.asset(
                themeCubit.isDark
                    ? LottieAnimations.loading
                    : LottieAnimations.loadingDark,
                height: 50,
                width: 50,
                fit: BoxFit.contain,
              ),
            ),
          );
        } else if (state.searchResultsType == SearchResultsType.content) {
          final ids = state.transactions;

          if (ids.isEmpty) {
            return SliverToBoxAdapter(
              child: EmptyList(
                description:
                    context.t.noTransactionCanBeFound.capitalizeFirst(),
                icon: FeatureIcons.zap,
              ),
            );
          } else {
            if (isTablet) {
              return _itemsGrid(state);
            } else {
              return _itemsList(state, ids);
            }
          }
        } else {
          return SliverToBoxAdapter(
            child: Text(
              context.t.selectWalletTransactions.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          );
        }
      },
    );
  }

  SliverList _itemsList(
      WalletsManagerState state, List<WalletTransactionModel> ids) {
    return SliverList.separated(
      itemBuilder: (context, index) {
        final zap = state.transactions[index];

        return InternalWalletZapContainer(zap: zap);
      },
      itemCount: ids.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );
  }

  SliverGrid _itemsGrid(WalletsManagerState state) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: kDefaultPadding / 2,
        mainAxisSpacing: kDefaultPadding / 2,
        mainAxisExtent: 75,
      ),
      itemBuilder: (context, index) {
        final zap = state.transactions[index];

        return InternalWalletZapContainer(zap: zap);
      },
      itemCount: state.transactions.length,
    );
  }

  SliverToBoxAdapter _header(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          const ModalBottomSheetHandle(),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            context.t.recentTransactions.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
        ],
      ),
    );
  }
}
