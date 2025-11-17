// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import 'eula_view.dart';

class OnboardingOptionsView extends StatelessWidget {
  const OnboardingOptionsView({
    super.key,
    required this.logifySelection,
    required this.controller,
    this.onPop,
  });

  final ValueNotifier<bool> logifySelection;
  final PageController controller;
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final List<Widget> components = [];

    components.addAll(
      [
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SvgPicture.asset(
          LogosIcons.logoMarkWhite,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
      ],
    );

    components.addAll(
      [
        Text(
          context.t.enjoyExpOwnData.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
      ],
    );

    components.addAll(
      [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: GlassmorphicContainer(
                width: constraints.maxWidth * 0.8,
                height: constraints.maxWidth * 0.8,
                borderRadius: 20,
                blur: 20,
                padding: const EdgeInsets.all(kDefaultPadding),
                alignment: Alignment.center,
                border: 0.5,
                linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColorDark.withValues(alpha: 0.1),
                      Theme.of(context)
                          .primaryColorDark
                          .withValues(alpha: 0.05),
                    ],
                    stops: const [
                      0.1,
                      1,
                    ]),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColorDark.withValues(alpha: 0.5),
                    kTransparent,
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    Images.initialOnboarding,
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
      ],
    );

    components.addAll(
      [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              logifySelection.value = false;
              controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Text(context.t.loginAction.capitalizeFirst()),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
      ],
    );

    components.addAll(
      [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              logifySelection.value = true;
              controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Text(context.t.createAccount.capitalizeFirst()),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
      ],
    );

    components.addAll(
      [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.labelMedium,
            children: [
              TextSpan(
                text: context.t.byContinuing.capitalizeFirst(),
              ),
              TextSpan(
                text: context.t.eula.capitalizeFirst(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    showCupertinoModalBottomSheet(
                      context: context,
                      elevation: 0,
                      builder: (_) {
                        return const EulaView();
                      },
                      useRootNavigator: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  },
              ),
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
      ],
    );

    components.addAll(
      [
        GestureDetector(
          onTap: () => onPop?.call() ?? YNavigator.pop(context),
          behavior: HitTestBehavior.translucent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentSigner == null
                    ? context.t.continueAsGuest.capitalizeFirst()
                    : context.t.cancel.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: currentSigner == null ? kWhite : kRed,
                    ),
                textAlign: TextAlign.center,
              ),
              if (currentSigner == null) ...[
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                RotatedBox(
                  quarterTurns: 1,
                  child: SvgPicture.asset(
                    FeatureIcons.arrowUp,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      kWhite,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Column(
          children: components,
        ),
      ),
    );
  }
}
