// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/properties_cubit/mute_list_cubit/mute_list_cubit.dart';
import '../../../utils/utils.dart';
import '../../profile_view/profile_view.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/response_snackbar.dart';

class MuteListView extends StatelessWidget {
  MuteListView({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Mute list view');
  }

  static const routeName = '/mutelistView';
  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => MuteListView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = !ResponsiveBreakpoints.of(context).isMobile;

    return BlocProvider(
      create: (context) => MuteListCubit(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.muteList.capitalizeFirst(),
        ),
        body: BlocBuilder<MuteListCubit, MuteListState>(
          builder: (context, state) {
            return getView(
              isEmpty: state.mutes.isEmpty,
              isTablet: isTablet,
              context: context,
            );
          },
        ),
      ),
    );
  }

  Widget getView({
    required isEmpty,
    required bool isTablet,
    required BuildContext context,
  }) {
    if (isEmpty) {
      return EmptyList(
        description: context.t.noMutedUserFound.capitalizeFirst(),
        icon: FeatureIcons.mute,
      );
    } else if (isTablet) {
      return const TabletMuteListView();
    } else {
      return const MobileMuteListView();
    }
  }
}

class TabletMuteListView extends StatelessWidget {
  const TabletMuteListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuteListCubit, MuteListState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: MasonryGridView.builder(
            itemCount: state.mutes.length,
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: kDefaultPadding / 2,
            crossAxisSpacing: kDefaultPadding / 2,
            itemBuilder: (context, index) {
              final pubkey = state.mutes[index];

              return MutedUserContainer(
                pubkey: pubkey,
                onUnmute: (name) {
                  final isMuted = state.mutes.contains(pubkey);

                  showCupertinoCustomDialogue(
                    context: context,
                    title: isMuted
                        ? context.t.unmuteUser.capitalizeFirst()
                        : context.t.muteUser.capitalizeFirst(),
                    description: isMuted
                        ? context.t.unmuteUserDesc(name: name).capitalizeFirst()
                        : context.t.muteUserDesc(name: name).capitalizeFirst(),
                    buttonText: isMuted
                        ? context.t.unmute.capitalizeFirst()
                        : context.t.mute.capitalizeFirst(),
                    buttonTextColor: isMuted ? kGreen : kRed,
                    onClicked: () {
                      context.read<MuteListCubit>().setMuteStatus(
                            pubkey: pubkey,
                            onSuccess: () => Navigator.pop(context),
                          );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class MobileMuteListView extends StatelessWidget {
  const MobileMuteListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuteListCubit, MuteListState>(
      builder: (context, state) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          separatorBuilder: (context, index) => const SizedBox(
            height: kDefaultPadding / 2,
          ),
          itemBuilder: (context, index) {
            final pubkey = state.mutes[index];

            return MutedUserContainer(
              pubkey: pubkey,
              onUnmute: (name) {
                final isMuted = state.mutes.contains(pubkey);

                showCupertinoCustomDialogue(
                  context: context,
                  title: isMuted
                      ? context.t.unmuteUser.capitalizeFirst()
                      : context.t.muteUser.capitalizeFirst(),
                  description: isMuted
                      ? context.t.unmuteUserDesc(name: name).capitalizeFirst()
                      : context.t.muteUserDesc(name: name).capitalizeFirst(),
                  buttonText: isMuted
                      ? context.t.unmute.capitalizeFirst()
                      : context.t.mute.capitalizeFirst(),
                  buttonTextColor: isMuted ? kGreen : kRed,
                  onClicked: () {
                    context.read<MuteListCubit>().setMuteStatus(
                          pubkey: pubkey,
                          onSuccess: () => Navigator.pop(context),
                        );
                  },
                );
              },
            );
          },
          itemCount: state.mutes.length,
        );
      },
    );
  }
}

class MutedUserContainer extends StatelessWidget {
  const MutedUserContainer({
    super.key,
    required this.pubkey,
    required this.onUnmute,
  });

  final String pubkey;
  final Function(String) onUnmute;

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, nip05) => GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            ProfileView.routeName,
            arguments: [metadata.pubkey],
          );
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding + 5),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _thumbnail(metadata),
                  _profilePicture(metadata, context),
                  _muteButton(metadata, context),
                ],
              ),
              _about(metadata, context),
            ],
          ),
        ),
      ),
    );
  }

  Padding _about(Metadata metadata, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: kDefaultPadding,
        left: kDefaultPadding,
        right: kDefaultPadding,
        top: kDefaultPadding / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.getName(),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (metadata.about.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            SelectableText(
              metadata.about.trim(),
              scrollPhysics: const NeverScrollableScrollPhysics(),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  Positioned _muteButton(Metadata metadata, BuildContext context) {
    return Positioned(
      right: 5,
      top: 5,
      child: Align(
        alignment: Alignment.topRight,
        child: TextButton.icon(
          onPressed: () => onUnmute.call(metadata.name),
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
            visualDensity: const VisualDensity(
              horizontal: -4,
              vertical: -2,
            ),
          ),
          icon: SvgPicture.asset(
            FeatureIcons.unmute,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          label: Text(
            context.t.unmute.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }

  Positioned _profilePicture(Metadata metadata, BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(
            left: kDefaultPadding / 2,
          ),
          child: ProfilePicture2(
            size: 60,
            image: metadata.picture,
            pubkey: metadata.pubkey,
            padding: 0,
            strokeWidth: 3,
            strokeColor: Theme.of(context).cardColor,
            onClicked: () {},
          ),
        ),
      ),
    );
  }

  Container _thumbnail(Metadata metadata) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: kDefaultPadding,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        child: CommonThumbnail(
          image: metadata.banner,
          placeholder: getRandomPlaceholder(
            input: metadata.pubkey,
            isPfp: false,
          ),
          width: double.infinity,
          height: 50,
          radius: 0,
          isRound: false,
        ),
      ),
    );
  }
}
