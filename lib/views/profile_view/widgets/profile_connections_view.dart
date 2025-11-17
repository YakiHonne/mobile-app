// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../logic/profile_cubit/profile_follow_authors_cubit/profile_follow_authors_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/user_profile_container.dart';

class ProfileConnectionsView extends StatelessWidget {
  const ProfileConnectionsView({
    super.key,
    required this.pubkey,
    this.isFollowers = true,
  });

  final String pubkey;
  final bool isFollowers;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileFollowAuthorsCubit(
        pubkey: pubkey,
        isFollowers: isFollowers,
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
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
          child: _contentColumn(context),
        ),
      ),
    );
  }

  DraggableScrollableSheet _contentColumn(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.60,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          const ModalBottomSheetHandle(
            padding: 0,
          ),
          AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 3,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: BlocBuilder<ProfileFollowAuthorsCubit,
                ProfileFollowAuthorsState>(
              buildWhen: (previous, current) =>
                  previous.isFollowers != current.isFollowers,
              builder: (context, state) {
                return CustomToggleButton(
                  state: state.isFollowers,
                  color: Theme.of(context).cardColor,
                  firstText: context.t.followers.toLowerCase(),
                  secondText: context.t.followings.toLowerCase(),
                  onClicked: () async {
                    context.read<ProfileFollowAuthorsCubit>().toggleFollowers();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<ProfileFollowAuthorsCubit,
                ProfileFollowAuthorsState>(
              buildWhen: (previous, current) =>
                  previous.isFollowers != current.isFollowers,
              builder: (context, state) {
                return getView(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getView(
    ScrollController controller,
  ) {
    return FollowList(
      controller: controller,
    );
  }
}

class CustomToggleButton extends StatelessWidget {
  const CustomToggleButton({
    super.key,
    required this.state,
    required this.firstText,
    required this.secondText,
    required this.onClicked,
    this.color,
  });

  final bool state;
  final String firstText;
  final String secondText;
  final Function() onClicked;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 200,
        height: 30,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  kDefaultPadding * 2,
                ),
                color: color ?? Theme.of(context).cardColor,
              ),
            ),
            AnimatedPositioned(
              right: state ? 100 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 30,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding * 2,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            _content(context)
          ],
        ),
      ),
    );
  }

  Positioned _content(BuildContext context) {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              firstText,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: state ? kWhite : Theme.of(context).primaryColorDark,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              secondText,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: !state ? kWhite : Theme.of(context).primaryColorDark,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class FollowList extends StatelessWidget {
  const FollowList({
    super.key,
    required this.controller,
  });

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileFollowAuthorsCubit, ProfileFollowAuthorsState>(
      builder: (context, state) {
        if ((state.isFollowers && state.isFollowersLoading) ||
            (!state.isFollowers && state.isFollowingLoading)) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitCircle(
                color: Theme.of(context).primaryColor,
                size: 25,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                state.isFollowers
                    ? context.t.loadingFollowers.capitalizeFirst()
                    : context.t.loadingFollowings.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          );
        } else if ((state.isFollowers && state.followers.isEmpty) ||
            (!state.isFollowers && state.followings.isEmpty)) {
          return Center(
            child: EmptyList(
              description: context.t
                  .noContentCanBeFound(type: context.t.profile)
                  .capitalize(),
              icon: FeatureIcons.user,
            ),
          );
        } else {
          return _itemsList(state);
        }
      },
    );
  }

  Scrollbar _itemsList(ProfileFollowAuthorsState state) {
    return Scrollbar(
      controller: controller,
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(
          height: kDefaultPadding / 2,
        ),
        controller: controller,
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        itemBuilder: (context, index) {
          final pubkey = state.isFollowers
              ? state.followers[index]
              : state.followings[index];

          final isFollowing = state.ownFollowings.contains(pubkey);
          final isSameUser = state.currentUserPubKey == pubkey;

          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: UserProfileContainer(
              pubkey: pubkey,
              zaps: 0,
              currentUserPubKey: state.currentUserPubKey,
              isFollowing: isFollowing,
              isDisabled: !state.isValidUser || isSameUser,
              isPending: state.pendings.contains(pubkey),
              onClicked: () {
                context
                    .read<ProfileFollowAuthorsCubit>()
                    .setFollowingOnStop(pubkey);
              },
            ),
          );
        },
        itemCount: state.isFollowers
            ? state.followers.length
            : state.followings.length,
      ),
    );
  }
}
