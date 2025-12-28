// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numeral/numeral.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../main_view/widgets/profile_share_view.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/custom_icon_buttons.dart';
import 'profile_connections_view.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        children: [
          BlocBuilder<ProfileCubit, ProfileState>(
            buildWhen: (previous, current) =>
                previous.user != current.user ||
                previous.isNip05 != current.isNip05 ||
                previous.refresh != current.refresh ||
                previous.userRelays != current.userRelays,
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  userRow(state),
                  if (state.user.nip05.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    _nip05Row(state, context),
                  ],
                  if (state.user.website.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    GestureDetector(
                      onTap: () {
                        openWebPage(url: state.user.website);
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            FeatureIcons.link,
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
                              state.user.website,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (state.user.about.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    ParsedText(
                      text: state.user.about.trim(),
                      style: Theme.of(context).textTheme.bodySmall,
                      disableNoteParsing: true,
                      disableUrlParsing: true,
                      enableTruncation: false,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          _followsYou(),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }

  BlocBuilder<ProfileCubit, ProfileState> _followsYou() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (previous, current) =>
          previous.followers != current.followers ||
          previous.followings != current.followings,
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return BlocProvider.value(
                  value: context.read<ProfileCubit>(),
                  child: ProfileConnectionsView(
                    pubkey: state.user.pubkey,
                  ),
                );
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserStatsRow(
                icon: FeatureIcons.user,
                firstTitle: context.t.followings.capitalizeFirst(),
                firstValue: state.followings.numeral(digits: 2),
                secondtitle: context.t.followers.capitalizeFirst(),
                secondValue: state.followers.numeral(digits: 2),
              ),
              if (state.isFollowedByUser) ...[
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Text(
                    context.t.followsYou.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                )
              ],
            ],
          ),
        );
      },
    );
  }

  Row _nip05Row(ProfileState state, BuildContext context) {
    return Row(
      children: [
        if (state.user.nip05.isNotEmpty)
          Expanded(
            child: Row(
              children: [
                SvgPicture.asset(
                  FeatureIcons.nip05,
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
                    state.user.nip05,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Builder userRow(ProfileState state) {
    return Builder(
      builder: (context) {
        final userName = state.user.getName();

        return Row(
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: userName,
                    ),
                  );

                  BotToastUtils.showSuccess(
                    context.t.userNameCopied.capitalizeFirst(),
                  );
                },
                child: Text(
                  userName,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            if (state.isNip05) ...[
              SvgPicture.asset(
                FeatureIcons.verified,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
            ],
            CustomIconButton(
              onClicked: () {
                Navigator.push(
                  context,
                  createViewFromBottom(
                    ProfileShareView(
                      metadata: state.user,
                    ),
                  ),
                );
              },
              vd: -4,
              icon: FeatureIcons.qr,
              size: 15,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ],
        );
      },
    );
  }
}

class UserStatsRow extends StatelessWidget {
  const UserStatsRow({
    super.key,
    required this.icon,
    required this.firstTitle,
    required this.firstValue,
    required this.secondtitle,
    required this.secondValue,
  });

  final String icon;
  final String firstTitle;
  final String firstValue;
  final String secondtitle;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall,
            children: [
              TextSpan(
                text: firstValue,
              ),
              TextSpan(
                text: ' $firstTitle',
                style: TextStyle(
                  color: Theme.of(context).highlightColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall,
            children: [
              TextSpan(
                text: secondValue,
              ),
              TextSpan(
                text: ' $secondtitle',
                style: TextStyle(
                  color: Theme.of(context).highlightColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UnStatsRow extends StatelessWidget {
  const UnStatsRow({
    super.key,
    required this.text,
    required this.impact,
    required this.onClicked,
  });

  final String text;
  final num impact;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          DotContainer(
            color: Theme.of(context).highlightColor,
            size: 3,
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
            ),
          ),
          Text(
            impact.toString(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          const Icon(
            Icons.keyboard_arrow_right_rounded,
            size: 20,
          ),
        ],
      ),
    );
  }
}
