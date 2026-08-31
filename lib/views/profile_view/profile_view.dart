// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../logic/dms_cubit/dms_cubit.dart';
import '../../logic/profile_cubit/profile_cubit.dart';
import '../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/flash_news_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../dm_view/widgets/dm_details.dart';
import '../gallery_view/gallery_view.dart';
import '../profile_settings_view/profile_settings_view.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/classic_footer.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/fluid_blur_container.dart';
import '../widgets/fluid_glass_tab_bar.dart';
import '../widgets/fluid_pull_down_button.dart';
import '../widgets/fluid_sheet.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/profile_picture.dart';
import '../widgets/pull_down_global_button.dart';
import 'widgets/profile_articles.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_media.dart';
import 'widgets/profile_notes.dart';
import 'widgets/profile_others.dart';
import 'widgets/relays_list.dart';

/// Profile tab order — premium sits right after notes when the user has it.
List<ProfileData> profileTabs(bool hasPremium) => [
      ProfileData.notes,
      if (hasPremium) ProfileData.premium,
      ProfileData.articles,
      ProfileData.allMedia,
      ProfileData.curations,
    ];

class ProfileView extends HookWidget {
  static const routeName = '/profileView';
  static Route route(RouteSettings settings) {
    final list = settings.arguments! as List;

    return CupertinoPageRoute(
      builder: (_) => ProfileView(
        pubkey: list[0] as String,
        profileData:
            list.length > 1 ? list[1] as ProfileData : ProfileData.notes,
      ),
    );
  }

  ProfileView({
    super.key,
    required this.pubkey,
    this.profileData = ProfileData.notes,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Profile view');
  }

  final String pubkey;
  final ProfileData profileData;

  @override
  Widget build(BuildContext context) {
    final profileDataState = useState(profileData);

    return BlocProvider(
      create: (context) => ProfileCubit(
        pubkey: pubkey,
      )..initView(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return Scaffold(
            appBar: isUserMuted(pubkey)
                ? CustomAppBar(
                    title: context.t.user.capitalize(),
                  )
                : null,
            body: isUserMuted(pubkey)
                ? Center(
                    child: MutedUserContent(
                      pubkey: pubkey,
                    ),
                  )
                : BlocBuilder<ProfileCubit, ProfileState>(
                    buildWhen: (previous, current) =>
                        previous.profileStatus != current.profileStatus ||
                        previous.creatorProviders != current.creatorProviders,
                    builder: (context, state) {
                      final hasPremium =
                          state.creatorProviders?.isNotEmpty ?? false;

                      return DefaultTabController(
                        length: hasPremium ? 5 : 4,
                        initialIndex:
                            getIndex(profileDataState.value, hasPremium),
                        child: ProfileNestedScrollView(
                          profileDataState: profileDataState,
                          hasPremium: hasPremium,
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  int getIndex(ProfileData profileData, bool hasPremium) {
    final index = profileTabs(hasPremium)
        .indexWhere((tab) => tab.getType() == profileData.getType());

    return index == -1 ? 0 : index;
  }
}

class ProfileNestedScrollView extends StatefulWidget {
  const ProfileNestedScrollView({
    super.key,
    required this.profileDataState,
    required this.hasPremium,
  });

  final ValueNotifier<ProfileData> profileDataState;
  final bool hasPremium;

  @override
  State<ProfileNestedScrollView> createState() =>
      _ProfileNestedScrollViewState();
}

class _ProfileNestedScrollViewState extends State<ProfileNestedScrollView> {
  final refreshController = RefreshController();

  void onRefresh({required Function() onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.loadingState == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.loadingState == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.loadingState != current.loadingState ||
          previous.mutes != current.mutes ||
          previous.user != current.user,
      builder: (context, state) {
        final currentType = widget.profileDataState.value.getType();
        final isNotes = currentType == 'notes';
        final isMedia = currentType == 'media';
        final isOthers = currentType == 'others';
        final showFilter = (isNotes || isMedia || isOthers) && isFluid();
        final showSwitcher = currentType == 'premium';

        return Stack(
          children: [
            SmartRefresher(
              controller: refreshController,
              enablePullUp: true,
              enablePullDown: false,
              footer: const RefresherClassicFooter(),
              onLoading: () => context.read<ProfileCubit>().getUserInfos(
                    profileData: widget.profileDataState.value,
                    isAdding: true,
                  ),
              child: CustomScrollView(
                slivers: [
                  ProfileAppBar(
                    profileData: widget.profileDataState.value,
                  ),
                  const SliverToBoxAdapter(
                    child: ProfileHeader(),
                  ),
                  OptionsHeader(
                    hasPremium: widget.hasPremium,
                    onProfileDataChanged: (profileData) {
                      widget.profileDataState.value = profileData;
                      context.read<ProfileCubit>().getUserInfos(
                            profileData: profileData,
                          );
                    },
                  ),
                  MediaQuery.removePadding(
                    removeTop: true,
                    context: context,
                    child: getCurrentWidget(
                      context: context,
                      profileDataState: widget.profileDataState,
                    ),
                  ),
                ],
              ),
            ),
            if (showFilter || showSwitcher)
              Positioned(
                left: kDefaultPadding / 2,
                right: kDefaultPadding / 2,
                bottom: kDefaultPadding + MediaQuery.of(context).padding.bottom,
                child: Align(
                  child: SizedBox(
                    width: 50.w,
                    child: FluidBlurContainer(
                      borderRadius: kDefaultPadding * 2,
                      backgroundLighten: 0.12,
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      child: showSwitcher
                          ? PremiumContentFilter(
                              articlesOnly: context
                                  .read<ProfileCubit>()
                                  .premiumArticlesOnly,
                              onChanged: (articlesOnly) => setState(() {
                                context
                                    .read<ProfileCubit>()
                                    .setPremiumArticlesOnly(articlesOnly);
                              }),
                            )
                          : isNotes
                              ? ProfileNotesFilter(
                                  profileData: widget.profileDataState.value,
                                  onChanged: (profileData) {
                                    widget.profileDataState.value = profileData;
                                    context.read<ProfileCubit>().getUserInfos(
                                          profileData: profileData,
                                        );
                                  },
                                )
                              : isMedia
                                  ? ProfileMediaFilter(
                                      profileData:
                                          widget.profileDataState.value,
                                      onChanged: (profileData) {
                                        widget.profileDataState.value =
                                            profileData;
                                        context
                                            .read<ProfileCubit>()
                                            .getUserInfos(
                                              profileData: profileData,
                                            );
                                      },
                                    )
                                  : ProfileOthersFilter(
                                      profileData:
                                          widget.profileDataState.value,
                                      onChanged: (profileData) {
                                        widget.profileDataState.value =
                                            profileData;
                                        context
                                            .read<ProfileCubit>()
                                            .getUserInfos(
                                              profileData: profileData,
                                            );
                                      },
                                    ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget getCurrentWidget({
    required BuildContext context,
    required ValueNotifier<ProfileData> profileDataState,
  }) {
    final type = profileDataState.value.getType();

    if (type == 'notes') {
      return ProfileNotes(
        profileData: widget.profileDataState.value,
        onProfileDataChanged: (profileData) {
          widget.profileDataState.value = profileData;
          context.read<ProfileCubit>().getUserInfos(
                profileData: profileData,
              );
        },
      );
    } else if (type == 'articles') {
      return const ProfileArticles();
    } else if (type == 'premium') {
      return ProfileNotes(
        profileData: widget.profileDataState.value,
        showFilters: false,
        onProfileDataChanged: (_) {},
      );
    } else if (type == 'media') {
      return ProfileMedia(
        profileData: widget.profileDataState.value,
        onProfileDataChanged: (profileData) {
          widget.profileDataState.value = profileData;
          context.read<ProfileCubit>().getUserInfos(
                profileData: profileData,
              );
        },
      );
    } else {
      return ProfileOthers(
        profileData: widget.profileDataState.value,
        onProfileDataChanged: (profileData) {
          widget.profileDataState.value = profileData;
          context.read<ProfileCubit>().getUserInfos(
                profileData: profileData,
              );
        },
      );
    }
  }
}

/// Floating pull-down that filters the premium tab between notes and articles.
class PremiumContentFilter extends StatelessWidget {
  const PremiumContentFilter({
    super.key,
    required this.articlesOnly,
    required this.onChanged,
  });

  final bool articlesOnly;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final isArticles = articlesOnly;

    return FluidPullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        return [false, true].map((articles) {
          return PullDownMenuItem.selectable(
            title: (articles ? context.t.articles : context.t.notes)
                .capitalizeFirst(),
            selected: articles == articlesOnly,
            onTap: () => onChanged(articles),
            itemTheme: PullDownMenuItemTheme(
              textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          );
        }).toList();
      },
      buttonBuilder: (context, showMenu) => GestureDetector(
        onTap: showMenu,
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  (isArticles ? context.t.articles : context.t.notes)
                      .capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(
                width: 30,
                height: 30,
                child: Icon(LucideIcons.chevronDown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionsHeader extends HookWidget {
  const OptionsHeader({
    super.key,
    required this.onProfileDataChanged,
    required this.hasPremium,
  });

  final Function(ProfileData profileData) onProfileDataChanged;
  final bool hasPremium;

  @override
  Widget build(BuildContext context) {
    final index = useState(0);
    final fluid = isFluid();

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeLeft: true,
      removeBottom: true,
      child: SliverAppBar(
        pinned: true,
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        titleSpacing: 0,
        toolbarHeight: fluid ? 48 : 40,
        backgroundColor: fluid
            ? Colors.transparent
            : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 1),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: const [SizedBox.shrink()],
        elevation: 0,
        title: fluid
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: FluidGlassTabBar(
                  onTap: (selectedIndex) {
                    index.value = selectedIndex;
                    onProfileDataChanged(getProfileData(selectedIndex));
                  },
                  tabs: [
                    GlassTab(label: context.t.notes.capitalizeFirst()),
                    if (hasPremium)
                      GlassTab(label: context.t.premium.capitalizeFirst()),
                    GlassTab(label: context.t.articles.capitalizeFirst()),
                    GlassTab(label: context.t.media.capitalizeFirst()),
                    GlassTab(label: context.t.others.capitalizeFirst()),
                  ],
                ),
              )
            : SizedBox(
                width: double.infinity,
                height: 40,
                child: ScrollShadow(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: TabBar(
                    onTap: (selectedIndex) {
                      index.value = selectedIndex;
                      onProfileDataChanged(getProfileData(selectedIndex));
                    },
                    indicatorSize: TabBarIndicatorSize.tab,
                    padding: EdgeInsets.zero,
                    labelStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.w600,
                            ),
                    unselectedLabelStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                    indicatorColor: Theme.of(context).primaryColor,
                    dividerColor: Theme.of(context).dividerColor,
                    tabs: [
                      Tab(text: context.t.notes.capitalizeFirst()),
                      if (hasPremium)
                        Tab(text: context.t.premium.capitalizeFirst()),
                      Tab(text: context.t.articles.capitalizeFirst()),
                      Tab(text: context.t.media.capitalizeFirst()),
                      Tab(text: context.t.others.capitalizeFirst()),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  ProfileData getProfileData(int index) {
    final tabs = profileTabs(hasPremium);

    return index < tabs.length ? tabs[index] : ProfileData.notes;
  }
}

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({
    super.key,
    required this.profileData,
  });

  final ProfileData profileData;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return SliverAppBar(
          expandedHeight: kToolbarHeight + 80,
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          stretch: true,
          leading: Center(
            child: AppIconButton(
              icon: FeatureIcons.arrowLeft,
              onClicked: () => YNavigator.pop(context),
            ),
          ),
          actions: [
            _pulldownButton(context, state),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: false,
            background: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        height: constraints.maxHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _gallery(state, context, constraints),
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            _actionsRow(state, context),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: kDefaultPadding / 2,
                          ),
                          child: ProfilePicture2(
                            size: 80,
                            image: state.user.picture,
                            pubkey: state.user.pubkey,
                            padding: 0,
                            strokeWidth: 3,
                            strokeColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            onClicked: () {
                              if (state.user.picture.isNotEmpty) {
                                openGallery(
                                  source: MapEntry(
                                    state.user.picture,
                                    UrlType.image,
                                  ),
                                  context: context,
                                  index: 0,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Row _actionsRow(ProfileState state, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (canSign() &&
            currentSigner!.getPublicKey() == state.user.pubkey) ...[
          TextButton(
            onPressed: () {
              YNavigator.pop(context);

              YNavigator.pushPage(
                context,
                (context) => ProfileSettingsView(),
              );
            },
            child: Text(
              context.t.editProfile.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ] else ...[
          Builder(
            builder: (context) {
              final isDisabled =
                  state.profileStatus != ProfileStatus.available ||
                      !canSign() ||
                      state.isSameUser;

              return AbsorbPointer(
                absorbing: isDisabled,
                child: TextButton(
                  onPressed: () {
                    if (canSign()) {
                      context.read<ProfileCubit>().setFollowingState();
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundBuilder: (_, __, child) => child!,
                    visualDensity: const VisualDensity(
                      vertical: -1,
                    ),
                    backgroundColor: isDisabled
                        ? Theme.of(context).highlightColor
                        : state.isFollowingUser
                            ? Theme.of(context).cardColor
                            : Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    state.isFollowingUser
                        ? context.t.unfollow.capitalizeFirst()
                        : context.t.follow.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: state.isFollowingUser
                              ? Theme.of(context).primaryColorDark
                              : kWhite,
                        ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Builder(
            builder: (context) {
              final isDisabled =
                  state.profileStatus != ProfileStatus.available ||
                      !state.canBeZapped;

              return AbsorbPointer(
                absorbing: isDisabled,
                child: CustomizedIconButton(
                  onClicked: () {
                    context.read<WalletsManagerCubit>().resetInvoice();

                    showAppModalSheet(
                      context: context,
                      builder: (_) {
                        return SendZapsView(
                          metadata: state.user,
                          isZapSplit: false,
                          zapSplits: const [],
                        );
                      },
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  },
                  icon: FeatureIcons.zaps,
                  buttonStatus: isDisabled
                      ? ButtonStatus.disabled
                      : ButtonStatus.inactive,
                ),
              );
            },
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          if (canSign()) ...[
            CustomizedIconButton(
              onClicked: () {
                context.read<DmsCubit>().updateReadedTime(
                      state.user.pubkey,
                    );
                Navigator.pushNamed(
                  context,
                  DmDetails.routeName,
                  arguments: [
                    state.user.pubkey,
                  ],
                );
              },
              icon: FeatureIcons.startDms,
              buttonStatus: ButtonStatus.inactive,
            ),
          ],
        ],
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
      ],
    );
  }

  Expanded _gallery(
      ProfileState state, BuildContext context, BoxConstraints constraints) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (state.user.banner.isNotEmpty) {
            openGallery(
              source: MapEntry(
                state.user.banner,
                UrlType.image,
              ),
              context: context,
              index: 0,
            );
          }
        },
        child: CommonThumbnail(
          image: state.user.banner,
          width: double.infinity,
          height: constraints.maxHeight,
          radius: 0,
          isRound: false,
          borderColor: kTransparent,
        ),
      ),
    );
  }

  Widget _pulldownButton(BuildContext context, ProfileState state) {
    return PullDownGlobalButton(
      model: LightMetadata.fromMetadata(state.user),
      enableCopyNpub: true,
      enableCopyNpubHex: true,
      enableUserRelays: true,
      enableShare: true,
      enableRefresh: true,
      enableMute:
          canSign() && currentSigner!.getPublicKey() != state.user.pubkey,
      muteStatus: state.mutes.contains(state.user.pubkey),
      onShowUserRelays: () {
        context.read<ProfileCubit>().setRelays();

        showAppModalSheet(
          context: context,
          builder: (_) {
            return BlocProvider.value(
              value: context.read<ProfileCubit>(),
              child: const ProfileRelays(),
            );
          },
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onRefresh: () {
        context.read<ProfileCubit>().getUserInfos(
              profileData: profileData,
            );
      },
      useFluidMode: true,
    );
  }
}
