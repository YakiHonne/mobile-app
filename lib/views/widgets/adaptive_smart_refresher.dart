import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../i18n/translations/translations.g.dart';
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
  if (status != LoadStatus.idle) {
    return false;
  }
  return pixels >= maxScrollExtent - _kLoadMoreThreshold;
}

class AdaptiveSmartRefresher extends StatefulWidget {
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
    this.showDesktopRefresh = true,
    this.desktopHasResults = false,
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
  final bool showDesktopRefresh;

  /// Whether the current feed has completed loading with at least one result.
  final bool desktopHasResults;

  @override
  State<AdaptiveSmartRefresher> createState() => _AdaptiveSmartRefresherState();
}

class _AdaptiveSmartRefresherState extends State<AdaptiveSmartRefresher> {
  bool _shortList = false;
  bool? _pendingShortList;
  bool _loadScheduled = false;

  @override
  void initState() {
    super.initState();
    if (isDesktopPlatform) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller.position != null) {
          _updateExtent(widget.controller.position!);
        }
      });
    }
  }

  void _updateExtent(ScrollMetrics metrics) {
    final shortList = metrics.maxScrollExtent <= 0;
    if (shortList == _pendingShortList ||
        (_pendingShortList == null && shortList == _shortList)) {
      return;
    }
    _pendingShortList = shortList;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pendingShortList != null) {
        final next = _pendingShortList!;
        _pendingShortList = null;
        if (next != _shortList) {
          setState(() => _shortList = next);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final onRefresh = widget.onRefresh;
    final onLoading = widget.onLoading;
    final enablePullUp = widget.enablePullUp;
    final refresher = SmartRefresher(
      controller: controller,
      scrollController: widget.scrollController,
      enablePullDown:
          widget.enablePullDown || (isDesktopPlatform && onRefresh != null),
      enablePullUp: enablePullUp,
      header: widget.header,
      footer: widget.footer,
      onRefresh: onRefresh,
      onLoading: onLoading,
      child: widget.child,
    );

    if (!isDesktopPlatform) {
      return refresher;
    }

    final scrollable = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            notification.metrics.axis == Axis.vertical) {
          _updateExtent(notification.metrics);
        }
        if (notification is! ScrollUpdateNotification &&
            notification is! ScrollEndNotification) {
          return false;
        }

        if (enablePullUp &&
            onLoading != null &&
            !controller.isRefresh &&
            shouldLoadMore(
              pixels: notification.metrics.pixels,
              maxScrollExtent: notification.metrics.maxScrollExtent,
              status: controller.footerStatus,
              depth: notification.depth,
              axis: notification.metrics.axis,
            )) {
          if (!_loadScheduled) {
            _loadScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadScheduled = false;
              if (mounted &&
                  identical(widget.controller, controller) &&
                  widget.enablePullUp &&
                  widget.onLoading != null &&
                  !widget.controller.isRefresh &&
                  widget.controller.footerStatus == LoadStatus.idle) {
                widget.controller.footerMode?.value = LoadStatus.loading;
              }
            });
            WidgetsBinding.instance.ensureVisualUpdate();
          }
        }

        return false;
      },
      child: refresher,
    );

    if (onRefresh == null && (!enablePullUp || onLoading == null)) {
      return scrollable;
    }

    return AnimatedBuilder(
      animation:
          Listenable.merge([controller.headerMode, controller.footerMode]),
      builder: (context, _) {
        final loading = controller.isLoading;
        final refreshing = controller.isRefresh;
        final status = controller.footerStatus;
        final showLoadControl = enablePullUp &&
            onLoading != null &&
            widget.desktopHasResults &&
            !loading &&
            !refreshing &&
            status != LoadStatus.noMore &&
            _shortList;
        return Column(
          children: [
            if (onRefresh != null && widget.showDesktopRefresh)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: DesktopRefreshButton(controller: controller),
              ),
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  if (notification.depth == 0 &&
                      notification.metrics.axis == Axis.vertical) {
                    _updateExtent(notification.metrics);
                  }
                  return false;
                },
                child: Stack(
                  children: [
                    Positioned.fill(child: scrollable),
                    if (showLoadControl)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          color: Theme.of(context).cardColor,
                          child: TextButton.icon(
                            onPressed: refreshing ||
                                    loading ||
                                    status == LoadStatus.noMore
                                ? null
                                : () => controller.footerMode?.value =
                                    LoadStatus.loading,
                            icon: const Icon(LucideIcons.chevronDown),
                            label: Text(
                              status == LoadStatus.noMore
                                  ? context.t.noMoreData
                                  : status == LoadStatus.failed
                                      ? context.t.retry
                                      : status == LoadStatus.loading
                                          ? context.t.loading
                                          : context.t.loadMore,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Refresh control shared by feed headers and the generic desktop fallback.
class DesktopRefreshButton extends StatelessWidget {
  const DesktopRefreshButton({
    super.key,
    required this.controller,
    this.compact = false,
  });

  final RefreshController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([controller.headerMode, controller.footerMode]),
      builder: (context, _) => IconButton(
        tooltip: context.t.refresh,
        iconSize: compact ? 20 : null,
        padding: compact ? EdgeInsets.zero : null,
        color: compact ? Theme.of(context).primaryColorDark : null,
        style: compact
            ? IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.comfortable,
              )
            : null,
        icon: const Icon(LucideIcons.refreshCw),
        onPressed: controller.isRefresh || controller.isLoading
            ? null
            : () {
                controller.resetNoData();
                controller.headerMode?.value = RefreshStatus.refreshing;
              },
      ),
    );
  }
}
