import 'package:flutter/material.dart';

import '../../utils.dart';

class TscrollBarTheme {
  TscrollBarTheme._();

  static ScrollbarThemeData lightScrollBarTheme(
      {Color primaryColor = kMainColor}) {
    return ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(primaryColor),
      trackColor: WidgetStateProperty.all(Colors.black12),
      trackVisibility: WidgetStateProperty.all(true),
      radius: const Radius.circular(8.0),
      thickness: WidgetStateProperty.all(3),
    );
  }

  static ScrollbarThemeData darkScrollbarTheme(
      {Color primaryColor = kMainColor}) {
    return ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(primaryColor),
      trackColor: WidgetStateProperty.all(Colors.white12),
      trackVisibility: WidgetStateProperty.all(true),
      radius: const Radius.circular(8.0),
      thickness: WidgetStateProperty.all(3),
    );
  }

  static ScrollbarThemeData blackScrollbarTheme(
      {Color primaryColor = kMainColor}) {
    return ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(primaryColor),
      trackColor: WidgetStateProperty.all(kBlackSoft),
      trackVisibility: WidgetStateProperty.all(true),
      radius: const Radius.circular(8.0),
      thickness: WidgetStateProperty.all(3),
    );
  }

  static ScrollbarThemeData creamScrollBarTheme(
      {Color primaryColor = kMainColor}) {
    return ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(primaryColor),
      trackColor: WidgetStateProperty.all(kCreamOutline),
      trackVisibility: WidgetStateProperty.all(true),
      radius: const Radius.circular(8.0),
      thickness: WidgetStateProperty.all(3),
    );
  }
}
