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
import '../widgets/custom_app_bar.dart';
import '../widgets/dotted_container.dart';
import '../widgets/modal_sheet_container.dart';
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
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.editProfile.capitalizeFirst(),
        ),
        bottomNavigationBar: BottomAppBar(
          height: kBottomNavigationBarHeight,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: _updateButton(description, displayName, name, website, nip05,
              lud16, picture, cover),
        ),
        body: CustomScrollView(
          slivers: [
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
    showModalBottomSheet(
      context: context,
      builder: (_) => const _RelayListRequiredSheet(),
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
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
        final dStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).highlightColor,
              fontStyle: FontStyle.italic,
            );

        const spacer = SizedBox(
          height: kDefaultPadding / 1.5,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t.userName.capitalizeFirst(), style: dStyle),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: name,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.yourName.capitalizeFirst(),
                prefixIcon: const Icon(LucideIcons.atSign),
              ),
            ),
            spacer,
            Text(context.t.displayName.capitalizeFirst(), style: dStyle),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: displayName,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.yourDisplayName.capitalizeFirst(),
              ),
            ),
            spacer,
            Text(context.t.aboutYou.capitalizeFirst(), style: dStyle),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: description,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.t.writeSomethingAboutYou.capitalizeFirst(),
              ),
            ),
            spacer,
            Text(context.t.website.capitalizeFirst(), style: dStyle),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: website,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.yourWebsite.capitalizeFirst(),
              ),
            ),
            spacer,
            Text(context.t.verifyNip05.capitalizeFirst(), style: dStyle),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: nip05,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.enterNip05.capitalizeFirst(),
              ),
            ),
            spacer,
            Text(
              context.t.lightningAddress.capitalizeFirst(),
              style: dStyle,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: lud16,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.enterLn.capitalizeFirst(),
              ),
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
                    Text('Picture url', style: dStyle),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    TextFormField(
                      controller: picture,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: context.t.enterPictureUrl.capitalizeFirst(),
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      context.t.coverUrl.capitalizeFirst(),
                      style: dStyle,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    TextFormField(
                      controller: cover,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: context.t.enterCoverUrl.capitalizeFirst(),
                      ),
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
