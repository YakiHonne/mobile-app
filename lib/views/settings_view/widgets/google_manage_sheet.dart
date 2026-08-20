// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:bip340/bip340.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../../common/pomegranate/google_auth_webview.dart';
import '../../../common/pomegranate/pomegranate_config.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/modal_sheet_container.dart';

/// Rebuilds the private key from the shards held by the account's operators.
void showGoogleRecoverSheet(BuildContext context) {
  showAppModalSheet(
    context: context,
    backgroundColor: kTransparent,
    builder: (_) => const _GoogleManageSheet(initialPhase: _Phase.recover),
  );
}

/// [onDisconnect] runs after a successful unlink: the caller signs the user
/// out of that account, since a Google identity that no longer maps to any
/// central can only sign back in with the recovered secret key.
void showGoogleUnlinkSheet(
  BuildContext context, {
  required VoidCallback onDisconnect,
}) {
  showAppModalSheet(
    context: context,
    backgroundColor: kTransparent,
    builder: (_) => _GoogleManageSheet(
      initialPhase: _Phase.unlink,
      onDisconnect: onDisconnect,
    ),
  );
}

enum _Phase { recover, unlink }

class _GoogleManageSheet extends HookWidget {
  const _GoogleManageSheet({required this.initialPhase, this.onDisconnect});

  final _Phase initialPhase;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = useState(initialPhase);
    final busy = useState(false);
    final errorMsg = useState('');

    final central = settingsCubit.pomegranateSetup?.central ?? kPomCentralUrl;

    Future<void> runUnlink() async {
      errorMsg.value = '';
      busy.value = true;
      try {
        // Fresh OAuth: the stored token has likely expired, and DELETE
        // /account needs a live one. Deliberately without the account picker
        // — silently deleting a different account would be unrecoverable.
        final rawToken = await GoogleAuthWebView.show(
          context,
          '$central/login/google',
          GoogleAuthWebViewType.login,
        );
        if (rawToken == null || rawToken.isEmpty) {
          busy.value = false;
          return;
        }

        String tokenStr = rawToken;
        try {
          final decoded = jsonDecode(rawToken);
          if (decoded is Map && decoded['token'] != null) {
            tokenStr = decoded['token'] as String;
          }
        } catch (_) {}

        final parsedToken = parsePomToken(tokenStr);
        if (parsedToken == null || !isPomTokenValid(parsedToken)) {
          errorMsg.value = context.t.pomTokenExpired;
          busy.value = false;
          return;
        }

        // Before the account goes: the signer is that central's bunker, and
        // leaving the 16440 behind would keep offering this identity in the
        // login chooser long after it stopped existing.
        final signer = currentSigner;
        if (signer != null) {
          await pomDeleteSetup(
            nc: nc,
            publishEvent: pomPublishEvent,
            signer: signer,
            onError: pomLogError,
          );
        }

        final ok = await pomDeleteAccount(pomGetDio, central, parsedToken);
        busy.value = false;
        if (!ok) {
          errorMsg.value = context.t.pomUnlinkFailed;
          return;
        }

        BotToastUtils.showSuccess(context.t.pomUnlinkSuccess);
        if (context.mounted) {
          Navigator.of(context).pop();
          onDisconnect?.call();
        }
      } catch (e) {
        busy.value = false;
        errorMsg.value = e.toString().replaceFirst('Exception: ', '');
      }
    }

    void confirmUnlink() {
      showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(context.t.pomUnlinkConfirmTitle),
          content: Text(
            context.t.pomUnlinkConfirmDesc(host: Uri.parse(central).host),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                context.t.cancel,
                style: TextStyle(color: theme.primaryColorDark),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(context.t.pomUnlinkConfirmAction),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed ?? false) {
          runUnlink();
        }
      });
    }

    Widget buildHeader(String title, String desc) {
      return Row(
        children: [
          GestureDetector(
            onTap: () {
              errorMsg.value = '';
              Navigator.of(context).pop();
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(kDefaultPadding / 4),
              child: AppIcon(LucideIcons.chevronLeft, size: 20),
            ),
          ),
          const SizedBox(width: kDefaultPadding / 4),
          FluidBlurContainer(
            blur: false,
            borderRadius: kDefaultPadding / 1.5,
            backgroundAlpha: 0.4,
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: SvgPicture.asset(
              FeatureIcons.google,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: kDefaultPadding / 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  desc,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildBody() {
      if (phase.value == _Phase.recover) {
        return const _RecoveryPanel();
      }

      // Unlink: the key must be recovered and copied before the account can
      // be removed — afterwards it is the only way back in.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              _RecoveryPanel(gateOnCopy: true, onContinue: confirmUnlink),
              // Overlay, not a swap, so a failed DELETE keeps the recovered
              // key in the panel instead of forcing a full re-collection.
              if (busy.value)
                Positioned.fill(
                  child: ColoredBox(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitCircle(color: theme.primaryColor, size: 28),
                        const SizedBox(height: kDefaultPadding / 2),
                        Text(
                          context.t.pomUnlinkProgress,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (errorMsg.value.isNotEmpty) ...[
            const SizedBox(height: kDefaultPadding / 2),
            Text(
              errorMsg.value,
              style: theme.textTheme.bodySmall?.copyWith(color: kRed),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: media.size.height * 0.9 - media.padding.top,
      ),
      child: ModalSheetContainer(
        padding: EdgeInsets.only(
          left: kDefaultPadding,
          right: kDefaultPadding,
          top: kDefaultPadding / 2,
          bottom: media.viewInsets.bottom + kDefaultPadding,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: kDefaultPadding),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              buildHeader(
                switch (phase.value) {
                  _Phase.recover => context.t.pomRecoverTitle,
                  _Phase.unlink => context.t.pomUnlinkTitle,
                },
                switch (phase.value) {
                  _Phase.recover => context.t.googleManageRecoverDesc,
                  _Phase.unlink => context.t.googleManageUnlinkDesc,
                },
              ),
              const SizedBox(height: kDefaultPadding),
              Flexible(child: SingleChildScrollView(child: buildBody())),
              const SizedBox(height: kDefaultPadding / 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collects shards from the account's operators and reconstructs the secret
/// key. In unlink mode the key is shown for copying and [onContinue] only
/// unlocks once it has been copied.
class _RecoveryPanel extends HookWidget {
  const _RecoveryPanel({this.gateOnCopy = false, this.onContinue});

  final bool gateOnCopy;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    // The account's own operator set. Registrations vary by client (2-of-3 is
    // common, ours included), so recomputing a threshold here would ask for
    // shards from servers that never held any.
    //
    // Accounts created before the setup was persisted have none: offer every
    // operator we know of and let the user collect until interpolation
    // succeeds, rather than guessing a threshold that may be wrong.
    final setup = settingsCubit.pomegranateSetup;
    // Union with the retired operators: accounts predating persisted setups
    // hold shards on servers the shared list no longer offers.
    final operators = setup?.operators ?? kPomRecoveryOperatorUrls;
    final threshold = setup?.threshold ?? kPomDefaultThreshold;
    final isThresholdKnown = setup != null;

    final theme = Theme.of(context);
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

        if (shardHex == null || shardHex.isEmpty) {
          recovering.value = {...recovering.value}..remove(operator);
          return;
        }

        // Operator may send a JSON envelope like {"shard":"hex..."} instead of
        // raw hex.
        String rawHex = shardHex;
        try {
          final decoded = jsonDecode(shardHex);
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

          // With an unknown threshold the count above is a guess, so the only
          // proof we reconstructed the right key is that it derives the
          // account's pubkey. Too few shards yields a wrong key, not an error.
          if (isThresholdKnown ||
              getPublicKey(secretHex) == settingsCubit.key) {
            recoveredNsec.value = Nip19.encodePrivkey(secretHex);
          }
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
      BotToastUtils.showSuccess(context.t.pomKeyCopied);
      isCopied.value = true;
    }

    if (!isComplete) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (gateOnCopy) ...[
            Text(
              context.t.pomUnlinkIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: kDefaultPadding / 2),
          ],
          FluidBlurContainer(
            blur: false,
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
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: collected >= threshold
                        ? theme.primaryColor
                        : theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kDefaultPadding / 1.5),
          ...operators.map((op) {
            final host = Uri.parse(op).host;
            final hasShard = shards.value.containsKey(op);
            final isLoading = recovering.value.contains(op);
            final error = errors.value[op];

            return Padding(
              padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
              child: FluidBlurContainer(
                blur: false,
                borderRadius: kDefaultPadding,
                backgroundAlpha: hasShard ? 0.45 : 0.25,
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                  vertical: kDefaultPadding * 0.7,
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: hasShard
                          ? AppIcon(
                              LucideIcons.circleCheckBig,
                              key: const ValueKey('check'),
                              color: theme.primaryColor,
                              size: 20,
                            )
                          : isLoading
                              ? SpinKitCircle(
                                  key: const ValueKey('spin'),
                                  color: theme.primaryColor,
                                  size: 20,
                                )
                              : AppIcon(
                                  LucideIcons.shield,
                                  key: const ValueKey('shield'),
                                  color: theme.hintColor,
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
                            style: theme.textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (error != null)
                            Text(
                              error,
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: kRed,
                              ),
                            )
                          else if (hasShard)
                            Text(
                              context.t.pomShardCollected,
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!hasShard && !isLoading)
                      GestureDetector(
                        onTap: () => handleRecover(op),
                        child: FluidBlurContainer(
                          blur: false,
                          backgroundAlpha: 0.4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding,
                            vertical: kDefaultPadding / 3,
                          ),
                          child: Text(
                            context.t.pomRecoverShard,
                            style: theme.textTheme.labelMedium!.copyWith(
                              color: theme.primaryColor,
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
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FluidBlurContainer(
          blur: false,
          borderRadius: kDefaultPadding,
          backgroundAlpha: 0.35,
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    LucideIcons.circleCheckBig,
                    color: theme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: kDefaultPadding / 2),
                  Text(
                    context.t.pomRecoverSuccess,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding / 1.5),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
                  color: theme.cardColor,
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 1.5,
                  vertical: kDefaultPadding / 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        recoveredNsec.value!,
                        style: theme.textTheme.labelSmall!.copyWith(
                          height: 1.6,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding / 2),
                    GestureDetector(
                      onTap: handleCopy,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: AppIcon(
                          isCopied.value ? LucideIcons.check : LucideIcons.copy,
                          key: ValueKey(isCopied.value),
                          size: 18,
                          color: isCopied.value
                              ? theme.primaryColor
                              : theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (gateOnCopy && onContinue != null) ...[
          const SizedBox(height: kDefaultPadding / 1.5),
          // The fluid theme paints its fill regardless of the disabled state,
          // so fade the whole button until the key has been copied rather
          // than recolor it.
          Opacity(
            opacity: isCopied.value ? 1 : 0.4,
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: isCopied.value ? onContinue : null,
                child: Text(context.t.pomUnlinkContinue),
              ),
            ),
          ),
        ],
      ],
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
