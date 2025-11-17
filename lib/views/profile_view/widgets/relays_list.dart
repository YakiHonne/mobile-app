// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';

class ProfileRelays extends StatelessWidget {
  const ProfileRelays({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding),
              topRight: Radius.circular(kDefaultPadding),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.60,
            maxChildSize: 0.7,
            expand: false,
            builder: (_, controller) => SafeArea(
              child: Column(
                children: [
                  const ModalBottomSheetHandle(),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.t
                            .profileRelays(
                              number: state.userRelays.length
                                  .toString()
                                  .padLeft(2, '0'),
                            )
                            .capitalizeFirst(),
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  if (state.isRelaysLoading)
                    SpinKitSpinningLines(
                      size: 25,
                      color: Theme.of(context).primaryColorDark,
                    )
                  else if (state.userRelays.isEmpty)
                    EmptyList(
                      description: context.t.noUserRelays.capitalizeFirst(),
                      icon: FeatureIcons.relays,
                    )
                  else
                    _relaysList(context, controller, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Expanded _relaysList(
      BuildContext context, ScrollController controller, ProfileState state) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
        ),
        alignment: Alignment.topCenter,
        child: ScrollShadow(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            controller: controller,
            separatorBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.only(
                  left: kDefaultPadding + 3,
                ),
                child: Divider(
                  height: kDefaultPadding / 1.5,
                ),
              );
            },
            itemBuilder: (context, index) {
              final relay = state.userRelays[index];

              return ProfileRelayContainer(
                canBeAdded:
                    !state.ownRelays.contains(relay.removeLastBackSlashes()),
                isActive:
                    state.activeRelays.contains(relay.removeLastBackSlashes()),
                isEnabled: canSign(),
                relay: relay,
                onAddRelay: () {
                  context.read<ProfileCubit>().addRelay(newRelay: relay);
                },
              );
            },
            itemCount: state.userRelays.length,
          ),
        ),
      ),
    );
  }
}

class ProfileRelayContainer extends StatelessWidget {
  const ProfileRelayContainer({
    super.key,
    required this.relay,
    required this.isActive,
    required this.canBeAdded,
    required this.onAddRelay,
    required this.isEnabled,
  });

  final String relay;
  final bool isActive;
  final bool canBeAdded;
  final Function() onAddRelay;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DotContainer(
          color: isActive ? kGreen : kRed,
          isNotMarging: true,
          size: 8,
        ),
        const SizedBox(
          width: kDefaultPadding - 5,
        ),
        Expanded(
          child: Text(
            relay,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        if (!canBeAdded)
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.check_circle,
              color: kGreen,
              size: 20,
            ),
            style: TextButton.styleFrom(
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          )
        else
          Visibility(
            visible: canBeAdded && isEnabled,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              children: [
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                IconButton(
                  onPressed: onAddRelay,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
