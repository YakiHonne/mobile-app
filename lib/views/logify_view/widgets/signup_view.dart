// ignore_for_file: public_member_api_docs, sort_constructors_first, prefer_foreach

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../utils/utils.dart';
import 'signup_appbar.dart';
import 'signup_interests.dart';
import 'signup_metadata.dart';
import 'signup_preview.dart';
import 'signup_wallet.dart';

class SignupView extends HookWidget {
  const SignupView({
    super.key,
    required this.controller,
    this.onPop,
  });

  final PageController controller;
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final components = <Widget>[];
    final childController = usePageController();
    final currentIndex = useState(0);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    components.add(
      OnboardingAppbar(
        onReturn: () {
          if (currentIndex.value == 0) {
            controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            childController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );

            currentIndex.value--;
          }
        },
        title: context.t.createAccount.capitalizeFirst(),
      ),
    );

    components.addAll(
      [
        Expanded(
          child: BlocBuilder<LogifyCubit, LogifyState>(
            builder: (context, state) {
              return Stack(
                children: [
                  _initializingAccount(state, context),
                  _pageView(state, childController, formKey),
                ],
              );
            },
          ),
        ),
      ],
    );

    components.addAll(
      [
        BlocBuilder<LogifyCubit, LogifyState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
              child: Column(
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  _animatedContainerDots(currentIndex, context),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  _textButton(
                      state, currentIndex, context, formKey, childController),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );

    return SafeArea(
      child: Column(
        children: components,
      ),
    );
  }

  Row _animatedContainerDots(
      ValueNotifier<int> currentIndex, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => AnimatedContainer(
          margin: const EdgeInsets.only(right: 5.0),
          duration: const Duration(milliseconds: 300),
          height: 6.0,
          width: currentIndex.value == index ? 25.0 : 6.0,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorDark,
            borderRadius: BorderRadius.circular(
              kDefaultPadding,
            ),
          ),
        ),
      ),
    );
  }

  SizedBox _textButton(
      LogifyState state,
      ValueNotifier<int> currentIndex,
      BuildContext context,
      GlobalKey<FormState> formKey,
      PageController childController) {
    return SizedBox(
      width: double.infinity,
      child: AbsorbPointer(
        absorbing: state.isSettingAccount,
        child: TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            if (currentIndex.value == 3) {
              context.read<LogifyCubit>().setupAccount(
                    onSuccess: onPop ??
                        () {
                          Navigator.pop(context);
                        },
                  );
            } else if (currentIndex.value != 0 ||
                formKey.currentState!.validate()) {
              childController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );

              currentIndex.value++;
            }
          },
          child: Text(
            currentIndex.value == 3
                ? context.t.letsGetStarted.capitalizeFirst()
                : context.t.next.capitalizeFirst(),
          ),
        ),
      ),
    );
  }

  Positioned _pageView(LogifyState state, PageController childController,
      GlobalKey<FormState> formKey) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: !state.isSettingAccount ? 1 : 0,
        child: PageView(
          controller: childController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SignupMetadata(
              formKey: formKey,
            ),
            const SignupInterestsAndFollowings(),
            const SignupWallet(),
            const SignupPreview(),
          ],
        ),
      ),
    );
  }

  Positioned _initializingAccount(LogifyState state, BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: state.isSettingAccount ? 1 : 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              themeCubit.isDark
                  ? LottieAnimations.loading
                  : LottieAnimations.loadingDark,
              height: 15.h,
              width: 15.h,
              fit: BoxFit.contain,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Text(
              context.t.initializingAccount.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
