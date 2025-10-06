// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../logic/logify_cubit/logify_cubit.dart';
import '../../utils/utils.dart';
import 'widgets/logify_views_page_builder.dart';

class LogifyView extends HookWidget {
  LogifyView({
    super.key,
    this.onPop,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Signin/Signup view');
  }

  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final logifySelection = useState(false);

    return BlocProvider(
      create: (context) => LogifyCubit(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColorLight,
                    Theme.of(context).primaryColorLight.withValues(alpha: 0.1),
                    Theme.of(context).primaryColorLight,
                  ],
                ),
                color: kScaffoldDark,
              ),
            ),
            LogifyViewPageBuilder(
              controller: pageController,
              logifySelection: logifySelection,
              onPop: onPop,
            ),
          ],
        ),
      ),
    );
  }
}
