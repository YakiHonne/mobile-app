// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/fluid_sheet.dart';
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
        Row(
          children: [
            Expanded(
              child: _optionCard(
                context,
                icon: FeatureIcons.keys,
                label: context.t.loginAction.capitalizeFirst(),
                onTap: () {
                  logifySelection.value = false;
                  controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Expanded(
              child: _optionCard(
                context,
                icon: FeatureIcons.profileAdd,
                label: context.t.createAccount.capitalizeFirst(),
                isPrimary: true,
                onTap: () {
                  logifySelection.value = true;
                  controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: kDefaultPadding),
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
                    showAppModalSheet(
                      context: context,
                      builder: (_) {
                        return const EulaView();
                      },
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
                const RotatedBox(
                  quarterTurns: 1,
                  child: AppIcon(
                    FeatureIcons.arrowUp,
                    size: 20,
                    color: kWhite,
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

  Widget _optionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    const br = kDefaultPadding * 1.25;
    final iconColor = isPrimary
        ? Theme.of(context).primaryColor
        : Theme.of(context).primaryColorDark;

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon,
            size: 32,
            color: iconColor,
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: isFluid()
            ? FluidBlurContainer(
                borderRadius: br,
                padding: const EdgeInsets.all(kDefaultPadding),
                borderColor: isPrimary
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                    : null,
                child: content,
              )
            : Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(br),
                  border: Border.all(
                    color: isPrimary
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
                        : Theme.of(context).dividerColor,
                    width: isPrimary ? 0.8 : 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(kDefaultPadding),
                alignment: Alignment.center,
                child: content,
              ),
      ),
    );
  }
}
