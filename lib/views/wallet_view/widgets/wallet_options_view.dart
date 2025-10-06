// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../common/common_regex.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';

class WalletOptions extends HookWidget {
  const WalletOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final isMainView = useState(true);
    final isTextfieldVisible = useState(false);
    final link = useTextEditingController();
    final name = useTextEditingController(
      text: nostrRepository.currentMetadata.getName(),
    );

    final errorMessage = useState('');

    return BlocListener<WalletsManagerCubit, WalletsManagerState>(
      listenWhen: (previous, current) =>
          previous.shouldPopView != current.shouldPopView,
      listener: (context, state) {
        Navigator.pop(context);
      },
      child: Container(
        width: isTablet ? 50.w : double.infinity,
        margin: const EdgeInsets.all(kDefaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(kDefaultPadding),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _wallet(isMainView, context),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            if (!isMainView.value) ...[
              Text(
                context.t.clickBelowToConnect.capitalizeFirst(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: kDefaultPadding / 1.5,
              ),
              _connecWithNwc(context),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _pasteNwc(context),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ] else ...[
              Text(
                context.t.createYakiWallet.capitalizeFirst(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              WalletOption(
                icon: LogosIcons.logoMarkWhite,
                title: context.t.yakiNwc.capitalizeFirst(),
                description: context.t.yakiNwcDesc.capitalizeFirst(),
                color: Theme.of(context).primaryColorDark,
                onClicked: () {
                  isTextfieldVisible.value = true;
                },
                widget: !isTextfieldVisible.value
                    ? null
                    : _walletTextfield(name, context, errorMessage),
              ),
              if (isTextfieldVisible.value) ...[
                const SizedBox(
                  height: kDefaultPadding / 8,
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      isTextfieldVisible.value = false;
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                    child: Text(
                      context.t.back.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                )
              ] else ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  context.t.orUseYourWallet.capitalizeFirst(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                WalletOption(
                  icon: FeatureIcons.nwc,
                  title: context.t.nostrWalletConnect.capitalizeFirst(),
                  description:
                      context.t.nostrWalletConnectDesc.capitalizeFirst(),
                  onClicked: () {
                    isMainView.value = false;
                    link.clear();
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                WalletOption(
                  icon: FeatureIcons.alby,
                  title: context.t.alby.capitalizeFirst(),
                  description: context.t.albyConnect.capitalizeFirst(),
                  onClicked: () {
                    context.read<WalletsManagerCubit>().launchUrl(false);
                  },
                ),
              ],
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                context.t.walletDataNote.capitalizeFirst(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Column _walletTextfield(TextEditingController name, BuildContext context,
      ValueNotifier<String> errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _walletInput(name, context, errorMessage),
        if (errorMessage.value.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Padding(
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
        ],
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        _createWallet(name, errorMessage, context),
      ],
    );
  }

  Row _walletInput(TextEditingController name, BuildContext context,
      ValueNotifier<String> errorMessage) {
    return Row(
      children: [
        Flexible(
          child: TextFormField(
            controller: name,
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

  SizedBox _createWallet(TextEditingController name,
      ValueNotifier<String> errorMessage, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          if (name.text.isEmpty) {
            errorMessage.value = context.t.usernameRequired.capitalizeFirst();
          } else if (!emailNamingRegex.hasMatch(name.text)) {
            errorMessage.value = context.t.onlyLettersNumber.capitalizeFirst();
          } else {
            walletManagerCubit.createWallet(
              context: context,
              name: name.text,
              onNameFailure: () {
                errorMessage.value = context.t.usernameTaken;
              },
            );
          }
        },
        child: Text(
          context.t.createWallet,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  SizedBox _pasteNwc(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
          final String? clipboardText = clipboardData?.text;

          if (clipboardText != null &&
              clipboardText.isNotEmpty &&
              context.mounted) {
            context.read<WalletsManagerCubit>().verifyUri(clipboardText);
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.paste_rounded,
              color: Theme.of(context).primaryColorDark,
              size: 20,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Text(
              context.t.pasteNwcAddress.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox _connecWithNwc(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          context.read<WalletsManagerCubit>().launchUrl(true);
        },
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              FeatureIcons.nwc,
              width: 20,
              height: 20,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Text(
              context.t.connectWithNwc.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Row _wallet(ValueNotifier<bool> isMainView, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Visibility(
          visible: !isMainView.value,
          maintainState: true,
          maintainSize: true,
          maintainAnimation: true,
          child: IconButton(
            onPressed: () {
              isMainView.value = true;
            },
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              visualDensity: const VisualDensity(
                vertical: -2,
                horizontal: -4,
              ),
            ),
          ),
        ),
        Text(
          context.t.wallet.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        CustomIconButton(
          onClicked: () {
            Navigator.pop(context);
          },
          icon: FeatureIcons.closeRaw,
          size: 20,
          vd: -2,
          backgroundColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}

class WalletOption extends StatelessWidget {
  const WalletOption({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onClicked,
    this.color,
    this.widget,
  });

  final String title;
  final String description;
  final String icon;
  final Function() onClicked;
  final Color? color;
  final Widget? widget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          children: [
            _infoRow(context),
            if (widget != null) ...[
              Divider(
                color: Theme.of(context).dividerColor,
                height: kDefaultPadding,
                thickness: 0.5,
              ),
              widget!
            ],
          ],
        ),
      ),
    );
  }

  Row _infoRow(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 30,
          height: 30,
          colorFilter: color != null
              ? ColorFilter.mode(
                  color!,
                  BlendMode.srcIn,
                )
              : null,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        _title(context),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        const Icon(
          Icons.add,
          size: 20,
        ),
      ],
    );
  }

  Expanded _title(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            description,
            style: Theme.of(context)
                .textTheme
                .labelSmall!
                .copyWith(color: Theme.of(context).highlightColor),
          ),
        ],
      ),
    );
  }
}
