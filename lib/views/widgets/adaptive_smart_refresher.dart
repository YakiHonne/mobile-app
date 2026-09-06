import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../utils/platform_utils.dart';

const double _kLoadMoreThreshold = 400;

bool shouldLoadMore({
  required double pixels,
  required double maxScrollExtent,
  required LoadStatus? status,
  required int depth,
  required Axis axis,
}) {
  if (depth != 0 || axis != Axis.vertical) {
    return false;
  }
  if (maxScrollExtent <= 0) {
    return false;
  }
  if (status == LoadStatus.loading || status == LoadStatus.noMore) {
    return false;
  }
  return pixels >= maxScrollExtent - _kLoadMoreThreshold;
}

class AdaptiveSmartRefresher extends StatelessWidget {
  const AdaptiveSmartRefresher({
    super.key,
    required this.controller,
    required this.child,
    this.scrollController,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.header,
    this.footer,
    this.onRefresh,
    this.onLoading,
  });

  final RefreshController controller;
  final Widget child;
  final ScrollController? scrollController;
  final bool enablePullDown;
  final bool enablePullUp;
  final Widget? header;
  final Widget? footer;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoading;

  @override
  Widget build(BuildContext context) {
    final refresher = SmartRefresher(
      controller: controller,
      scrollController: scrollController,
      enablePullDown: enablePullDown,
      enablePullUp: enablePullUp,
      header: header,
      footer: footer,
      onRefresh: onRefresh,
      onLoading: onLoading,
      child: child,
    );

    if (!isDesktopPlatform || !enablePullUp || onLoading == null) {
      return refresher;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is! ScrollUpdateNotification &&
            notification is! ScrollEndNotification) {
          return false;
        }

        if (shouldLoadMore(
          pixels: notification.metrics.pixels,
          maxScrollExtent: notification.metrics.maxScrollExtent,
          status: controller.footerStatus,
          depth: notification.depth,
          axis: notification.metrics.axis,
        )) {
          // ponytail: needs page one to overflow the window to ever trigger;
          // fine for feeds, a visible "load more" button is the fix if a
          // short filtered list ever needs it.
          // Driving footerMode straight to `loading` fires the footer
          // indicator's listener, which calls onLoading — synchronously, so a
          // second notification in the same frame sees `loading` and bails.
          controller.footerMode?.value = LoadStatus.loading;
        }

        return false;
      },
      child: refresher,
    );
  }
}
