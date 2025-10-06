import 'package:flutter/material.dart';

import '../../utils.dart';

class TappbarTheme {
  TappbarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    backgroundColor: kWhite,
    elevation: 0,
    scrolledUnderElevation: 1,
    surfaceTintColor: kTransparent,
  );

  static const darkAppBarTheme = AppBarTheme(
    backgroundColor: kScaffoldDark,
    elevation: 0,
    scrolledUnderElevation: 2,
    surfaceTintColor: kTransparent,
  );

  static const blackAppBarTheme = AppBarTheme(
    backgroundColor: kBlackTheme,
    elevation: 0,
    scrolledUnderElevation: 2,
    surfaceTintColor: kTransparent,
  );

  static const creamAppBarTheme = AppBarTheme(
    backgroundColor: kCreamTheme,
    elevation: 0,
    scrolledUnderElevation: 1,
    surfaceTintColor: kTransparent,
  );
}
