import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/routing_cubit/routing_cubit.dart';
import '../../utils/utils.dart';
import '../disclosure_view/disclosure_view.dart';
import '../logify_view/logify_view.dart';
import '../main_view/main_view.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/splash_screen.dart';

class RoutingView extends StatelessWidget {
  const RoutingView({super.key});

  static const routeName = '/';

  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => const RoutingView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocBuilder<RoutingCubit, RoutingState>(
        buildWhen: (previous, current) =>
            previous.currentRoute != current.currentRoute,
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: getView(
              state.updatingState,
              state.currentRoute,
              () => context.read<RoutingCubit>().routingViewInit(),
              context,
            ),
          );
        },
      ),
    );
  }

  Widget getView(
    UpdatingState updatingState,
    CurrentRoute currentRoute,
    Function() reInit,
    BuildContext context,
  ) {
    if (updatingState == UpdatingState.progress) {
      return const SplashScreen(key: ValueKey<String>('splash'));
    } else if (updatingState == UpdatingState.idle) {
      return getViewSelection(currentRoute, context);
    } else if (updatingState == UpdatingState.networkFailure) {
      return NoInternetView(onClicked: reInit, isButtonEnabled: true);
    } else if (updatingState == UpdatingState.failure) {
      return WrongView(onClicked: reInit);
    } else {
      return const SplashScreen(key: ValueKey<String>('splash'));
    }
  }

  Widget getViewSelection(CurrentRoute routeState, BuildContext context) {
    if (routeState == CurrentRoute.logify) {
      return LogifyView(
        onPop: () {
          context.read<RoutingCubit>().setDisclosureView();
        },
      );
    } else if (routeState == CurrentRoute.disclosure) {
      return const DisclosureView();
    } else {
      return const MainView();
    }
  }
}
