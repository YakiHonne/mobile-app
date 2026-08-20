import 'package:flutter/material.dart';

import '../../../../utils/utils.dart';

Color energyColor(double score) {
  if (score < 30) {
    return const Color(0xFFEF4444);
  }
  if (score <= 60) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFF10B981);
}

String energyLabel(BuildContext context, double score) {
  if (score < 30) {
    return context.t.energy_mapper_label_low;
  }
  if (score <= 60) {
    return context.t.energy_mapper_label_medium;
  }
  return context.t.energy_mapper_label_high;
}
