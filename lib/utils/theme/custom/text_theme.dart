import 'package:flutter/material.dart';

import '../../constants.dart';

/// Single source of truth for every text size in the app. Tune here.
class FontSizes {
  FontSizes._();

  static const displayLarge = 63.0;
  static const displayMedium = 50.0;
  static const displaySmall = 40.0;
  static const headlineLarge = 35.0;
  static const headlineMedium = 31.0;
  static const headlineSmall = 26.0;
  static const titleLarge = 24.0;
  static const titleMedium = 18.0;
  static const titleSmall = 15.0;
  static const bodyLarge = 18.0;
  static const bodyMedium = 18.0;
  static const bodySmall = 13.0;
  static const labelLarge = 15.0;
  static const labelMedium = 13.0;
  static const labelSmall = 11.0;
}

class TtextTheme {
  TtextTheme._();

  /// Every theme shares one size scale — only the text color differs.
  static TextTheme _of(Color color) => TextTheme(
        displayLarge: TextStyle(
            fontSize: FontSizes.displayLarge,
            fontWeight: FontWeight.bold,
            color: color),
        displayMedium: TextStyle(
            fontSize: FontSizes.displayMedium,
            fontWeight: FontWeight.bold,
            color: color),
        displaySmall: TextStyle(
            fontSize: FontSizes.displaySmall,
            fontWeight: FontWeight.bold,
            color: color),
        headlineLarge: TextStyle(
            fontSize: FontSizes.headlineLarge,
            fontWeight: FontWeight.w500,
            color: color),
        headlineMedium: TextStyle(
            fontSize: FontSizes.headlineMedium,
            fontWeight: FontWeight.w500,
            color: color),
        headlineSmall: TextStyle(
            fontSize: FontSizes.headlineSmall,
            fontWeight: FontWeight.w500,
            color: color),
        titleLarge: TextStyle(
            fontSize: FontSizes.titleLarge,
            fontWeight: FontWeight.w500,
            color: color),
        titleMedium: TextStyle(
            fontSize: FontSizes.titleMedium,
            fontWeight: FontWeight.w500,
            color: color),
        titleSmall: TextStyle(
            fontSize: FontSizes.titleSmall,
            fontWeight: FontWeight.w500,
            color: color),
        bodyLarge: TextStyle(
            fontSize: FontSizes.bodyLarge,
            fontWeight: FontWeight.normal,
            color: color),
        bodyMedium: TextStyle(
            fontSize: FontSizes.bodyMedium,
            fontWeight: FontWeight.normal,
            color: color),
        bodySmall: TextStyle(
            fontSize: FontSizes.bodySmall,
            fontWeight: FontWeight.normal,
            color: color),
        labelLarge: TextStyle(
            fontSize: FontSizes.labelLarge,
            fontWeight: FontWeight.normal,
            color: color),
        labelMedium: TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.normal,
            color: color),
        labelSmall: TextStyle(
            fontSize: FontSizes.labelSmall,
            fontWeight: FontWeight.normal,
            color: color),
      );

  static TextTheme get lightTextTheme => _of(Colors.black);
  static TextTheme get darkTextTheme => _of(Colors.white);
  static TextTheme get blackTextTheme => _of(Colors.white);
  static TextTheme get creamTextTheme => _of(Colors.black);
  static TextTheme get fluidTextTheme => _of(kGlassText);
}
