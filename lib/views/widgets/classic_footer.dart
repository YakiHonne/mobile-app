import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../utils/utils.dart';

class RefresherClassicFooter extends StatelessWidget {
  const RefresherClassicFooter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClassicFooter(
      loadStyle: LoadStyle.ShowWhenLoading,
      noMoreIcon: Icon(
        LucideIcons.braces,
        color: Theme.of(context).primaryColor,
        size: 15,
      ),
      completeDuration: const Duration(milliseconds: 500),
      loadingText: context.t.loading.capitalizeFirst(),
      canLoadingText: context.t.releaseToLoad.capitalizeFirst(),
      idleText: context.t.finished.capitalizeFirst(),
      noDataText: context.t.noMoreData.capitalizeFirst(),
      idleIcon: Icon(
        LucideIcons.check,
        color: Theme.of(context).primaryColor,
        size: 15,
      ),
      loadingIcon: SpinKitCircle(
        color: Theme.of(context).primaryColor,
        size: 15,
      ),
    );
  }
}

class RefresherClassicHeader extends StatelessWidget {
  const RefresherClassicHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClassicHeader(
      height: 50,
      textStyle: Theme.of(context).textTheme.labelMedium!,
      completeDuration: const Duration(milliseconds: 500),
      completeText: context.t.refreshed.capitalizeFirst(),
      completeIcon: Icon(
        LucideIcons.check,
        color: Theme.of(context).primaryColor,
        size: 15,
      ),
      refreshingText: context.t.refreshing.capitalizeFirst(),
      idleText: context.t.pullToRefresh.capitalizeFirst(),
      idleIcon: Icon(
        LucideIcons.arrowDown,
        color: Theme.of(context).primaryColor,
        size: 15,
      ),
    );
  }
}
