import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../utils/utils.dart';
import 'fluid_scaffold.dart';

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
    this.additionalOffset = 0,
  });

  /// Extra paint offset for fixed controls sitting between the glass app bar
  /// and the scrollable content, such as the main feed filter row.
  final double additionalOffset;

  @override
  Widget build(BuildContext context) {
    return _OffsetClassicHeader(
      // `offset` changes only the header's paint position, so it clears the
      // glass app bar without adding space to the scrollable or moving data.
      headerOffset: isFluid()
          ? fluidScaffoldTopInset(context) + additionalOffset
          : 0,
      textStyle: Theme.of(context).textTheme.labelMedium!,
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

class _OffsetClassicHeader extends ClassicHeader {
  // ClassicHeader keeps its visual and state behavior but does not forward
  // RefreshIndicator.offset, so expose the inherited paint offset here.
  const _OffsetClassicHeader({
    required double headerOffset,
    required super.textStyle,
    required super.completeText,
    required super.completeIcon,
    required super.refreshingText,
    required super.idleText,
    required super.idleIcon,
  })  : _headerOffset = headerOffset,
        super(
          height: 50,
          completeDuration: const Duration(milliseconds: 500),
        );

  final double _headerOffset;

  @override
  double get offset => _headerOffset;
}
