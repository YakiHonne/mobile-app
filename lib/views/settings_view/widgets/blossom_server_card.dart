import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../logic/blossom_cubit/blossom_state.dart';
import '../../../logic/media_servers_cubit/media_servers_cubit.dart';
import '../../../logic/subscription_cubit/subscription_cubit.dart';
import '../../../repositories/blossom_repository.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../subscription_view/pricing/pricing_screen.dart';
import '../../widgets/app_icon.dart';

const _kMb = 1024 * 1024;
const _kGb = 1024 * _kMb;

/// Storage counts as full — and the upgrade prompt appears — from this ratio on.
const _kFullRatio = 0.95;

// ponytail: tier quotas hardcoded; read them from /api/v1/usage once it
// exposes a storage key (UsageItem already carries limit/percentage).
// Free and trial accounts share the 500 MB allowance — `plan` alone doesn't
// say that, since a non-subscriber still reads as 'basic'.
int _quotaBytes(String plan, bool isActivePaidSub) {
  if (!isActivePaidSub) {
    return 500 * _kMb;
  }
  return _isTopTier(plan) ? 100 * _kGb : 50 * _kGb;
}

bool _isTopTier(String plan) => plan.toLowerCase() == 'premium';

String formatMediaBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
}

/// Always-on card for the YakiHonne Blossom server: storage consumption for
/// the user's plan, plus the add / upgrade actions when they apply.
class YakiBlossomBanner extends StatefulWidget {
  const YakiBlossomBanner({super.key, required this.state});

  final BlossomState state;

  @override
  State<YakiBlossomBanner> createState() => _YakiBlossomBannerState();
}

class _YakiBlossomBannerState extends State<YakiBlossomBanner> {
  bool _isAdding = false;

  String get _host => Uri.parse(yakiProBlossomServer).host;

  /// Null until the first measurement lands.
  int? _consumed;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  @override
  void didUpdateWidget(YakiBlossomBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An upload or a delete replaces the list; re-measure once it settles.
    if (oldWidget.state.isLoading && !widget.state.isLoading) {
      _loadUsage();
    }
  }

  /// Asks our server directly instead of summing [BlossomState.allMedia]: that
  /// list only holds servers the user has added, and is narrowed further by the
  /// filter row — either way it would read as "0 B used".
  Future<void> _loadUsage() async {
    // A declined signature or a failed list reads as "nothing stored" rather
    // than leaving the card on a permanent spinner.
    var used = 0;

    final auth = await blossomAuthEvent('list');
    if (auth != null) {
      final items = await BlossomRepository().fetchMediaList(
        serverUrl: yakiProBlossomServer,
        pubkey: currentSigner!.getPublicKey(),
        authEvent: auth,
      );
      used = items.fold<int>(0, (sum, m) => sum + m.size);
    }

    if (!mounted) {
      return;
    }

    setState(() => _consumed = used);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      builder: (context, subState) {
        return BlocBuilder<MediaServersCubit, MediaServersState>(
          bloc: mediaServersCubit,
          builder: (context, _) {
            final status = subState.subscriptionStatus;
            final consumed = _consumed;
            // Only the usage blocks the card: a status that never lands falls
            // back to the basic-tier quota rather than spinning forever.
            final isLoading = consumed == null;
            final plan = status?.plan ?? '';
            final isActivePaidSub = status?.isActivePaidSub ?? false;
            final quota = _quotaBytes(plan, isActivePaidSub);
            final ratio = ((consumed ?? 0) / quota).clamp(0.0, 1.0);
            final isFull = !isLoading && ratio >= _kFullRatio;

            // Only once the allowance runs out — free/trial at 500 MB, Basic
            // at 50 GB — and never on the top tier, which has nothing above it.
            final showUpgrade = isFull && !_isTopTier(plan);
            final showAdd = !mediaServersCubit.hasYakiProBlossomServer;

            return BlossomServerCard(
              host: _host,
              consumed: consumed ?? 0,
              quota: quota,
              isLoading: isLoading,
              showAdd: showAdd,
              showUpgrade: showUpgrade,
              isAdding: _isAdding,
              onAdd: _add,
              onUpgrade: () => YNavigator.pushPage(
                context,
                (_) => const PricingScreen(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _add() async {
    setState(() => _isAdding = true);
    await mediaServersCubit.addYakiProBlossomServer();
    if (mounted) {
      setState(() => _isAdding = false);
    }
  }
}

/// Presentation half of [YakiBlossomBanner]; state-free so the display cases
/// can be rendered on their own.
class BlossomServerCard extends StatelessWidget {
  const BlossomServerCard({
    super.key,
    required this.host,
    required this.consumed,
    required this.quota,
    required this.isLoading,
    required this.showAdd,
    required this.showUpgrade,
    this.isAdding = false,
    this.onAdd,
    this.onUpgrade,
  });

  final String host;
  final int consumed;
  final int quota;
  final bool isLoading;
  final bool showAdd;
  final bool showUpgrade;
  final bool isAdding;
  final VoidCallback? onAdd;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (consumed / quota).clamp(0.0, 1.0);
    final isFull = !isLoading && ratio >= _kFullRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 4,
      ),
      child: _GlowBorder(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    LucideIcons.crown,
                    size: 18,
                    color: theme.primaryColorDark,
                  ),
                  const SizedBox(width: kDefaultPadding / 4),
                  Expanded(
                    child: Text(
                      host,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding / 2),
              if (isLoading)
                SpinKitCircle(size: 18, color: theme.primaryColor)
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation(
                      isFull ? kMainColor2 : theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 4),
                Row(
                  children: [
                    Text(
                      formatMediaBytes(consumed),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' / ${formatMediaBytes(quota)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.highlightColor,
                      ),
                    ),
                    if (isFull) ...[
                      const SizedBox(width: kDefaultPadding / 2),
                      Text(
                        context.t.usage_limit_reached_short,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: kMainColor2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (showAdd || showUpgrade) ...[
                const SizedBox(height: kDefaultPadding / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showUpgrade)
                      Expanded(
                        child: TextButton(
                          onPressed: onUpgrade,
                          child: Text(context.t.usage_upgrade),
                        ),
                      ),
                    if (showAdd && showUpgrade)
                      const SizedBox(width: kDefaultPadding / 4),
                    if (showAdd)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: isAdding ? null : onAdd,
                          // Secondary next to Upgrade, which keeps the themed
                          // orange fill.
                          style: TextButton.styleFrom(
                            backgroundColor: theme.dividerColor,
                            foregroundColor: theme.primaryColorDark,
                          ),
                          icon: const AppIcon(LucideIcons.plus, size: 16),
                          label: Text(context.t.media_yakipro_server_action),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Transparent card with a slowly rotating gradient glow around its edge.
class _GlowBorder extends StatefulWidget {
  const _GlowBorder({required this.child});

  final Widget child;

  @override
  State<_GlowBorder> createState() => _GlowBorderState();
}

class _GlowBorderState extends State<_GlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(painter: _GlowPainter(_controller.value), child: child),
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(kDefaultPadding / 2),
    );
    final shader = SweepGradient(
      colors: const [kMainColor, kMainColor1, kMainColor5, kMainColor],
      transform: GradientRotation(t * 2 * pi),
    ).createShader(rect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => oldDelegate.t != t;
}
