import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/theme_cubit/theme_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import 'settings_text.dart';

class PropertyAppearance extends HookWidget {
  PropertyAppearance({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Appearance view');
  }

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = useState(themeCubit.state.textScaleFactor);

    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.appearance,
      ),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        children: [
          Text(
            context.t.settingsAppearanceDesc,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const Divider(
            height: kDefaultPadding * 1.5,
            thickness: 0.5,
          ),
          const AppThemeModeBox(),
          const SizedBox(
            height: kDefaultPadding,
          ),
          const AppPrimaryColorBox(),
          const SizedBox(
            height: kDefaultPadding,
          ),
          _options(context, textScaleFactor),
        ],
      ),
    );
  }

  Column _options(BuildContext context, ValueNotifier<double> textScaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fontSize(context),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        _fontSizeSlider(textScaleFactor),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        const AbsorbPointer(
          child: ParsedText(
            text:
                'note1m80wgfxkh3awamrz8vu0qm45jsq0tyv7zw4uuaclldqgnrjlvmjsccq5v6',
          ),
        ),
      ],
    );
  }

  SliderTheme _fontSizeSlider(ValueNotifier<double> textScaleFactor) {
    return SliderTheme(
      data: SliderThemeData(
        overlayShape: SliderComponentShape.noOverlay,
        inactiveTickMarkColor: kTransparent,
        activeTickMarkColor: kTransparent,
      ),
      child: Slider(
        value: textScaleFactor.value,
        min: 0.8,
        max: 1.25,
        divisions: 8,
        thumbColor: Theme.of(nostrRepository.currentContext()).primaryColor,
        activeColor: Theme.of(nostrRepository.currentContext()).primaryColor,
        onChanged: (double value) {
          textScaleFactor.value = value;
          themeCubit.setTextScaleFactor(value);
        },
      ),
    );
  }

  Row _fontSize(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.fontSize.capitalizeFirst(),
            description: context.t.fontSizeDesc,
          ),
        ),
        const Icon(
          Icons.font_download_outlined,
          size: kDefaultPadding,
        ),
      ],
    );
  }
}

class AppThemeModeBox extends StatelessWidget {
  const AppThemeModeBox({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = AppThemeMode.values.toList();

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Column(
          children: [
            TitleDescriptionComponent(
              title: context.t.appTheme.capitalizeFirst(),
              description: context.t.appThemeDesc,
            ),
            const SizedBox(
              height: kDefaultPadding / 1.5,
            ),
            MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: kDefaultPadding / 8,
                  mainAxisSpacing: kDefaultPadding / 8,
                  mainAxisExtent: 55,
                ),
                shrinkWrap: true,
                primary: false,
                itemBuilder: (context, index) {
                  final mode = modes[index];
                  final isSelected = state.mode == mode;
                  final isDark = themeCubit.checkThemeDarkness(mode);

                  return _modeItem(
                      mode, state.primaryColor, isSelected, context, isDark);
                },
                itemCount: modes.length,
              ),
            )
          ],
        );
      },
    );
  }

  GestureDetector _modeItem(
    AppThemeMode mode,
    Color primaryColor,
    bool isSelected,
    BuildContext context,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        themeCubit.setTheme(mode: mode, primaryColor: primaryColor);
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              color: getModeColor(mode),
              border: isSelected
                  ? Border.all(color: Theme.of(context).primaryColor)
                  : Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
            ),
            alignment: Alignment.center,
            child: Row(
              spacing: kDefaultPadding / 2,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  LogosIcons.logoMarkWhite,
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    isDark ? kWhite : kBlack,
                    BlendMode.srcIn,
                  ),
                ),
                Text(
                  mode.name.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: isDark ? kWhite : kBlack,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 5,
              left: 5,
              child: FadeIn(
                duration: const Duration(milliseconds: 200),
                child: SvgPicture.asset(
                  FeatureIcons.verified,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color getModeColor(AppThemeMode mode) {
    late Color color;

    switch (mode) {
      case AppThemeMode.graphite:
        color = kScaffoldDark;
      case AppThemeMode.noir:
        color = kBlack;
      case AppThemeMode.neige:
        color = kWhite;
      case AppThemeMode.ivory:
        color = kCreamCard;
    }

    return color;
  }
}

class AppPrimaryColorBox extends StatelessWidget {
  const AppPrimaryColorBox({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Column(
          children: [
            TitleDescriptionComponent(
              title: context.t.primaryColor.capitalizeFirst(),
              description: context.t.primaryColorDesc,
            ),
            const SizedBox(
              height: kDefaultPadding / 1.5,
            ),
            MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: kDefaultPadding / 8,
                  mainAxisSpacing: kDefaultPadding / 8,
                  mainAxisExtent: 55,
                ),
                shrinkWrap: true,
                primary: false,
                itemBuilder: (context, index) {
                  final color = mainColorsList[index];
                  final isSelected = state.primaryColor == color;

                  return _colorItem(state.mode, color, isSelected, context);
                },
                itemCount: mainColorsList.length,
              ),
            )
          ],
        );
      },
    );
  }

  GestureDetector _colorItem(
    AppThemeMode mode,
    Color primaryColor,
    bool isSelected,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        themeCubit.setTheme(mode: mode, primaryColor: primaryColor);
      },
      behavior: HitTestBehavior.translucent,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: constraints.maxWidth,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 2,
                ),
                color: Theme.of(context).cardColor,
                border: isSelected
                    ? Border.all(color: Theme.of(context).primaryColor)
                    : Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
              ),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(300),
                ),
                width: constraints.maxWidth / 4,
                height: constraints.maxWidth / 4,
              ),
            ),
            // if (isSelected)
            //   Positioned(
            //     child: SvgPicture.asset(
            //       FeatureIcons.verified,
            //       width: 20,
            //       height: 20,
            //       colorFilter: const ColorFilter.mode(
            //         kWhite,
            //         BlendMode.srcIn,
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}

class SettingsOptionRow extends StatelessWidget {
  const SettingsOptionRow({
    super.key,
    required this.onClicked,
    required this.title,
    required this.isToggled,
    required this.firstIcon,
    required this.secondIcon,
    required this.description,
  });

  final Function() onClicked;
  final String title;
  final String description;
  final bool isToggled;
  final IconData firstIcon;
  final IconData secondIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: title,
            description: description,
          ),
        ),
        _button(context),
      ],
    );
  }

  GestureDetector _button(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 100,
        height: 30,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  kDefaultPadding * 2,
                ),
                color: Theme.of(context).cardColor,
              ),
            ),
            AnimatedPositioned(
              right: isToggled ? 50 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 30,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding * 2,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            _positionedItem()
          ],
        ),
      ),
    );
  }

  BlocBuilder<ThemeCubit, ThemeState> _positionedItem() {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isLight = state.mode == AppThemeMode.neige ||
            state.mode == AppThemeMode.ivory;

        return Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Icon(
                  key: const Key('sunny'),
                  firstIcon,
                  size: 20,
                  color: !isToggled && isLight ? kBlack : kWhite,
                ),
              ),
              Expanded(
                child: Icon(
                  key: const Key('night'),
                  secondIcon,
                  size: 20,
                  color: isToggled && isLight ? kBlack : kWhite,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
