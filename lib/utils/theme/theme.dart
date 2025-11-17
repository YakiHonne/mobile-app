import 'package:flutter/material.dart';

import '../utils.dart';
import 'custom/app_bar_theme.dart';
import 'custom/buttons_theme.dart';
import 'custom/input_decoration_theme.dart';
import 'custom/scroll_bar_theme.dart';
import 'custom/text_theme.dart';

class AppPreferredThemes {
  AppPreferredThemes._();

  static ThemeData light({Color primaryColor = kMainColor}) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'DMSans',
      useMaterial3: true,
      scaffoldBackgroundColor: kWhite,
      primaryColor: primaryColor,
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
      scrollbarTheme: TscrollBarTheme.lightScrollBarTheme(
        primaryColor: primaryColor,
      ),
      inputDecorationTheme: TinputDecorationTheme.lightInputDecorationTheme,
      elevatedButtonTheme:
          TbuttonsTheme.lightElevatedButtonTheme(primaryColor: primaryColor),
      textButtonTheme:
          TbuttonsTheme.lightTextButtonTheme(primaryColor: primaryColor),
      outlinedButtonTheme:
          TbuttonsTheme.lightOutlinedButtonTheme(primaryColor: primaryColor),
      dividerTheme: const DividerThemeData(
        color: kOutlineLight,
      ),
    );
  }

  static ThemeData dark({Color primaryColor = kMainColor}) {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'DMSans',
      useMaterial3: true,
      scaffoldBackgroundColor: kScaffoldDark,
      cardColor: kCardDark,
      primaryColor: primaryColor,
      highlightColor: kDimGrey,
      primaryColorDark: kWhite,
      primaryColorLight: kBlack,
      shadowColor: kBlack.withValues(alpha: 0.2),
      unselectedWidgetColor: kDimGrey2,
      hintColor: kLightGrey,
      dividerColor: kOutlineDark,
      appBarTheme: TappbarTheme.darkAppBarTheme,
      textTheme: TtextTheme.darkTextTheme,
      scrollbarTheme: TscrollBarTheme.darkScrollbarTheme(
        primaryColor: primaryColor,
      ),
      inputDecorationTheme: TinputDecorationTheme.darkInputDecorationTheme,
      elevatedButtonTheme:
          TbuttonsTheme.darkElevatedButtonTheme(primaryColor: primaryColor),
      textButtonTheme:
          TbuttonsTheme.darkTextButtonTheme(primaryColor: primaryColor),
      outlinedButtonTheme:
          TbuttonsTheme.darkOutlinedButtonTheme(primaryColor: primaryColor),
      dividerTheme: const DividerThemeData(
        color: kOutlineDark,
      ),
    );
  }

  static ThemeData black({Color primaryColor = kMainColor}) {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'DMSans',
      useMaterial3: true,
      scaffoldBackgroundColor: kBlackTheme,
      cardColor: kScaffoldDark,
      primaryColor: primaryColor,
      highlightColor: kDimGrey,
      primaryColorDark: kWhite,
      primaryColorLight: kBlackTheme,
      shadowColor: kBlackTheme.withValues(alpha: 0.5),
      unselectedWidgetColor: kDimGrey2,
      hintColor: kLightGrey,
      dividerColor: kBlackOutline,
      appBarTheme: TappbarTheme.blackAppBarTheme,
      textTheme: TtextTheme.blackTextTheme,
      scrollbarTheme: TscrollBarTheme.blackScrollbarTheme(
        primaryColor: primaryColor,
      ),
      inputDecorationTheme: TinputDecorationTheme.blackInputDecorationTheme,
      elevatedButtonTheme:
          TbuttonsTheme.blackElevatedButtonTheme(primaryColor: primaryColor),
      textButtonTheme:
          TbuttonsTheme.blackTextButtonTheme(primaryColor: primaryColor),
      outlinedButtonTheme:
          TbuttonsTheme.blackOutlinedButtonTheme(primaryColor: primaryColor),
      dividerTheme: const DividerThemeData(
        color: kBlackOutline,
      ),
    );
  }

// CREAM THEME (Light variant)
  static ThemeData cream({Color primaryColor = kMainColor}) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'DMSans',
      useMaterial3: true,
      scaffoldBackgroundColor: kCreamTheme,
      primaryColor: primaryColor,
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
      scrollbarTheme: TscrollBarTheme.creamScrollBarTheme(
        primaryColor: primaryColor,
      ),
      inputDecorationTheme: TinputDecorationTheme.creamInputDecorationTheme,
      elevatedButtonTheme:
          TbuttonsTheme.creamElevatedButtonTheme(primaryColor: primaryColor),
      textButtonTheme:
          TbuttonsTheme.creamTextButtonTheme(primaryColor: primaryColor),
      outlinedButtonTheme:
          TbuttonsTheme.creamOutlinedButtonTheme(primaryColor: primaryColor),
      dividerTheme: const DividerThemeData(
        color: kCreamOutline,
      ),
    );
  }
}
