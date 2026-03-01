// ignore_for_file: prefer_foreach

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../models/packs_model.dart';
import '../../../utils/utils.dart';
import '../../profile_view/widgets/profile_fast_access.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/user_profile_container.dart';

class SignupPacks extends HookWidget {
  const SignupPacks({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = context.select((LogifyCubit cubit) => cubit.packs);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final slivers = <Widget>[];

    slivers.add(
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.starterPacks.capitalizeFirst(),
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: kDefaultPadding / 4),
            Text(
              context.t.starterPacksDesc.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
      ),
    );

    slivers.add(
      const SliverToBoxAdapter(
        child: SizedBox(
          height: kDefaultPadding / 2,
        ),
      ),
    );

    slivers.add(
      isTablet
          ? SliverMasonryGrid.count(
              crossAxisCount: 2,
              itemBuilder: (context, index) {
                final pack = packs[index];

                return PackOnboardingCard(pack: pack);
              },
              childCount: packs.length,
              crossAxisSpacing: kDefaultPadding,
              mainAxisSpacing: kDefaultPadding,
            )
          : SliverList.separated(
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 1.5,
              ),
              itemBuilder: (context, index) {
                final pack = packs[index];

                return PackOnboardingCard(pack: pack);
              },
              itemCount: packs.length,
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      child: ScrollShadow(
        color: Theme.of(context).primaryColorLight.withValues(alpha: 0.5),
        size: 3,
        child: CustomScrollView(slivers: slivers),
      ),
    );
  }
}

class PackOnboardingCard extends StatelessWidget {
  const PackOnboardingCard({super.key, required this.pack});

  final PacksModel pack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return BlocProvider.value(
              value: context.read<LogifyCubit>(),
              child: OnboardingPackInfo(pack: pack),
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          _packHeader(context),
        ],
      ),
    );
  }

  Widget _packFollows() {
    return CommonUsersRow(
      commonPubkeys: pack.pubkeys,
      mainAxisSize: MainAxisSize.min,
      useOthers: true,
    );
  }

  Row _packHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonThumbnail(
          image: pack.image,
          width: 10.w,
          height: 10.w,
          radius: kDefaultPadding / 2,
          isRound: true,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pack.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                pack.description.isNotEmpty
                    ? pack.description
                    : context.t.noDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _packFollows(),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        _buildExpandButton(context),
      ],
    );
  }

  Container _buildExpandButton(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(kDefaultPadding / 3),
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
      child: RotatedBox(
        quarterTurns: 4,
        child: SvgPicture.asset(
          FeatureIcons.arrowRight,
          width: 17,
          height: 17,
          colorFilter: ColorFilter.mode(
            Theme.of(context).highlightColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class OnboardingPackInfo extends HookWidget {
  const OnboardingPackInfo({super.key, required this.pack});

  final PacksModel pack;

  @override
  Widget build(BuildContext context) {
    final pubkeys = pack.pubkeys.toList();

    return BlocBuilder<LogifyCubit, LogifyState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
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
          child: DraggableScrollableSheet(
            maxChildSize: 0.95,
            minChildSize: 0.2,
            initialChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Column(
                children: [
                  const ModalBottomSheetHandle(),
                  Expanded(
                    child: ScrollShadow(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          const SliverToBoxAdapter(
                            child: SizedBox(height: kDefaultPadding / 2),
                          ),
                          _infoHeader(context),
                          const SliverToBoxAdapter(
                            child: Divider(
                              height: kDefaultPadding * 2,
                              thickness: 0.5,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    context.t.inThisPack(
                                      number: pubkeys.length,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                Builder(builder: (context) {
                                  final isFollowingAll = state.pubkeys
                                      .toSet()
                                      .containsAll(pack.pubkeys);

                                  return TextButton(
                                    onPressed: () {
                                      context
                                          .read<LogifyCubit>()
                                          .setListPubkeys(
                                              pkeys: pack.pubkeys,
                                              isDelete: isFollowingAll);
                                    },
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.comfortable,
                                      backgroundColor: state.pubkeys
                                              .toSet()
                                              .containsAll(pack.pubkeys)
                                          ? Theme.of(context).cardColor
                                          : Theme.of(context).primaryColor,
                                    ),
                                    child: Text(
                                      isFollowingAll
                                          ? context.t.unfollowAll
                                              .capitalizeFirst()
                                          : context.t.followAll
                                              .capitalizeFirst(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .copyWith(
                                            color: isFollowingAll
                                                ? Theme.of(context)
                                                    .primaryColorDark
                                                : kWhite,
                                          ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: kDefaultPadding),
                          ),
                          SliverList.separated(
                            itemBuilder: (context, index) {
                              final pubkey = pubkeys[index];
                              final isFollowing =
                                  state.pubkeys.contains(pubkey);

                              return UserProfileContainer(
                                pubkey: pubkey,
                                zaps: 0,
                                currentUserPubKey: '',
                                isFollowing: isFollowing,
                                isDisabled: false,
                                isPending: false,
                                onClicked: () {
                                  context.read<LogifyCubit>().setPubkey(pubkey);
                                },
                              );
                            },
                            itemCount: pubkeys.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: kDefaultPadding / 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _infoHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        spacing: kDefaultPadding / 2,
        children: [
          Center(
            child: CommonThumbnail(
              image: pack.image,
              width: 80,
              height: 80,
              isRound: true,
              radius: 300,
            ),
          ),
          Text(
            pack.title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (pack.description.isNotEmpty) ...[
            Text(
              pack.description,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          MetadataProvider(
            pubkey: pack.pubkey,
            child: (metadata, isNip05Valid) {
              void accessProfile() {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              }

              return GestureDetector(
                onTap: accessProfile,
                behavior: HitTestBehavior.translucent,
                child: Row(
                  spacing: kDefaultPadding / 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.t.by,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                    ProfilePicture2(
                      size: 22,
                      image: metadata.picture,
                      pubkey: metadata.pubkey,
                      padding: 0,
                      strokeWidth: 0,
                      strokeColor: kTransparent,
                      onClicked: accessProfile,
                    ),
                    Flexible(
                      child: Text(
                        metadata.getName().capitalize(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
