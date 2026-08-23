// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../common/common_regex.dart';
import '../../../common/nostr_password_manager.dart';
import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_zaps_view/send_tips_invoice.dart';
import '../../wallet_view/widgets/export_wallets.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/content_manager/add_discover_filter.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/fluid_glass_tab_bar.dart';
import '../../widgets/modal_with_blur.dart';
import 'google_login_sheet.dart';
import 'login_mesh_background.dart';
import 'signup_packs.dart';
import 'signup_wallet.dart';

// Widest the auth card is allowed to get. On a tablet the card would otherwise
// stretch edge to edge; a centred, phone-width card is the expected pattern.
const double _kMaxCardWidth = 460;

// Tallest the auth card is allowed to get. The signup body has an Expanded in
// it, so without a cap the card stretches to fill a tablet's full height and
// the content strands itself in the middle of an empty sheet.
const double _kMaxCardHeight = 680;

// Login sub-state: which method panel is open
enum _LoginStep { options, key, remote }

// Top-level: login or signup
enum _AuthView { login, signup }

class FluidLogifyView extends HookWidget {
  const FluidLogifyView({super.key, this.onPop});
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final authView = useState(_AuthView.login);
    final loginStep = useState(_LoginStep.options);
    final signupStep = useState(0); // 0=profile,1=packs,2=wallet,3=allset
    final tabCtrl = useTabController(initialLength: 2);

    void switchToLogin() {
      authView.value = _AuthView.login;
      loginStep.value = _LoginStep.options;
      if (tabCtrl.index != 0) {
        tabCtrl.animateTo(0);
      }
    }

    useEffect(() {
      // No guard on indexIsChanging: the body cross-fade should start with the
      // tap, not after the tab settles. Waiting left the panel frozen for the
      // length of the tab animation, which read as a stutter.
      void listener() {
        if (tabCtrl.index == 0 && authView.value != _AuthView.login) {
          authView.value = _AuthView.login;
          loginStep.value = _LoginStep.options;
        } else if (tabCtrl.index == 1 && authView.value != _AuthView.signup) {
          authView.value = _AuthView.signup;
          signupStep.value = 0;
        }
      }

      tabCtrl.addListener(listener);
      return () => tabCtrl.removeListener(listener);
    }, [tabCtrl]);

    void handleBack() {
      if (authView.value == _AuthView.login) {
        if (loginStep.value != _LoginStep.options) {
          if (loginStep.value == _LoginStep.remote) {
            context.read<LogifyCubit>().offloadRemoteSigner();
          }
          loginStep.value = _LoginStep.options;
        } else {
          onPop?.call() ?? YNavigator.pop(context);
        }
      } else {
        if (signupStep.value > 0) {
          signupStep.value--;
        } else {
          switchToLogin();
        }
      }
    }

    final availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kDefaultPadding * 4;

    // Brand copy sits beside the card only when there is room for both; on a
    // phone the card keeps just the pill — vertical space is too tight there.
    // 900, not the MOBILE breakpoint (720): a phone in landscape is ~844 wide
    // but only ~390 tall, and the two-column split would crush both the card
    // and the brand copy. Real tablets clear 900.
    final isWide = ResponsiveBreakpoints.of(context).screenWidth >= 900;

    final maxCardHeight = availableHeight.clamp(0.0, _kMaxCardHeight);

    final card = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxCardHeight,
        maxWidth: _kMaxCardWidth,
      ),
      child: FluidBlurContainer(
        borderRadius: kDefaultPadding * 1.5,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 1.5,
          vertical: kDefaultPadding / 1.5,
        ),
        blur: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header row ──────────────────────────────
            Row(
              children: [
                AppIconButton(
                  icon: FeatureIcons.arrowLeft,
                  size: 32,
                  iconSize: 16,
                  onClicked: handleBack,
                ),
                const Spacer(),
                SvgPicture.asset(
                  LogosIcons.logoMarkWhite,
                  height: 30,
                  width: 30,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kDefaultPadding / 2),
            // ── Eyebrow pill ─────────────────────────────
            // On wide layouts the brand column already carries this pill, so
            // showing it here too would double up.
            if (!isWide) ...[
              const Center(child: _BuiltOnNostrPill()),
              const SizedBox(height: kDefaultPadding / 2),
            ],
            // ── Animated title ────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Align(
                key: ValueKey(authView.value),
                child: Text(
                  authView.value == _AuthView.login
                      ? context.t.loginToYakihonne
                      : context.t.createAccount.capitalizeFirst(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding / 1.5),
            // ── Mode pill tabs ────────────────────────────
            _ModePillTabBar(tabCtrl: tabCtrl),
            const SizedBox(height: kDefaultPadding),
            // ── Body ──────────────────────────────────────
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(authView.value),
                  child: authView.value == _AuthView.login
                      ? _LoginBody(
                          loginStep: loginStep,
                          onPop: onPop,
                        )
                      : _SignupBody(
                          step: signupStep,
                          onPop: onPop,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Stack(
          children: [
            const LoginMeshBackground(),
            Column(
              children: [
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            const Expanded(child: _LoginBrandColumn()),
                            Expanded(child: Center(child: card)),
                          ],
                        )
                      : Center(child: card),
                ),
                const SizedBox(height: kDefaultPadding / 2),
                GestureDetector(
                  onTap: () => onPop?.call() ?? YNavigator.pop(context),
                  behavior: HitTestBehavior.translucent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSigner == null
                            ? context.t.continueAsGuest.capitalizeFirst()
                            : context.t.cancel.capitalizeFirst(),
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: currentSigner == null ? kWhite : kRed,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (currentSigner == null) ...[
                        const SizedBox(width: kDefaultPadding / 2),
                        const RotatedBox(
                          quarterTurns: 1,
                          child: AppIcon(
                            FeatureIcons.arrowUp,
                            size: 20,
                            color: kWhite,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared brand bits ─────────────────────────────────────────────────────

List<String> _facts(BuildContext context) => [
      context.t.loginFactSelfSovereign,
      context.t.loginFactLightning,
      context.t.loginFactCensorshipResistant,
      context.t.loginFactRelayRedundant,
    ];

class _BuiltOnNostrPill extends StatelessWidget {
  const _BuiltOnNostrPill();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 0.7,
        vertical: kDefaultPadding / 4,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        context.t.loginBuiltOnNostr,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

// ─── Brand column (mirrors yaki_pro's LoginBrandColumn) ────────────────────
// Tablet/landscape only — gives the card something to sit next to instead of
// floating alone in the middle of a wide screen.

class _LoginBrandColumn extends StatelessWidget {
  const _LoginBrandColumn();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        top: kDefaultPadding * 3,
        bottom: kDefaultPadding * 3,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          // Scrollable so a short-but-wide window degrades instead of
          // overflowing the Row's height constraint.
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  LogosIcons.logoMarkWhite,
                  width: 44,
                  height: 44,
                  colorFilter: ColorFilter.mode(
                    theme.primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: kDefaultPadding * 1.4),
                const _BuiltOnNostrPill(),
                const SizedBox(height: kDefaultPadding * 1.2),
                Text(
                  context.t.loginTagline,
                  style: theme.textTheme.displaySmall!.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: kDefaultPadding * 0.8),
                Text(
                  context.t.loginPlatformDesc,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.highlightColor,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: kDefaultPadding * 1.4),
                ..._facts(context).map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(
                          '+  ',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          f,
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mode pill tab bar (mirrors DM view's _FluidFloatingTabBar) ─────────────

class _ModePillTabBar extends StatelessWidget {
  const _ModePillTabBar({required this.tabCtrl});

  final TabController tabCtrl;

  @override
  Widget build(BuildContext context) {
    return FluidGlassTabBar(
      controller: tabCtrl,
      tabs: [
        GlassTab(label: context.t.loginAction.capitalizeFirst()),
        GlassTab(label: context.t.createAccount.capitalizeFirst()),
      ],
    );
  }
}

// ─── Login body ────────────────────────────────────────────────────────────

class _LoginBody extends HookWidget {
  const _LoginBody({required this.loginStep, this.onPop});

  final ValueNotifier<_LoginStep> loginStep;
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (loginStep.value) {
        _LoginStep.options => _LoginOptions(
            key: const ValueKey('options'),
            loginStep: loginStep,
            onPop: onPop,
          ),
        _LoginStep.key => _LoginKeyInput(
            key: const ValueKey('key'),
            loginStep: loginStep,
            onPop: onPop,
          ),
        _LoginStep.remote => _LoginRemote(
            key: const ValueKey('remote'),
            onPop: onPop,
          ),
      },
    );
  }
}

// Conversation-style method cards (matches web's login-convo-options)
class _LoginOptions extends StatelessWidget {
  const _LoginOptions({
    super.key,
    required this.loginStep,
    this.onPop,
  });

  final ValueNotifier<_LoginStep> loginStep;
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.loginToYakihonne,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(height: kDefaultPadding / 1.5),
          _MethodCard(
            icon: FeatureIcons.keys,
            title: context.t.keys,
            desc: context.t.npubNsecHex,
            enabled: true,
            onTap: () => loginStep.value = _LoginStep.key,
          ),
          if (isExternalSignerInstalled) ...[
            const SizedBox(height: kDefaultPadding / 2),
            _MethodCard(
              icon: FeatureIcons.shareGlobal,
              title: context.t.amber,
              desc: context.t.useAmber,
              enabled: true,
              onTap: () => context.read<LogifyCubit>().loginWithAmber(
                    context: context,
                    onSuccess: onPop ?? () => Navigator.pop(context),
                  ),
            ),
          ],
          const SizedBox(height: kDefaultPadding / 2),
          _MethodCard(
            icon: FeatureIcons.shareGlobal,
            title: context.t.remoteSigner,
            desc: context.t.useUrlBunker,
            enabled: true,
            onTap: () => loginStep.value = _LoginStep.remote,
          ),
          if (!Platform.isIOS) ...[
            const SizedBox(height: kDefaultPadding / 2),
            _MethodCard(
              icon: FeatureIcons.shareGlobal,
              svgIcon: FeatureIcons.google,
              title: context.t.loginWithGoogle,
              desc: context.t.pomLoginDesc,
              enabled: true,
              onTap: () => showGoogleLoginSheet(
                context,
                onSuccess: onPop ?? () => Navigator.pop(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.enabled,
    this.svgIcon,
    this.onTap,
  });

  final IconData icon;
  final String? svgIcon;
  final String title;
  final String desc;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.42,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding * 0.7,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(kDefaultPadding),
          ),
          child: Row(
            children: [
              if (svgIcon != null)
                SvgPicture.asset(
                  svgIcon!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColor,
                    BlendMode.srcIn,
                  ),
                )
              else
                AppIcon(
                  icon,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
              const SizedBox(width: kDefaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              AppIcon(
                FeatureIcons.arrowRight,
                size: 14,
                color: Theme.of(context).highlightColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Key input panel (matches web's login-convo-answer)
class _LoginKeyInput extends HookWidget {
  const _LoginKeyInput({
    super.key,
    required this.loginStep,
    this.onPop,
  });

  final ValueNotifier<_LoginStep> loginStep;
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final controller = useTextEditingController();
    final fieldValue = useState('');
    final isLoading = useState(false);

    final proceed = useCallback(() async {
      if (controller.text.isEmpty) {
        final clipText = await getClipboardTextSafely();
        if (clipText != null && clipText.isNotEmpty && context.mounted) {
          controller.value = TextEditingValue(text: clipText);
          fieldValue.value = clipText;
        }
      } else {
        if (formKey.currentState!.validate()) {
          isLoading.value = true;
          context.read<LogifyCubit>().login(
                key: controller.text.trim(),
                isExternalSigner: false,
                newKey: false,
                context: context,
                onSuccess: onPop ??
                    () => Navigator.popUntil(context, (r) => r.isFirst),
              );
        }
      }
    });

    useEffect(() {
      Future.microtask(() async {
        final cred = await NostrPasswordManager.requestSavedNsec();
        if (cred != null && context.mounted) {
          controller.text = cred;
          fieldValue.value = cred;
          proceed();
        }
      });
      return null;
    }, []);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back link (matches web's login-convo-back)
          GestureDetector(
            onTap: () => loginStep.value = _LoginStep.options,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  FeatureIcons.arrowLeft,
                  size: 13,
                  color: Theme.of(context).highlightColor,
                ),
                const SizedBox(width: 6),
                Text(
                  context.t.back,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kDefaultPadding / 1.5),
          Form(
            key: formKey,
            child: AutofillGroup(
              child: TextFormField(
                autofillHints: const [AutofillHints.password],
                controller: controller,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (v) => keyValidator.call(v, context),
                onChanged: (v) => fieldValue.value = v,
                decoration: InputDecoration(
                  prefixIcon: SizedBox(
                    width: 44,
                    child: Center(
                      child: AppIcon(
                        FeatureIcons.keys,
                        size: 18,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ),
                  hintText: context.t.npubNsecHex,
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 1.5),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isLoading.value ? null : proceed,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading.value
                    ? const SpinKitCircle(color: kWhite, size: 21)
                    : fieldValue.value.isNotEmpty
                        ? Row(
                            key: const ValueKey(1),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(context.t.loginAction.capitalizeFirst()),
                              const SizedBox(width: kDefaultPadding / 2),
                              const RotatedBox(
                                quarterTurns: 1,
                                child: AppIcon(
                                  FeatureIcons.arrowUp,
                                  size: 18,
                                  color: kWhite,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            key: const ValueKey(2),
                            context.t.pasteYourKey.capitalizeFirst(),
                          ),
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.secureStorageDesc.capitalizeFirst(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ],
      ),
    );
  }
}

// Remote signer panel (unchanged from original)
class _LoginRemote extends HookWidget {
  const _LoginRemote({super.key, this.onPop});
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final logifyCubit = context.read<LogifyCubit>();
    final bunkerController = useTextEditingController();
    final isLoading = useState(false);

    final connectionUrlFuture = useMemoized(
      () => logifyCubit.initRemoteSignerFromNostrConnect(
        context: context,
        onSuccess: onPop ?? () => YNavigator.popToRoot(context),
      ),
    );
    final connectionUrlSnapshot = useFuture(connectionUrlFuture);
    final connectionUrl = connectionUrlSnapshot.data ?? '';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t.remoteSigner,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 4),
          Text(
            context.t.useUrlBunker,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 1.5),
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                border: Border.all(
                  color: Theme.of(context).primaryColorDark,
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: connectionUrl,
                // Clamped against the card, not the screen: 52.w alone would
                // overflow the capped card on a tablet.
                size: 52.w.clamp(0.0, _kMaxCardWidth * 0.6),
                dataModuleStyle: QrDataModuleStyle(
                  color: Theme.of(context).primaryColorDark,
                  dataModuleShape: QrDataModuleShape.circle,
                ),
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          DottedCopyContainer(
            lnurl: connectionUrl,
            message: context.t.textSuccesfulyCopied,
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.or,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          TextField(
            controller: bunkerController,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(hintText: 'bunker://..'),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          RegularLoadingButton(
            title: context.t.login,
            onClicked: () async {
              isLoading.value = true;
              await logifyCubit.initRemoteSignerFromBunkerUrl(
                bunkerUrl: bunkerController.text,
                onSuccess: onPop ??
                    () {
                      if (context.mounted) {
                        YNavigator.popToRoot(context);
                        isLoading.value = false;
                      }
                    },
                context: context,
              );
              isLoading.value = false;
            },
            isLoading: isLoading.value,
          ),
        ],
      ),
    );
  }
}

// ─── Signup body ────────────────────────────────────────────────────────────

class _SignupBody extends HookWidget {
  const _SignupBody({required this.step, this.onPop});

  final ValueNotifier<int> step;
  final Function()? onPop;

  // Steps: 0=Profile, 1=Packs, 2=Wallet, 3=All set
  static const int _totalSteps = 4;
  static const int _lastStep = _totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final nameFormKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(
      text: context.read<LogifyCubit>().state.name,
    );
    final walletNameCtrl = useTextEditingController(
      text: context.read<LogifyCubit>().state.name,
    );
    final isWalletCreated = useState(
      context.read<LogifyCubit>().state.wallet.isNotEmpty,
    );
    final isCreatingWallet = useState(false);
    final walletError = useState('');

    return BlocBuilder<LogifyCubit, LogifyState>(
      builder: (context, state) {
        if (state.isSettingAccount) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  themeCubit.isDark
                      ? LottieAnimations.loading
                      : LottieAnimations.loadingDark,
                  height: 15.h,
                  width: 15.h,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  context.t.initializingAccount.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Step rail ──────────────────────────────────────────────
            _SignupRail(
              currentStep: step.value,
              totalSteps: _totalSteps,
            ),
            const SizedBox(height: kDefaultPadding / 1.5),
            // ── Step body ──────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: step.value,
                children: [
                  _SignupProfileStep(
                    nameController: nameController,
                    formKey: nameFormKey,
                    state: state,
                  ),
                  const SignupPacks(),
                  CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: SignupWallet(
                          nameCtrl: walletNameCtrl,
                          isWalletCreated: isWalletCreated,
                          errorMessage: walletError,
                        ),
                      ),
                    ],
                  ),
                  const _SignupAllSetStep(),
                ],
              ),
            ),
            const SizedBox(height: kDefaultPadding / 2),
            // ── Navigation buttons ─────────────────────────────────────
            AbsorbPointer(
              absorbing: state.isSettingAccount || isCreatingWallet.value,
              child: _buildNav(context, step, nameFormKey, isWalletCreated,
                  isCreatingWallet, walletNameCtrl, walletError),
            ),
            const SizedBox(height: kDefaultPadding / 2),
          ],
        );
      },
    );
  }

  Widget _buildNav(
    BuildContext context,
    ValueNotifier<int> step,
    GlobalKey<FormState> nameFormKey,
    ValueNotifier<bool> isWalletCreated,
    ValueNotifier<bool> isCreatingWallet,
    TextEditingController walletNameCtrl,
    ValueNotifier<String> walletError,
  ) {
    final isWalletStep = step.value == 2 && !isWalletCreated.value;

    if (isWalletStep) {
      // Three-button layout: Previous | Skip to next | Create & continue
      return Row(
        children: [
          OutlinedButton(
            onPressed: () => step.value--,
            child: Text(context.t.back.capitalizeFirst()),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          OutlinedButton(
            onPressed: () => step.value++,
            child: Text(context.t.skip.capitalizeFirst()),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: TextButton(
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                walletError.value = '';
                if (walletNameCtrl.text.isEmpty) {
                  walletError.value =
                      context.t.usernameRequired.capitalizeFirst();
                  return;
                }
                if (!emailNamingRegex.hasMatch(walletNameCtrl.text)) {
                  walletError.value =
                      context.t.onlyLettersNumber.capitalizeFirst();
                  return;
                }
                isCreatingWallet.value = true;
                await context.read<LogifyCubit>().createWallet(
                      onSuccess: (la, wallet) async {
                        isWalletCreated.value = true;
                        step.value++;
                        await Future.delayed(
                          const Duration(milliseconds: 400),
                        );
                        if (context.mounted) {
                          showBlurredModal(
                            context: context,
                            isDismissable: false,
                            view: ExportWalletOnCreation(
                              wallet: NostrWalletConnectModel(
                                id: '',
                                kind: 0,
                                lud16: la,
                                connectionString: wallet,
                                relays: Uri.parse(wallet)
                                        .queryParametersAll['relay'] ??
                                    const [],
                                secret: '',
                                walletPubkey: '',
                                permissions: const [],
                              ),
                            ),
                          );
                        }
                      },
                      name: walletNameCtrl.text,
                      onNameFailure: () {
                        walletError.value = context.t.usernameTaken;
                      },
                    );
                isCreatingWallet.value = false;
              },
              child: isCreatingWallet.value
                  ? const SpinKitCircle(color: kWhite, size: 18)
                  : const Text('Create & continue'),
            ),
          ),
        ],
      );
    }

    // Default: Back + Next/Finish
    return Row(
      children: [
        if (step.value > 0) ...[
          OutlinedButton(
            onPressed: () => step.value--,
            child: Text(context.t.back.capitalizeFirst()),
          ),
          const SizedBox(width: kDefaultPadding / 2),
        ],
        Expanded(
          child: TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              if (step.value == 0) {
                if (!nameFormKey.currentState!.validate()) {
                  return;
                }
              }
              if (step.value == _lastStep) {
                context.read<LogifyCubit>().setupAccount(
                      onSuccess: onPop ?? () => Navigator.pop(context),
                    );
              } else {
                step.value++;
              }
            },
            child: Text(
              step.value == _lastStep
                  ? context.t.letsGetStarted.capitalizeFirst()
                  : context.t.next.capitalizeFirst(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Signup rail (matches web's .signup-rail + .signup-rail-marker) ─────────

class _SignupRail extends StatelessWidget {
  const _SignupRail({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (i) {
        final isActive = currentStep == i;
        final isDone = currentStep > i;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : isDone
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.13)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                border: Border.all(
                  color: (isActive || isDone)
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? AppIcon(
                        FeatureIcons.widgetCorrect,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      )
                    : Text(
                        '${i + 1}',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: isActive
                                  ? kWhite
                                  : Theme.of(context).highlightColor,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                      ),
              ),
            ),
            if (i < totalSteps - 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 2,
                decoration: BoxDecoration(
                  color: isDone
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ─── Signup Step 1: Profile (matches web's signup step 1) ────────────────────
// Big centered circular avatar + large centered name input (no border)

class _SignupProfileStep extends StatelessWidget {
  const _SignupProfileStep({
    required this.nameController,
    required this.formKey,
    required this.state,
  });

  final TextEditingController nameController;
  final GlobalKey<FormState> formKey;
  final LogifyState state;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar circle (112px, matches .signup-avatar-wrap min-width: 112px)
                GestureDetector(
                  onTap: () =>
                      context.read<LogifyCubit>().selectMetadataMedia(true),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColorDark,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (state.picture != null)
                            Image(
                              image: FileImage(state.picture!),
                              fit: BoxFit.cover,
                            )
                          else
                            const Image(
                              image: AssetImage(Images.profileAvatar),
                              fit: BoxFit.cover,
                            ),
                          // Dark overlay (matches .signup-avatar-overlay)
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.72),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AppIcon(
                                  FeatureIcons.image,
                                  size: 24,
                                  color: kWhite,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.t.editPicture.capitalizeFirst(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        color: Theme.of(context).highlightColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                // Large centered name input (matches .signup-name-field input {
                // font-size: 1.7rem, if-no-border, p-bold, p-centered})
                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: nameController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    onChanged: (v) =>
                        context.read<LogifyCubit>().setPersonalInformation(
                              text: v,
                              isName: true,
                            ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.t.setProperName.capitalizeFirst();
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: context.t.yourName.capitalizeFirst(),
                      hintStyle:
                          Theme.of(context).textTheme.titleLarge!.copyWith(
                                color: Theme.of(context).highlightColor,
                                fontWeight: FontWeight.w800,
                              ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      fillColor: kTransparent,
                      errorBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Signup step 4: All set ────────────────────────────────────────────────

class _SignupAllSetStep extends StatelessWidget {
  const _SignupAllSetStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LogifyCubit, LogifyState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: kDefaultPadding / 2),
                  Text(
                    '${context.t.youreAllSet}!',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding * 1.5),
                  // Avatar circle with orange glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.45),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: state.picture != null
                          ? Image(
                              image: FileImage(state.picture!),
                              fit: BoxFit.cover,
                            )
                          : const Image(
                              image: AssetImage(Images.profileAvatar),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  Text(
                    state.name,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  // Lightning address card — only if wallet was created
                  if (state.lightningAddress.isNotEmpty) ...[
                    const SizedBox(height: kDefaultPadding),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding * 0.85,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(kDefaultPadding),
                      ),
                      child: Column(
                        children: [
                          Text(
                            context.t.lightningAddress.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Theme.of(context).highlightColor,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: kDefaultPadding / 2),
                          Text(
                            state.lightningAddress,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
