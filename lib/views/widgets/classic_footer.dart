import 'package:flutter/material.dart';
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
      noMoreIcon: const Icon(
        Icons.data_object_rounded,
        color: kMainColor,
        size: 15,
      ),
      completeDuration: const Duration(milliseconds: 500),
      loadingText: context.t.loading.capitalizeFirst(),
      canLoadingText: context.t.releaseToLoad.capitalizeFirst(),
      idleText: context.t.finished.capitalizeFirst(),
      noDataText: context.t.noMoreData.capitalizeFirst(),
      idleIcon: const Icon(
        Icons.done,
        color: kMainColor,
        size: 15,
      ),
      loadingIcon: const SizedBox(
        height: 15.0,
        width: 15.0,
        child: CircularProgressIndicator(
          color: kMainColor,
          strokeWidth: 1,
        ),
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
      completeIcon: const Icon(
        Icons.done,
        color: kMainColor,
        size: 15,
      ),
      refreshingText: context.t.refreshing.capitalizeFirst(),
      idleText: context.t.pullToRefresh.capitalizeFirst(),
      idleIcon: const Icon(
        Icons.arrow_downward_rounded,
        color: kMainColor,
        size: 15,
      ),
    );
  }
}
