import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

class OnboardingAppbar extends StatelessWidget {
  const OnboardingAppbar({
    super.key,
    required this.title,
    required this.onReturn,
  });

  final String title;
  final Function() onReturn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: 100.w,
          height: 40,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onReturn,
            icon: RotatedBox(
              quarterTurns: -1,
              child: SvgPicture.asset(
                FeatureIcons.arrowUp,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          top: 0,
          right: 0,
          left: 0,
          child: Align(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
