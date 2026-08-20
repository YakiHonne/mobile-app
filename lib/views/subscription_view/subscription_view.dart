import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../logic/points_management_cubit/points_management_cubit.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../widgets/fluid_glass_tab_bar.dart';
import '../widgets/fluid_scaffold.dart';
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

    return FluidScaffold(
      title: context.t.subscription,
      body: Padding(
        padding: EdgeInsets.only(top: fluidScaffoldTopInset(context)),
        child: Column(
          children: [
            if (!isFluid())
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                  vertical: kDefaultPadding / 2,
                ),
                child: Align(
                  child: SizedBox(
                    width: 70.w,
                    child: _tabBar(context, tabController, floating: false),
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BlocBuilder<PointsManagementCubit,
                        PointsManagementState>(
                      bloc: pointsManagementCubit,
                      buildWhen: (p, c) =>
                          p.isSystemLoggedIn != c.isSystemLoggedIn,
                      builder: (context, pointsState) {
                        final isLoggedIn =
                            currentSigner != null &&
                                pointsState.isSystemLoggedIn;

                        if (!isLoggedIn) {
                          return Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(kDefaultPadding * 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: kDefaultPadding,
                                children: [
                                  Text(
                                    currentSigner == null
                                        ? context.t.sub_login_required
                                        : context.t.sub_connect_required,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context).hintColor,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () =>
                                          pointsManagementCubit.login(
                                        onSuccess: () {},
                                      ),
                                      child: Text(
                                        currentSigner == null
                                            ? context.t.login
                                                .capitalizeFirst()
                                            : context.t.sub_connect_btn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final bottomPadding = isFluid()
                            ? _floatingTabBarClearance(context)
                            : null;

                        return TabBarView(
                          controller: tabController,
                          children: [
                            SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom: bottomPadding ?? 0,
                              ),
                              child: SubscriptionSection(
                                onUpgrade: () => YNavigator.pushPage(
                                  context,
                                  (_) => const PricingScreen(),
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom: bottomPadding ?? 0,
                              ),
                              child: const UsageSection(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (isFluid())
                    Positioned(
                      left: kDefaultPadding / 2,
                      right: kDefaultPadding / 2,
                      bottom: MediaQuery.of(context).padding.bottom +
                          kDefaultPadding / 2,
                      child: Align(
                        child: SizedBox(
                          width: 70.w,
                          child: _tabBar(
                            context,
                            tabController,
                            floating: true,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBar(
    BuildContext context,
    TabController tabController, {
    required bool floating,
  }) {
    return FluidGlassTabBar(
      floating: floating,
      controller: tabController,
      tabs: [
        GlassTab(label: context.t.sub_subscription_tab),
        GlassTab(label: context.t.sub_usage_tab),
      ],
    );
  }
}

/// Bottom inset a fully-scrolled list needs so its last item clears the
/// floating tab bar pill instead of hiding behind it: the pill sits
/// `kDefaultPadding / 2` above the safe area and is [FluidGlassTabBar]'s
/// default `barHeight` (40) tall.
double _floatingTabBarClearance(BuildContext context) =>
    MediaQuery.of(context).padding.bottom + kDefaultPadding / 2 + 40;
