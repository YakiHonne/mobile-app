// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../logic/users_info_list_cubit/users_info_list_cubit.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../utils/utils.dart';
import 'dotted_container.dart';
import 'empty_list.dart';
import 'loading_indicators.dart';
import 'user_profile_container.dart';

class ZappersView extends StatelessWidget {
  const ZappersView({
    super.key,
    required this.zappers,
  });

  final Map<String, MapEntry<String, int>> zappers;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersInfoListCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.60,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) => Column(
              children: [
                const ModalBottomSheetHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Text(
                    context.t.zappers.capitalizeFirst(),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Expanded(
                  child: BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
                    buildWhen: (previous, current) =>
                        previous.isLoading != current.isLoading,
                    builder: (context, state) {
                      return getView(
                        state.isLoading,
                        zappers,
                        controller,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getView(
    bool isLoading,
    Map<String, MapEntry<String, int>> zappers,
    ScrollController controller,
  ) {
    if (isLoading) {
      return const Center(
        child: LoadingWidget(),
      );
    } else {
      return ZappersList(
        zappers: Map.fromEntries(
          zappers.entries.toList()
            ..sort((a, b) => b.value.value.compareTo(a.value.value)),
        ),
        controller: controller,
      );
    }
  }
}

class ZappersList extends StatelessWidget {
  const ZappersList({
    super.key,
    required this.zappers,
    required this.controller,
  });

  final Map<String, MapEntry<String, int>> zappers;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
      buildWhen: (previous, current) =>
          previous.currentUserPubKey != current.currentUserPubKey ||
          previous.mutes != current.mutes ||
          previous.pendings != current.pendings,
      builder: (context, state) {
        if (zappers.isEmpty) {
          return Center(
            child: EmptyList(
              description: context.t.noZappersCanBeFound.capitalizeFirst(),
              icon: FeatureIcons.user,
            ),
          );
        } else {
          final z = zappers.keys.toList();

          return _itemsList(context, z, state);
        }
      },
    );
  }

  Scrollbar _itemsList(
      BuildContext context, List<String> z, UsersInfoListState state) {
    return Scrollbar(
      controller: controller,
      child: ScrollShadow(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(
            height: kDefaultPadding / 2,
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          controller: controller,
          itemBuilder: (context, index) {
            final pubkey = z[index];

            if (state.mutes.contains(pubkey)) {
              return const SizedBox.shrink();
            }

            return _item(pubkey);
          },
          itemCount: z.length,
        ),
      ),
    );
  }

  FadeInUp _item(String pubkey) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
        builder: (context, state) {
          final zap = zappers[pubkey];
          final isFollowing = state.followings.contains(pubkey);
          final isSameUser = state.currentUserPubKey == pubkey;
          String message = '';

          return FutureBuilder(
            future: zap != null ? nc.db.loadEventById(zap.key, false) : null,
            builder: (context, snapshot) {
              final ev = snapshot.data;

              if (ev != null) {
                final res = getZapPubkey(ev.tags);
                message = res[1];
              }

              return UserProfileContainer(
                pubkey: pubkey,
                currentUserPubKey: state.currentUserPubKey,
                isFollowing: isFollowing,
                isDisabled: !state.isValidUser || isSameUser,
                zaps: zap?.value ?? 0,
                message: message,
                isPending: state.pendings.contains(pubkey),
                onClicked: () {
                  context.read<UsersInfoListCubit>().setFollowingOnStop(pubkey);
                },
              );
            },
          );
        },
      ),
    );
  }
}
