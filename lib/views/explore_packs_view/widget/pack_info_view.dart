import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../../logic/explore_pack_details_cubit/explore_pack_details_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/packs_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/content_manager/dicover_settings_views/set_pack_view.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/modal_sheet_container.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/user_profile_container.dart';

class PackInfoView extends StatelessWidget {
  const PackInfoView({super.key, required this.pack});

  final PacksModel pack;

  @override
  Widget build(BuildContext context) {
    final pubkeys = pack.pubkeys.toList();

    return BlocProvider(
      create: (context) => ExplorePackDetailsCubit(),
      child: BlocBuilder<ExplorePackDetailsCubit, ExplorePackDetailsState>(
        builder: (context, state) {
          return ModalSheetContainer(
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
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Builder(builder: (context) {
                                    final isFollowingAll = state.ownFollowings
                                        .toSet()
                                        .containsAll(pack.pubkeys);
                                    return TextButton(
                                      onPressed: () {
                                        context
                                            .read<ExplorePackDetailsCubit>()
                                            .followPack(pack);
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundBuilder: (_, __, child) =>
                                            child!,
                                        visualDensity:
                                            VisualDensity.comfortable,
                                        backgroundColor: state.ownFollowings
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
                                    state.ownFollowings.contains(pubkey);
                                final isSameUser =
                                    state.currentUserPubKey == pubkey;

                                return UserProfileContainer(
                                  pubkey: pubkey,
                                  zaps: 0,
                                  currentUserPubKey: state.currentUserPubKey,
                                  isFollowing: isFollowing,
                                  isDisabled: isSameUser,
                                  isPending: state.pendings.contains(pubkey),
                                  onClicked: () {
                                    context
                                        .read<ExplorePackDetailsCubit>()
                                        .setFollowingOnStop(pubkey);
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
                    Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        Expanded(
                          child: SendOptionsButton(
                            onClicked: () {
                              doIfCanSign(
                                func: () {
                                  YNavigator.pushPage(
                                    context,
                                    (context) => SetPackView(pack: pack),
                                  );
                                },
                                context: context,
                              );
                            },
                            title: context.t.clone.capitalizeFirst(),
                            icon: FeatureIcons.clone,
                          ),
                        ),
                        Expanded(
                          child: SendOptionsButton(
                            onClicked: () {
                              shareContent(
                                text: pack.url,
                                subject: 'Check out this pack: ${pack.title}',
                              );
                            },
                            title: context.t.share.capitalizeFirst(),
                            icon: FeatureIcons.shareExternal,
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
