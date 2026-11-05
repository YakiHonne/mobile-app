import 'package:flutter/material.dart';

import '../platform_utils.dart';

WidgetStateProperty<Color?>? desktopNoHoverOverlay(Color fallback) =>
    isDesktopPlatform ? noHoverOverlay(fallback) : null;

/// Suppress only pointer hover while preserving pressed and keyboard focus.
WidgetStateProperty<Color?> noHoverOverlay(
  Color fallback, {
  WidgetStateProperty<Color?>? original,
}) =>
    WidgetStateProperty.resolveWith((states) {
      final withoutHover = {...states}..remove(WidgetState.hovered);
      final existing = original?.resolve(withoutHover);
      if (states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.focused)) {
        return existing ?? fallback.withValues(alpha: 0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return Colors.transparent;
      }
      return existing;
    });

ButtonStyle _withoutHover(ButtonStyle? style, Color fallback) {
  final original = style ?? const ButtonStyle();
  return original.copyWith(
    overlayColor: noHoverOverlay(fallback, original: original.overlayColor),
  );
}

/// Removes Material hover tints without changing interaction or selection.
ThemeData withoutHoverHighlights(ThemeData theme) {
  final primary = theme.colorScheme.primary;
  final onSurface = theme.colorScheme.onSurface;
  return theme.copyWith(
    hoverColor: Colors.transparent,
    inputDecorationTheme:
        theme.inputDecorationTheme.copyWith(hoverColor: Colors.transparent),
    textButtonTheme: TextButtonThemeData(
      style: _withoutHover(theme.textButtonTheme.style, primary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _withoutHover(theme.elevatedButtonTheme.style, primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _withoutHover(theme.outlinedButtonTheme.style, primary),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: _withoutHover(theme.iconButtonTheme.style, onSurface),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: _withoutHover(theme.menuButtonTheme.style, onSurface),
    ),
    checkboxTheme: theme.checkboxTheme.copyWith(
      overlayColor:
          noHoverOverlay(primary, original: theme.checkboxTheme.overlayColor),
    ),
    radioTheme: theme.radioTheme.copyWith(
      overlayColor:
          noHoverOverlay(primary, original: theme.radioTheme.overlayColor),
    ),
    switchTheme: theme.switchTheme.copyWith(
      overlayColor:
          noHoverOverlay(primary, original: theme.switchTheme.overlayColor),
    ),
    floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
      hoverColor: Colors.transparent,
    ),
  );
}
