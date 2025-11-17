import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';

import '../../../logic/crashlytics_cubit/crashlytics_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../notifications_view/widgets/notifications_customization.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/response_snackbar.dart';
import 'mute_list_view.dart';
import 'property_appearance.dart';
import 'settings_text.dart';

class PropertyAnalyticsCache extends StatelessWidget {
  PropertyAnalyticsCache({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Analytics cache view');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.analyticsCache.capitalizeFirst(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        children: [
          Text(
            context.t.settingsCacheDesc,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const Divider(
            height: kDefaultPadding * 1.5,
            thickness: 0.5,
          ),
          BlocBuilder<CrashlyticsCubit, CrashlyticsState>(
            builder: (context, state) {
              return SwitchRow(
                title: context.t.automaticPurge,
                desc: context.t.automaticPurgeDesc,
                onSwitched:
                    context.read<CrashlyticsCubit>().setAutomaticCachePurge,
                val: state.automaticCachePurge,
              );
            },
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          TitleDescriptionComponent(
            title: context.t.appCache.capitalizeFirst(),
            description: context.t.closeAppClearingCache,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          const AppCacheBox(
            isSettingsView: true,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          _crashlytics(),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _muteList(),
        ],
      ),
    );
  }

  StreamBuilder<EventSigner?> _muteList() {
    return StreamBuilder(
      stream: nostrRepository.currentSignerStream,
      builder: (context, snapshot) {
        if (currentSigner == null || !canSign()) {
          return Row(
            children: [
              Text(
                context.t.muteList.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    MuteListView.routeName,
                  );
                },
                style: TextButton.styleFrom(
                  visualDensity: const VisualDensity(vertical: -3),
                ),
                child: Text(
                  context.t.edit.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).primaryColorDark,
                      ),
                ),
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  BlocBuilder<CrashlyticsCubit, CrashlyticsState> _crashlytics() {
    return BlocBuilder<CrashlyticsCubit, CrashlyticsState>(
      builder: (context, state) {
        return SettingsOptionRow(
          onClicked: () async {
            if (state.isCrashlyticsEnabled) {
              context.read<CrashlyticsCubit>().setCrashlyticsStatus(false);
              BotToastUtils.showSuccess(
                context.t.analyticsCacheOff.capitalizeFirst(),
              );
            } else {
              context.read<CrashlyticsCubit>().setCrashlyticsStatus(true);
              BotToastUtils.showSuccess(
                context.t.analyticsCacheOn.capitalizeFirst(),
              );
            }
          },
          description: context.t.crashlyticsDesc,
          title: context.t.analyticsCrashlytics.capitalizeFirst(),
          isToggled: state.isCrashlyticsEnabled,
          firstIcon: CupertinoIcons.play_circle,
          secondIcon: CupertinoIcons.pause_circle,
        );
      },
    );
  }
}

class AppCacheBox extends HookWidget {
  const AppCacheBox({
    super.key,
    required this.isSettingsView,
    this.hideBox,
  });

  final bool isSettingsView;
  final Function()? hideBox;

  @override
  Widget build(BuildContext context) {
    useMemoized(
      () async {
        await context.read<CrashlyticsCubit>().getSizes();
      },
    );

    return BlocBuilder<CrashlyticsCubit, CrashlyticsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _appCacheBoxRow(
                context,
                context.t.cachedData,
                state.dataCacheSize,
                state.isDataCacheToggled,
                state.dataCacheSize > cacheMaxSize,
                (val) {
                  context.read<CrashlyticsCubit>().toggleSelection(
                        isDataCacheToggled: val,
                      );
                },
              ),
              _appCacheBoxRow(
                context,
                context.t.cachedMedia,
                state.mediaCacheSize,
                state.isMediaCacheToggled,
                state.mediaCacheSize > cacheMaxSize,
                (val) {
                  context.read<CrashlyticsCubit>().toggleSelection(
                        isMediaCacheToggled: val,
                      );
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              _textButton(state),
            ],
          ),
        );
      },
    );
  }

  Builder _textButton(CrashlyticsState state) {
    return Builder(
      builder: (context) {
        final isDisabled =
            !state.isDataCacheToggled && !state.isMediaCacheToggled;

        return Opacity(
          opacity: isDisabled ? 0.5 : 1,
          child: AbsorbPointer(
            absorbing: !state.isDataCacheToggled && !state.isMediaCacheToggled,
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  showCupertinoCustomDialogue(
                    context: context,
                    title: context.t.clearAppCache.capitalizeFirst(),
                    description: context.t.clearAppCacheDesc.capitalizeFirst(),
                    buttonText: context.t.clear.capitalizeFirst(),
                    buttonTextColor: kRed,
                    onClicked: () async {
                      context.read<CrashlyticsCubit>().purgeCache(
                            dataCheckBox: state.isDataCacheToggled,
                            mediaCheckBox: state.isMediaCacheToggled,
                            onSuccess: () {
                              BotToastUtils.showSuccess(
                                context.t.cacheCleared,
                              );

                              YNavigator.pop(context);
                            },
                          );
                    },
                  );
                },
                child: Text(
                  context.t.clearAppCache,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _appCacheBoxRow(
    BuildContext context,
    String title,
    double size,
    bool checkedVal,
    bool exceededSize,
    Function(bool) onToggle,
  ) {
    return GestureDetector(
      onTap: () => onToggle(!checkedVal),
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ),
          Text(
            '${size.toStringAsFixed(2)} MB',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      exceededSize ? kRed : Theme.of(context).primaryColorDark,
                ),
          ),
          MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            removeLeft: true,
            removeRight: true,
            removeTop: true,
            child: Checkbox(
              value: checkedVal,
              visualDensity: VisualDensity.compact,
              activeColor: Theme.of(context).primaryColor,
              checkColor: kWhite,
              onChanged: (value) => onToggle(value ?? false),
            ),
          )
        ],
      ),
    );
  }
}
