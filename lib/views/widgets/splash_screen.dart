import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../utils/utils.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorLight,
      body: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Center(
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
            ],
          ),
        ),
      ),
    );
  }
}
