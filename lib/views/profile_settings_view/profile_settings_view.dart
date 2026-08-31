// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../logic/profile_settings_cubit/profile_settings_cubit.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../settings_view/widgets/relays_update.dart';
import '../widgets/app_icon.dart';
import '../widgets/dotted_container.dart';
import '../widgets/fluid_scaffold.dart';
import '../widgets/fluid_sheet.dart';
import '../widgets/identity_field.dart';
import '../widgets/modal_sheet_container.dart';
import 'widgets/profile_settings_identity.dart';
import 'widgets/profile_settings_media.dart';

class ProfileSettingsView extends HookWidget {
  ProfileSettingsView({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Profile settings view');
  }

  @override
  Widget build(BuildContext context) {
    final name = useTextEditingController(text: '');
    final displayName = useTextEditingController(text: '');
    final website = useTextEditingController(text: '');
    final description = useTextEditingController(text: '');
    final nip05 = useTextEditingController(text: '');
    final lud16 = useTextEditingController(text: '');
    final picture = useTextEditingController(text: '');
    final cover = useTextEditingController(text: '');

    return BlocProvider(
      create: (context) => ProfileSettingsCubit(),
      child: FluidScaffold(
        title: context.t.editProfile.capitalizeFirst(),
        bottomBarHeight: kBottomNavigationBarHeight,
        bottomBar: FluidBottomBar(
          height: kBottomNavigationBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: _updateButton(description, displayName, name, website, nip05,
              lud16, picture, cover),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: fluidScaffoldTopInset(context)),
            ),
            const SliverToBoxAdapter(
              child: ProfileSettingsMedia(),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              sliver: SliverToBoxAdapter(
                child: ProfileSettingsMetadata(
                  description: description,
                  name: name,
                  displayName: displayName,
                  website: website,
                  nip05: nip05,
                  lud16: lud16,
                  cover: cover,
                  picture: picture,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kBottomNavigationBarHeight + kDefaultPadding,
              ),
            )
          ],
        ),
      ),
    );
  }

  Center _updateButton(
      TextEditingController description,
      TextEditingController displayName,
      TextEditingController name,
      TextEditingController website,
      TextEditingController nip05,
      TextEditingController lud16,
      TextEditingController picture,
      TextEditingController cover) {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
          builder: (context, state) {
            return AbsorbPointer(
              absorbing: state.isUploading,
              child: TextButton(
                onPressed: () async {
                  final hasNoIdentity =
                      name.text.trim().isEmpty && picture.text.trim().isEmpty;

                  if (hasNoIdentity) {
                    final relayListEvent = await nc.db
                        .loadUserRelayList(currentUserRelayList.pubkey);

                    if (!context.mounted) {
                      return;
                    }

                    if (relayListEvent == null) {
                      _showRelayListRequiredSheet(context);
                      return;
                    }
                  }

                  context.read<ProfileSettingsCubit>().updateMetadata(
                    data: {
                      'about': description.text.trim(),
                      'displayName': displayName.text.trim(),
                      'name': name.text.trim(),
                      'website': website.text.trim(),
                      'nip05': nip05.text.trim(),
                      'lud16': lud16.text.trim(),
                      'picture': picture.text.trim(),
                      'banner': cover.text.trim(),
                    },
                    onFailure: (message) {
                      BotToastUtils.showError(message);
                    },
                    onSuccess: (message) {
                      BotToastUtils.showSuccess(message);
                    },
                  );
                },
                child: Text(
                  state.isUploading ? 'Uploading image...' : 'Update Profile',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showRelayListRequiredSheet(BuildContext context) {
    showAppModalSheet(
      context: context,
      builder: (_) => const _RelayListRequiredSheet(),
      backgroundColor: kTransparent,
    );
  }
}

class _RelayListRequiredSheet extends StatelessWidget {
  const _RelayListRequiredSheet();

  @override
  Widget build(BuildContext context) {
    return ModalSheetContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 1.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalBottomSheetHandle(),
          AppIcon(
            FeatureIcons.relays,
            size: 40,
            color: Theme.of(context).primaryColorDark,
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.relayListRequiredTitle.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 4),
          Text(
            context.t.relayListRequiredDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                YNavigator.pushPage(
                  context,
                  (context) => RelayUpdateView(),
                );
              },
              child: Text(context.t.goToRelaySettings.capitalizeFirst()),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
        ],
      ),
    );
  }
}

/// A compact pill that sits inside a field, right of the input. Small enough
/// not to compete with the value it sits beside.
class _InlineFieldAction extends StatelessWidget {
  const _InlineFieldAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      // Not scaffoldBackgroundColor: in the light and cream themes it sits
      // within a few points of cardColor, leaving the pill with no edge.
      color: theme.dividerColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(kDefaultPadding),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(kDefaultPadding),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 1.5,
            vertical: kDefaultPadding / 2.5,
          ),
          child: Text(
            label,
            // A long label in ru/hi/ar would otherwise overflow the row.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSettingsMetadata extends HookWidget {
  const ProfileSettingsMetadata({
    super.key,
    required this.description,
    required this.name,
    required this.displayName,
    required this.website,
    required this.nip05,
    required this.lud16,
    required this.picture,
    required this.cover,
  });

  final TextEditingController description;
  final TextEditingController name;
  final TextEditingController displayName;
  final TextEditingController website;
  final TextEditingController nip05;
  final TextEditingController lud16;

  final TextEditingController picture;
  final TextEditingController cover;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);
    useMemoized(
      () {
        final state = context.read<ProfileSettingsCubit>().state;

        description.text = state.description;
        name.text = state.name;
        displayName.text = state.displayName;
        website.text = state.website;
        lud16.text = state.lud16;
        picture.text = state.imageLink;
        cover.text = state.bannerLink;
        nip05.text = state.nip05;
      },
    );

    return BlocConsumer<ProfileSettingsCubit, ProfileSettingsState>(
      // Only a metadata resync should overwrite the controllers. The identity
      // rows emit on every keystroke, and an unguarded listener would snap
      // every other field back to its stored value mid-edit.
      listenWhen: (p, c) => p.refresh != c.refresh,
      listener: (context, state) {
        description.text = state.description;
        name.text = state.name;
        displayName.text = state.displayName;
        website.text = state.website;
        lud16.text = state.lud16;
        picture.text = state.imageLink;
        cover.text = state.bannerLink;
        nip05.text = state.nip05;
      },
      builder: (context, state) {
        const spacer = SizedBox(
          height: kDefaultPadding / 1.5,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always visible. For a non-subscriber (trial included) the row
            // itself routes to pricing on tap instead of offering an edit.
            const YakiUsernameField(),
            spacer,
            // The two short names pair on one row; everything below is a
            // full-width row of the same card field.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IdentityField(
                    label: context.t.displayName.capitalizeFirst(),
                    controller: displayName,
                    hint: context.t.yourDisplayName.capitalizeFirst(),
                    capitalize: true,
                  ),
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Expanded(
                  child: IdentityField(
                    label: context.t.userName.capitalizeFirst(),
                    controller: name,
                    hint: context.t.yourName.capitalizeFirst(),
                    prefixIcon: LucideIcons.atSign,
                    capitalize: true,
                  ),
                ),
              ],
            ),
            spacer,
            IdentityField(
              label: context.t.aboutYou.capitalizeFirst(),
              controller: description,
              hint: context.t.writeSomethingAboutYou.capitalizeFirst(),
              maxLines: 4,
              capitalize: true,
            ),
            spacer,
            IdentityField(
              label: context.t.website.capitalizeFirst(),
              controller: website,
              hint: context.t.yourWebsite.capitalizeFirst(),
            ),
            spacer,
            IdentityField(
              label: context.t.verifyNip05.capitalizeFirst(),
              controller: nip05,
              hint: context.t.enterNip05.capitalizeFirst(),
              // Always offered: the sheet itself sends an unsubscribed user to
              // pricing rather than hiding the entry point.
              trailing: _InlineFieldAction(
                label: context.t.yakiNip05,
                onPressed: () => showYakiNip05Sheet(
                  context: context,
                  nip05: nip05,
                ),
              ),
            ),
            spacer,
            IdentityField(
              label: context.t.lightningAddress.capitalizeFirst(),
              controller: lud16,
              hint: context.t.enterLn.capitalizeFirst(),
              // Independent of the subscription: this only offers addresses
              // from wallets the user has already connected.
              trailing: context.read<ProfileSettingsCubit>().hasWalletAddresses
                  ? _InlineFieldAction(
                      label: context.t.useConnectedWallet,
                      onPressed: () => showWalletAddressSheet(
                        context: context,
                        lud16: lud16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    child: TextButton.icon(
                      onPressed: () {
                        isExpanded.value = !isExpanded.value;
                      },
                      style: TextButton.styleFrom(
                        backgroundBuilder: (_, __, child) => child!,
                        backgroundColor: kTransparent,
                      ),
                      icon: Text(
                        isExpanded.value
                            ? context.t.less.capitalizeFirst()
                            : context.t.more.capitalizeFirst(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      label: AppIcon(
                        isExpanded.value
                            ? FeatureIcons.arrowUp
                            : FeatureIcons.arrowDown,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  if (isExpanded.value) ...[
                    IdentityField(
                      label: 'Picture url',
                      controller: picture,
                      hint: context.t.enterPictureUrl.capitalizeFirst(),
                    ),
                    spacer,
                    IdentityField(
                      label: context.t.coverUrl.capitalizeFirst(),
                      controller: cover,
                      hint: context.t.enterCoverUrl.capitalizeFirst(),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        );
      },
    );
  }
}
