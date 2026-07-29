import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../logic/points_management_cubit/points_management_cubit.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/fluid_blur_container.dart';
import 'pricing/pricing_screen.dart';
import 'widgets/subscription_section.dart';
import 'widgets/usage_section.dart';

class SubscriptionView extends HookWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2);

    useEffect(() {
      subscriptionCubit.loadViewData();
      return null;
    }, const []);

    return Scaffold(
      appBar: CustomAppBar(title: context.t.subscription),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kDefaultPadding / 2,
            ),
            child: Align(
              child: SizedBox(
                width: 70.w,
                child: FluidBlurContainer(
                  padding: const EdgeInsets.all(3),
                  backgroundAlpha: 0.5,
                  child: TabBar(
                    controller: tabController,
                    dividerHeight: 0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.all(3),
                    indicator: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(300),
                    ),
                    labelStyle: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                    unselectedLabelStyle: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(fontWeight: FontWeight.w500),
                    tabs: [
                      Tab(
                        height: 28,
                        text: context.t.sub_subscription_tab,
                      ),
                      Tab(
                        height: 28,
                        text: context.t.sub_usage_tab,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder<PointsManagementCubit, PointsManagementState>(
            bloc: pointsManagementCubit,
            buildWhen: (p, c) => p.isSystemLoggedIn != c.isSystemLoggedIn,
            builder: (context, pointsState) {
              final isLoggedIn = currentSigner != null && pointsState.isSystemLoggedIn;

              if (!isLoggedIn) {
                return Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(kDefaultPadding * 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: kDefaultPadding,
                        children: [
                          Text(
                            currentSigner == null
                                ? context.t.sub_login_required
                                : context.t.sub_connect_required,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => pointsManagementCubit.login(
                                onSuccess: () {},
                              ),
                              child: Text(
                                currentSigner == null
                                    ? context.t.login.capitalizeFirst()
                                    : context.t.sub_connect_btn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    SingleChildScrollView(
                      child: SubscriptionSection(
                        onUpgrade: () => YNavigator.pushPage(
                          context,
                          (_) => const PricingScreen(),
                        ),
                      ),
                    ),
                    const SingleChildScrollView(
                      child: UsageSection(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
