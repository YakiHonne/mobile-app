// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/dotted_container.dart';
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
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              icon: Text(
                context.t.visitProfile.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
              ),
              label: Icon(
                Icons.arrow_outward_rounded,
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
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                icon: Text(
                  context.t.editProfile.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                label: SvgPicture.asset(
                  FeatureIcons.article,
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
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
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                icon: Text(
                  context.t.copyNpub.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                label: SvgPicture.asset(
                  FeatureIcons.copy,
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
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
                      visualDensity: const VisualDensity(
                        vertical: -1,
                      ),
                      backgroundColor: !canBeFollowed
                          ? Theme.of(context).highlightColor
                          : state.isFollowing
                              ? Theme.of(context).scaffoldBackgroundColor
                              : kMainColor,
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
              child: NewBorderedIconButton(
                onClicked: () {
                  walletManagerCubit.resetInvoice();

                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return SendZapsView(
                        metadata: metadata,
                        isZapSplit: false,
                        zapSplits: const [],
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
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
          NewBorderedIconButton(
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
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          MutedUserProvider(
            pubkey: pubkey,
            child: (isMuted) => NewBorderedIconButton(
              onClicked: () {
                doIfCanSign(
                  func: () {
                    setMuteStatus(
                      pubkey: pubkey,
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
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
        ],
        NewBorderedIconButton(
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
          icon: '',
          iconData: CupertinoIcons.qrcode,
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
  });

  final Set<String> commonPubkeys;
  final bool compact;

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
                  onClicked: () {},
                );
              },
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
              if (usersToBeShown.length < commonPubkeys.length) ...[
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Text(
                  context.t
                      .mutualsNum(
                        number: (commonPubkeys.length - usersToBeShown.length)
                            .toString(),
                      )
                      .capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ] else ...[
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Text(
                  context.t.mutuals.capitalizeFirst(),
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

class AdditionalInformationRow extends StatelessWidget {
  const AdditionalInformationRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onClick,
  });

  final String icon;
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
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
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
