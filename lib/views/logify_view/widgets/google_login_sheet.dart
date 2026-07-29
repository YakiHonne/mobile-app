// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:uuid/uuid.dart';

import '../../../common/pomegranate/google_auth_webview.dart';
import '../../../common/pomegranate/pomegranate_crypto.dart';
import '../../../common/pomegranate/pomegranate_helpers.dart';
import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/modal_sheet_container.dart';

enum _Phase { intro, setup }

enum _Status { idle, authenticating, checking, creating }

void showGoogleLoginSheet(
  BuildContext context, {
  required Function() onSuccess,
}) {
  final cubit = context.read<LogifyCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kTransparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: GoogleLoginSheet(onSuccess: onSuccess),
    ),
  );
}

class GoogleLoginSheet extends HookWidget {
  const GoogleLoginSheet({super.key, required this.onSuccess});

  final Function() onSuccess;

  @override
  Widget build(BuildContext context) {
    final phase = useState(_Phase.intro);
    final status = useState(_Status.idle);
    final errorMsg = useState('');
    final token = useState<PomToken?>(null);
    final nsec = useState('');
    final secretKeyHex = useState('');
    final isCopied = useState(false);

    final busy = status.value != _Status.idle;

    final statusLabel = {
          _Status.authenticating: context.t.pomAuthenticating,
          _Status.checking: context.t.pomCheckingAccount,
          _Status.creating: context.t.pomCreatingAccount,
        }[status.value] ??
        '';

    Future<void> handleStart() async {
      errorMsg.value = '';
      status.value = _Status.authenticating;
      try {
        const central = kPomCentralUrl;
        final rawToken = await GoogleAuthWebView.show(
          context,
          '$central/login/google',
          GoogleAuthWebViewType.login,
        );

        if (rawToken == null || rawToken.isEmpty) {
          status.value = _Status.idle;
          return;
        }

        // Parse the token (may be JSON-encoded from the postMessage)
        String tokenStr = rawToken;
        try {
          final decoded = jsonDecodeToken(rawToken);
          if (decoded is Map && decoded['token'] != null) {
            tokenStr = decoded['token'] as String;
          }
        } catch (_) {}

        final parsedToken = parsePomToken(tokenStr);
        if (parsedToken == null || !isPomTokenValid(parsedToken)) {
          errorMsg.value = context.t.pomTokenExpired;
          status.value = _Status.idle;
          return;
        }
        token.value = parsedToken;
        status.value = _Status.checking;

        final account = await pomGetAccount(central, parsedToken);

        if (account != null) {
          // Existing account — find/create default profile and login via bunker
          List<dynamic> profiles = await pomListProfiles(central, parsedToken);
          if (!profiles.any((p) => p['name'] == 'default')) {
            await pomCreateProfile(central, parsedToken, 'default');
            profiles = await pomListProfiles(central, parsedToken);
          }
          final profile = profiles.firstWhere(
            (p) => p['name'] == 'default',
            orElse: () => profiles.first,
          ) as Map<String, dynamic>;
          final bunkerUrl = pomGetBunkerUrl(central, profile);
          final pubkey = account['pubkey'] as String;
          status.value = _Status.idle;

          if (context.mounted) {
            await context.read<LogifyCubit>().loginWithGoogle(
                  context: context,
                  onSuccess: () {
                    Navigator.pop(context);
                    onSuccess();
                  },
                  bunkerUrl: bunkerUrl,
                  pubkey: pubkey,
                );
          }
        } else {
          // New account — generate keypair and show setup phase
          final kc = Keychain.generate();
          secretKeyHex.value = kc.private;
          nsec.value = Nip19.encodePrivkey(kc.private);
          status.value = _Status.idle;
          phase.value = _Phase.setup;
        }
      } catch (e) {
        errorMsg.value = e.toString().replaceFirst('Exception: ', '');
        status.value = _Status.idle;
      }
    }

    Future<void> handleCreate() async {
      if (token.value == null) {
        return;
      }
      errorMsg.value = '';
      status.value = _Status.creating;
      try {
        const central = kPomCentralUrl;
        const operators = kPomOperatorUrls;
        final threshold = pomThreshold(operators.length);
        final session = const Uuid().v4();

        await pomRegister(
          central: central,
          operators: operators,
          threshold: threshold,
          token: token.value!,
          email: token.value!.email,
          secretKeyHex: secretKeyHex.value,
          session: session,
        );

        // Poll for account confirmation
        Map<String, dynamic>? account;
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 1500));
          account = await pomGetAccount(central, token.value!);
          if (account != null) {
            break;
          }
        }

        if (account == null) {
          throw Exception(context.t.pomAccountTimeout);
        }

        List<dynamic> profiles = await pomListProfiles(central, token.value!);
        if (!profiles.any((p) => p['name'] == 'default')) {
          await pomCreateProfile(central, token.value!, 'default');
          profiles = await pomListProfiles(central, token.value!);
        }
        final profile = profiles.firstWhere(
          (p) => p['name'] == 'default',
          orElse: () => profiles.first,
        ) as Map<String, dynamic>;
        final bunkerUrl = pomGetBunkerUrl(central, profile);
        final pubkey = account['pubkey'] as String;
        status.value = _Status.idle;

        if (context.mounted) {
          await context.read<LogifyCubit>().loginWithGoogle(
                context: context,
                onSuccess: () {
                  Navigator.pop(context);
                  onSuccess();
                },
                bunkerUrl: bunkerUrl,
                pubkey: pubkey,
              );
        }
      } catch (e) {
        errorMsg.value = e.toString().replaceFirst('Exception: ', '');
        status.value = _Status.idle;
      }
    }

    void handleCopy() {
      Clipboard.setData(ClipboardData(text: nsec.value));
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
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: kDefaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (phase.value == _Phase.intro) ...[
                _GoogleIcon(),
                const SizedBox(height: kDefaultPadding / 2),
                Text(
                  context.t.loginWithGoogle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding / 4),
                Text(
                  context.t.pomLoginDesc,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding),
                if (errorMsg.value.isNotEmpty) ...[
                  Text(
                    errorMsg.value,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: kRed),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                ],
                if (busy)
                  Column(
                    children: [
                      SpinKitCircle(
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: handleStart,
                      child: Text(
                        errorMsg.value.isNotEmpty
                            ? context.t.retry
                            : context.t.pomSignInWithGoogle,
                      ),
                    ),
                  ),
              ] else ...[
                // Setup phase — new account key backup
                Text(
                  context.t.pomNewAccountTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding / 2),
                Text(
                  context.t.pomSaveKeyDesc,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nsec.value,
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontFamily: 'monospace',
                                    height: 1.5,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: handleCopy,
                        icon: Icon(
                          isCopied.value ? LucideIcons.check : LucideIcons.copy,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                if (errorMsg.value.isNotEmpty) ...[
                  Text(
                    errorMsg.value,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: kRed),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                ],
                if (busy)
                  Column(
                    children: [
                      SpinKitCircle(
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          phase.value = _Phase.intro;
                          token.value = null;
                          errorMsg.value = '';
                        },
                        icon: const RotatedBox(
                          quarterTurns: 1,
                          child: Icon(LucideIcons.arrowUp),
                        ),
                      ),
                      const SizedBox(width: kDefaultPadding / 2),
                      Expanded(
                        child: TextButton(
                          onPressed: handleCreate,
                          child: Text(
                            errorMsg.value.isNotEmpty
                                ? context.t.retry
                                : context.t.pomCreateAccount,
                          ),
                        ),
                      ),
                    ],
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

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Center(
        child: SvgPicture.asset(
          FeatureIcons.google,
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}

// Helper to parse raw webview message — handles both plain base64 and JSON envelope
dynamic jsonDecodeToken(String raw) {
  try {
    return jsonDecode(raw);
  } catch (_) {
    return raw;
  }
}
