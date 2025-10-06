import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class UnderMaintenanceView extends StatelessWidget {
  const UnderMaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kDefaultPadding,
          children: [
            Image.asset(
              Images.underMaintenance,
              width: 170,
            ),
            Text(
              context.t.underMaintenance,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              context.t.smartWidgetMaintenance,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
