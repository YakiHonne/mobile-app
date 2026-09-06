import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/subscription_cubit/subscription_cubit.dart';
import '../../utils/utils.dart';

/// Rebuilds [builder] whenever the usage snapshot changes, so limit gates
/// reflect a refresh without the surrounding screen knowing about usage.
class UsageGate extends StatelessWidget {
  const UsageGate({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionCubit, SubscriptionState>(
        bloc: subscriptionCubit,
        buildWhen: (p, c) => p.usageData != c.usageData,
        builder: (ctx, _) => builder(ctx),
      );
}
