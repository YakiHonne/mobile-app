// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../logic/users_info_list_cubit/users_info_list_cubit.dart';
import '../../models/app_models/extended_model.dart';
import '../../models/detailed_note_model.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../utils/utils.dart';
import '../note_view/note_view.dart';
import 'dotted_container.dart';
import 'empty_list.dart';
import 'loading_indicators.dart';
import 'user_profile_container.dart';

class NetStatsView extends HookWidget {
  const NetStatsView({
    super.key,
    required this.id,
    required this.type,
  });

  final String id;
  final NoteRelatedEventsType type;

  @override
  Widget build(BuildContext context) {
    final events = useState(<Event>[]);

    final f = useCallback(
      () async {
        events.value = await notesEventsCubit.loadNoteRelatedEvents(
          id: id,
          type: type,
          fetchAllMetadata: false,
        );
      },
    );

    useMemoized(() {
      f.call();
    });

    return BlocProvider(
      create: (context) => UsersInfoListCubit(
        nostrRepository: context.read<NostrDataRepository>(),
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
          child: _content(context, events),
        ),
      ),
    );
  }

  DraggableScrollableSheet _content(
      BuildContext context, ValueNotifier<List<Event>> events) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.60,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const ModalBottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
            child: Text(
              type.name.capitalize(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Expanded(
            child: BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
              buildWhen: (previous, current) =>
                  previous.isLoading != current.isLoading,
              builder: (context, state) {
                return getView(
                  state.isLoading,
                  events.value,
                  controller,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getView(
    bool isLoading,
    List<Event> events,
    ScrollController controller,
  ) {
    if (isLoading) {
      return const Center(
        child: LoadingWidget(),
      );
    } else {
      return NoteUsersList(
        events: events,
        controller: controller,
      );
    }
  }
}

class NoteUsersList extends StatelessWidget {
  const NoteUsersList({
    super.key,
    required this.events,
    required this.controller,
  });

  final List<Event> events;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
      buildWhen: (previous, current) =>
          previous.currentUserPubKey != current.currentUserPubKey ||
          previous.mutes != current.mutes ||
          previous.pendings != current.pendings,
      builder: (context, state) {
        if (events.isEmpty) {
          return Center(
            child: EmptyList(
              description: context.t.noUserCanBeFound.capitalizeFirst(),
              icon: FeatureIcons.user,
            ),
          );
        } else {
          return _itemsList(context, state);
        }
      },
    );
  }

  Scrollbar _itemsList(BuildContext context, UsersInfoListState state) {
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
            final pubkey = events[index].pubkey;

            if (state.mutes.contains(pubkey)) {
              return const SizedBox.shrink();
            }

            return _item(pubkey);
          },
          itemCount: events.length,
        ),
      ),
    );
  }

  FadeInUp _item(String pubkey) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
        builder: (context, state) {
          final isFollowing = state.followings.contains(pubkey);
          final isSameUser = state.currentUserPubKey == pubkey;
          final ev = events.firstWhere((element) => element.pubkey == pubkey);
          final event = ExtendedEvent.fromEv(ev);

          return GestureDetector(
            onTap: event.isQuote()
                ? () {
                    Navigator.pushNamed(
                      context,
                      NoteView.routeName,
                      arguments: [DetailedNoteModel.fromEvent(event)],
                    );
                  }
                : null,
            child: UserNoteStatContainer(
              pubkey: pubkey,
              currentUserPubKey: state.currentUserPubKey,
              isFollowing: isFollowing,
              isDisabled: !state.isValidUser || isSameUser,
              event: event,
              isPending: state.pendings.contains(pubkey),
              onClicked: () {
                context.read<UsersInfoListCubit>().setFollowingOnStop(pubkey);
              },
            ),
          );
        },
      ),
    );
  }
}
