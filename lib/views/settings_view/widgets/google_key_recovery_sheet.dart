// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../../common/pomegranate/google_auth_webview.dart';
import '../../../common/pomegranate/pomegranate_crypto.dart';
import '../../../common/pomegranate/pomegranate_helpers.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/modal_sheet_container.dart';

void showGoogleKeyRecoverySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kTransparent,
    builder: (_) => const GoogleKeyRecoverySheet(),
  );
}

class GoogleKeyRecoverySheet extends HookWidget {
  const GoogleKeyRecoverySheet({super.key});

  @override
  Widget build(BuildContext context) {
    const operators = kPomOperatorUrls;
    final threshold = pomThreshold(operators.length);

    final shards = useState<Map<String, String>>({});
    final recovering = useState<Set<String>>({});
    final errors = useState<Map<String, String>>({});
    final recoveredNsec = useState<String?>(null);
    final isCopied = useState(false);

    final collected = shards.value.length;
    final isComplete = recoveredNsec.value != null;

    Future<void> handleRecover(String operator) async {
      recovering.value = {...recovering.value, operator};
      errors.value = {...errors.value}..remove(operator);

      try {
        final shardHex = await GoogleAuthWebView.show(
          context,
          '$operator/po/recover/google',
          GoogleAuthWebViewType.recovery,
        );

        lg.i(shardHex);

        if (shardHex == null || shardHex.isEmpty) {
          recovering.value = {...recovering.value}..remove(operator);
          return;
        }

        // Operator may send a JSON envelope like {"shard":"hex..."} instead of raw hex.
        String rawHex = shardHex;
        try {
          final decoded = jsonDecode(shardHex);
          lg.i(decoded);
          if (decoded is Map) {
            rawHex = (decoded['shard'] ??
                    decoded['data'] ??
                    decoded['hex'] ??
                    shardHex)
                .toString();
          } else if (decoded is String) {
            rawHex = decoded;
          }
        } catch (_) {}
        rawHex = rawHex.trim();

        final newShards = {...shards.value, operator: rawHex};
        shards.value = newShards;

        if (newShards.length >= threshold) {
          final parsedShards =
              newShards.values.map(pomKeyShardFromHex).toList();
          final secret = pomAggregateShards(parsedShards);
          final secretHex = bigIntToBytes32(secret)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          recoveredNsec.value = Nip19.encodePrivkey(secretHex);
        }
      } catch (e) {
        errors.value = {
          ...errors.value,
          operator: e.toString().replaceFirst('Exception: ', ''),
        };
      } finally {
        recovering.value = {...recovering.value}..remove(operator);
      }
    }

    void handleCopy() {
      Clipboard.setData(ClipboardData(text: recoveredNsec.value!));
      BotToastUtils.showSuccess(context.t.textSuccesfulyCopied);
      isCopied.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          isCopied.value = false;
        }
      });
    }

    return ModalSheetContainer(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: kDefaultPadding,
            right: kDefaultPadding,
            top: kDefaultPadding,
            bottom: MediaQuery.of(context).viewInsets.bottom + kDefaultPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: kDefaultPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  FluidBlurContainer(
                    borderRadius: kDefaultPadding / 1.5,
                    backgroundAlpha: 0.4,
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    child: Text(
                      'G',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: const Color(0xFF4285F4),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding / 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t.pomRecoverTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          context.t.pomRecoverDesc(
                            threshold: threshold,
                            total: operators.length,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall!
                              .copyWith(
                                  color: Theme.of(context).highlightColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: kDefaultPadding),

              if (!isComplete) ...[
                // Progress indicator
                FluidBlurContainer(
                  borderRadius: kDefaultPadding,
                  backgroundAlpha: 0.3,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding / 1.5,
                  ),
                  child: Row(
                    children: [
                      _ProgressDots(collected: collected, total: threshold),
                      const Spacer(),
                      Text(
                        context.t.pomShardsProgress(
                          collected: collected,
                          threshold: threshold,
                        ),
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: collected >= threshold
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).highlightColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: kDefaultPadding / 1.5),

                // Operator list
                ...operators.map((op) {
                  final host = Uri.parse(op).host;
                  final hasShard = shards.value.containsKey(op);
                  final isLoading = recovering.value.contains(op);
                  final error = errors.value[op];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
                    child: FluidBlurContainer(
                      borderRadius: kDefaultPadding,
                      backgroundAlpha: hasShard ? 0.45 : 0.25,
                      borderColor: hasShard
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.6)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding * 0.7,
                      ),
                      child: Row(
                        children: [
                          // Status icon
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: hasShard
                                ? Icon(
                                    LucideIcons.circleCheck,
                                    key: const ValueKey('check'),
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  )
                                : isLoading
                                    ? SpinKitCircle(
                                        key: const ValueKey('spin'),
                                        color: Theme.of(context).primaryColor,
                                        size: 20,
                                      )
                                    : Icon(
                                        LucideIcons.shield,
                                        key: const ValueKey('shield'),
                                        color: Theme.of(context).highlightColor,
                                        size: 20,
                                      ),
                          ),
                          const SizedBox(width: kDefaultPadding / 1.5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  host,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (error != null)
                                  Text(
                                    error,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(color: kRed),
                                  )
                                else if (hasShard)
                                  Text(
                                    context.t.pomShardCollected,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          if (!hasShard && !isLoading)
                            GestureDetector(
                              onTap: () => handleRecover(op),
                              child: FluidBlurContainer(
                                backgroundAlpha: 0.4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kDefaultPadding,
                                  vertical: kDefaultPadding / 3,
                                ),
                                child: Text(
                                  context.t.pomRecoverShard,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                // Success state
                FluidBlurContainer(
                  borderRadius: kDefaultPadding,
                  backgroundAlpha: 0.35,
                  borderColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.circleCheck,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: kDefaultPadding / 2),
                          Text(
                            context.t.pomRecoverSuccess,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kDefaultPadding / 1.5),
                      FluidBlurContainer(
                        borderRadius: kDefaultPadding / 1.5,
                        blur: false,
                        backgroundAlpha: 0.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 1.5,
                          vertical: kDefaultPadding / 2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                recoveredNsec.value!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      fontFamily: 'monospace',
                                      height: 1.6,
                                      color: Theme.of(context).highlightColor,
                                    ),
                              ),
                            ),
                            const SizedBox(width: kDefaultPadding / 2),
                            GestureDetector(
                              onTap: handleCopy,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isCopied.value
                                      ? LucideIcons.check
                                      : LucideIcons.copy,
                                  key: ValueKey(isCopied.value),
                                  size: 18,
                                  color: isCopied.value
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).highlightColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: kDefaultPadding / 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.collected, required this.total});

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final done = i < collected;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: done ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: done
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
          ),
        );
      }),
    );
  }
}
