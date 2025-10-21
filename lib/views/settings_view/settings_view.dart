// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/localization_cubit/localization_cubit.dart';
import '../../logic/properties_cubit/properties_cubit.dart';
import '../../routes/navigator.dart';
import '../../routes/pages_router.dart';
import '../../utils/utils.dart';
import '../notifications_view/widgets/notifications_customization.dart';
import '../profile_settings_view/profile_settings_view.dart';
import '../profile_view/profile_view.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/profile_picture.dart';
import 'widgets/keys_view.dart';
import 'widgets/property_account_deletion.dart';
import 'widgets/property_analytics_cache.dart';
import 'widgets/property_appearance.dart';
import 'widgets/property_content_moderation.dart';
import 'widgets/property_customization.dart';
import 'widgets/property_keys.dart';
import 'widgets/property_language_preferences.dart';
import 'widgets/property_relay_settings.dart';
import 'widgets/property_version.dart';
import 'widgets/property_wallet.dart';
import 'widgets/property_yaki_chest.dart';

class SettingsView extends StatelessWidget {
  SettingsView({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Settings view');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertiesCubit(),
      child: BlocBuilder<LocalizationCubit, LocalizationState>(
        builder: (context, state) {
          return BlocBuilder<PropertiesCubit, PropertiesState>(
            builder: (context, state) {
              return Scaffold(
                appBar: CustomAppBar(
                  title: context.t.settings.capitalizeFirst(),
                ),
                body: const PropertiesList(),
              );
            },
          );
        },
      ),
    );
  }
}

class PropertiesList extends HookWidget {
  const PropertiesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        final isLargeScreen =
            ResponsiveBreakpoints.of(context).largerThan(MOBILE);

        return isLargeScreen
            ? _buildDesktopLayout(context, state)
            : _buildMobileLayout(context, state);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, PropertiesState state) {
    return ListView(
      padding: const EdgeInsets.all(kDefaultPadding),
      children: [
        const SizedBox(height: kDefaultPadding / 2),
        _buildProfileSection(context, isDesktop: true),
        const SizedBox(height: kDefaultPadding / 2),
        _buildDesktopPropertyGrid(context, state),
        const SizedBox(height: kDefaultPadding / 2),
        const PropertyAccountDeletion(),
        const SizedBox(height: kDefaultPadding * 1.5),
        const PropertyVersion(),
        const SizedBox(height: 45),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, PropertiesState state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      children: [
        const SizedBox(height: kDefaultPadding / 2),
        _buildProfileSection(context, isDesktop: false),
        const SizedBox(height: kDefaultPadding / 2),
        ..._buildMobilePropertyList(context, state),
        const SizedBox(height: kDefaultPadding * 1.5),
        const PropertyVersion(),
        const SizedBox(height: 45),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, {required bool isDesktop}) {
    final canSign = currentSigner?.canSign() ?? false;

    if (!canSign) {
      return const HorizontalViewModeWidget();
    }

    return _ProfileSection(isDesktop: isDesktop);
  }

  Widget _buildDesktopPropertyGrid(
      BuildContext context, PropertiesState state) {
    final propertyBoxes = _getPropertyBoxes(context, state, isDesktop: true);

    return MasonryGridView(
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      shrinkWrap: true,
      primary: false,
      children: propertyBoxes,
    );
  }

  List<Widget> _buildMobilePropertyList(
    BuildContext context,
    PropertiesState state,
  ) {
    final propertyBoxes = _getPropertyBoxes(context, state, isDesktop: false);
    final widgets = <Widget>[];

    for (int i = 0; i < propertyBoxes.length; i++) {
      widgets.add(propertyBoxes[i]);
      if (i < propertyBoxes.length - 1) {
        widgets.add(_buildDivider());
      }
    }

    final canSign = currentSigner?.canSign() ?? false;
    if (canSign) {
      widgets.addAll([
        const SizedBox(height: kDefaultPadding),
        const PropertyAccountDeletion(),
      ]);
    }

    return widgets;
  }

  Widget _buildDivider() {
    return const Divider(
      height: 5,
      indent: 30,
      thickness: 0.5,
    );
  }

  List<Widget> _getPropertyBoxes(BuildContext context, PropertiesState state,
      {required bool isDesktop}) {
    final canSign = currentSigner?.canSign() ?? false;
    final boxes = <Widget>[];

    // Always available properties

    // Properties only available when user can sign
    if (canSign) {
      boxes.addAll(_getSignerProperties(context, state, isDesktop));
    }

    boxes.add(_createPropertyBox(
      context,
      title: context.t.appearance.capitalizeFirst(),
      icon: FeatureIcons.appearance,
      onTap: () => _navigateToAppearance(context),
    ));

    boxes.add(_createPropertyBox(
      context,
      title: context.t.analyticsCache.capitalizeFirst(),
      icon: FeatureIcons.cache,
      onTap: () => _navigateToAnalyticsCache(context),
    ));

    boxes.add(
      const PropertyYakiChest(),
    );

    return boxes;
  }

  List<Widget> _getSignerProperties(
    BuildContext context,
    PropertiesState state,
    bool isDesktop,
  ) {
    final signerBoxes = <Widget>[
      BlocBuilder<PropertiesCubit, PropertiesState>(
        builder: (context, state) {
          return _createPropertyBox(
            context,
            title: context.t.keys.capitalizeFirst(),
            icon: FeatureIcons.keys,
            onTap: () => _navigateToKeys(context, state),
          );
        },
      ),
      const PropertyRelaySettings(),
      _createPropertyBox(
        context,
        title: context.t.contentModeration.capitalizeFirst(),
        icon: FeatureIcons.shuffle,
        onTap: () => _navigateToContentModeration(context),
      ),
      _createPropertyBox(
        context,
        title: context.t.wallets.capitalizeFirst(),
        icon: FeatureIcons.wallet,
        onTap: () => _navigateToWallets(context),
      ),
      _createPropertyBox(
        context,
        title: context.t.customization.capitalizeFirst(),
        icon: FeatureIcons.customization,
        onTap: () => _navigateToCustomization(context),
      ),
      _createPropertyBox(
        context,
        title: context.t.notifications.capitalizeFirst(),
        icon: FeatureIcons.notification,
        onTap: () => _navigateToNotifications(context),
      ),
      _createPropertyBox(
        context,
        title: context.t.languagePreferences.capitalizeFirst(),
        icon: FeatureIcons.translation,
        onTap: () => _navigateToLanguagePreferences(context),
      )
    ];

    return signerBoxes;
  }

  Widget _createPropertyBox(
    BuildContext context, {
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    return PropertySimpleBox(
      title: title,
      icon: icon,
      onClick: onTap,
    );
  }

  // Navigation methods
  void _navigateToAppearance(BuildContext context) {
    YNavigator.pushPage(
      context,
      (context) => PropertyAppearance(),
    );
  }

  void _navigateToAnalyticsCache(BuildContext context) {
    YNavigator.pushPage(
      context,
      (context) => PropertyAnalyticsCache(),
    );
  }

  void _navigateToKeys(BuildContext context, PropertiesState state) {
    YNavigator.pushPage(
      context,
      (context) => KeysView(
        pubkey: state.authPubKey,
        secKey: state.authPrivKey,
        isUsingSigner: state.isUsingSigner,
      ),
    );
  }

  void _navigateToContentModeration(BuildContext context) {
    YNavigator.pushPage(
      context,
      (_) => BlocProvider.value(
        value: context.read<PropertiesCubit>(),
        child: PropertyContentModeration(),
      ),
    );
  }

  void _navigateToCustomization(BuildContext context) {
    YNavigator.pushPage(
      context,
      (_) => BlocProvider.value(
        value: context.read<PropertiesCubit>(),
        child: PropertyCustomization(),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    YNavigator.pushPage(
      context,
      (context) => const NotificationsCustomization(),
    );
  }

  void _navigateToLanguagePreferences(BuildContext context) {
    YNavigator.pushPage(
      context,
      (_) => BlocProvider.value(
        value: context.read<PropertiesCubit>(),
        child: PropertyLanguagePreferences(),
      ),
    );
  }

  void _navigateToWallets(BuildContext context) {
    YNavigator.pushPage(
      context,
      (_) => BlocProvider.value(
        value: context.read<PropertiesCubit>(),
        child: PropertyWallets(),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildProfilePicture(context),
        const Spacer(),
        if (isDesktop)
          ..._buildDesktopButtons(context)
        else
          ..._buildMobileButtons(context),
      ],
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    final profilePictureWidget =
        isDesktop ? ProfilePicture2.new : ProfilePicture3.new;

    return profilePictureWidget(
      size: 50,
      pubkey: nostrRepository.currentMetadata.pubkey,
      image: nostrRepository.currentMetadata.picture,
      padding: 0,
      strokeWidth: 0,
      strokeColor: kTransparent,
      onClicked: () => _navigateToProfileSettings(context),
    );
  }

  List<Widget> _buildDesktopButtons(BuildContext context) {
    return [
      _buildViewProfileButton(context, isDesktop: true),
      const SizedBox(width: kDefaultPadding / 4),
      _buildEditProfileButton(context, isDesktop: true),
    ];
  }

  List<Widget> _buildMobileButtons(BuildContext context) {
    return [
      Flexible(child: _buildViewProfileButton(context, isDesktop: false)),
      const SizedBox(width: kDefaultPadding / 4),
      Flexible(child: _buildEditProfileButton(context, isDesktop: false)),
    ];
  }

  Widget _buildViewProfileButton(BuildContext context,
      {required bool isDesktop}) {
    return TextButton(
      onPressed: () => _navigateToProfile(context),
      style: TextButton.styleFrom(
        backgroundColor: isDesktop ? Theme.of(context).cardColor : kMainColor,
      ),
      child: Text(
        context.t.viewProfile.capitalizeFirst(),
        maxLines: isDesktop ? null : 1,
        overflow: isDesktop ? null : TextOverflow.ellipsis,
        style: _getButtonTextStyle(context,
            isDesktop: isDesktop, isPrimary: !isDesktop),
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context,
      {required bool isDesktop}) {
    return TextButton(
      onPressed: () => _navigateToProfileSettings(context),
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
      ),
      child: Text(
        context.t.editProfile.capitalizeFirst(),
        maxLines: isDesktop ? null : 1,
        overflow: isDesktop ? null : TextOverflow.ellipsis,
        style: _getButtonTextStyle(context,
            isDesktop: isDesktop, isPrimary: false),
      ),
    );
  }

  TextStyle _getButtonTextStyle(BuildContext context,
      {required bool isDesktop, required bool isPrimary}) {
    final baseStyle = isDesktop
        ? Theme.of(context).textTheme.bodyMedium!
        : Theme.of(context).textTheme.labelMedium!;

    final color = isPrimary ? kWhite : Theme.of(context).primaryColorDark;

    return baseStyle.copyWith(color: color);
  }

  void _navigateToProfile(BuildContext context) {
    YNavigator.pushPage(
      context,
      (context) => ProfileView(
        pubkey: nostrRepository.currentMetadata.pubkey,
      ),
    );
  }

  void _navigateToProfileSettings(BuildContext context) {
    YNavigator.push(
      context,
      SlideupPageRoute(
        builder: (context) => ProfileSettingsView(),
        settings: const RouteSettings(),
      ),
    );
  }
}

// Keep existing PropertyRow and PropertiesTextControllers classes unchanged
class PropertyRow extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.icon,
    required this.title,
    required this.isToggled,
    this.description,
    this.isRaw,
  });

  final String icon;
  final String title;
  final String? description;
  final bool isToggled;
  final bool? isRaw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 25,
          height: 25,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: kDefaultPadding / 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (description != null)
                Text(
                  description!,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(width: kDefaultPadding / 2),
        Icon(
          isRaw != null
              ? Icons.keyboard_arrow_right_outlined
              : isToggled
                  ? Icons.keyboard_arrow_up_outlined
                  : Icons.keyboard_arrow_down_outlined,
          color: Theme.of(context).primaryColorDark,
        ),
      ],
    );
  }
}

class PropertiesTextControllers extends StatelessWidget {
  const PropertiesTextControllers({
    super.key,
    required this.textController,
    required this.onClose,
    required this.onSubmit,
    this.maxLines,
  });

  final TextEditingController textController;
  final Function() onClose;
  final Function() onSubmit;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: textController,
          minLines: maxLines,
          maxLines: maxLines,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              context,
              icon: FeatureIcons.send,
              onPressed: onSubmit,
            ),
            _buildActionButton(
              context,
              icon: FeatureIcons.close,
              onPressed: onClose,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        icon,
        width: 30,
        height: 30,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
