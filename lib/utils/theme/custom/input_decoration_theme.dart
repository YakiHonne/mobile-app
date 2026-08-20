import 'package:flutter/material.dart';

import '../../utils.dart';

class TinputDecorationTheme {
  TinputDecorationTheme._();

  static final lightInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: kLightBgGrey,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: kDefaultPadding,
      vertical: kDefaultPadding / 1.5,
    ),
    labelStyle: const TextStyle(
      color: kDimGrey,
      fontSize: 14,
      fontFamily: 'DMSans',
    ),
    errorStyle: const TextStyle(color: kRed),
    isDense: true,
    hintStyle: const TextStyle(
      color: kDimGrey,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    helperStyle: const TextStyle(
      color: kWhite,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kOutlineLight,
        width: 0.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kOutlineLight,
        width: 0.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kDimGrey,
        width: 0.5,
      ),
    ),
  );

  static final darkInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: kDarkThemeCard,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: kDefaultPadding,
      vertical: kDefaultPadding / 1.5,
    ),
    labelStyle: const TextStyle(
      color: kDimGrey,
      fontSize: 14,
    ),
    helperStyle: const TextStyle(
      color: kWhite,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    isDense: true,
    hintStyle: const TextStyle(
      color: kDimGrey,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kOutlineDark,
        width: 0.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kOutlineDark,
        width: 0.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kDimGrey,
        width: 0.5,
      ),
    ),
  );

  static final blackInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: kBlackThemeCard,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: kDefaultPadding,
      vertical: kDefaultPadding / 1.5,
    ),
    labelStyle: const TextStyle(
      color: kDimGrey,
      fontSize: 14,
    ),
    helperStyle: const TextStyle(
      color: kWhite,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    isDense: true,
    hintStyle: const TextStyle(
      color: kDimGrey,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kBlackOutline,
        width: 0.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kBlackOutline,
        width: 0.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kDimGrey,
        width: 0.5,
      ),
    ),
  );

  static final creamInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: kCreamCard,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: kDefaultPadding,
      vertical: kDefaultPadding / 1.5,
    ),
    labelStyle: const TextStyle(
      color: kCreamHint,
      fontSize: 14,
      fontFamily: 'DMSans',
    ),
    errorStyle: const TextStyle(color: kRed),
    isDense: true,
    hintStyle: const TextStyle(
      color: kCreamHint,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    helperStyle: const TextStyle(
      color: kBlack,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kCreamOutline,
        width: 0.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kCreamOutline,
        width: 0.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kCreamHint,
        width: 0.5,
      ),
    ),
  );

  // Used for glass graphite + noir (dark glass variants)
  static final fluidInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: kGlassCard,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: kDefaultPadding,
      vertical: kDefaultPadding / 1.5,
    ),
    labelStyle: const TextStyle(
      color: kGlassHint,
      fontSize: 14,
      fontFamily: 'DMSans',
    ),
    errorStyle: const TextStyle(color: kRed),
    isDense: true,
    hintStyle: const TextStyle(
      color: kGlassHint,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    helperStyle: const TextStyle(
      color: kGlassText,
      fontFamily: 'DMSans',
      fontSize: 14,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kGlassOutline,
        width: 0.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kGlassOutline,
        width: 0.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kRed,
        width: 0.5,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding - 5),
      borderSide: const BorderSide(
        color: kGlassHint,
        width: 0.5,
      ),
    ),
  );
}
