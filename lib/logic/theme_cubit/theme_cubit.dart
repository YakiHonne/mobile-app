import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

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

    switch (mode) {
      case AppThemeMode.graphite:
        theme = AppPreferredThemes.dark(primaryColor: primaryColor);
        enableDarkEasyLoading();
      case AppThemeMode.noir:
        theme = AppPreferredThemes.black(primaryColor: primaryColor);
        enableDarkEasyLoading();
      case AppThemeMode.neige:
        theme = AppPreferredThemes.light(primaryColor: primaryColor);
        enableLightEasyLoading();
      case AppThemeMode.ivory:
        theme = AppPreferredThemes.cream(primaryColor: primaryColor);
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
