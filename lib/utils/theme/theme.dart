import 'package:flutter/material.dart';

import '../utils.dart';
import 'custom/app_bar_theme.dart';
import 'custom/buttons_theme.dart';
import 'custom/input_decoration_theme.dart';
import 'custom/scroll_bar_theme.dart';
import 'custom/text_theme.dart';

class AppPreferredThemes {
  AppPreferredThemes._();

  static final light = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'DMSans',
    useMaterial3: true,
    scaffoldBackgroundColor: kWhite,
    primaryColor: kMainColor,
    primaryColorLight: kWhite,
    primaryColorDark: kBlack,
    shadowColor: kLightGrey,
    hintColor: kDimGrey,
    highlightColor: kDimGrey3,
    cardColor: kPaleGrey2,
    unselectedWidgetColor: kDimGrey,
    dividerColor: kOutlineLight,
    appBarTheme: TappbarTheme.lightAppBarTheme,
    textTheme: TtextTheme.lightTextTheme,
    scrollbarTheme: TscrollBarTheme.lightScrollBarTheme,
    inputDecorationTheme: TinputDecorationTheme.lightInputDecorationTheme,
    elevatedButtonTheme: TbuttonsTheme.lightElevatedButtonTheme,
    textButtonTheme: TbuttonsTheme.lightTextButtonTheme,
    outlinedButtonTheme: TbuttonsTheme.lightOutlinedButtonTheme,
    dividerTheme: const DividerThemeData(
      color: kOutlineLight,
    ),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'DMSans',
    useMaterial3: true,
    scaffoldBackgroundColor: kScaffoldDark,
    cardColor: kCardDark,
    primaryColor: kMainColor,
    highlightColor: kDimGrey,
    primaryColorDark: kWhite,
    primaryColorLight: kBlack,
    shadowColor: kBlack.withValues(alpha: 0.2),
    unselectedWidgetColor: kDimGrey2,
    hintColor: kLightGrey,
    dividerColor: kOutlineDark,
    appBarTheme: TappbarTheme.darkAppBarTheme,
    textTheme: TtextTheme.darkTextTheme,
    scrollbarTheme: TscrollBarTheme.darkScrollbarTheme,
    inputDecorationTheme: TinputDecorationTheme.darkInputDecorationTheme,
    elevatedButtonTheme: TbuttonsTheme.darkElevatedButtonTheme,
    textButtonTheme: TbuttonsTheme.darkTextButtonTheme,
    outlinedButtonTheme: TbuttonsTheme.darkOutlinedButtonTheme,
    dividerTheme: const DividerThemeData(
      color: kOutlineDark,
    ),
  );

  static final black = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'DMSans',
    useMaterial3: true,
    scaffoldBackgroundColor: kBlackTheme,
    cardColor: kScaffoldDark,
    primaryColor: kMainColor,
    highlightColor: kDimGrey,
    primaryColorDark: kWhite,
    primaryColorLight: kBlackTheme,
    shadowColor: kBlackTheme.withValues(alpha: 0.5),
    unselectedWidgetColor: kDimGrey2,
    hintColor: kLightGrey,
    dividerColor: kBlackOutline,
    appBarTheme: TappbarTheme.blackAppBarTheme,
    textTheme: TtextTheme.blackTextTheme,
    scrollbarTheme: TscrollBarTheme.blackScrollbarTheme,
    inputDecorationTheme: TinputDecorationTheme.blackInputDecorationTheme,
    elevatedButtonTheme: TbuttonsTheme.blackElevatedButtonTheme,
    textButtonTheme: TbuttonsTheme.blackTextButtonTheme,
    outlinedButtonTheme: TbuttonsTheme.blackOutlinedButtonTheme,
    dividerTheme: const DividerThemeData(
      color: kBlackOutline,
    ),
  );

// CREAM THEME (Light variant)
  static final cream = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'DMSans',
    useMaterial3: true,
    scaffoldBackgroundColor: kCreamTheme,
    primaryColor: kMainColor,
    primaryColorLight: kCreamLight,
    primaryColorDark: kBlack,
    shadowColor: kCreamHint,
    hintColor: kCreamHint,
    highlightColor: kDimGrey3,
    cardColor: kCreamCard,
    unselectedWidgetColor: kCreamHint,
    dividerColor: kCreamOutline,
    appBarTheme: TappbarTheme.creamAppBarTheme,
    textTheme: TtextTheme.creamTextTheme,
    scrollbarTheme: TscrollBarTheme.creamScrollBarTheme,
    inputDecorationTheme: TinputDecorationTheme.creamInputDecorationTheme,
    elevatedButtonTheme: TbuttonsTheme.creamElevatedButtonTheme,
    textButtonTheme: TbuttonsTheme.creamTextButtonTheme,
    outlinedButtonTheme: TbuttonsTheme.creamOutlinedButtonTheme,
    dividerTheme: const DividerThemeData(
      color: kCreamOutline,
    ),
  );
}
