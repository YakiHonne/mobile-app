import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/cashu/models/mint_info.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_manager/add_discover_filter.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import 'mint_details.dart';
import 'mints_list.dart';

class CreateCashuWallet extends HookWidget {
  const CreateCashuWallet({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2, initialIndex: 1);
    final mintInfos = useState<Map<String, MintInfo>>({});

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
                    text: context.t.active,
                  ),
                  Tab(
                    text: context.t.recommended,
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding / 2),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _activeMintsList(
                      scrollController: scrollController,
                      mintInfos: mintInfos,
                    ),
                    _recommendedList(
                      scrollController: scrollController,
                      mintInfos: mintInfos,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding / 2),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: RegularLoadingButton(
                  title: context.t.createWallet,
                  onClicked: () async {
                    HapticFeedback.mediumImpact();
                    final isSuccessful =
                        await cashuWalletManagerCubit.createWallet(
                      mintInfos.value.keys.toList(),
                    );

                    if (isSuccessful && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  isLoading: false,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeMintsList({
    required ScrollController scrollController,
    required ValueNotifier<Map<String, MintInfo>> mintInfos,
  }) {
    return SubmittedMintsList(
      scrollController: scrollController,
      mintInfos: mintInfos,
    );
  }

  Widget _recommendedList(
      {required ScrollController scrollController,
      required ValueNotifier<Map<String, MintInfo>> mintInfos}) {
    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        return ListView.separated(
          controller: scrollController,
          itemCount: state.recommendedMints.length,
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          separatorBuilder: (context, index) =>
              const SizedBox(height: kDefaultPadding / 3),
          itemBuilder: (context, index) {
            final mint = state.recommendedMints[index];

            return MintContainer(
              isActive: false,
              isAvailableInMintList: mintInfos.value.containsKey(mint.mintURL),
              inActiveList: false,
              url: mint.mintURL,
              mintInfo: mint,
              onActionTap: () {
                if (mintInfos.value.containsKey(mint.mintURL)) {
                  mintInfos.value = {...mintInfos.value..remove(mint.mintURL)};
                } else {
                  mintInfos.value = {
                    ...mintInfos.value,
                    mint.mintURL: mint,
                  };
                }
              },
              onTap: () {
                YNavigator.pushPage(
                  context,
                  (context) => MintDetails(mintInfo: mint),
                );
              },
            );
          },
        );
      },
    );
  }
}

class SubmittedMintsList extends HookWidget {
  const SubmittedMintsList({
    super.key,
    required this.scrollController,
    required this.mintInfos,
  });

  final ScrollController scrollController;
  final ValueNotifier<Map<String, MintInfo>> mintInfos;

  @override
  Widget build(BuildContext context) {
    final textEdittingController = useTextEditingController();
    final text = useState('');

    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        final mints = mintInfos.value.values.toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSearchField(
                    context, textEdittingController, text, mintInfos),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              if (mints.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyList(
                    description: context.t.noMintsAvailable,
                    icon: FeatureIcons.note,
                  ),
                )
              else
                _buildMintsList(mints, mintInfos),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kBottomNavigationBarHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    TextEditingController textEdittingController,
    ValueNotifier<String> text,
    ValueNotifier<Map<String, MintInfo>> mintInfos,
  ) {
    return TextFormField(
      controller: textEdittingController,
      onChanged: (value) {
        text.value = value;
      },
      decoration: InputDecoration(
        hintText: context.t.mintUrl,
        prefixIcon: SvgPicture.asset(
          FeatureIcons.search,
          width: 20,
          height: 20,
          fit: BoxFit.scaleDown,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        suffixIcon: text.value.isEmpty
            ? null
            : CustomIconButton(
                onClicked: () async {
                  HapticFeedback.mediumImpact();
                  final mintInfo =
                      await cashuWalletManagerCubit.getMintInfo(text.value);
                  lg.i(mintInfo);
                  if (mintInfo != null) {
                    textEdittingController.clear();
                    text.value = '';
                    mintInfos.value = {
                      ...mintInfos.value,
                      mintInfo.mintURL: mintInfo,
                    };
                  }
                },
                icon: FeatureIcons.addRaw,
                size: 20,
                backgroundColor: kTransparent,
              ),
      ),
    );
  }

  Widget _buildMintsList(
    List<MintInfo> mints,
    ValueNotifier<Map<String, MintInfo>> mintInfos,
  ) {
    return SliverList.separated(
      itemCount: mints.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 3),
      itemBuilder: (context, index) {
        final mintInfo = mints[index];

        return MintContainer(
          isAvailableInMintList: true,
          isActive: false,
          url: mintInfo.mintURL,
          inActiveList: false,
          mintInfo: mintInfo,
          onActionTap: () {
            mintInfos.value = {...mintInfos.value..remove(mintInfo.mintURL)};
          },
          onTap: () {
            YNavigator.pushPage(
              context,
              (context) => MintDetails(mintInfo: mintInfo),
            );
          },
        );
      },
    );
  }
}
