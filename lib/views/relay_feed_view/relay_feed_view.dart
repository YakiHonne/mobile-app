import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/relay.dart';

import '../../logic/relay_feed_cubit/relay_feed_cubit.dart';
import '../../logic/relay_info_cubit/relay_info_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/dotted_container.dart';
import 'widgets/relay_content_feed.dart';

class RelayFeedView extends StatelessWidget {
  const RelayFeedView({
    super.key,
    required this.relay,
  });

  final String relay;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RelayFeedCubit(
        relay: Relay.clean(relay) ?? relay,
      )..initView(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SafeArea(
            child: ModalBottomSheetAppbar(
              title: Relay.removeSocket(relay) ?? relay,
              isBack: false,
              widget: !canSign() ? null : _buildPullDown(context),
            ),
          ),
        ),
        floatingActionButton: canSign()
            ? Builder(
                builder: (context) {
                  return Padding(
                    padding: isFluid()
                        ? const EdgeInsets.only(bottom: kDefaultPadding * 2 + 4)
                        : EdgeInsets.zero,
                    child: FloatingActionButton(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: const CircleBorder(),
                      heroTag: 'content_creation',
                      child: const AppIcon(
                        FeatureIcons.addRaw,
                        size: 20,
                        color: kWhite,
                      ),
                      onPressed: () {
                        doIfCanSign(
                          func: () {
                            HapticFeedback.mediumImpact();
                            YNavigator.pushPage(
                              context,
                              (_) => AddContentView(
                                contentType: AppContentType.note,
                                selectedExternalRelay:
                                    context.read<RelayFeedCubit>().relay,
                              ),
                            );
                          },
                          context: context,
                        );
                      },
                    ),
                  );
                },
              )
            : null,
        body: const RelayContentFeed(),
      ),
    );
  }

  Widget _buildPullDown(BuildContext context) {
    return BlocBuilder<RelayInfoCubit, RelayInfoState>(
      buildWhen: (previous, current) =>
          previous.relayFeeds.favoriteRelays !=
          current.relayFeeds.favoriteRelays,
      builder: (context, state) {
        final isAvailable = state.relayFeeds.favoriteRelays.contains(
          relay,
        );

        return AppIconButton(
          onClicked: () {
            relayInfoCubit.setAndUpdateFavoriteRelay(
              relay,
            );
          },
          backgroundColor: Theme.of(context).cardColor,
          icon:
              isAvailable ? FeatureIcons.favoriteFilled : FeatureIcons.favorite,
          iconColor: isAvailable
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColorDark,
          size: 40,
          iconSize: 20,
        );
      },
    );
  }
}
