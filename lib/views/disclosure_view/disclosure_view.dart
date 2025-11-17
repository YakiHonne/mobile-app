import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/crashlytics_cubit/crashlytics_cubit.dart';
import '../../logic/routing_cubit/routing_cubit.dart';
import '../../utils/utils.dart';
import 'widgets/set_anaytics_status.dart';

class DisclosureView extends StatelessWidget {
  const DisclosureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        height: kBottomNavigationBarHeight,
        color: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        child: BlocBuilder<CrashlyticsCubit, CrashlyticsState>(
          builder: (context, state) {
            return RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.labelSmall,
                children: [
                  TextSpan(
                    text: state.isCrashlyticsEnabled
                        ? '${context.t.collectAnonymised.capitalizeFirst()} '
                        : '${context.t.shareNoUsage.capitalizeFirst()} ',
                  ),
                  TextSpan(
                    text: context.t.wantShareAnalytics.capitalizeFirst(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showModalBottomSheet(
                          context: context,
                          elevation: 0,
                          builder: (_) {
                            return BlocProvider.value(
                              value: context.read<CrashlyticsCubit>(),
                              child: const SetAnalyticsStatus(),
                            );
                          },
                          useRootNavigator: true,
                          useSafeArea: true,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  LogosIcons.logoMarkPurple,
                  width: 50,
                  height: 50,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  context.t.yakihonneNote.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding / 2),
                Text(
                  context.t.privacyNote.capitalizeFirst(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: kDefaultPadding),
                BlocBuilder<CrashlyticsCubit, CrashlyticsState>(
                  builder: (context, state) {
                    return TextButton(
                      onPressed: context.read<RoutingCubit>().setMainView,
                      child: const Text('Proceed'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
