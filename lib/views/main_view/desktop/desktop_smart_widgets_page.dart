import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';
import '../../smart_widgets_view/smart_widgets_search.dart';
import '../../widgets/fluid_scaffold.dart';

/// A pane-owned instance, with a scroll controller independent of mobile tabs.
class DesktopSmartWidgetsPage extends HookWidget {
  const DesktopSmartWidgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    return FluidScaffold(
      title: context.t.smartWidgets.capitalizeFirst(),
      body: SmartWidgetsSearch(
        scrollController: controller,
        onReadyChanged: (_) {},
      ),
    );
  }
}
