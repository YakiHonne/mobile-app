import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../utils/theme/theme.dart';
import '../../utils/utils.dart';

part 'theme_state.dart';

enum AppThemeMode { graphite, noir, neige, ivory }

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit()
      : super(
          ThemeState(
            textScaleFactor: localDatabaseRepository.getTextScaleFactor(),
            mode: AppThemeMode.graphite,
            isFluid: localDatabaseRepository.getFluidMode(),
            fluidCards: localDatabaseRepository.getFluidCards(),
            glassQuality: localDatabaseRepository.getGlassQuality(),
            theme: AppPreferredThemes.dark(),
            primaryColor: kMainColor,
          ),
        ) {
    init();
  }

  void init() {
    final mode = localDatabaseRepository.getAppThemeMode();
    final primaryColor = localDatabaseRepository.getAppMainColor();

    setTheme(
      mode: mode,
      primaryColor: primaryColor ?? kMainColor,
      saveLocally: false,
    );
  }

  void setFluidMode(bool isFluidMode) {
    localDatabaseRepository.setFluidMode(isFluidMode);
    if (!isClosed) {
      emit(state.copyWith(isFluid: isFluidMode));

      setTheme(
        mode: state.mode,
        primaryColor: state.primaryColor,
        saveLocally: false,
      );
    }
  }

  void setGlassQuality(GlassQuality quality) {
    localDatabaseRepository.setGlassQuality(quality);
    if (!isClosed) {
      emit(state.copyWith(glassQuality: quality));
    }
  }

  void setFluidCards(bool enabled) {
    localDatabaseRepository.setFluidCards(enabled);
    if (!isClosed) {
      emit(state.copyWith(fluidCards: enabled));
    }
  }

  void setTextScaleFactor(double tsf) {
    localDatabaseRepository.setTextScaleFactor(tsf);
    if (!isClosed) {
      emit(state.copyWith(textScaleFactor: tsf));
    }
  }

  void setTheme({
    required AppThemeMode mode,
    required Color primaryColor,
    bool saveLocally = true,
  }) {
    ThemeData theme;
    final isGlass = state.isFluid;

    switch (mode) {
      case AppThemeMode.graphite:
        theme = isGlass
            ? AppPreferredThemes.fluidGraphite(primaryColor: primaryColor)
            : AppPreferredThemes.dark(primaryColor: primaryColor);
        enableDarkEasyLoading();
      case AppThemeMode.noir:
        theme = isGlass
            ? AppPreferredThemes.fluidNoir(primaryColor: primaryColor)
            : AppPreferredThemes.black(primaryColor: primaryColor);
        enableDarkEasyLoading();
      case AppThemeMode.neige:
        theme = isGlass
            ? AppPreferredThemes.fluidNeige(primaryColor: primaryColor)
            : AppPreferredThemes.light(primaryColor: primaryColor);
        enableLightEasyLoading();
      case AppThemeMode.ivory:
        theme = isGlass
            ? AppPreferredThemes.fluidIvory(primaryColor: primaryColor)
            : AppPreferredThemes.cream(primaryColor: primaryColor);
        enableLightEasyLoading();
    }

    if (saveLocally) {
      localDatabaseRepository.setAppThemeMode(mode);
      localDatabaseRepository.setAppMainColor(primaryColor);
    }

    if (!isClosed) {
      emit(
          state.copyWith(mode: mode, theme: theme, primaryColor: primaryColor));
    }
  }

  void enableLightEasyLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..maskColor = Colors.grey.withValues(alpha: 0.3)
      ..loadingStyle = EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..animationStyle = EasyLoadingAnimationStyle.scale
      ..radius = kDefaultPadding - 5
      ..progressColor = kMainColor
      ..dismissOnTap = false;
  }

  void enableDarkEasyLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..maskColor = Colors.black.withValues(alpha: 0.4)
      ..loadingStyle = EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..animationStyle = EasyLoadingAnimationStyle.scale
      ..radius = kDefaultPadding - 5
      ..progressColor = kMainColor
      ..dismissOnTap = false;
  }

  bool get isDark =>
      state.mode == AppThemeMode.noir || state.mode == AppThemeMode.graphite;

  bool checkThemeDarkness(AppThemeMode mode) {
    return mode == AppThemeMode.noir || mode == AppThemeMode.graphite;
  }
}
