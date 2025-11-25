// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/points_management_cubit/points_management_cubit.dart';
import '../../../utils/utils.dart';

class PointsLoginPopup extends HookWidget {
  const PointsLoginPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: isTablet ? 50.w : double.infinity,
      margin: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: BlocBuilder<PointsManagementCubit, PointsManagementState>(
        builder: (context, state) {
          if (state.isNew && state.standards.isNotEmpty) {
            return YakiHonneFirstRewards(
              level: state.currentLevel,
              percentage: state.percentage,
              standards: state.standards,
              xp: state.currentXp,
            );
          } else {
            return const YakiLoginChest();
          }
        },
      ),
    );
  }
}

class YakiHonneFirstRewards extends HookWidget {
  const YakiHonneFirstRewards({
    super.key,
    required this.standards,
    required this.xp,
    required this.level,
    required this.percentage,
  });

  final List<String> standards;
  final int xp;
  final int level;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    final animation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    useEffect(() {
      animationController.forward();
      return;
    }, [animationController]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 200),
          child: Text(
            '🎉',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontSize: 50,
                  height: 1,
                ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          duration: const Duration(milliseconds: 200),
          child: Text(
            context.t.congratulations.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        FadeIn(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 200),
          child: Text(
            context.t.congratsDesc(number: xp.toString()).capitalizeFirst(),
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Theme.of(context).highlightColor),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        _xpLevel(animation, context),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          runSpacing: kDefaultPadding / 2,
          spacing: kDefaultPadding / 2,
          children: standards
              .map(
                (e) => FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: kGreen,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SizedBox(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(context.t.gotIt.capitalizeFirst()),
          ),
        ),
      ],
    );
  }

  FadeInUp _xpLevel(Animation<double> animation, BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) => CircularProgressIndicator(
                  value: animation.value,
                  color: kRed,
                  strokeCap: StrokeCap.round,
                  backgroundColor: kBlack.withValues(alpha: 0.3),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        xp.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      Text(
                        'xp',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Theme.of(context).highlightColor),
                      ),
                    ],
                  ),
                  Text(
                    context.t.levelNumber(number: level.toString()),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class YakiLoginChest extends StatelessWidget {
  const YakiLoginChest({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.t.yakihonneChest.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          context.t.loginYakiChestPoints.capitalizeFirst(),
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Theme.of(context).highlightColor),
          textAlign: TextAlign.center,
        ),
        Image.asset(
          Images.yakiChest,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              if (currentSigner?.canSign() ?? false) {
                pointsManagementCubit.login(
                  onSuccess: () {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                );
              }
            },
            child: Text(context.t.login.capitalizeFirst()),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            context.t.noImGood.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
      ],
    );
  }
}
