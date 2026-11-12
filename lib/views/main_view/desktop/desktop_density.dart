import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/constants.dart';

const _densityKey = 'desktop_density';

enum DesktopDensity { comfortable, compact }

/// Device-local spacing for desktop workspace surfaces.
class DesktopDensityController extends ValueNotifier<DesktopDensity> {
  DesktopDensityController(this.preferences)
      : super(preferences.getString(_densityKey) == 'compact'
            ? DesktopDensity.compact
            : DesktopDensity.comfortable);

  final SharedPreferences preferences;

  void select(DesktopDensity density) {
    value = density;
    preferences.setString(_densityKey, density.name);
  }
}

class DesktopDensityScope extends InheritedNotifier<DesktopDensityController> {
  const DesktopDensityScope({
    super.key,
    required DesktopDensityController controller,
    required super.child,
  }) : super(notifier: controller);

  static DesktopDensityController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesktopDensityScope>()
      ?.notifier;

  static DesktopDensity of(BuildContext context) =>
      maybeOf(context)?.value ?? DesktopDensity.comfortable;
}

extension DesktopDensitySpacing on DesktopDensity {
  double get gap => this == DesktopDensity.compact
      ? kDefaultPadding / 2.5
      : kDefaultPadding / 1.5;
  double get cardPadding => this == DesktopDensity.compact
      ? kDefaultPadding / 4
      : kDefaultPadding / 2;
  double get contentCardPadding => this == DesktopDensity.compact
      ? kDefaultPadding / 2
      : kDefaultPadding / 1.5;
  double get headerGap =>
      this == DesktopDensity.compact ? kDefaultPadding / 2 : kDefaultPadding;
  double get sectionGap =>
      this == DesktopDensity.compact ? kDefaultPadding : kDefaultPadding * 1.5;
  double get sectionHeadingGap => this == DesktopDensity.compact
      ? kDefaultPadding / 4
      : kDefaultPadding / 2;
}
