// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/core/nostr_core_repository.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../common/pomegranate/google_auth_webview.dart';
import '../../../common/pomegranate/pomegranate_config.dart';
import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/modal_sheet_container.dart';
import '../../widgets/profile_picture.dart';
import 'pom_key_choice.dart';
import 'pom_progress_view.dart';
import 'pom_server_picker.dart';

enum _Phase { intro, foundElsewhere, keyChoice, backupKey, progress }

/// A phase that keeps its actions pinned below the scrolling body, so the
/// primary button stays reachable however tall the content grows.
abstract class _PinnedActions {
  Widget? buildActions(BuildContext context);
}

enum _Status { idle, authenticating, searching, checking }

void showGoogleLoginSheet(
  BuildContext context, {
  required Function() onSuccess,
}) {
  final cubit = context.read<LogifyCubit>();
  final registering = ValueNotifier(false);

  showAppModalSheet(
    context: context,
    backgroundColor: kTransparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: ValueListenableBuilder(
        valueListenable: registering,
        // Dismissing mid-registration abandons a half-created account, and
        // dismissing after it succeeds strands the user on the login screen
        // with an account that already exists.
        builder: (_, isRegistering, child) =>
            PopScope(canPop: !isRegistering, child: child!),
        child: GoogleLoginSheet(
          onSuccess: onSuccess,
          onRegisteringChanged: (value) => registering.value = value,
        ),
      ),
    ),
  ).whenComplete(registering.dispose);
}

class GoogleLoginSheet extends HookWidget {
  const GoogleLoginSheet({
    super.key,
    required this.onSuccess,
    this.onRegisteringChanged,
  });

  final Function() onSuccess;
  final ValueChanged<bool>? onRegisteringChanged;

  @override
  Widget build(BuildContext context) {
    final phase = useState(_Phase.intro);
    final status = useState(_Status.idle);
    final errorMsg = useState('');
    final central = useState(kPomCentralUrl);
    final token = useState<PomToken?>(null);
    final foundSetups = useState<List<PomSetup>>(const []);
    final nsec = useState('');
    final secretKeyHex = useState('');
    final isCopied = useState(false);
    final progress = useState(PomProgressState.running);
    final progressTitle = useState('');
    final progressAction = useState('');

    final busy = status.value != _Status.idle;
    final operators = useState<List<String>>(kPomDefaultOperatorUrls);
    final threshold = useState(kPomDefaultThreshold);

    final statusLabel = {
          _Status.authenticating: context.t.pomAuthenticating,
          _Status.searching: context.t.pomSearchingSetup,
          _Status.checking: context.t.pomCheckingAccount,
        }[status.value] ??
        '';

    Future<void> finishWithAccount(
      String usedCentral,
      Map<String, dynamic> account,
      PomToken activeToken, {
      PomSetup? discovered,
    }) async {
      List<dynamic> profiles =
          await pomListProfiles(pomGetDio, usedCentral, activeToken);
      if (!profiles.any((p) => p['name'] == 'default')) {
        await pomCreateProfile(pomGetDio, usedCentral, activeToken, 'default');
        profiles = await pomListProfiles(pomGetDio, usedCentral, activeToken);
      }
      final profile = profiles.firstWhere(
        (p) => p['name'] == 'default',
        orElse: () => profiles.first,
      ) as Map<String, dynamic>;

      final bunkerUrl = pomGetBunkerUrl(usedCentral, profile);
      final pubkey = account['pubkey'] as String;
      status.value = _Status.idle;

      // The NIP-46 handshake and backend login are slow, so both paths show
      // the same progress view rather than a frozen screen.
      progressAction.value = context.t.pomStepSigningIn;

      if (context.mounted) {
        // canPop also gates programmatic pops, so lift it before handing off.
        onRegisteringChanged?.call(false);

        await context.read<LogifyCubit>().loginWithGoogle(
              context: context,
              onSuccess: () {
                Navigator.pop(context);
                onSuccess();
              },
              bunkerUrl: bunkerUrl,
              pubkey: pubkey,
              // The account's real operator set. When the central omits it,
              // the discovered kind 16440 event is the only other source —
              // dropping it here reintroduces the hardcoded-threshold bug.
              pomegranateSetup: pomSetupFromAccount(usedCentral, account) ??
                  (discovered != null && discovered.operators.isNotEmpty
                      ? discovered
                      : null),
            );
      }
    }

    /// Log in if the account exists on [target], otherwise start creating one.
    Future<void> continueOnCentral(
      String target,
      PomToken activeToken, {
      PomSetup? discovered,
    }) async {
      // Same view as account creation: only the steps differ, not the shape.
      errorMsg.value = '';
      progress.value = PomProgressState.running;
      progressTitle.value = context.t.pomSigningInTitle;
      progressAction.value = context.t.pomStepFindingAccount;
      phase.value = _Phase.progress;

      try {
        final account = await pomGetAccount(pomGetDio, target, activeToken);

        if (account != null) {
          await finishWithAccount(
            target,
            account,
            activeToken,
            discovered: discovered,
          );
        } else {
          // No account here — back out of the progress view to set one up.
          status.value = _Status.idle;
          phase.value = _Phase.keyChoice;
        }
      } catch (e) {
        progress.value = PomProgressState.failed;
        progressTitle.value = context.t.pomSetupFailedTitle;
        errorMsg.value = e.toString().replaceFirst('Exception: ', '');
        status.value = _Status.idle;
      }
    }

    /// OAuth against [target], then either log in, offer the central the user
    /// is already registered with, or move on to creating an account.
    Future<void> authenticate(
      String target, {
      bool skipLookup = false,
      PomSetup? discovered,
    }) async {
      errorMsg.value = '';
      status.value = _Status.authenticating;
      try {
        final rawToken = await GoogleAuthWebView.show(
          context,
          '$target/login/google',
          GoogleAuthWebViewType.login,
          // Google skips its chooser when one account is signed in, so the
          // user could never pick a different one.
          forceAccountPicker: true,
        );

        if (rawToken == null || rawToken.isEmpty) {
          status.value = _Status.idle;
          return;
        }

        String tokenStr = rawToken;
        try {
          final decoded = _jsonDecodeToken(rawToken);
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
        central.value = target;

        // Spec step 5: setups published by any client tell us which identities
        // this email already owns, before we offer to make another.
        PomSetup? onTarget;
        if (!skipLookup && parsedToken.email.isNotEmpty) {
          status.value = _Status.searching;
          final existing = await pomLookupSetups(nc, parsedToken.email,
              onError: pomLogError);

          // An identity on the chosen central is the one the user asked for —
          // nothing to choose between. The chooser only exists to offer the
          // identities living elsewhere when this central has none.
          final targetUrl = pomNormaliseUrl(target) ?? target;
          onTarget =
              existing.where((setup) => setup.central == targetUrl).firstOrNull;

          if (onTarget == null && existing.isNotEmpty) {
            foundSetups.value = existing;
            status.value = _Status.idle;
            phase.value = _Phase.foundElsewhere;
            return;
          }
        }

        await continueOnCentral(
          target,
          parsedToken,
          discovered: discovered ?? onTarget,
        );
      } catch (e) {
        errorMsg.value = e.toString().replaceFirst('Exception: ', '');
        status.value = _Status.idle;
      }
    }

    void handleKeyChosen(String hex) {
      secretKeyHex.value = hex;
      nsec.value = Nip19.encodePrivkey(hex);
      phase.value = _Phase.backupKey;
    }

    Future<void> handleCreate() async {
      final activeToken = token.value;
      if (activeToken == null) {
        return;
      }
      // Registration succeeded and erased the key; only the login tail failed,
      // so retry that rather than re-sharding an empty secret.
      if (secretKeyHex.value.isEmpty) {
        final account =
            await pomGetAccount(pomGetDio, central.value, activeToken);
        if (account != null) {
          await finishWithAccount(central.value, account, activeToken);
          return;
        }
      }
      errorMsg.value = '';
      progress.value = PomProgressState.running;
      progressTitle.value = context.t.pomSettingUpTitle;
      progressAction.value = context.t.pomStepPreparingKey;
      phase.value = _Phase.progress;
      onRegisteringChanged?.call(true);

      final target = central.value;
      final selectedOperators = operators.value;
      final selectedThreshold = threshold.value;

      try {
        final session = const Uuid().v4();

        await pomRegister(
          getDio: pomGetDio,
          publishEvent: pomPublishEvent,
          onPublishError: pomLogError,
          central: target,
          operators: selectedOperators,
          threshold: selectedThreshold,
          token: activeToken,
          email: activeToken.email,
          secretKeyHex: secretKeyHex.value,
          session: session,
          onProgress: (step, operatorIndex) {
            progressAction.value = switch (step) {
              PomStep.preparingKey => context.t.pomStepPreparingKey,
              PomStep.splittingSecret => context.t.pomStepSplittingSecret,
              PomStep.registeringCentral => context.t.pomStepRegisteringCentral(
                  host: Uri.parse(target).host,
                ),
              PomStep.registeringOperator =>
                context.t.pomStepRegisteringOperator(
                  host: Uri.parse(selectedOperators[operatorIndex!]).host,
                ),
              PomStep.publishingSetup => context.t.pomStepPublishingSetup,
              PomStep.confirmingAccount => context.t.pomStepConfirmingAccount,
            };
          },
        );

        progressAction.value = context.t.pomStepConfirmingAccount;

        Map<String, dynamic>? account;
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 1500));
          account = await pomGetAccount(pomGetDio, target, activeToken);
          if (account != null) {
            break;
          }
        }

        if (account == null) {
          throw Exception(context.t.pomAccountTimeout);
        }

        // Spec step 16: the key is sharded and no longer needed in memory.
        secretKeyHex.value = '';

        await finishWithAccount(target, account, activeToken);
      } catch (e) {
        progress.value = PomProgressState.failed;
        progressTitle.value = context.t.pomSetupFailedTitle;
        errorMsg.value = e.toString().replaceFirst('Exception: ', '');
        status.value = _Status.idle;
      }
    }

    Future<void> handleExport() async {
      File? file;
      try {
        final dir = await getTemporaryDirectory();
        file = File('${dir.path}/nostr-private-key.txt');
        await file.writeAsString(nsec.value);
        await shareContent(files: [XFile(file.path)]);
      } catch (e) {
        lg.e('GoogleLoginSheet.handleExport: $e');
        BotToastUtils.showError(context.t.pomExportError);
      } finally {
        // Never leave a plaintext private key in shared temp storage.
        try {
          if (file != null && file.existsSync()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }

    void handleCopy() {
      Clipboard.setData(ClipboardData(text: nsec.value));
      BotToastUtils.showSuccess(context.t.pomKeyCopied);
      isCopied.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          isCopied.value = false;
        }
      });
    }

    final theme = Theme.of(context);

    final media = MediaQuery.of(context);

    // Built once so its actions can be pinned below the scrolling body.
    final Widget phaseWidget = switch (phase.value) {
      _Phase.intro => _IntroPhase(
          central: central.value,
          busy: busy,
          statusLabel: statusLabel,
          errorMsg: errorMsg.value,
          onCentralChanged: (value) => central.value = value,
          onStart: () => authenticate(central.value),
        ),
      _Phase.foundElsewhere => _FoundElsewherePhase(
          setups: foundSetups.value,
          busy: busy,
          statusLabel: statusLabel,
          errorMsg: errorMsg.value,
          onBack: () {
            foundSetups.value = const [];
            errorMsg.value = '';
            phase.value = _Phase.intro;
          },
          // Kept until the phase actually changes: this widget reads the list
          // on every rebuild, including the one showing the re-auth spinner.
          //
          // Every card is on a central other than the one just authenticated
          // against, so each needs its own OAuth round.
          onConnect: (discovered) => authenticate(
            discovered.central,
            skipLookup: true,
            discovered: discovered,
          ),
          // The token from the intro's central is still valid, so a new
          // identity starts from the account check rather than a new OAuth.
          onCreateNew: () => continueOnCentral(central.value, token.value!),
        ),
      _Phase.keyChoice => PomKeyChoice(
          operators: operators.value,
          threshold: threshold.value,
          busy: busy,
          onOperatorsChanged: (value) {
            operators.value = value;
            if (threshold.value > value.length) {
              threshold.value = value.length;
            }
          },
          onThresholdChanged: (value) => threshold.value = value,
          onContinue: handleKeyChosen,
        ),
      _Phase.backupKey => _BackupKeyPhase(
          nsec: nsec.value,
          isCopied: isCopied.value,
          errorMsg: errorMsg.value,
          onCopy: handleCopy,
          onExport: handleExport,
          onBack: () {
            phase.value = _Phase.keyChoice;
            errorMsg.value = '';
          },
          onCreate: handleCreate,
        ),
      _Phase.progress => PomProgressView(
          state: progress.value,
          title: progressTitle.value,
          action: progressAction.value,
          errorMsg: errorMsg.value,
          // Creating an account can be retried from the key we still hold;
          // signing in to an existing one restarts from OAuth.
          onRetry: secretKeyHex.value.isNotEmpty
              ? handleCreate
              : () => authenticate(central.value, skipLookup: true),
          onBack: () {
            errorMsg.value = '';
            onRegisteringChanged?.call(false);
            phase.value =
                secretKeyHex.value.isNotEmpty ? _Phase.backupKey : _Phase.intro;
          },
        ),
    };

    final pinnedActions = phaseWidget is _PinnedActions
        ? (phaseWidget as _PinnedActions).buildActions(context)
        : null;

    // Hug the content while it is short, and only start scrolling once it
    // would grow past 90% of the screen — the key choice with advanced
    // options expanded is far taller than the progress view. A
    // DraggableScrollableSheet is wrong here: it always takes its
    // initialChildSize, forcing the short phases to the tallest one's height.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: media.size.height * 0.9 - media.padding.top,
      ),
      child: ModalSheetContainer(
        padding: EdgeInsets.only(
          left: kDefaultPadding,
          right: kDefaultPadding,
          top: kDefaultPadding / 2,
          bottom: media.viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // The phase body scrolls; its actions stay pinned below it.
              // PomKeyChoice scrolls itself (its button needs its hook state),
              // so it gets the space directly rather than a second scroll view.
              Flexible(
                child: phaseWidget is PomKeyChoice
                    ? phaseWidget
                    : SingleChildScrollView(child: phaseWidget),
              ),

              if (pinnedActions != null) ...[
                const SizedBox(height: kDefaultPadding / 2),
                pinnedActions,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPhase extends StatelessWidget implements _PinnedActions {
  const _IntroPhase({
    required this.central,
    required this.busy,
    required this.statusLabel,
    required this.errorMsg,
    required this.onCentralChanged,
    required this.onStart,
  });

  final String central, statusLabel, errorMsg;
  final bool busy;
  final ValueChanged<String> onCentralChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _GoogleIcon()),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.loginWithGoogle,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 4),
        Text(
          context.t.pomLoginDesc,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding),
        PomServerPicker(
          selected: central,
          enabled: !busy,
          onChanged: onCentralChanged,
        ),
      ],
    );
  }

  @override
  Widget buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMsg.isNotEmpty) ...[
          Text(
            errorMsg,
            style: theme.textTheme.bodySmall?.copyWith(color: kRed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 2),
        ],
        if (busy)
          _BusyIndicator(label: statusLabel)
        else
          SizedBox(
            height: 48,
            child: TextButton(
              // An invalid custom central reports up as an empty string, so
              // OAuth can never start against a half-typed host.
              onPressed: central.isEmpty ? null : onStart,
              child: Text(
                errorMsg.isNotEmpty
                    ? context.t.sub_retry
                    : context.t.pomSignInWithGoogle,
              ),
            ),
          ),
      ],
    );
  }
}

/// Profiles for the discovered identities, keyed by pubkey. Bootstrap relays
/// because no user is logged in yet, so the usual read-relay list is empty,
/// and `loadMissingMetadatas` only returns what it actually fetched — anything
/// already cached has to be read back from the db.
Future<Map<String, Metadata>> _loadDiscoveredProfiles(
  List<String> pubkeys,
) async {
  final fetched =
      await nc.loadMissingMetadatas(pubkeys, DEFAULT_BOOTSTRAP_RELAYS);

  final byPubkey = {for (final m in fetched) m.pubkey: m};
  for (final pubkey in pubkeys) {
    if (!byPubkey.containsKey(pubkey)) {
      final cached = await nc.db.loadMetadata(pubkey);
      if (cached != null) {
        byPubkey[pubkey] = cached;
      }
    }
  }

  return byPubkey;
}

class _FoundElsewherePhase extends HookWidget implements _PinnedActions {
  const _FoundElsewherePhase({
    required this.setups,
    required this.busy,
    required this.statusLabel,
    required this.onConnect,
    required this.onCreateNew,
    required this.onBack,
    required this.errorMsg,
  });

  /// Identities on centrals other than the one being signed in to — the phase
  /// is skipped entirely when that central already holds one.
  final List<PomSetup> setups;
  final bool busy;
  final String statusLabel, errorMsg;
  final ValueChanged<PomSetup> onConnect;
  final VoidCallback onCreateNew, onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pubkeys = [
      for (final setup in setups)
        if (setup.pubkey != null) setup.pubkey!,
    ];

    final profiles = useFuture(
      useMemoized(() => _loadDiscoveredProfiles(pubkeys), [pubkeys.join(',')]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AppIcon(
            LucideIcons.serverCog,
            size: 32,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 1.5),
        Text(
          context.t.pomFoundElsewhereTitle,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 4),
        Text(
          context.t.pomFoundElsewhereDesc,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = kDefaultPadding / 2;
            final cardWidth = (constraints.maxWidth - gap) / 2;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final setup in setups)
                  SizedBox(
                    width: cardWidth,
                    child: _IdentityCard(
                      setup: setup,
                      profile: profiles.data?[setup.pubkey],
                      onPressed: busy ? null : () => onConnect(setup),
                    ),
                  ),
                SizedBox(
                  width: cardWidth,
                  child: _ChoiceCard(
                    avatar: const _UnknownAvatar(),
                    title: context.t.pomNotYou,
                    subtitle: context.t.pomNotYouDesc,
                    buttonLabel: context.t.pomCreateAccount,
                    outlined: true,
                    onPressed: busy ? null : onCreateNew,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMsg.isNotEmpty) ...[
          Text(
            errorMsg,
            style: theme.textTheme.bodySmall?.copyWith(color: kRed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 2),
        ],
        if (busy)
          _BusyIndicator(label: statusLabel)
        else
          Align(
            // Without this the phase is a dead end when the discovered
            // central is unreachable.
            child: _RoundedIconButton(
              icon: LucideIcons.chevronLeft,
              onTap: onBack,
            ),
          ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.avatar,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    this.subtitle,
    this.outlined = false,
  });

  final Widget avatar;
  final String title, buttonLabel;
  final String? subtitle;
  final bool outlined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              avatar,
              const SizedBox(height: kDefaultPadding / 2),
              Text(
                title,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 2),
          // A host name in the label wraps at this width, so the height is a
          // floor rather than a fixed size.
          if (outlined)
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
              child: Text(buttonLabel, textAlign: TextAlign.center),
            )
          else
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
              child: Text(buttonLabel, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

/// One discovered identity: who it is, and which central holds it.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.setup,
    required this.profile,
    required this.onPressed,
  });

  final PomSetup setup;
  final Metadata? profile;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final pubkey = setup.pubkey;
    final host = Uri.parse(setup.central).host;

    return _ChoiceCard(
      avatar: pubkey == null
          ? const _UnknownAvatar()
          : ProfilePicture2(
              size: 56,
              image: profile?.picture ?? '',
              pubkey: pubkey,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {},
            ),
      // Metadata.empty falls back to a shortened npub, so the card never
      // renders nameless while the profile is still loading.
      title: pubkey == null
          ? host
          : (profile ?? Metadata.empty(pubkey: pubkey)).getName(),
      subtitle: host,
      buttonLabel: context.t.connect,
      onPressed: onPressed,
    );
  }
}

class _UnknownAvatar extends StatelessWidget {
  const _UnknownAvatar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.scaffoldBackgroundColor,
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Center(
        child: Text(
          '?',
          style: theme.textTheme.titleLarge!.copyWith(color: theme.hintColor),
        ),
      ),
    );
  }
}

class _BackupKeyPhase extends StatelessWidget implements _PinnedActions {
  const _BackupKeyPhase({
    required this.nsec,
    required this.isCopied,
    required this.errorMsg,
    required this.onCopy,
    required this.onExport,
    required this.onBack,
    required this.onCreate,
  });

  final String nsec, errorMsg;
  final bool isCopied;
  final VoidCallback onCopy, onExport, onBack, onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t.pomNewAccountTitle,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.pomSaveKeyDesc,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding / 2,
          ),
          child: Text(
            nsec,
            style: theme.textTheme.labelMedium!.copyWith(height: 1.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextButton.icon(
                  onPressed: onExport,
                  icon: const AppIcon(LucideIcons.download, size: 16),
                  label: Text(context.t.pomExportKey),
                ),
              ),
            ),
            const SizedBox(width: kDefaultPadding / 4),
            _RoundedIconButton(
              icon: isCopied ? LucideIcons.check : LucideIcons.copy,
              onTap: onCopy,
              highlight: isCopied,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMsg.isNotEmpty) ...[
          Text(
            errorMsg,
            style: theme.textTheme.bodySmall?.copyWith(color: kRed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 2),
        ],
        Row(
          children: [
            _RoundedIconButton(icon: LucideIcons.chevronLeft, onTap: onBack),
            const SizedBox(width: kDefaultPadding / 4),
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: onCreate,
                  child: Text(
                    errorMsg.isNotEmpty
                        ? context.t.sub_retry
                        : context.t.pomCreateAccount,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundedIconButton extends StatelessWidget {
  const _RoundedIconButton({
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

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
          borderRadius: BorderRadius.circular(300),
          color: highlight
              ? theme.primaryColor.withValues(alpha: 0.12)
              : theme.cardColor,
          border: Border.all(
            color: highlight ? theme.primaryColor : theme.dividerColor,
            width: highlight ? 1 : 0.5,
          ),
        ),
        child: Center(
          child: AppIcon(
            icon,
            size: 18,
            color: highlight ? theme.primaryColor : null,
          ),
        ),
      ),
    );
  }
}

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SpinKitCircle(color: theme.primaryColor, size: 28),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

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
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

// Helper to parse raw webview message — handles both plain base64 and JSON envelope
dynamic _jsonDecodeToken(String raw) {
  try {
    return jsonDecode(raw);
  } catch (_) {
    return raw;
  }
}
