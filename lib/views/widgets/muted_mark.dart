// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import 'tooltip_with_text.dart';

class MutedMark extends StatelessWidget {
  const MutedMark({
    super.key,
    required this.kind,
  });

  final String kind;

  @override
  Widget build(BuildContext context) {
    return TooltipWithText(
      message: 'This $kind belongs to a muted user.',
      child: CircleAvatar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        radius: 12,
        child: SvgPicture.asset(
          FeatureIcons.mute,
          width: 15,
          height: 15,
          colorFilter: const ColorFilter.mode(
            kRed,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
