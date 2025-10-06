// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'onboarding_option_view.dart';
import 'signin_view.dart';
import 'signup_view.dart';

class LogifyViewPageBuilder extends HookWidget {
  const LogifyViewPageBuilder({
    super.key,
    required this.controller,
    required this.logifySelection,
    this.onPop,
  });

  final PageController controller;
  final ValueNotifier<bool> logifySelection;
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        OnboardingOptionsView(
          controller: controller,
          logifySelection: logifySelection,
          onPop: onPop,
        ),
        if (!logifySelection.value) ...[
          SignInView(
            controller: controller,
            onPop: onPop,
          ),
        ],
        if (logifySelection.value) ...[
          SignupView(
            controller: controller,
            onPop: onPop,
          ),
        ],
      ],
    );
  }
}
