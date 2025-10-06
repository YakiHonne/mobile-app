import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/properties_cubit/properties_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import '../../leading_view/widgets/leading_customization.dart';
import '../../widgets/custom_app_bar.dart';
import 'settings_text.dart';

class PropertyCustomization extends HookWidget {
  PropertyCustomization({
    super.key,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Customization view');
  }

  @override
  Widget build(BuildContext context) {
    final reactionButtonKey = useMemoized(() => GlobalKey(), []);

    final profilePreview = useState(
      nostrRepository.currentAppCustomization?.enableProfilePreview ?? true,
    );

    final collapsedNote = useState(
      nostrRepository.currentAppCustomization?.collapsedNote ?? true,
    );

    final openPromptedUrl = useState(
      nostrRepository.currentAppCustomization?.openPromptedUrl ?? true,
    );

    final selectedContentType = useState(
      nostrRepository.currentAppCustomization?.writingContentType ??
          AppContentType.note.name,
    );

    final onUpdateProfilePreview = useCallback(
      () {
        if (nostrRepository.currentAppCustomization?.enableProfilePreview !=
            profilePreview.value) {
          nostrRepository.currentAppCustomization?.enableProfilePreview =
              profilePreview.value;

          nostrRepository.broadcastCurrentAppCustomization();
          nostrRepository.saveAppCustomization();
        }
      },
    );

    final onUpdateCollapsedNote = useCallback(
      () {
        if (nostrRepository.currentAppCustomization?.collapsedNote !=
                collapsedNote.value ||
            nostrRepository.currentAppCustomization?.openPromptedUrl !=
                openPromptedUrl.value) {
          nostrRepository.currentAppCustomization?.collapsedNote =
              collapsedNote.value;
          nostrRepository.currentAppCustomization?.openPromptedUrl =
              openPromptedUrl.value;

          nostrRepository.broadcastCurrentAppCustomization();
          nostrRepository.saveAppCustomization();
        }
      },
    );

    useEffect(
      () {
        onUpdateProfilePreview();
        return null;
      },
      [profilePreview.value],
    );

    useEffect(
      () {
        onUpdateCollapsedNote();
        return null;
      },
      [collapsedNote.value],
    );

    useEffect(
      () {
        onUpdateCollapsedNote();
        return null;
      },
      [openPromptedUrl.value],
    );

    final onUpdateSelectedContentType = useCallback(
      (String type) {
        selectedContentType.value = type;
        nostrRepository.currentAppCustomization?.writingContentType = type;
        nostrRepository.broadcastCurrentAppCustomization();
        nostrRepository.saveAppCustomization();
      },
    );

    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: context.t.customization.capitalizeFirst(),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  context.t.settingsCustomizationDesc,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
                const Divider(
                  height: kDefaultPadding * 1.5,
                  thickness: 0.5,
                ),
                _feedCustomization(context),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                _newPostGesture(
                    context, onUpdateSelectedContentType, selectedContentType),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                _profilePreview(context, profilePreview),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                _openUrlPrompt(context, openPromptedUrl),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                _defaultReaction(context, reactionButtonKey, state),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                _oneTapReaction(context, state),
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

  Row _oneTapReaction(BuildContext context, PropertiesState state) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.oneTapReaction.capitalizeFirst(),
            description: context.t.oneTapReactionDesc,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.enableOneTapReaction,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<PropertiesCubit>().setOneTapReaction(isToggled);
            },
          ),
        ),
      ],
    );
  }

  Row _defaultReaction(
      BuildContext context,
      GlobalKey<State<StatefulWidget>> reactionButtonKey,
      PropertiesState state) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.defaultReaction.capitalizeFirst(),
            description: context.t.defaultReactionDesc,
          ),
        ),
        GestureDetector(
          onTap: () {
            doIfCanSign(
              func: () {
                showReactionPopup(
                  context,
                  reactionButtonKey,
                  (emoji) {
                    context.read<PropertiesCubit>().setDefaultReaction(emoji);
                  },
                  displayOnLeft: true,
                );
              },
              context: context,
            );
          },
          child: Container(
            width: 45,
            height: 45,
            key: reactionButtonKey,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: state.defaultReaction == '+'
                ? SvgPicture.asset(
                    FeatureIcons.heartFilled,
                    width: 25,
                    height: 25,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.only(
                      top: 12,
                    ),
                    width: 22,
                    height: 22,
                    child: FittedBox(
                      child: Text(
                        state.defaultReaction.trim(),
                        style: const TextStyle(
                          fontSize: 100,
                          height: 1.0,
                        ),
                        strutStyle: const StrutStyle(
                          forceStrutHeight: true,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Row _openUrlPrompt(
      BuildContext context, ValueNotifier<bool> openPromptedUrl) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.openUrlPrompt.capitalizeFirst(),
            description: context.t.openUrlPromptDesc,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: openPromptedUrl.value,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              openPromptedUrl.value = isToggled;
            },
          ),
        ),
      ],
    );
  }

  Row _profilePreview(
      BuildContext context, ValueNotifier<bool> profilePreview) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.profilePreview.capitalizeFirst(),
            description: context.t.profilePreviewDesc,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: profilePreview.value,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              profilePreview.value = isToggled;
            },
          ),
        ),
      ],
    );
  }

  Row _newPostGesture(
      BuildContext context,
      Function(String) onUpdateSelectedContentType,
      ValueNotifier<String> selectedContentType) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.newPostGesture.capitalizeFirst(),
            description: context.t.NewPostDesc,
          ),
        ),
        PullDownButton(
          animationBuilder: (context, state, child) {
            return child;
          },
          routeTheme: PullDownMenuRouteTheme(
            backgroundColor: Theme.of(context).cardColor,
          ),
          itemBuilder: (context) {
            return List.generate(
              5,
              (index) {
                AppContentType contentType = AppContentType.note;

                if (index == 0) {
                  contentType = AppContentType.note;
                } else if (index == 1) {
                  contentType = AppContentType.article;
                } else if (index == 2) {
                  contentType = AppContentType.curation;
                } else if (index == 3) {
                  contentType = AppContentType.video;
                } else if (index == 4) {
                  contentType = AppContentType.smartWidget;
                }

                return PullDownMenuItem.selectable(
                  onTap: () {
                    onUpdateSelectedContentType(contentType.name);
                  },
                  selected: contentType.name == selectedContentType.value,
                  title: getSelectedContentName(contentType, context)
                      .capitalizeFirst(),
                  itemTheme: PullDownMenuItemTheme(
                    textStyle: Theme.of(context).textTheme.labelMedium,
                  ),
                );
              },
            );
          },
          buttonBuilder: (context, showMenu) => GestureDetector(
            onTap: showMenu,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    getSelectedContentName(
                      AppContentType.values.firstWhere(
                        (e) => e.name == selectedContentType.value,
                        orElse: () => AppContentType.note,
                      ),
                      context,
                    ).capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  const Icon(
                    CupertinoIcons.chevron_up_chevron_down,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Row _feedCustomization(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.feedCustomization.capitalizeFirst(),
            description: context.t.homeFeedCustomDesc,
          ),
        ),
        TextButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return const LeadingCustomization();
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

  String getSelectedContentName(AppContentType ct, BuildContext context) {
    switch (ct) {
      case AppContentType.note:
        return context.t.note;
      case AppContentType.article:
        return context.t.article;
      case AppContentType.video:
        return context.t.video;
      case AppContentType.smartWidget:
        return context.t.smartWidget;
      case AppContentType.curation:
        return context.t.curation;
    }
  }
}

class ReplyOptionContainer extends StatelessWidget {
  const ReplyOptionContainer({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String icon;
  final bool isSelected;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          border: Border.all(
            color: isSelected ? kMainColor : Theme.of(context).dividerColor,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(kDefaultPadding / 2),
                    topRight: Radius.circular(kDefaultPadding / 2),
                  ),
                  image: DecorationImage(
                    image: AssetImage(icon),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
