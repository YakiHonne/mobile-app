// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/string_utils.dart';
import 'package:open_filex/open_filex.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../widgets/signup_preview.dart';

class LogifyDirectView extends HookWidget {
  const LogifyDirectView({super.key});

  @override
  Widget build(BuildContext context) {
    final isLogin = useState(true);

    return BlocProvider(
      create: (context) => LogifyCubit(),
      child: isLogin.value
          ? LoginDirectView(
              onCreate: () {
                isLogin.value = false;
              },
            )
          : SignupViewDirect(
              onPop: () {
                isLogin.value = true;
              },
            ),
    );
  }
}

class LoginDirectView extends HookWidget {
  const LoginDirectView({
    super.key,
    required this.onCreate,
  });

  final Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final textEditingController = useTextEditingController();
    final textfieldValue = useState('');
    final components = <Widget>[];

    final t = Column(
      children: [
        _keyContainer(textEditingController, context, textfieldValue, formKey),
        if (isExternalSignerInstalled) ...[
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<LogifyCubit>().loginWithAmber(
                  onSuccess: () {
                    Navigator.pop(context);
                  },
                );
              },
              child: Text(
                context.t.useAmber.capitalizeFirst(),
              ),
            ),
          ),
        ],
      ],
    );

    components.add(
      Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            children: [
              Text(
                context.t.loginToYakihonne,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: textEditingController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  validator: (value) {
                    return keyValidator.call(value, context);
                  },
                  onChanged: (value) {
                    textfieldValue.value = value;
                  },
                  decoration: InputDecoration(
                    prefixIcon: SizedBox(
                      width: 25,
                      height: 25,
                      child: Center(
                        child: SvgPicture.asset(
                          FeatureIcons.keys,
                          width: 25,
                          height: 25,
                          fit: BoxFit.scaleDown,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                    hintText: context.t.npubNsecHex,
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              t,
              TextButton(
                onPressed: onCreate,
                style: TextButton.styleFrom(
                  backgroundColor: kTransparent,
                ),
                child: Text(
                  context.t.createAccount.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: CustomIconButton(
            onClicked: () {
              YNavigator.pop(context);
            },
            icon: FeatureIcons.closeRaw,
            size: 20,
            vd: -2,
            backgroundColor: Theme.of(context).cardColor,
          ),
        ),
        title: SvgPicture.asset(
          LogosIcons.logoBlack,
          height: 45,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: components,
        ),
      ),
    );
  }

  SizedBox _keyContainer(
      TextEditingController textEditingController,
      BuildContext context,
      ValueNotifier<String> textfieldValue,
      GlobalKey<FormState> formKey) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          if (textEditingController.text.isEmpty) {
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            final String? clipboardText = clipboardData?.text;

            if (clipboardText != null &&
                clipboardText.isNotEmpty &&
                context.mounted) {
              textEditingController.value = TextEditingValue(
                text: clipboardText,
              );
              textfieldValue.value = clipboardText;
            }
          } else {
            if (formKey.currentState!.validate()) {
              context.read<LogifyCubit>().login(
                    key: textEditingController.text.trim(),
                    isExternalSigner: false,
                    newKey: false,
                    onSuccess: () {
                      Navigator.pop(context);
                    },
                  );
            }
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: textfieldValue.value.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      key: const ValueKey(1),
                      context.t.loginAction.capitalizeFirst(),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    RotatedBox(
                      quarterTurns: 1,
                      child: SvgPicture.asset(
                        FeatureIcons.arrowUp,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          kWhite,
                          BlendMode.srcIn,
                        ),
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
    );
  }
}

class SignupViewDirect extends HookWidget {
  const SignupViewDirect({
    super.key,
    required this.onPop,
  });

  final Function() onPop;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final name = useTextEditingController();
    final wallet = useTextEditingController();
    final errorMessage = useState('');
    final useWallet = useState(true);
    final components = <Widget>[];
    final isAccountCreated = useState(false);

    useEffect(() {
      void nameListner() {
        wallet.text = name.text;
        errorMessage.value = '';
      }

      void walletListener() {
        errorMessage.value = '';
      }

      name.addListener(nameListner);
      wallet.addListener(walletListener);

      return () {
        name.removeListener(nameListner);
        wallet.removeListener(walletListener);
      };
    }, [name, wallet]);

    components.add(
      Expanded(
        child: BlocBuilder<LogifyCubit, LogifyState>(
          builder: (context, state) {
            return Stack(
              children: [
                _initalizeAccount(state, context),
                _wallet(
                  state,
                  isAccountCreated,
                  context,
                  formKey,
                  name,
                  wallet,
                  errorMessage,
                  useWallet,
                ),
              ],
            );
          },
        ),
      ),
    );

    components.addAll(
      [
        BlocBuilder<LogifyCubit, LogifyState>(
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  _settingAccount(state, isAccountCreated, context, formKey,
                      useWallet, wallet, errorMessage),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  _loginAction(context)
                ],
              ),
            );
          },
        ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: context.t.createAccount,
        onBackClicked: onPop,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Column(
          spacing: kDefaultPadding / 2,
          children: components,
        ),
      ),
    );
  }

  GestureDetector _loginAction(BuildContext context) {
    return GestureDetector(
      onTap: onPop,
      behavior: HitTestBehavior.translucent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t.alreadyUser,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Text(
            context.t.loginAction,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  SizedBox _settingAccount(
      LogifyState state,
      ValueNotifier<bool> isAccountCreated,
      BuildContext context,
      GlobalKey<FormState> formKey,
      ValueNotifier<bool> useWallet,
      TextEditingController wallet,
      ValueNotifier<String> errorMessage) {
    return SizedBox(
      width: double.infinity,
      child: AbsorbPointer(
        absorbing: state.isSettingAccount,
        child: TextButton(
          onPressed: () async {
            if (isAccountCreated.value) {
              YNavigator.pop(context);
            } else {
              FocusManager.instance.primaryFocus?.unfocus();

              if (formKey.currentState!.validate()) {
                await context.read<LogifyCubit>().setupDirectAccount(
                      walletName: useWallet.value ? wallet.text : '',
                      onNameFailure: () {
                        errorMessage.value =
                            context.t.usernameTaken.capitalizeFirst();
                      },
                      onSuccess: () {
                        isAccountCreated.value = true;
                      },
                    );
              }
            }
          },
          child: Text(
            state.isSettingAccount
                ? context.t.initializingAccount
                : isAccountCreated.value
                    ? context.t.letsGetStarted
                    : context.t.createAccount.capitalizeFirst(),
          ),
        ),
      ),
    );
  }

  Positioned _wallet(
      LogifyState state,
      ValueNotifier<bool> isAccountCreated,
      BuildContext context,
      GlobalKey<FormState> formKey,
      TextEditingController name,
      TextEditingController wallet,
      ValueNotifier<String> errorMessage,
      ValueNotifier<bool> useWallet) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: !state.isSettingAccount ? 1 : 0,
        child: ListView(
          children: isAccountCreated.value
              ? [
                  _signupPreview(context, state),
                ]
              : [
                  SignupDirectMetadata(
                    formKey: formKey,
                    nameTextEditingController: name,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  SignupDirectWallet(
                    walletTextEditingController: wallet,
                    errorMessage: errorMessage,
                    useWallet: useWallet,
                  ),
                ],
        ),
      ),
    );
  }

  FadeIn _signupPreview(BuildContext context, LogifyState state) {
    return FadeIn(
      child: SignupPreview(
        removePadding: true,
        onExport: () async {
          final isWalletAvailable =
              context.read<LogifyCubit>().state.wallet.isNotEmpty;

          if (isWalletAvailable) {
            final wallets = walletManagerCubit.getUserWallets(true);

            final res = await exportWalletToUserDirectory(wallets);
            if (res == ResultType.noAppToOpen) {
              BotToastUtils.showError(context.t.noApp);
            }
          } else {
            final res = await exportKeysToUserDirectory(
              publicKey: Keychain.getPublicKey(
                state.private,
              ),
              secretKey: state.private,
            );

            if (res == ResultType.noAppToOpen) {
              BotToastUtils.showError(context.t.noApp);
            }
          }
        },
      ),
    );
  }

  Positioned _initalizeAccount(LogifyState state, BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: state.isSettingAccount ? 1 : 0,
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
            const SizedBox(
              height: kDefaultPadding,
            ),
            Text(
              context.t.initializingAccount.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupDirectMetadata extends HookWidget {
  const SignupDirectMetadata({
    super.key,
    required this.formKey,
    required this.nameTextEditingController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameTextEditingController;

  @override
  Widget build(BuildContext context) {
    final c = context.read<LogifyCubit>();

    final components = <Widget>[];

    components.addAll(
      [
        Text(
          context.t.details.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: kDefaultPadding / 4),
        Text(
          context.t.shareGlimps.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        BlocBuilder<LogifyCubit, LogifyState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  SizedBox(
                    height: constraints.maxWidth * 0.55,
                    width: constraints.maxWidth,
                  ),
                  _addEditCover(constraints, context, state),
                  _thumbnail(context, constraints, state),
                ],
              ),
            );
          },
        ),
        BlocBuilder<LogifyCubit, LogifyState>(
          builder: (context, state) {
            return Center(
              child: TextButton(
                onPressed: () {
                  context.read<LogifyCubit>().selectMetadataMedia(true);
                },
                style: TextButton.styleFrom(
                  backgroundColor: kTransparent,
                ),
                child: Text(
                  state.picture != null
                      ? context.t.editPicture.capitalizeFirst()
                      : context.t.addPicture.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            );
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
      ],
    );

    components.addAll(
      [
        Form(
          key: formKey,
          child: TextFormField(
            controller: nameTextEditingController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              c.setPersonalInformation(
                text: value,
                isName: true,
              );
            },
            validator: (value) {
              if (StringUtil.isBlank(value)) {
                return context.t.setProperName.capitalizeFirst();
              }

              return null;
            },
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: context.t.yourName.capitalizeFirst(),
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        TextFormField(
          maxLines: 4,
          minLines: 3,
          initialValue: c.state.about,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (value) {
            c.setPersonalInformation(
              text: value,
              isName: false,
            );
          },
          decoration: InputDecoration(
            hintText: context.t.aboutYou.capitalizeFirst(),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: components,
    );
  }

  Positioned _thumbnail(
      BuildContext context, BoxConstraints constraints, LogifyState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          context.read<LogifyCubit>().selectMetadataMedia(true);
        },
        child: Container(
          width: constraints.maxWidth * 0.35,
          height: constraints.maxWidth * 0.35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kCardDark,
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 3,
            ),
            image: const DecorationImage(
              image: AssetImage(Images.profileAvatar),
            ),
          ),
          foregroundDecoration: state.picture != null
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3,
                  ),
                  image: DecorationImage(
                    image: FileImage(state.picture!),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Positioned _addEditCover(
      BoxConstraints constraints, BuildContext context, LogifyState state) {
    return Positioned(
      top: 0,
      child: Stack(
        children: [
          Container(
            width: constraints.maxWidth,
            height: constraints.maxWidth * 0.35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
              color: Theme.of(context).cardColor,
            ),
            foregroundDecoration: state.cover != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 1.5,
                    ),
                    image: DecorationImage(
                      image: FileImage(state.cover!),
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 6,
            top: 2,
            child: TextButton(
              onPressed: () {
                context.read<LogifyCubit>().selectMetadataMedia(false);
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                visualDensity: VisualDensity.comfortable,
              ),
              child: Text(
                state.cover != null
                    ? context.t.editCover.capitalizeFirst()
                    : context.t.addCover.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupDirectWallet extends HookWidget {
  const SignupDirectWallet({
    super.key,
    required this.walletTextEditingController,
    required this.errorMessage,
    required this.useWallet,
  });

  final TextEditingController walletTextEditingController;
  final ValueNotifier<String> errorMessage;
  final ValueNotifier<bool> useWallet;

  @override
  Widget build(BuildContext context) {
    final c1 = Column(
      key: const ValueKey('c1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _useWallet(context),
        if (useWallet.value) ...[
          const SizedBox(height: kDefaultPadding / 2),
          _walletTextfield(context),
        ],
        if (errorMessage.value.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                left: kDefaultPadding / 4,
              ),
              child: Text(
                errorMessage.value,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kRed,
                    ),
              ),
            ),
          ),
        ],
      ],
    );

    return BlocBuilder<LogifyCubit, LogifyState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: c1,
        );
      },
    );
  }

  Row _walletTextfield(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: TextFormField(
            controller: walletTextEditingController,
            style: Theme.of(context).textTheme.labelMedium,
            onChanged: (_) {
              errorMessage.value = '';
            },
            decoration: InputDecoration(
              hintText: context.t.yourName,
              hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Text(
          '@wallet.yakihonne.com',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }

  Container _useWallet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          useWallet.value = !useWallet.value;
        },
        behavior: HitTestBehavior.translucent,
        child: Row(
          children: [
            Checkbox(
              value: useWallet.value,
              onChanged: (value) {
                useWallet.value = value ?? true;
              },
            ),
            Text(
              context.t.createWalletSendRecSats.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
