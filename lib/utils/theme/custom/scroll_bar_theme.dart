import 'package:flutter/material.dart';

import '../../utils.dart';

class TscrollBarTheme {
  TscrollBarTheme._();

  static final lightScrollBarTheme = ScrollbarThemeData(
    thumbColor: WidgetStateProperty.all(kMainColor),
    trackColor: WidgetStateProperty.all(Colors.black12),
    trackVisibility: WidgetStateProperty.all(true),
    radius: const Radius.circular(8.0),
    thickness: WidgetStateProperty.all(3),
  );

  static final darkScrollbarTheme = ScrollbarThemeData(
    thumbColor: WidgetStateProperty.all(kMainColor),
    trackColor: WidgetStateProperty.all(Colors.white12),
    trackVisibility: WidgetStateProperty.all(true),
    radius: const Radius.circular(8.0),
    thickness: WidgetStateProperty.all(3),
  );

  static final blackScrollbarTheme = ScrollbarThemeData(
    thumbColor: WidgetStateProperty.all(kMainColor),
    trackColor: WidgetStateProperty.all(kBlackSoft),
    trackVisibility: WidgetStateProperty.all(true),
    radius: const Radius.circular(8.0),
    thickness: WidgetStateProperty.all(3),
  );

  static final creamScrollBarTheme = ScrollbarThemeData(
    thumbColor: WidgetStateProperty.all(kMainColor),
    trackColor: WidgetStateProperty.all(kCreamOutline),
    trackVisibility: WidgetStateProperty.all(true),
    radius: const Radius.circular(8.0),
    thickness: WidgetStateProperty.all(3),
  );
}
