import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../utils/theme/glass_settings.dart';
import '../../utils/utils.dart';

/// Drop-in replacement for [CupertinoSwitch] that renders a [GlassSwitch]
/// when fluid mode is on. Parameter names match [CupertinoSwitch] so call
/// sites only change the widget name.
class FluidSwitch extends StatelessWidget {
  const FluidSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor,
    this.inactiveTrackColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;

  @override
  Widget build(BuildContext context) {
    if (!isFluid()) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeTrackColor,
        inactiveTrackColor: inactiveTrackColor,
      );
    }

    return GlassSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeTrackColor,
      inactiveColor: inactiveTrackColor,
      // Width and height are NOT independent. GlassSwitch's thumb is a pill of
      // (height - 4) * 1.6, so the distance it travels is
      //   width - (height - 4) * 1.6 - 4
      // Matching CupertinoSwitch's 51x31 leaves only ~3.8px of travel, which
      // reads as an instant snap rather than a slide. At 68x28 the thumb is
      // 38.4 wide and travels ~25.6px — the full 380ms slide is visible.
      width: 68,
      height: 28,
      useOwnLayer: true,
      settings: GlassSettings.glassSwitch(context),
      quality: themeCubit.state.glassQuality,
    );
  }
}
