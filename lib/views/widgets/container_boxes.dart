import 'package:flutter/material.dart';

import '../../utils/utils.dart';

BoxDecoration defaultBoxDecoration({BuildContext? ctx, double? radius}) {
  final context = ctx ?? gc;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius ?? kDefaultPadding / 2),
    border: Border.all(
      color: Theme.of(context).dividerColor,
      width: 0.5,
    ),
    color: Theme.of(context).cardColor,
  );
}
