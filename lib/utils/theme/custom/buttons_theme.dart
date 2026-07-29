import 'package:flutter/material.dart';

import '../../constants.dart';

class TbuttonsTheme {
  TbuttonsTheme._();

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
                top: BorderSide(
                  color: borderColor,
                ),
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
              : Border(top: BorderSide(color: borderColor)),
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
