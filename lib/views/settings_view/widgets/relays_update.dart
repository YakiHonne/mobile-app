// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/core/nostr_core_repository.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../logic/properties_cubit/update_relays_cubit/update_relays_cubit.dart';
import '../../../repositories/nostr_data_repository.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../relay_feed_view/relay_feed_view.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import 'properties_relay_list.dart';
import 'relay_info_view.dart';
import 'settings_text.dart';

class RelayUpdateView extends HookWidget {
  RelayUpdateView({super.key, this.initialIndex}) {
    umamiAnalytics.trackEvent(screenName: 'Relays update view');
  }

  static const routeName = '/relayUpdateView';
  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => RelayUpdateView(),
    );
  }

  final int? initialIndex;

  @override
  Widget build(BuildContext context) {
    final addRelayState = useState('');
    final addRelayController = useTextEditingController();
    final connect = useState<RelayConnectivity>(RelayConnectivity.idle);
    final formkey = useMemoized(() => GlobalKey<FormState>());
    final pageController = PageController(
      viewportFraction: 0.95,
      initialPage: initialIndex ?? 0,
    );
    final List<Widget> widgets = [];
    final index = useState(initialIndex ?? 0);
    final addRelay = useCallback(
      (UpdateRelaysCubit urCubit) async {
        final r = getProperRelayUrl(addRelayState.value);

        if (index.value == 0) {
          urCubit.setRelay(
            r,
            textfield: true,
            onSuccess: () async {
              await urCubit.updateRelays(
                onSuccess: () {
                  addRelayController.clear();
                },
              );

              connect.value = RelayConnectivity.idle;
            },
          );
        } else {
          await urCubit.updateDmRelay(
            relay: r,
            isAdding: true,
            onSuccess: () {
              addRelayController.clear();
            },
          );

          connect.value = RelayConnectivity.idle;
        }
      },
    );

    final Widget addingRelayManually = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          context.t.settingsRelaysDesc,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        const Divider(
          height: kDefaultPadding * 1.5,
          thickness: 0.5,
        ),
        TitleDescriptionComponent(
          title: context.t.instantConntect.capitalizeFirst(),
          description: context.t.addQuickRelayDesc,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        _searchRow(formkey, addRelayController, connect, addRelay,
            addRelayState, index),
      ],
    );

    widgets.addAll(
      [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: Column(
            spacing: kDefaultPadding,
            children: [
              addingRelayManually,
              Row(
                spacing: kDefaultPadding / 4,
                children: [
                  Expanded(
                    child: Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        Flexible(
                          child: Text(
                            context.t.relays,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        _relaysRow(context)
                      ],
                    ),
                  ),
                  RotatedBox(
                    quarterTurns: 3,
                    child: CustomIconButton(
                      onClicked: () {
                        pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      },
                      icon: FeatureIcons.arrowUp,
                      size: 17,
                      backgroundColor: kTransparent,
                      vd: -4,
                    ),
                  ),
                  DotContainer(
                    color: Theme.of(context).primaryColorDark,
                    isNotMarging: false,
                    height: 7,
                    width: index.value == 0 ? 32 : 7,
                  ),
                  DotContainer(
                    color: Theme.of(context).primaryColorDark,
                    isNotMarging: false,
                    height: 7,
                    width: index.value != 0 ? 32 : 7,
                  ),
                  RotatedBox(
                    quarterTurns: 1,
                    child: CustomIconButton(
                      onClicked: () {
                        pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      },
                      icon: FeatureIcons.arrowUp,
                      size: 17,
                      backgroundColor: kTransparent,
                      vd: -4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: (value) {
              index.value = value;
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 8,
                ),
                child: Column(
                  children: [
                    Flexible(child: ContentRelaysContainer()),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 4,
                ),
                child: Column(
                  children: [
                    Flexible(child: PrivateMessageRelaysContainer()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return BlocProvider(
      create: (context) => UpdateRelaysCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.relays.capitalizeFirst(),
        ),
        body: Column(
          children: widgets,
        ),
      ),
    );
  }

  GestureDetector _relaysRow(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(
                  kDefaultPadding / 2,
                ),
                margin: const EdgeInsets.all(
                  kDefaultPadding,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding / 1.5,
                  ),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.t.status,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Divider(
                      height: kDefaultPadding,
                      thickness: 0.5,
                    ),
                    _relayStatusBox(
                      context: context,
                      color: kGreen,
                      title: context.t.greenDotsDesc,
                    ),
                    _relayStatusBox(
                      context: context,
                      color: kDimGrey,
                      title: context.t.greyDotsDesc,
                    ),
                    _relayStatusBox(
                      context: context,
                      color: kRed,
                      title: context.t.redDotsDesc,
                    ),
                    const Divider(
                      height: kDefaultPadding,
                      thickness: 0.5,
                    ),
                    Text(
                      context.t.fewerRelays,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Icon(
        CupertinoIcons.info,
        color: Theme.of(context).highlightColor,
        size: 18,
      ),
    );
  }

  Builder _searchRow(
    GlobalKey<FormState> formkey,
    TextEditingController addRelayController,
    ValueNotifier<RelayConnectivity> connect,
    Function(UpdateRelaysCubit) addRelay,
    ValueNotifier<String> addRelayState,
    ValueNotifier<int> index,
  ) {
    return Builder(
      builder: (context) {
        return Form(
          key: formkey,
          child: Row(
            children: [
              Expanded(
                child: RelaySearchTextfield(
                  addRelayController: addRelayController,
                  connect: connect,
                  formkey: formkey,
                  addRelay: () => addRelay.call(
                    context.read<UpdateRelaysCubit>(),
                  ),
                  addRelayState: addRelayState,
                  isAdd: false,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              _searchButton(context, index)
            ],
          ),
        );
      },
    );
  }

  Container _searchButton(BuildContext context, ValueNotifier<int> index) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 1.5,
        ),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: CustomIconButton(
        icon: FeatureIcons.search,
        size: 18,
        backgroundColor: Theme.of(context).cardColor,
        vd: -2,
        onClicked: () {
          context.read<UpdateRelaysCubit>().setOnlineRelays();

          showModalBottomSheet(
            context: context,
            elevation: 0,
            builder: (_) {
              return BlocProvider.value(
                value: context.read<UpdateRelaysCubit>(),
                child: RelaysList(
                  isPrivateMessages: index.value == 1,
                ),
              );
            },
            isScrollControlled: true,
            useRootNavigator: true,
            useSafeArea: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
      ),
    );
  }

  Row _relayStatusBox({
    required BuildContext context,
    required Color color,
    required String title,
  }) {
    return Row(
      children: [
        DotContainer(
          color: color,
          size: 7,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }
}

class RelaySearchTextfield extends StatelessWidget {
  const RelaySearchTextfield({
    super.key,
    required this.addRelayController,
    required this.connect,
    required this.formkey,
    required this.addRelay,
    required this.addRelayState,
    required this.isAdd,
  });

  final TextEditingController addRelayController;
  final ValueNotifier<RelayConnectivity> connect;
  final GlobalKey<FormState> formkey;
  final Function() addRelay;
  final ValueNotifier<String> addRelayState;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: addRelayController,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'wss://sort.relay.com',
        suffixIcon: connect.value == RelayConnectivity.idle
            ? null
            : connect.value == RelayConnectivity.searching
                ? SizedBox(
                    width: 25,
                    height: 25,
                    child: SpinKitCircle(
                      color: Theme.of(context).primaryColorDark,
                      size: 20,
                    ),
                  )
                : connect.value == RelayConnectivity.found
                    ? TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: kTransparent,
                        ),
                        onPressed: () async {
                          if (formkey.currentState!.validate()) {
                            addRelay();
                          }
                        },
                        child: Text(
                          (isAdd ? context.t.add : context.t.connect)
                              .capitalizeFirst(),
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: kGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      )
                    : const Icon(
                        Icons.close,
                        color: kRed,
                        size: 18,
                      ),
      ),
      onChanged: (relay) async {
        addRelayState.value = relay;
        connect.value = relay.isEmpty
            ? RelayConnectivity.idle
            : RelayConnectivity.searching;

        if (relay.isNotEmpty) {
          final res =
              await appSettingsManagerCubit.checkRelayConnectivity(relay);

          connect.value =
              res ? RelayConnectivity.found : RelayConnectivity.notFound;
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return context.t.invalidRelayUrl.capitalizeFirst();
        }

        return null;
      },
    );
  }
}

class ContentRelaysContainer extends StatelessWidget {
  const ContentRelaysContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final addRelays = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.t.content.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
      ],
    );

    final relaysList = BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
      builder: (context, state) {
        final rEntries = state.relays.entries.toList();

        return MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemBuilder: (context, index) {
              final relay = rEntries[index];

              return RelayInfoProvider(
                relay: relay.key,
                child: (info) => ContentRelayUpdateContainer(
                  canBeDeleted: rEntries.length > 1,
                  isActive: state.activeRelays.contains(relay.key),
                  relay: relay.key,
                  rwMarker: relay.value,
                  toBeDeleted: state.toBeDeleted.contains(relay.key),
                  onDelete: () {
                    context.read<UpdateRelaysCubit>().setToBeDeleted(relay.key);
                  },
                  updateReadWriteMarket: (m) {
                    context.read<UpdateRelaysCubit>().updateRelayMarker(
                          relay: relay.key,
                          rwMarker: m,
                        );
                  },
                  isPair: index.isEven,
                  relayInfo: info,
                  isPending: state.pendingRelays.keys.contains(relay.key),
                ),
              );
            },
            itemCount: rEntries.length,
          ),
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 1.5,
            ),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          margin: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              addRelays,
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight - 120,
                  ),
                  child: relaysList,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _saveButton(),
            ],
          ),
        );
      },
    );
  }

  BlocBuilder<UpdateRelaysCubit, UpdateRelaysState> _saveButton() {
    return BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
      builder: (context, state) {
        if (state.isSameRelays) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  context.read<UpdateRelaysCubit>().updateRelays(
                        onSuccess: () {},
                      );
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.comfortable,
                ),
                child: Text(
                  context.t.save,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PrivateMessageRelaysContainer extends HookWidget {
  const PrivateMessageRelaysContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasNoDms = useState(nostrRepository.dmRelays.isEmpty);

    final addRelays = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.privateMessages.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).highlightColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
      ],
    );

    final relaysList = BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
      builder: (context, state) {
        final relays = state.dmRelays;

        if (relays.isEmpty) {
          return SizedBox(
            width: double.infinity,
            child: Text(
              context.t.noRelays,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          );
        }

        return MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemBuilder: (context, index) {
              final relay = relays[index];

              return RelayInfoProvider(
                relay: relay,
                child: (info) => DmRelayUpdateContainer(
                  relay: relay,
                  isActive: state.activeRelays.contains(relay),
                  relayInfo: info,
                  onDelete: () {
                    context.read<UpdateRelaysCubit>().updateDmRelay(
                          relay: relay,
                          isAdding: false,
                        );
                  },
                ),
              );
            },
            itemCount: relays.length,
          ),
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 1.5,
            ),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addRelays,
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight - 120,
                ),
                child: relaysList,
              ),
              _dmRelays(constraints, hasNoDms),
            ],
          ),
        );
      },
    );
  }

  ConstrainedBox _dmRelays(
      BoxConstraints constraints, ValueNotifier<bool> hasNoDms) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: constraints.maxHeight - 120,
      ),
      child: BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
        builder: (context, state) {
          final relays =
              DEFAULT_DM_RELAYS.toSet().difference(state.dmRelays.toSet());
          if (hasNoDms.value && relays.isNotEmpty) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  Text(
                    context.t.suggestions,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  _itemsList(context, relays),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  MediaQuery _itemsList(BuildContext context, Set<String> relays) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        primary: false,
        itemBuilder: (context, index) {
          final r = relays.elementAt(index);

          return DmRelaySuggestionContainer(
            relay: r,
            onAdd: () async {
              await context.read<UpdateRelaysCubit>().updateDmRelay(
                    relay: r,
                    isAdding: true,
                    onSuccess: () {},
                  );
            },
          );
        },
        separatorBuilder: (context, index) {
          return const Divider();
        },
        itemCount: relays.length,
      ),
    );
  }
}

class DmRelaySuggestionContainer extends StatelessWidget {
  const DmRelaySuggestionContainer({
    super.key,
    required this.relay,
    required this.onAdd,
    this.relayInfo,
  });

  final String relay;
  final Function() onAdd;
  final RelayInfo? relayInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _relayImage(context),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    _relayTitle(context),
                    CustomIconButton(
                      onClicked: onAdd,
                      icon: FeatureIcons.log,
                      vd: -4,
                      size: 18,
                      iconColor: kGreen,
                      backgroundColor: kTransparent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Expanded _relayTitle(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(
              relay,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (relayInfo != null) ...[
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (relayInfo != null) {
                  Navigator.pushNamed(
                    context,
                    RelayInfoView.routeName,
                    arguments: relayInfo,
                  );
                }
              },
              child: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).highlightColor,
                size: 18,
              ),
            )
          ],
        ],
      ),
    );
  }

  Container _relayImage(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 4,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Center(
        child: ExtendedImage.network(
          relayInfo?.icon ?? '',
          width: 20,
          height: 20,
          compressionRatio: 1,
          borderRadius: BorderRadius.circular(kDefaultPadding / 4),
          shape: BoxShape.rectangle,
          loadStateChanged: (state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                return null;
              case LoadState.completed:
                return null;
              case LoadState.failed:
                return Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(2),
                  child: FittedBox(
                    child: Text(
                      relay.isNotEmpty
                          ? relay.characters.first.capitalize()
                          : '',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class DmRelayUpdateContainer extends StatelessWidget {
  const DmRelayUpdateContainer({
    super.key,
    required this.relay,
    required this.isActive,
    required this.onDelete,
    this.relayInfo,
  });

  final String relay;
  final bool isActive;
  final Function() onDelete;
  final RelayInfo? relayInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _relayImage(context),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    _relayTitle(context),
                    DotContainer(
                      color: isActive ? kGreen : kRed,
                      size: 8,
                    ),
                    _deleteRelay()
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector _deleteRelay() {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          color: kRed.withValues(alpha: 0.1),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 4,
          horizontal: kDefaultPadding / 1.5,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              FeatureIcons.log,
              width: 15,
              height: 15,
              colorFilter: const ColorFilter.mode(
                kRed,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _relayTitle(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(
              relay,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (relayInfo != null) ...[
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (relayInfo != null) {
                  Navigator.pushNamed(
                    context,
                    RelayInfoView.routeName,
                    arguments: relayInfo,
                  );
                }
              },
              child: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).highlightColor,
                size: 18,
              ),
            )
          ],
        ],
      ),
    );
  }

  Container _relayImage(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 4,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Center(
        child: ExtendedImage.network(
          relayInfo?.icon ?? '',
          width: 20,
          height: 20,
          compressionRatio: 1,
          borderRadius: BorderRadius.circular(kDefaultPadding / 4),
          shape: BoxShape.rectangle,
          loadStateChanged: (state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                return null;
              case LoadState.completed:
                return null;
              case LoadState.failed:
                return Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(2),
                  child: FittedBox(
                    child: Text(
                      relay.isNotEmpty
                          ? relay.characters.first.capitalize()
                          : '',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class ContentRelayUpdateContainer extends StatelessWidget {
  const ContentRelayUpdateContainer({
    super.key,
    required this.relay,
    required this.rwMarker,
    required this.isActive,
    required this.isPending,
    required this.canBeDeleted,
    required this.toBeDeleted,
    required this.onDelete,
    required this.updateReadWriteMarket,
    this.relayInfo,
    this.isPair,
  });

  final String relay;
  final ReadWriteMarker rwMarker;
  final bool isActive;
  final bool isPending;
  final bool canBeDeleted;
  final bool toBeDeleted;
  final Function() onDelete;
  final Function(ReadWriteMarker) updateReadWriteMarket;
  final RelayInfo? relayInfo;
  final bool? isPair;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _relayImage(context),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    _relayTitle(context),
                    DotContainer(
                      color: isPending
                          ? Theme.of(context).highlightColor
                          : isActive
                              ? kGreen
                              : kRed,
                      size: 8,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _relayOptions(context),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    if (canBeDeleted) _relayDelete(context)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector _relayDelete(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          color: toBeDeleted
              ? Theme.of(context).cardColor
              : kRed.withValues(alpha: 0.1),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 4,
          horizontal: kDefaultPadding / 1.5,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              toBeDeleted ? FeatureIcons.undo : FeatureIcons.log,
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                toBeDeleted ? Theme.of(context).primaryColorDark : kRed,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Flexible _relayOptions(BuildContext context) {
    return Flexible(
      child: Row(
        children: [
          Flexible(
            child: RelayStatusContainer(
              isMarkerSelected: rwMarker == ReadWriteMarker.readOnly,
              title: context.t.readOnly.capitalizeFirst(),
              onClicked: () {
                updateReadWriteMarket.call(ReadWriteMarker.readOnly);
              },
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Flexible(
            child: RelayStatusContainer(
              isMarkerSelected: rwMarker == ReadWriteMarker.writeOnly,
              title: context.t.writeOnly.capitalizeFirst(),
              onClicked: () {
                updateReadWriteMarket.call(ReadWriteMarker.writeOnly);
              },
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Flexible(
            child: RelayStatusContainer(
              isMarkerSelected: rwMarker == ReadWriteMarker.readWrite,
              title: context.t.readWrite.capitalizeFirst(),
              onClicked: () {
                updateReadWriteMarket.call(ReadWriteMarker.readWrite);
              },
            ),
          ),
        ],
      ),
    );
  }

  Expanded _relayTitle(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => onClickRelay.call(context),
              child: Text(
                relay,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (relayInfo != null) ...[
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (relayInfo != null) {
                  Navigator.pushNamed(
                    context,
                    RelayInfoView.routeName,
                    arguments: relayInfo,
                  );
                }
              },
              child: Icon(
                CupertinoIcons.info,
                color: Theme.of(context).highlightColor,
                size: 18,
              ),
            )
          ],
        ],
      ),
    );
  }

  Container _relayImage(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 4,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Center(
        child: GestureDetector(
          onTap: () => onClickRelay.call(context),
          child: ExtendedImage.network(
            relayInfo?.icon ?? '',
            width: 20,
            height: 20,
            compressionRatio: 1,
            borderRadius: BorderRadius.circular(kDefaultPadding / 4),
            shape: BoxShape.rectangle,
            loadStateChanged: (state) {
              switch (state.extendedImageLoadState) {
                case LoadState.loading:
                  return null;
                case LoadState.completed:
                  return null;
                case LoadState.failed:
                  return Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(2),
                    child: FittedBox(
                      child: Text(
                        relay.isNotEmpty
                            ? relay.characters.first.capitalize()
                            : '',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  void onClickRelay(BuildContext context) {
    YNavigator.pushPage(
      context,
      (context) => RelayFeedView(
        relay: relay,
      ),
    );
  }
}

class RelayStatusContainer extends StatelessWidget {
  const RelayStatusContainer({
    super.key,
    required this.isMarkerSelected,
    required this.onClicked,
    required this.title,
  });

  final bool isMarkerSelected;
  final Function() onClicked;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isMarkerSelected ? 1 : 0.4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: isMarkerSelected
                  ? Theme.of(context).dividerColor
                  : kTransparent,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding / 3,
            horizontal: kDefaultPadding / 1.5,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
