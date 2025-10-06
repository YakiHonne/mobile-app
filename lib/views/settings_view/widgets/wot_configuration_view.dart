import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/properties_cubit/wot_configuration_cubit/wot_configuration_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_manager/add_discover_filter.dart';
import '../../widgets/custom_app_bar.dart';

class WotConfigurationView extends StatelessWidget {
  const WotConfigurationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WotConfigurationCubit(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.wot.capitalizeFirst(),
        ),
        body: BlocBuilder<WotConfigurationCubit, WotConfigurationState>(
          builder: (context, state) {
            final c = context.read<WotConfigurationCubit>();

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 2,
              ),
              children: [
                Text(
                  context.t.wotThreshold.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                FilterSliderBox(
                  title: '',
                  max: 10,
                  min: 0,
                  onChanged: (val) {
                    c.updateSettings(threshold: val);
                  },
                  val: state.threshold,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  context.t.enabledFor.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                _allRow(context, c),
                const Divider(
                  height: kDefaultPadding / 2,
                  thickness: 0.5,
                ),
                _optionRow(
                  context: context,
                  onChanged: (value) {
                    if (value != null) {
                      c.updateSettings(
                        notifications: value,
                      );
                    }
                  },
                  status: state.notifications,
                  title: context.t.notifications,
                ),
                _optionRow(
                  context: context,
                  onChanged: (value) {
                    if (value != null) {
                      c.updateSettings(
                        postActions: value,
                      );
                    }
                  },
                  status: state.postActions,
                  title: context.t.postActions,
                ),
                _optionRow(
                  context: context,
                  onChanged: (value) {
                    if (value != null) {
                      c.updateSettings(
                        privateMessages: value,
                      );
                    }
                  },
                  status: state.privateMessages,
                  title: context.t.privateMessages,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Row _allRow(BuildContext context, WotConfigurationCubit c) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.all.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Checkbox(
          tristate: true,
          value: c.getSettingsStatus(),
          onChanged: (value) {
            if (value != null) {
              if (value) {
                c.updateSettings(
                  notifications: true,
                  postActions: true,
                  privateMessages: true,
                );
              } else {
                c.updateSettings(
                  notifications: false,
                  postActions: false,
                  privateMessages: false,
                );
              }
            } else {
              c.updateSettings(
                notifications: false,
                postActions: false,
                privateMessages: false,
              );
            }
          },
          activeColor: kMainColor,
          checkColor: kBlack,
        ),
      ],
    );
  }

  Row _optionRow({
    required BuildContext context,
    required String title,
    required bool status,
    required Function(bool? value) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Checkbox(
          value: status,
          onChanged: onChanged,
          activeColor: kMainColor,
          checkColor: kBlack,
        ),
      ],
    );
  }
}
