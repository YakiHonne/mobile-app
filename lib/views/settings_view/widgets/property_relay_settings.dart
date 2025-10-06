import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/properties_cubit/properties_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../settings_view.dart';
import 'relays_update.dart';

class PropertyRelaySettings extends StatelessWidget {
  const PropertyRelaySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      buildWhen: (previous, current) =>
          previous.relays != current.relays ||
          previous.activeRelays != current.activeRelays,
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            YNavigator.pushPage(
              context,
              (context) => RelayUpdateView(),
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 1.5,
            ),
            child: PropertyRow(
              isToggled: false,
              icon: FeatureIcons.relays,
              title: context.t
                  .relaySettings(
                    number:
                        '${currentUserRelayList.urls.length} / ${state.relays.length}',
                  )
                  .capitalizeFirst(),
              isRaw: true,
            ),
          ),
        );
      },
    );
  }
}
