import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';

enum PomProgressState { running, done, failed }

/// The single terminal view for both login paths — creating an account and
/// signing into an existing one. Both do different work, but the user only
/// needs to know what is happening now and whether it finished.
class PomProgressView extends StatelessWidget {
  const PomProgressView({
    super.key,
    required this.state,
    required this.title,
    required this.action,
    this.errorMsg = '',
    this.onRetry,
    this.onBack,
  });

  final PomProgressState state;

  /// Headline: what the app is doing overall.
  final String title;

  /// The step currently in flight, shown under the spinner.
  final String action;

  final String errorMsg;
  final VoidCallback? onRetry, onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = state == PomProgressState.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            height: 44,
            width: 44,
            child: Center(
              child: switch (state) {
                PomProgressState.running => SpinKitCircle(
                  color: theme.primaryColor,
                  size: 34,
                ),
                PomProgressState.done => AppIcon(
                  LucideIcons.circleCheckBig,
                  size: 34,
                  color: theme.primaryColor,
                ),
                PomProgressState.failed => const AppIcon(
                  LucideIcons.circleX,
                  size: 34,
                  color: kRed,
                ),
              },
            ),
          ),
        ),

        const SizedBox(height: kDefaultPadding / 1.5),
        Text(
          title,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            failed && errorMsg.isNotEmpty ? errorMsg : action,
            key: ValueKey(failed && errorMsg.isNotEmpty ? errorMsg : action),
            style: theme.textTheme.bodySmall?.copyWith(
              color: failed ? kRed : theme.hintColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (failed && (onRetry != null || onBack != null)) ...[
          const SizedBox(height: kDefaultPadding),
          Row(
            children: [
              if (onBack != null) ...[
                _BackButton(onTap: onBack!),
                const SizedBox(width: kDefaultPadding / 2),
              ],
              if (onRetry != null)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: onRetry,
                      child: Text(context.t.sub_retry),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: theme.cardColor,
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: const Center(child: AppIcon(LucideIcons.chevronLeft, size: 18)),
      ),
    );
  }
}
