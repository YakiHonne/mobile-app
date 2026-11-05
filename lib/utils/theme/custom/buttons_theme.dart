import 'package:flutter/material.dart';

import '../../constants.dart';

/// Visible diameter of the default glass icon button.
const double kDesktopGlassButtonHeight = 44;

class TbuttonsTheme {
  TbuttonsTheme._();

  /// Keep desktop glass action surfaces aligned with the default icon button.
  /// A minimum, rather than a fixed height, lets large text expand naturally.
  static ButtonStyle desktopFluidButtonStyle(ButtonStyle? original) =>
      (original ?? const ButtonStyle()).copyWith(
        minimumSize:
            const WidgetStatePropertyAll(Size(0, kDesktopGlassButtonHeight)),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  static TextButtonThemeData desktopFluidTextButtonTheme(
          TextButtonThemeData original) =>
      TextButtonThemeData(style: desktopFluidButtonStyle(original.style));

  static ElevatedButtonThemeData desktopFluidElevatedButtonTheme(
          ElevatedButtonThemeData original) =>
      ElevatedButtonThemeData(style: desktopFluidButtonStyle(original.style));

  static OutlinedButtonThemeData desktopFluidOutlinedButtonTheme(
          OutlinedButtonThemeData original) =>
      OutlinedButtonThemeData(style: desktopFluidButtonStyle(original.style));

  static ElevatedButtonThemeData lightElevatedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Background color
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static TextButtonThemeData lightTextButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kWhite,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData lightOutlinedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static ElevatedButtonThemeData darkElevatedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Background color
        foregroundColor: kWhite,

        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static TextButtonThemeData darkTextButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kWhite,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData darkOutlinedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static ElevatedButtonThemeData blackElevatedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static TextButtonThemeData blackTextButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kWhite,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData blackOutlinedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Cream theme buttons
  static ElevatedButtonThemeData creamElevatedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static TextButtonThemeData creamTextButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kWhite,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData creamOutlinedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static ElevatedButtonThemeData fluidElevatedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: const StadiumBorder(),
      ),
    );
  }

  static TextButtonThemeData fluidTextButtonTheme({
    required Color backgroundColor,
    required Color borderColor,
    required Color foregroundColor,
  }) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(foregroundColor),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        backgroundBuilder: (context, states, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border(
                top: BorderSide(color: borderColor, width: 1.5),
                left: BorderSide(color: borderColor, width: 0.5),
                right: BorderSide(color: borderColor, width: 0.5),
                bottom: BorderSide(color: borderColor, width: 0.5),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor.withValues(alpha: 0.95),
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.15, 1.0],
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  static OutlinedButtonThemeData fluidOutlinedButtonTheme({
    Color primaryColor = kMainColor,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: const StadiumBorder(),
      ),
    );
  }

  /// One-off [TextButton] style pinned to [backgroundColor] (e.g. a
  /// destructive action) instead of the app's fixed accent colors.
  /// [fluidTextButtonTheme] paints every themed TextButton's background via
  /// its own `backgroundBuilder`, which ignores `TextButton.styleFrom(
  /// backgroundColor: ...)` entirely — this overrides that builder with the
  /// same top-to-bottom glass gradient shape, just built off [backgroundColor]
  /// instead of the theme's fixed accent, so it still reads as "glass".
  static ButtonStyle solidTextButtonStyle(
    Color backgroundColor, {
    Color foregroundColor = kWhite,
    Color? borderColor,
  }) {
    return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(foregroundColor),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      backgroundBuilder: (context, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: borderColor == null
              ? null
              : Border(
                  top: BorderSide(color: borderColor, width: 1.5),
                  left: BorderSide(color: borderColor, width: 0.5),
                  right: BorderSide(color: borderColor, width: 0.5),
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor.withValues(alpha: 0.95),
              backgroundColor,
              backgroundColor.withValues(alpha: 0.85),
            ],
            stops: const [0.0, 0.15, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}
