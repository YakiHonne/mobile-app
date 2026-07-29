import 'package:flutter/widgets.dart';

/// Unified icon widget: every UI icon in the app renders through here,
/// backed by lucide_icons_flutter [IconData]s.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color);
}
