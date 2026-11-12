// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../../models/smart_widgets_components.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';
import 'global_smart_widget_container.dart';

class SmartWidgetDisplay extends StatelessWidget {
  const SmartWidgetDisplay({
    super.key,
    required this.smartWidgetModel,
  });

  final SmartWidget smartWidgetModel;

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: GlobalSmartWidgetContainer(
        smartWidgetModel: smartWidgetModel,
        disableActions: true,
      ),
    );
    final display = Container(
      constraints: BoxConstraints(
        maxWidth: isDesktopPlatform ? 560 : double.infinity,
        maxHeight:
            isDesktopPlatform ? MediaQuery.sizeOf(context).height * 0.7 : 70.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: Theme.of(context).primaryColorLight,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      margin: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    smartWidgetModel.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                CustomIconButton(
                  onClicked: () {
                    Navigator.pop(context);
                  },
                  icon: FeatureIcons.closeRaw,
                  size: 20,
                  vd: -2,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (isDesktopPlatform) Flexible(child: content) else content,
        ],
      ),
    );
    return display;
  }
}
