import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../discover_view/discover_view.dart' show SourceButton;
import '../main_view/widgets/app_bar_widgets.dart' show FilterGlobalButton;
import '../widgets/fluid_blur_container.dart';

class FluidSourceFilterRow extends StatelessWidget {
  const FluidSourceFilterRow({
    super.key,
    required this.viewType,
    required this.onSourceChanged,
  });

  final ViewDataTypes viewType;
  final VoidCallback onSourceChanged;

  @override
  Widget build(BuildContext context) {
    // ponytail: 70.w is the phone pill; the cap only bites on tablets, where
    // 70% of a 1024+ screen is an absurdly wide filter row.
    return SizedBox(
      width: min(70.w, 380),
      child: FluidBlurContainer(
        borderRadius: kDefaultPadding * 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SourceButton(
                viewType: viewType,
                onSourceChanged: onSourceChanged,
              ),
            ),
            SizedBox(
              height: 20,
              child: VerticalDivider(
                width: 1,
                thickness: 0.5,
                color: Theme.of(context).dividerColor,
              ),
            ),
            FilterGlobalButton(viewType: viewType),
          ],
        ),
      ),
    );
  }
}
