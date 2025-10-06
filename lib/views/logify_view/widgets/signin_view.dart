// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../wallet_view/send_zaps_view/send_tips_invoice.dart';
import '../../widgets/content_manager/add_discover_filter.dart';
import 'signup_appbar.dart';

class SignInView extends HookWidget {
  const SignInView({
    super.key,
    required this.controller,
    this.onPop,
  });

  final PageController controller;
  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final isKeysSelected = useState(true);

    final t = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      child: Column(
        spacing: kDefaultPadding / 4,
        children: [
          Row(
            spacing: kDefaultPadding / 4,
            children: [
              Expanded(
                child: SendOptionsButton(
                  onClicked: () {
                    isKeysSelected.value = true;
                    context.read<LogifyCubit>().offloadRemoteSigner();
                  },
                  title: context.t.keys,
                  icon: FeatureIcons.keys,
                  borderColor: isKeysSelected.value
                      ? Theme.of(context).primaryColor
                      : null,
                  borderWidth: isKeysSelected.value ? 1.5 : null,
                ),
              ),
              Expanded(
                child: SendOptionsButton(
                  onClicked: () {
                    isKeysSelected.value = false;
                  },
                  title: context.t.remoteSigner,
                  icon: FeatureIcons.shareGlobal,
                  borderColor: !isKeysSelected.value
                      ? Theme.of(context).primaryColor
                      : null,
                  borderWidth: !isKeysSelected.value ? 1.5 : null,
                ),
              ),
            ],
          ),
          if (isExternalSignerInstalled) ...[
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  context.read<LogifyCubit>().loginWithAmber(
                        onSuccess: onPop ??
                            () {
                              Navigator.pop(context);
                            },
                      );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    color: Theme.of(context).cardColor,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 2,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.t.amber.capitalizeFirst(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return SafeArea(
      child: Column(
        children: [
          OnboardingAppbar(
            title: context.t.loginAction.capitalizeFirst(),
            onReturn: () {
              controller.previousPage(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
              context.read<LogifyCubit>().offloadRemoteSigner();
            },
          ),
          Expanded(
            child: isKeysSelected.value
                ? KeysLogin(
                    key: const ValueKey('keys_login'),
                    onPop: onPop,
                  )
                : RemoteLogin(
                    onPop: onPop,
                  ),
          ),
          t,
        ],
      ),
    );
  }
}

class RemoteLogin extends HookWidget {
  const RemoteLogin({
    super.key,
    this.onPop,
  });

  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final logifyCubit = context.read<LogifyCubit>();
    final textEditingController = useTextEditingController();
    final connectionUrlFuture = useMemoized(
      () {
        return logifyCubit.initRemoteSignerFromNostrConnect(
          context: context,
          onSuccess: onPop ??
              () {
                YNavigator.popToRoot(context);
              },
        );
      },
    );

    final isLoading = useState(false);

    final connectionUrlSnapshot = useFuture(connectionUrlFuture);

    final connectionUrl = connectionUrlSnapshot.data ?? '';

    final components = <Widget>[
      Text(
        context.t.remoteSigner,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(
        height: kDefaultPadding / 4,
      ),
      Text(
        context.t.useUrlBunker,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(
        height: kDefaultPadding,
      ),
      Center(
        child: Container(
          width: 60.w,
          height: 60.w,
          padding: const EdgeInsets.all(
            kDefaultPadding / 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            border: Border.all(
              color: Theme.of(context).primaryColorDark,
              width: 2,
            ),
          ),
          child: QrImageView(
            data: connectionUrl,
            dataModuleStyle: QrDataModuleStyle(
              color: Theme.of(context).primaryColorDark,
              dataModuleShape: QrDataModuleShape.circle,
            ),
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: Theme.of(context).primaryColorDark,
            ),
            embeddedImage: const AssetImage(
              Images.logo,
            ),
          ),
        ),
      ),
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
      DottedCopyContainer(
        lnurl: connectionUrl,
        message: context.t.textSuccesfulyCopied,
      ),
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
      Text(
        context.t.or,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
      TextField(
        controller: textEditingController,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: const InputDecoration(
          hintText: 'bunker://..',
        ),
      ),
      const SizedBox(
        height: kDefaultPadding / 4,
      ),
      RegularLoadingButton(
        title: context.t.login,
        onClicked: () async {
          isLoading.value = true;

          await logifyCubit.initRemoteSignerFromBunkerUrl(
            bunkerUrl: textEditingController.text,
            onSuccess: onPop ??
                () {
                  YNavigator.popToRoot(context);
                  isLoading.value = false;
                },
            context: context,
          );

          isLoading.value = false;
        },
        isLoading: isLoading.value,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(kDefaultPadding),
      children: components,
    );
  }
}

class KeysLogin extends HookWidget {
  const KeysLogin({super.key, this.onPop});

  final Function()? onPop;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final textEditingController = useTextEditingController();
    final textfieldValue = useState('');
    final components = <Widget>[];

    components.addAll(
      [
        Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.t.heyWelcomeBack,
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        )
      ],
    );

    components.add(
      Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            children: [
              _textfield(
                  formKey, textEditingController, context, textfieldValue),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              _textButton(
                  textEditingController, context, textfieldValue, formKey),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                context.t.secureStorageDesc.capitalizeFirst(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    return ListView(
      children: components,
    );
  }

  SizedBox _textButton(
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
                    onSuccess: onPop ??
                        () {
                          Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          );
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

  Form _textfield(
      GlobalKey<FormState> formKey,
      TextEditingController textEditingController,
      BuildContext context,
      ValueNotifier<String> textfieldValue) {
    return Form(
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
    );
  }
}
