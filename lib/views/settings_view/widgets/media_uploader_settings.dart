import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/media_servers_cubit/media_servers_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_buttons.dart';

class MediaUploaderSettings extends HookWidget {
  const MediaUploaderSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final isRegularToggled = useState(false);
    final isBlossomToggled = useState(false);
    final blossomTextFieldEnabled = useState(false);
    final blossomTextField = useTextEditingController();
    final blossomUrl = useState('');

    return BlocBuilder<MediaServersCubit, MediaServersState>(
      builder: (context, state) {
        final services = <String>[
          context.t.regularServers,
          context.t.blossomServers,
        ];

        return Scaffold(
          appBar: CustomAppBar(
            title: context.t.mediaUploader.capitalizeFirst(),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: CustomScrollView(
              slivers: [
                _pulldownButton(context, services, state),
                const SliverToBoxAdapter(
                  child: Divider(),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      Text(
                        context.t.settings.capitalizeFirst(),
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: Theme.of(context).highlightColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      _mediaSettingsContainer(context, isRegularToggled, state),
                      const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      _mediaSettingsContainer2(
                        context,
                        isBlossomToggled,
                        state,
                        blossomTextFieldEnabled,
                        blossomTextField,
                        blossomUrl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  MediaSettingsContainer _mediaSettingsContainer2(
      BuildContext context,
      ValueNotifier<bool> isBlossomToggled,
      MediaServersState state,
      ValueNotifier<bool> blossomTextFieldEnabled,
      TextEditingController blossomTextField,
      ValueNotifier<String> blossomUrl) {
    return MediaSettingsContainer(
      title: context.t.blossomServers.capitalizeFirst(),
      isToggled: isBlossomToggled.value,
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kDefaultPadding / 2,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t.mirrorAllServer.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: state.enableMirroring,
                  activeTrackColor: kMainColor,
                  onChanged: (isToggled) {
                    mediaServersCubit.setMirrorStatus(
                      isToggled,
                    );
                  },
                ),
              ),
            ],
          ),
          if (state.blossomServers.isNotEmpty) ...[
            Text(
              context.t.mainServer.capitalizeFirst(),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.activeBlossomServer,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: kGreen,
                        ),
                  ),
                ),
                const DotContainer(
                  color: kGreen,
                  size: 7,
                ),
              ],
            )
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t.myList,
                ),
              ),
              CustomIconButton(
                onClicked: () {
                  blossomTextFieldEnabled.value =
                      !blossomTextFieldEnabled.value;
                },
                icon: blossomTextFieldEnabled.value
                    ? FeatureIcons.closeRaw
                    : FeatureIcons.addRaw,
                size: 15,
                backgroundColor: Theme.of(context).cardColor,
                vd: -2,
              ),
            ],
          ),
          if (blossomTextFieldEnabled.value) ...[
            TextFormField(
              controller: blossomTextField,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.serverPath,
                suffixIcon: blossomUrl.value.isNotEmpty
                    ? CustomIconButton(
                        onClicked: () async {
                          final status =
                              await mediaServersCubit.addBlossomServer(
                            blossomUrl.value,
                          );

                          if (status) {
                            blossomTextField.clear();
                            blossomUrl.value = '';
                            blossomTextFieldEnabled.value = false;
                          }
                        },
                        icon: FeatureIcons.addRaw,
                        size: 15,
                        backgroundColor: kTransparent,
                      )
                    : null,
              ),
              onChanged: (value) {
                blossomUrl.value = value;
              },
            ),
          ],
          if (state.blossomServers.isNotEmpty) ...[
            MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              removeTop: true,
              child: ListView.separated(
                shrinkWrap: true,
                primary: false,
                separatorBuilder: (context, index) => const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                itemBuilder: (context, index) {
                  final server = state.blossomServers[index];

                  return Row(
                    spacing: kDefaultPadding / 4,
                    children: [
                      Expanded(
                        child: Text(
                          server,
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: state.activeBlossomServer == server
                                        ? kGreen
                                        : Theme.of(context).primaryColorDark,
                                  ),
                        ),
                      ),
                      if (state.activeBlossomServer != server)
                        OutlinedButton(
                          onPressed: () {
                            mediaServersCubit.selectBlossomServer(index);
                          },
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            context.t.select,
                          ),
                        ),
                      CustomIconButton(
                        onClicked: () {
                          mediaServersCubit.deleteBlossomServer(index);
                        },
                        icon: FeatureIcons.trash,
                        size: 18,
                        backgroundColor: Theme.of(context).cardColor,
                        vd: -2,
                      ),
                    ],
                  );
                },
                itemCount: state.blossomServers.length,
              ),
            )
          ] else if (!blossomTextFieldEnabled.value) ...[
            Text(
              context.t.noServerFound,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ],
      ),
      onToggle: () {
        isBlossomToggled.value = !isBlossomToggled.value;
      },
    );
  }

  MediaSettingsContainer _mediaSettingsContainer(BuildContext context,
      ValueNotifier<bool> isRegularToggled, MediaServersState state) {
    return MediaSettingsContainer(
      title: context.t.regularServers.capitalizeFirst(),
      onToggle: () {
        isRegularToggled.value = !isRegularToggled.value;
      },
      isToggled: isRegularToggled.value,
      widget: Row(
        children: [
          Expanded(
            child: Text(
              context.t.mediaUploader.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
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
                state.regularServers.length,
                (index) {
                  final uploadServer = state.regularServers[index];

                  return PullDownMenuItem.selectable(
                    onTap: () {
                      mediaServersCubit.setActiveRegularServer(
                        uploadServer,
                      );
                    },
                    selected: uploadServer == state.activeRegularServer,
                    title: uploadServer,
                    itemTheme: PullDownMenuItemTheme(
                      textStyle: Theme.of(context).textTheme.labelLarge,
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
                      state.activeRegularServer,
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
      ),
    );
  }

  SliverToBoxAdapter _pulldownButton(
      BuildContext context, List<String> services, MediaServersState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.t.activeService.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
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
                  services.length,
                  (index) {
                    final service = services[index];

                    return PullDownMenuItem.selectable(
                      onTap: () {
                        mediaServersCubit.setBlossomStatus(index == 1);
                      },
                      selected: index == 0 && !state.isBlossomActive ||
                          index == 1 && state.isBlossomActive,
                      title: service,
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: Theme.of(context).textTheme.labelLarge,
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
                        state.isBlossomActive ? services[1] : services[0],
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
        ),
      ),
    );
  }
}

class MediaSettingsContainer extends StatelessWidget {
  const MediaSettingsContainer({
    super.key,
    required this.title,
    required this.isToggled,
    required this.widget,
    required this.onToggle,
  });

  final String title;
  final bool isToggled;
  final Widget widget;
  final Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.translucent,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                SvgPicture.asset(
                  isToggled ? FeatureIcons.arrowUp : FeatureIcons.arrowDown,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                const Divider(
                  thickness: 0.5,
                  height: kDefaultPadding,
                ),
                widget,
              ],
            ),
            secondChild: const SizedBox(
              width: double.infinity,
            ),
            crossFadeState: isToggled
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
