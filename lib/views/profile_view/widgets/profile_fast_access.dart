// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:numeral/numeral.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/metadata_cubit/metadata_cubit.dart';
import '../../../logic/profile_cubit/profile_fast_access_cubit/profile_fast_access_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../routes/pages_router.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../dm_view/widgets/dm_details.dart';
import '../../main_view/widgets/profile_share_view.dart';
import '../../profile_settings_view/profile_settings_view.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/no_content_widgets.dart';
import '../../widgets/profile_picture.dart';
import '../profile_view.dart';

class ProfileFastAccess extends HookWidget {
  const ProfileFastAccess({
    super.key,
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      metadataCubit.requestMetadata(pubkey);
    });

    return BlocProvider(
      create: (context) => ProfileFastAccessCubit(pubkey: pubkey),
      child: BlocBuilder<ProfileFastAccessCubit, ProfileFastAccessState>(
        builder: (context, state) {
          return _profileContent(context);
        },
      ),
    );
  }

  MetadataProvider _profileContent(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, isNip05Valid) {
        return Material(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ModalBottomSheetHandle(),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  if (isUserMuted(pubkey))
                    Center(
                      child: MutedUserContent(
                        pubkey: pubkey,
                      ),
                    )
                  else ...[
                    _contentColumn(metadata, context),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    _contentRow(metadata, context),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    _actionsButtons(context, metadata),
                  ],
                  const SizedBox(
                    height: kDefaultPadding * 1.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SizedBox _actionsButtons(BuildContext context, Metadata metadata) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushNamed(
                  context,
                  ProfileView.routeName,
                  arguments: [metadata.pubkey],
                );
              },
              style: isFluid()
                  ? TextButton.styleFrom(
                      backgroundBuilder: (_, __, child) => child!,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    )
                  : null,
              icon: Text(
                context.t.visitProfile.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
              ),
              label: Icon(
                LucideIcons.arrowUpRight,
                size: 20,
                color: Theme.of(context).primaryColorDark,
              ),
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          if (canSign() && currentSigner!.getPublicKey() == pubkey)
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  YNavigator.pop(context);

                  YNavigator.push(
                    context,
                    SlideupPageRoute(
                      builder: (context) => ProfileSettingsView(),
                      settings: const RouteSettings(),
                    ),
                  );
                },
                style: isFluid()
                    ? TextButton.styleFrom(
                        backgroundBuilder: (_, __, child) => child!,
                        backgroundColor: Theme.of(context).primaryColorDark,
                      )
                    : null,
                icon: Text(
                  context.t.editProfile.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                label: AppIcon(
                  FeatureIcons.editArticle,
                  size: 15,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            )
          else
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: Nip19.encodePubkey(pubkey),
                    ),
                  );

                  BotToastUtils.showSuccess(
                    context.t.publicKeyCopied.capitalizeFirst(),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundBuilder: (_, __, child) => child!,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                icon: Text(
                  context.t.copyNpub.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                label: AppIcon(
                  FeatureIcons.copy,
                  size: 15,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Row _contentRow(Metadata metadata, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BlocBuilder<ProfileFastAccessCubit, ProfileFastAccessState>(
          buildWhen: (previous, current) =>
              previous.isFollowing != current.isFollowing,
          builder: (context, state) {
            return Builder(
              builder: (context) {
                final canBeFollowed = canUserBeFollowed(metadata);

                return AbsorbPointer(
                  absorbing: !canBeFollowed,
                  child: TextButton(
                    onPressed: () {
                      if (canBeFollowed) {
                        context
                            .read<ProfileFastAccessCubit>()
                            .setFollowingState();
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundBuilder: (_, __, child) => child!,
                      visualDensity: const VisualDensity(
                        vertical: -1,
                      ),
                      backgroundColor: !canBeFollowed
                          ? Theme.of(context).highlightColor
                          : state.isFollowing
                              ? Theme.of(context).scaffoldBackgroundColor
                              : Theme.of(context).primaryColor,
                    ),
                    child: Text(
                      state.isFollowing
                          ? context.t.unfollow.capitalizeFirst()
                          : context.t.follow.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: state.isFollowing
                                ? Theme.of(context).primaryColorDark
                                : kWhite,
                          ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Builder(
          builder: (context) {
            final canBeZapped = canUserBeZapped(metadata);

            return AbsorbPointer(
              absorbing: !canBeZapped,
              child: CustomizedIconButton(
                onClicked: () {
                  walletManagerCubit.resetInvoice();

                  showAppModalSheet(
                    context: context,
                    builder: (_) {
                      return SendZapsView(
                        metadata: metadata,
                        isZapSplit: false,
                        zapSplits: const [],
                      );
                    },
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                icon: FeatureIcons.zaps,
                buttonStatus: !canBeZapped
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
                    metadata.pubkey,
                  );
              Navigator.pushNamed(
                context,
                DmDetails.routeName,
                arguments: [
                  metadata.pubkey,
                ],
              );
            },
            icon: FeatureIcons.startDms,
            buttonStatus: canUserBeFollowed(metadata)
                ? ButtonStatus.inactive
                : ButtonStatus.disabled,
          ),
          if (currentSigner!.getPublicKey() != metadata.pubkey) ...[
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            MutedUserProvider(
              pubkey: pubkey,
              child: (isMuted) => CustomizedIconButton(
                onClicked: () {
                  doIfCanSign(
                    func: () {
                      setMuteStatus(
                        muteKey: pubkey,
                        onSuccess: () {},
                      );
                    },
                    context: context,
                  );
                },
                icon: FeatureIcons.mute,
                buttonStatus: ButtonStatus.inactive,
              ),
            ),
          ],
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
        ],
        CustomizedIconButton(
          onClicked: () {
            Navigator.push(
              context,
              createViewFromBottom(
                ProfileShareView(
                  metadata: metadata,
                ),
              ),
            );
          },
          icon: FeatureIcons.qr,
          buttonStatus: ButtonStatus.inactive,
        ),
      ],
    );
  }

  Column _contentColumn(Metadata metadata, BuildContext context) {
    return Column(
      children: [
        Center(
          child: ProfilePicture2(
            size: 90,
            image: metadata.picture,
            pubkey: metadata.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () {},
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Center(
          child: Text(
            metadata.getName(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Center(
          child: (metadata.nip05.isNotEmpty)
              ? Column(
                  children: [
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    AdditionalInformationRow(
                      icon: FeatureIcons.nip05,
                      text: metadata.nip05,
                      onClick: () {},
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        if (metadata.website.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Center(
            child: AdditionalInformationRow(
              icon: FeatureIcons.link,
              text: metadata.website,
              onClick: () {
                openWebPage(url: metadata.website);
              },
            ),
          ),
        ],
        BlocBuilder<ProfileFastAccessCubit, ProfileFastAccessState>(
          builder: (context, state) {
            if (state.commonPubkeys.isNotEmpty || state.followersCount != 0) {
              return Column(
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.followersCount != 0) ...[
                        Text(
                          context.t.followersNum(
                            number: state.followersCount.numeral(
                              digits: 2,
                            ),
                          ),
                        ),
                      ],
                      if (state.commonPubkeys.isNotEmpty &&
                          state.followersCount != 0)
                        DotContainer(
                          color: Theme.of(context).highlightColor,
                          size: 2,
                        ),
                      if (state.commonPubkeys.isNotEmpty)
                        CommonUsersRow(
                          commonPubkeys: state.commonPubkeys,
                        ),
                    ],
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        if (metadata.about.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding,
          ),
          Center(
            child: Text(
              metadata.about,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ],
    );
  }
}

class CommonUsersRow extends StatelessWidget {
  const CommonUsersRow({
    super.key,
    required this.commonPubkeys,
    this.compact = false,
    this.useOthers = false,
    this.mainAxisSize,
  });

  final Set<String> commonPubkeys;
  final bool compact;
  final MainAxisSize? mainAxisSize;
  final bool useOthers;

  @override
  Widget build(BuildContext context) {
    return commonPubkeys.isEmpty
        ? Text(
            context.t.notFollowedByAnyoneYouFollow.capitalizeFirst(),
          )
        : _imagesRow();
  }

  BlocBuilder<MetadataCubit, MetadataState> _imagesRow() {
    return BlocBuilder<MetadataCubit, MetadataState>(
      builder: (context, state) {
        final List<Metadata> usersToBeShown = [];
        final max = commonPubkeys.length >= 3 ? 3 : commonPubkeys.length;
        final List<Widget> images = [];

        for (int i = 0; i < max; i++) {
          final pubkey = commonPubkeys.elementAt(i);

          images.add(
            MetadataProvider(
              pubkey: pubkey,
              child: (metadata, p1) {
                usersToBeShown.add(metadata);
                return ProfilePicture2(
                  size: 25,
                  image: metadata.picture.isEmpty
                      ? profileImages.first
                      : metadata.picture,
                  pubkey: metadata.pubkey,
                  padding: 0,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).cardColor,
                  onClicked: () {
                    // openProfileFastAccess(context: context, pubkey: pubkey);
                  },
                );
              },
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: mainAxisSize ?? MainAxisSize.max,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 25,
                  width: 25 + (images.length - 1) * (compact ? 10 : 15),
                ),
                ...images.reversed.map(
                  (e) => Positioned(
                    left: images.indexOf(e) * (compact ? 10 : 15),
                    child: e,
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              if (commonPubkeys.length > 3) ...[
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Builder(builder: (context) {
                  final number =
                      (commonPubkeys.length - usersToBeShown.length).toString();
                  return Text(
                    (useOthers
                            ? context.t.othersNumber(number: number)
                            : context.t.mutualsNum(number: number))
                        .capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  );
                }),
              ] else if (!useOthers) ...[
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Text(
                  (useOthers ? context.t.others : context.t.mutuals)
                      .capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

// ─── Fluid mode card ─────────────────────────────────────────────────────────

class ProfileFastAccessFluid extends HookWidget {
  const ProfileFastAccessFluid({super.key, required this.pubkey});

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    useMemoized(() => metadataCubit.requestMetadata(pubkey));

    return BlocProvider(
      create: (_) => ProfileFastAccessCubit(pubkey: pubkey),
      child: MetadataProvider(
        pubkey: pubkey,
        child: (metadata, isNip05Valid) {
          return BlocBuilder<ProfileFastAccessCubit, ProfileFastAccessState>(
            builder: (context, state) => SlideInDown(
              duration: const Duration(milliseconds: 200),
              child: _FluidProfileCard(
                pubkey: pubkey,
                metadata: metadata,
                isNip05Valid: isNip05Valid,
                state: state,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FluidProfileCard extends StatelessWidget {
  const _FluidProfileCard({
    required this.pubkey,
    required this.metadata,
    required this.isNip05Valid,
    required this.state,
  });

  final String pubkey;
  final Metadata metadata;
  final bool isNip05Valid;
  final ProfileFastAccessState state;

  @override
  Widget build(BuildContext context) {
    final hasLightning = metadata.lud16.isNotEmpty || metadata.lud06.isNotEmpty;
    final showStats = state.followersCount > 0 ||
        state.commonPubkeys.isNotEmpty ||
        hasLightning;

    return Center(
      child: SizedBox(
        width: 75.w,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient: bottom black → top transparent
              CommonThumbnail(image: metadata.picture),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, 1],
                    colors: [
                      kBlack,
                      kTransparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              // Content pinned to bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + verified badge
                      Row(
                        spacing: kDefaultPadding / 4,
                        children: [
                          Flexible(
                            child: Text(
                              metadata.getName(),
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isNip05Valid) ...[
                            const SizedBox(width: kDefaultPadding / 4),
                            const AppIcon(
                              FeatureIcons.verified,
                              size: 18,
                              color: kMainColor,
                            ),
                          ],
                        ],
                      ),
                      if (metadata.about.isNotEmpty) ...[
                        const SizedBox(height: kDefaultPadding / 4),
                        Text(
                          metadata.about,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: Theme.of(context).highlightColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                      if (showStats) ...[
                        const SizedBox(height: kDefaultPadding),
                        _FluidStatsRow(
                          state: state,
                          hasLightning: hasLightning,
                        ),
                      ],
                      const SizedBox(height: kDefaultPadding / 2),
                      _FluidActionButtons(
                        pubkey: pubkey,
                        metadata: metadata,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FluidStatsRow extends StatelessWidget {
  const _FluidStatsRow({
    required this.state,
    required this.hasLightning,
  });

  final ProfileFastAccessState state;
  final bool hasLightning;

  Widget _divider(BuildContext context) => VerticalDivider(
        width: 1,
        thickness: 0.5,
        color: Theme.of(context).highlightColor,
      );

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
      );

  Widget _placeholder(BuildContext context) => Text(
        '-',
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontWeight: FontWeight.w700, color: kWhite),
      );

  @override
  Widget build(BuildContext context) {
    final followersSection = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.followersCount > 0)
            SizedBox(
              height: 25,
              child: Center(
                child: Text(
                  state.followersCount.numeral(digits: 2),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(fontWeight: FontWeight.w700, color: kWhite),
                ),
              ),
            )
          else
            _placeholder(context),
          const SizedBox(height: 2),
          _label(context, context.t.followers.capitalizeFirst()),
        ],
      ),
    );

    final mutualsSection = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.commonPubkeys.isNotEmpty)
            CommonUsersRow(
              commonPubkeys: state.commonPubkeys,
              compact: true,
              useOthers: true,
            )
          else
            _placeholder(context),
          const SizedBox(height: 2),
          _label(context, context.t.mutuals.capitalizeFirst()),
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        children: [
          followersSection,
          _divider(context),
          mutualsSection,
          if (hasLightning) ...[
            _divider(context),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 25,
                    child: Center(
                      child: Icon(
                        LucideIcons.check,
                        size: 16,
                        color: kWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _label(context, context.t.lightning),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FluidActionButtons extends StatelessWidget {
  const _FluidActionButtons({
    required this.pubkey,
    required this.metadata,
  });

  final String pubkey;
  final Metadata metadata;

  @override
  Widget build(BuildContext context) {
    final canBeFollowed = canUserBeFollowed(metadata);
    final canBeZapped = canUserBeZapped(metadata);
    final isOwnProfile = canSign() && currentSigner!.getPublicKey() == pubkey;

    return Row(
      children: [
        Expanded(
          child: isOwnProfile
              ? TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    YNavigator.push(
                      context,
                      SlideupPageRoute(
                        builder: (_) => ProfileSettingsView(),
                        settings: const RouteSettings(),
                      ),
                    );
                  },
                  child: Text(
                    context.t.editProfile.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                )
              : BlocBuilder<ProfileFastAccessCubit, ProfileFastAccessState>(
                  buildWhen: (p, c) => p.isFollowing != c.isFollowing,
                  builder: (context, state) {
                    return AbsorbPointer(
                      absorbing: !canBeFollowed,
                      child: TextButton(
                        onPressed: canBeFollowed
                            ? () => context
                                .read<ProfileFastAccessCubit>()
                                .setFollowingState()
                            : null,
                        child: Text(
                          state.isFollowing
                              ? context.t.unfollow.capitalizeFirst()
                              : context.t.follow.capitalizeFirst(),
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (canSign() && !isOwnProfile) ...[
          const SizedBox(width: kDefaultPadding / 4),
          AppIconButton(
            onClicked: () {
              context.read<DmsCubit>().updateReadedTime(metadata.pubkey);
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                DmDetails.routeName,
                arguments: [metadata.pubkey],
              );
            },
            icon: FeatureIcons.startDms,
            iconColor: kWhite,
            buttonStatus:
                canBeFollowed ? ButtonStatus.inactive : ButtonStatus.disabled,
          ),
          const SizedBox(width: kDefaultPadding / 4),
          AbsorbPointer(
            absorbing: !canBeZapped,
            child: AppIconButton(
              onClicked: () {
                walletManagerCubit.resetInvoice();
                showAppModalSheet(
                  context: context,
                  builder: (_) => SendZapsView(
                    metadata: metadata,
                    isZapSplit: false,
                    zapSplits: const [],
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              iconColor: kWhite,
              icon: FeatureIcons.zaps,
              buttonStatus:
                  canBeZapped ? ButtonStatus.inactive : ButtonStatus.disabled,
            ),
          ),
        ],
        const SizedBox(width: kDefaultPadding / 4),
        AppIconButton(
          onClicked: () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              ProfileView.routeName,
              arguments: [metadata.pubkey],
            );
          },
          iconColor: kWhite,
          icon: FeatureIcons.user,
          buttonStatus: ButtonStatus.inactive,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AdditionalInformationRow extends StatelessWidget {
  const AdditionalInformationRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onClick,
  });

  final IconData icon;
  final String text;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColorDark,
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
