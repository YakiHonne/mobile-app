// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/properties_cubit/mute_list_cubit/mute_list_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../profile_view/profile_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/note_container.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/response_snackbar.dart';

class MuteListView extends HookWidget {
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
        body: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 50,
                  title: TabBar(
                    dividerColor: kTransparent,
                    unselectedLabelColor: Theme.of(context).highlightColor,
                    labelColor: Theme.of(context).primaryColor,
                    indicatorColor: Theme.of(context).primaryColor,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle:
                        Theme.of(context).textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    tabs: [
                      Tab(text: context.t.people.capitalizeFirst()),
                      Tab(text: context.t.notes.capitalizeFirst()),
                    ],
                  ),
                ),
              ];
            },
            body: BlocBuilder<MuteListCubit, MuteListState>(
              builder: (context, state) {
                return TabBarView(
                  children: [
                    getUsersMutesView(
                      isEmpty: state.usersMutes.isEmpty,
                      isTablet: isTablet,
                      context: context,
                    ),
                    getEventsMutesView(
                      isEmpty: state.eventsMutes.isEmpty,
                      isTablet: isTablet,
                      context: context,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget getUsersMutesView({
    required isEmpty,
    required bool isTablet,
    required BuildContext context,
  }) {
    if (isEmpty) {
      return EmptyList(
        description: context.t.noMutedUserFound.capitalizeFirst(),
        icon: FeatureIcons.mute,
      );
    } else {
      return TabletMuteListView(
        isTablet: isTablet,
      );
    }
  }
}

Widget getEventsMutesView({
  required isEmpty,
  required bool isTablet,
  required BuildContext context,
}) {
  if (isEmpty) {
    return EmptyList(
      description: context.t.noMutedEventsFound.capitalizeFirst(),
      icon: FeatureIcons.mute,
    );
  } else if (isTablet) {
    return const TabletEventMuteListView();
  } else {
    return const MobileEventMuteListView();
  }
}

class TabletMuteListView extends StatelessWidget {
  const TabletMuteListView({super.key, required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuteListCubit, MuteListState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: MasonryGridView.builder(
            itemCount: state.usersMutes.length,
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 4 : 2,
            ),
            mainAxisSpacing: kDefaultPadding / 2,
            crossAxisSpacing: kDefaultPadding / 2,
            itemBuilder: (context, index) {
              final pubkey = state.usersMutes[index];

              return MutedUserContainer(
                pubkey: pubkey,
                onUnmute: (name) {
                  final isMuted = state.usersMutes.contains(pubkey);

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
                      context.read<MuteListCubit>().setMuteStatusFunc(
                            muteKey: pubkey,
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

class TabletEventMuteListView extends StatelessWidget {
  const TabletEventMuteListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuteListCubit, MuteListState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: MasonryGridView.builder(
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: kDefaultPadding / 2,
            crossAxisSpacing: kDefaultPadding / 2,
            itemBuilder: (context, index) {
              final id = state.eventsMutes[index];

              return MutedEventContainer(
                id: id,
                onUnmute: () {
                  final isMuted = state.eventsMutes.contains(id);

                  showCupertinoCustomDialogue(
                    context: context,
                    title: isMuted
                        ? context.t.unmuteThread.capitalizeFirst()
                        : context.t.muteThread.capitalizeFirst(),
                    description: isMuted
                        ? context.t.unmuteThreadDesc.capitalizeFirst()
                        : context.t.muteThreadDesc.capitalizeFirst(),
                    buttonText: isMuted
                        ? context.t.unmute.capitalizeFirst()
                        : context.t.mute.capitalizeFirst(),
                    buttonTextColor: isMuted ? kGreen : kRed,
                    onClicked: () {
                      context.read<MuteListCubit>().setMuteStatusFunc(
                            muteKey: id,
                            isPubkey: false,
                            onSuccess: () => Navigator.pop(context),
                          );
                    },
                  );
                },
              );
            },
            itemCount: state.eventsMutes.length,
          ),
        );
      },
    );
  }
}

class MobileEventMuteListView extends StatelessWidget {
  const MobileEventMuteListView({super.key});

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
            final id = state.eventsMutes[index];

            return MutedEventContainer(
              id: id,
              onUnmute: () {
                final isMuted = state.eventsMutes.contains(id);

                showCupertinoCustomDialogue(
                  context: context,
                  title: isMuted
                      ? context.t.unmuteThread.capitalizeFirst()
                      : context.t.muteThread.capitalizeFirst(),
                  description: isMuted
                      ? context.t.unmuteThreadDesc.capitalizeFirst()
                      : context.t.muteThreadDesc.capitalizeFirst(),
                  buttonText: isMuted
                      ? context.t.unmute.capitalizeFirst()
                      : context.t.mute.capitalizeFirst(),
                  buttonTextColor: isMuted ? kGreen : kRed,
                  onClicked: () {
                    context.read<MuteListCubit>().setMuteStatusFunc(
                          muteKey: id,
                          isPubkey: false,
                          onSuccess: () => Navigator.pop(context),
                        );
                  },
                );
              },
            );
          },
          itemCount: state.eventsMutes.length,
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
            borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _about(metadata, context),
            ],
          ),
        ),
      ),
    );
  }

  Padding _about(Metadata metadata, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        children: [
          Row(
            spacing: kDefaultPadding / 2,
            children: [
              ProfilePicture3(
                size: 35,
                image: metadata.picture,
                pubkey: metadata.pubkey,
                padding: 0,
                strokeWidth: 0,
                strokeColor: Theme.of(context).cardColor,
                onClicked: () {},
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.getName(),
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Nip05Component(
                      metadata: metadata,
                      removeSpace: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          //
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _muteButton(metadata, context),
        ],
      ),
    );
  }

  Widget _muteButton(Metadata metadata, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => onUnmute.call(metadata.name),
        style: TextButton.styleFrom(
          backgroundColor: kRed.withValues(alpha: 0.2),
          visualDensity: const VisualDensity(
            horizontal: -4,
            vertical: -2,
          ),
        ),
        icon: SvgPicture.asset(
          FeatureIcons.unmute,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            kRed,
            BlendMode.srcIn,
          ),
        ),
        label: Text(
          context.t.unmute.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(color: kRed),
        ),
      ),
    );
  }
}

class MutedEventContainer extends StatelessWidget {
  const MutedEventContainer({
    super.key,
    required this.id,
    required this.onUnmute,
  });

  final String id;
  final Function() onUnmute;

  @override
  Widget build(BuildContext context) {
    return SingleEventProvider(
      id: id,
      isReplaceable: false,
      child: (event) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event == null || event.kind != EventKind.TEXT_NOTE) ...[
              Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 4),
                child: Column(
                  spacing: kDefaultPadding / 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.identifier,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                    Text(id),
                  ],
                ),
              )
            ] else ...[
              NoteContainer(
                note: DetailedNoteModel.fromEvent(event),
              ),
            ],
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            _muteButton(context),
          ],
        ),
      ),
    );
  }

  Widget _muteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => onUnmute.call(),
        style: TextButton.styleFrom(
          backgroundColor: kRed.withValues(alpha: 0.2),
          visualDensity: const VisualDensity(
            horizontal: -4,
            vertical: -2,
          ),
        ),
        icon: SvgPicture.asset(
          FeatureIcons.unmute,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            kRed,
            BlendMode.srcIn,
          ),
        ),
        label: Text(
          context.t.unmuteThread.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(color: kRed),
        ),
      ),
    );
  }
}
