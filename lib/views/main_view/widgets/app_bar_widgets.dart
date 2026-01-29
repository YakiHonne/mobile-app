import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../logic/notifications_cubit/notifications_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/wallet_model.dart';
import '../../../utils/utils.dart';
import '../../wallet_cashu_view/widgets/mints_list.dart';
import '../../wallet_view/widgets/internal_wallets_list_view.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/content_manager/add_discover_filter.dart';
import '../../widgets/content_manager/discover_filter_list.dart';
import '../../widgets/custom_icon_buttons.dart';

class SelectedWalletContainer extends StatelessWidget {
  const SelectedWalletContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, mainState) {
        if (mainState.isCashuWallet) {
          return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
            builder: (context, state) {
              if (state.mints.isEmpty) {
                return FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    context.t.wallet,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) {
                      return const MintsList();
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                behavior: HitTestBehavior.translucent,
                child: _cashuWalletSelector(state),
              );
            },
          );
        } else {
          return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
            builder: (context, state) {
              if (state.wallets.isEmpty) {
                return FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    context.t.wallet,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) {
                      return const InternalWalletsListView();
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                behavior: HitTestBehavior.translucent,
                child: _nwcWalletSelector(state),
              );
            },
          );
        }
      },
    );
  }

  SizedBox _nwcWalletSelector(WalletsManagerState state) {
    return SizedBox(
      width: 50.w,
      child: Builder(
        builder: (context) {
          final wallet = state.wallets[state.selectedWalletId];
          final isNwc = wallet is NostrWalletConnectModel;
          final walletId = wallet?.lud16 ?? 'wallet';

          return Row(
            spacing: kDefaultPadding / 4,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: SvgPicture.asset(
                    isNwc ? FeatureIcons.nwc : FeatureIcons.alby,
                    width: 20,
                    height: 20,
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  walletId,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SizedBox _cashuWalletSelector(CashuWalletManagerState state) {
    final activeMint = state.mints[state.activeMint];
    final activeMintName = activeMint?.name ?? state.activeMint;
    final image = activeMint?.info?.iconUrl ?? '';

    return SizedBox(
      width: 50.w,
      child: Builder(
        builder: (context) {
          return Row(
            spacing: kDefaultPadding / 4,
            children: [
              if (image.isNotEmpty)
                ExtendedImage.network(
                  image,
                  width: 20,
                  height: 20,
                )
              else
                ExtendedImage.asset(
                  Images.cashu,
                  width: 20,
                  height: 20,
                ),
              Expanded(
                child: Text(
                  activeMintName,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DmOptionsButton extends StatelessWidget {
  const DmOptionsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) => _buildFilterMenuItems(context),
      buttonBuilder: (context, showMenu) => CustomIconButton(
        onClicked: () => doIfCanSign(func: showMenu, context: context),
        icon: FeatureIcons.more,
        size: 20,
        vd: -1,
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  List<PullDownMenuEntry> _buildFilterMenuItems(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium;

    return [
      // Read All option
      PullDownMenuItem(
        title: context.t.readAll.capitalizeFirst(),
        onTap: dmsCubit.markAllAsRead,
        itemTheme: PullDownMenuItemTheme(textStyle: textStyle),
        iconWidget: SvgPicture.asset(
          FeatureIcons.visible,
          height: 20,
          width: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
      const PullDownMenuDivider.large(),

      // Time filter section
      PullDownMenuTitle(title: Text(context.t.filterByTime)),
      ..._buildTimeFilterItems(context, textStyle),
    ];
  }

  List<PullDownMenuEntry> _buildTimeFilterItems(
    BuildContext context,
    TextStyle? textStyle,
  ) {
    final timeOptions = [
      (0, context.t.allTime),
      (1, context.t.oneMonth),
      (3, context.t.threeMonths),
      (6, context.t.sixMonths),
      (12, context.t.oneYear),
    ];

    return timeOptions.map((option) {
      final (timeValue, label) = option;
      final isSelected = dmsCubit.state.selectedTime == timeValue;

      return PullDownMenuItem.selectable(
        title: label.capitalizeFirst(),
        selected: isSelected,
        onTap: () => context.read<DmsCubit>().setSelectedTime(timeValue),
        itemTheme: PullDownMenuItemTheme(
          textStyle: textStyle?.copyWith(
            color: isSelected ? kGreen : Theme.of(context).primaryColorDark,
          ),
        ),
      );
    }).toList();
  }
}

class InboxTypes extends HookWidget {
  const InboxTypes({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final types = inboxTypes(context);

    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, state) {
        return FutureBuilder<List<int>>(
          initialData: const [0, 0, 0],
          future: messagesCount(),
          builder: (context, snapshot) {
            final counts = snapshot.data!;

            return PullDownButton(
              animationBuilder: (context, state, child) => child,
              routeTheme: PullDownMenuRouteTheme(
                backgroundColor: Theme.of(context).cardColor,
              ),
              itemBuilder: (context) {
                final items = <PullDownMenuEntry>[];

                for (int i = 0; i < types.length; i++) {
                  final type = types[i];
                  final isSelected = state.index == i;

                  items.add(
                    PullDownMenuItem.selectable(
                      title: type,
                      iconWidget: Text(
                        counts[i] == 0 ? '' : '${counts[i]}',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: isSelected,
                      onTap: () {
                        dmsCubit.setIndex(i);
                        scrollController.jumpTo(0);
                      },
                      itemTheme: PullDownMenuItemTheme(
                        textStyle:
                            Theme.of(context).textTheme.labelLarge!.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ),
                  );
                }

                return items;
              },
              buttonBuilder: (context, showMenu) =>
                  _showMenu(showMenu, context, state, counts),
            );
          },
        );
      },
    );
  }

  GestureDetector _showMenu(Function() showMenu, BuildContext context,
      DmsState state, List<int> counts) {
    return GestureDetector(
      onTap: showMenu,
      child: SizedBox(
        width: 50.w,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  inboxTypes(context)[state.index].capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  ' ${counts[state.index] == 0 ? '' : '(${counts[state.index]})'}',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> inboxTypes(BuildContext context) {
    return [
      context.t.followings,
      context.t.known,
      context.t.unknown,
    ];
  }

  Future<List<int>> messagesCount() async {
    final res = await Future.wait(
      [
        dmsCubit.howManyNewDMSessionsWithNewMessages(
          DmsType.followings,
        ),
        dmsCubit.howManyNewDMSessionsWithNewMessages(
          DmsType.known,
        ),
        dmsCubit.howManyNewDMSessionsWithNewMessages(
          DmsType.unknown,
        )
      ],
    );

    return res;
  }
}

class NotificationTypes extends HookWidget {
  const NotificationTypes({super.key});

  @override
  Widget build(BuildContext context) {
    final types = inboxTypes(context);

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return PullDownButton(
          animationBuilder: (context, state, child) => child,
          routeTheme: PullDownMenuRouteTheme(
            backgroundColor: Theme.of(context).cardColor,
          ),
          itemBuilder: (context) {
            final items = <PullDownMenuEntry>[];

            for (int i = 0; i < types.length; i++) {
              final type = types[i];
              final isSelected = state.index == i;

              items.add(
                PullDownMenuItem.selectable(
                  title: type.capitalizeFirst(),
                  selected: isSelected,
                  onTap: () => notificationsCubit.setIndex(i),
                  itemTheme: PullDownMenuItemTheme(
                    textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              );
            }

            return items;
          },
          buttonBuilder: (context, showMenu) =>
              _showMenu(showMenu, context, state),
        );
      },
    );
  }

  GestureDetector _showMenu(
      Function() showMenu, BuildContext context, NotificationsState state) {
    return GestureDetector(
      onTap: showMenu,
      child: SizedBox(
        width: 50.w,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  inboxTypes(context)[state.index].capitalizeFirst(),
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
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> inboxTypes(BuildContext context) {
    return [
      context.t.all,
      context.t.mentions,
      context.t.zaps,
      context.t.replies,
      context.t.followings,
    ];
  }
}

class FilterGlobalButton extends StatelessWidget {
  const FilterGlobalButton({
    super.key,
    required this.viewType,
  });

  final ViewDataTypes viewType;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsManagerCubit, AppSettingsManagerState>(
      listener: (context, state) {
        if (viewType == ViewDataTypes.articles) {
          discoverCubit.buildDiscoverFeed(
            exploreType: discoverCubit.exploreType,
            isAdding: false,
          );
        } else if (viewType == ViewDataTypes.notes) {
          leadingCubit.buildLeadingFeed(isAdding: false);
        } else if (viewType == ViewDataTypes.media) {
          mediaCubit.buildMediaFeed(isAdding: false);
        }
      },
      listenWhen: (previous, current) =>
          previous.selectedDiscoverFilter != current.selectedDiscoverFilter ||
          previous.selectedMediaFilter != current.selectedMediaFilter ||
          previous.selectedNotesFilter != current.selectedNotesFilter ||
          previous.discoverFilters != current.discoverFilters ||
          previous.mediaFilters != current.mediaFilters ||
          previous.notesFilters != current.notesFilters,
      builder: (context, state) {
        final filter = viewType == ViewDataTypes.articles
            ? state.discoverFilters[state.selectedDiscoverFilter]
            : viewType == ViewDataTypes.media
                ? state.mediaFilters[state.selectedMediaFilter]
                : state.notesFilters[state.selectedNotesFilter];

        return Stack(
          children: [
            _customIconButton(state, context),
            if (filter != null)
              Positioned(
                right: 1,
                top: 3,
                child: DotContainer(
                  color: Theme.of(context).primaryColor,
                  size: 8,
                  isNotMarging: true,
                ),
              ),
          ],
        );
      },
    );
  }

  CustomIconButton _customIconButton(
      AppSettingsManagerState state, BuildContext context) {
    return CustomIconButton(
      onClicked: () {
        doIfCanSign(
          func: () {
            Widget view;

            if (viewType == ViewDataTypes.articles) {
              if (state.discoverFilters.isEmpty) {
                view = AddDiscoverFilter(
                  discoverFilter:
                      appSettingsManagerCubit.getSelectedDiscoverFilter(),
                );
              } else {
                view = AppFilterList(
                  viewType: viewType,
                );
              }
            } else if (viewType == ViewDataTypes.notes) {
              if (state.notesFilters.isEmpty) {
                view = AddNotesFilter(
                  notesFilter: appSettingsManagerCubit.getSelectedNotesFilter(),
                );
              } else {
                view = AppFilterList(
                  viewType: viewType,
                );
              }
            } else {
              if (state.mediaFilters.isEmpty) {
                view = AddMediaFilter(
                  mediaFilter: appSettingsManagerCubit.getSelectedMediaFilter(),
                );
              } else {
                view = AppFilterList(
                  viewType: viewType,
                );
              }
            }

            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return view;
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          context: context,
        );
      },
      icon: FeatureIcons.filter,
      size: 20,
      borderColor: Theme.of(context).dividerColor,
      backgroundColor: Theme.of(context).cardColor,
      vd: -1,
    );
  }
}
