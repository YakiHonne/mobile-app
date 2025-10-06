import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/properties_cubit/properties_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import 'media_uploader_settings.dart';
import 'mute_list_view.dart';
import 'settings_text.dart';
import 'wot_configuration_view.dart';

class PropertyContentModeration extends StatelessWidget {
  PropertyContentModeration({
    super.key,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Content moderation view');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: context.t.contentModeration.capitalizeFirst(),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: ListView(
              children: [
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  context.t.settingsContentDesc,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
                const Divider(
                  height: kDefaultPadding * 1.5,
                  thickness: 0.5,
                ),
                _muteList(context),
                const SizedBox(
                  height: kDefaultPadding / 1.5,
                ),
                _mediaUploader(context),
                const SizedBox(
                  height: kDefaultPadding / 1.5,
                ),
                _wotConfig(context),
                const SizedBox(
                  height: kDefaultPadding / 1.5,
                ),
                _automaticSignin(context, state),
                const SizedBox(
                  height: kDefaultPadding / 1.5,
                ),
                _enableGossip(context, state),
                const SizedBox(
                  height: kDefaultPadding / 1.5,
                ),
                _enableExternalBrowser(context, state),
                const SizedBox(
                  height: kDefaultPadding / 1.5,
                ),
                _secureMessaging(context, state),
                const SizedBox(
                  height: kDefaultPadding,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Row _secureMessaging(BuildContext context, PropertiesState state) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.secureDirectMessaging.capitalizeFirst(),
            description: context.t.secureDmDesc.capitalizeFirst(),
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.isUsingNip44,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<PropertiesCubit>().setUsedMessagingNip(isToggled);
            },
          ),
        ),
      ],
    );
  }

  Row _enableExternalBrowser(BuildContext context, PropertiesState state) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.enableExternalBrowser.capitalizeFirst(),
            description: context.t.useExternalBrowsDesc,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.enableUsingExternalBrowser,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<PropertiesCubit>().setExternalBrowser(isToggled);
            },
          ),
        ),
      ],
    );
  }

  Row _enableGossip(BuildContext context, PropertiesState state) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.enableGossip.capitalizeFirst(),
            description: context.t.gossipDesc,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.enableGossip,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<PropertiesCubit>().setGossip(isToggled);
            },
          ),
        ),
      ],
    );
  }

  Row _automaticSignin(BuildContext context, PropertiesState state) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.enableAutomaticSigning.capitalizeFirst(),
            description: context.t.autoSignDesc,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.enableAutomaticSigning,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<PropertiesCubit>().setAutomaticSigning(isToggled);
            },
          ),
        ),
      ],
    );
  }

  Row _wotConfig(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.wotConfig.capitalizeFirst(),
            description: context.t.wotConfigDesc,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        TextButton(
          onPressed: () {
            YNavigator.pushPage(
              context,
              (context) => const WotConfigurationView(),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            visualDensity: VisualDensity.comfortable,
          ),
          child: Text(
            context.t.edit.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
        ),
      ],
    );
  }

  Row _mediaUploader(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.mediaUploader.capitalizeFirst(),
            description: context.t.mediaUploaderDesc,
          ),
        ),
        TextButton(
          onPressed: () {
            YNavigator.pushPage(
              context,
              (context) => const MediaUploaderSettings(),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            visualDensity: VisualDensity.comfortable,
          ),
          child: Text(
            context.t.edit.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
        ),
      ],
    );
  }

  Row _muteList(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.muteList.capitalizeFirst(),
            description: context.t.muteListDesc,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              MuteListView.routeName,
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            visualDensity: VisualDensity.comfortable,
          ),
          child: Text(
            context.t.edit.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          ),
        ),
      ],
    );
  }
}
