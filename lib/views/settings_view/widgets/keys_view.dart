// ignore_for_file: public_member_api_docs, sort_constructors_first, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:open_filex/open_filex.dart';

import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_scaffold.dart';
import 'google_manage_sheet.dart';
import 'settings_text.dart';

class KeysView extends HookWidget {
  KeysView({
    super.key,
    required this.pubkey,
    required this.secKey,
    required this.isUsingSigner,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Keys view');
  }

  static const routeName = '/keysView';
  static Route route(RouteSettings settings) {
    final keys = settings.arguments! as List<dynamic>;

    return CupertinoPageRoute(
      builder: (_) => KeysView(
        pubkey: keys[0],
        secKey: keys[1],
        isUsingSigner: keys[2],
      ),
    );
  }

  final String pubkey;
  final String secKey;
  final bool isUsingSigner;

  @override
  Widget build(BuildContext context) {
    final secretKey = useState(false);

    return FluidScaffold(
      title: context.t.keys.capitalizeFirst(),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding / 2)
            .copyWith(top: kDefaultPadding / 2 + fluidScaffoldTopInset(context)),
        children: [
          Text(
            context.t.settingsKeysDesc,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const Divider(
            height: kDefaultPadding * 1.5,
            thickness: 0.5,
          ),
          DottedContainer(
            title: context.t.myPublicKey.capitalizeFirst(),
            onClicked: () {
              Clipboard.setData(
                ClipboardData(
                  text: Nip19.encodePubkey(
                    pubkey,
                  ),
                ),
              );

              BotToastUtils.showSuccess(
                context.t.publicKeyCopied.capitalizeFirst(),
              );
            },
            isShown: true,
            value: Nip19.encodePubkey(
              pubkey,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            context.t.pubkeySharedDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          _dottedContainer(context, secretKey),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.triangleAlert,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Text(
                  context.t.privKeyDesc.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          _textButton(context),
          if (settingsCubit.privateKeyIndex != null &&
              settingsCubit
                  .isExternalGoogle(settingsCubit.privateKeyIndex!)) ...[
            const Divider(
              thickness: 0.5,
              height: kDefaultPadding * 2,
            ),
            _googleRow(
              context,
              title: context.t.pomRecoverTitle,
              description: context.t.recoverWithGoogle,
              onTap: () => showGoogleRecoverSheet(context),
            ),
            const SizedBox(height: kDefaultPadding),
            _googleRow(
              context,
              title: context.t.pomUnlinkTitle,
              description: context.t.googleManageUnlinkDesc,
              onTap: () => showGoogleUnlinkSheet(
                context,
                // The key is no longer reachable through Google, so this
                // account has to go — the user keeps it via the nsec the
                // unlink flow made them copy first. `onLogoutTap`, not
                // `removeKey`: the latter leaves `currentSigner` pointing at
                // the deleted account's remote signer, and leaves this
                // index flagged Google for whatever key lands there next.
                onDisconnect: () => settingsCubit.onLogoutTap(
                  settingsCubit.privateKeyIndex!,
                  onPop: () {},
                ),
              ),
            ),
          ],
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding * 2,
          ),
          TitleDescriptionComponent(
            title: context.t.note.capitalizeFirst(),
            description: context.t.secureStorageDesc.capitalizeFirst(),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
        ],
      ),
    );
  }

  Widget _googleRow(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: Theme.of(context).highlightColor,
          ),
        ],
      ),
    );
  }

  TextButton _textButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final res = await exportKeysToUserDirectory(
          publicKey: pubkey,
          secretKey: secKey,
        );

        if (res == ResultType.noAppToOpen) {
          BotToastUtils.showError(context.t.noApp);
        }
      },
      child: Text(
        context.t.exportKeys,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: kWhite,
            ),
      ),
    );
  }

  DottedContainer _dottedContainer(
      BuildContext context, ValueNotifier<bool> secretKey) {
    return DottedContainer(
      title: context.t.mySecretKey.capitalizeFirst(),
      isShown: secretKey.value,
      onClicked: () {
        if (!secretKey.value) {
          showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    secretKey.value = true;
                  },
                  style: TextButton.styleFrom(
                    backgroundBuilder: (_, __, child) => child!,
                    backgroundColor: kTransparent,
                  ),
                  child: Text(
                    context.t.show.capitalizeFirst(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundBuilder: (_, __, child) => child!,
                    backgroundColor: kTransparent,
                  ),
                  child: Text(
                    context.t.cancel.capitalizeFirst(),
                    style: const TextStyle(color: kRed),
                  ),
                ),
              ],
              title: Text(
                context.t.showSecret.capitalizeFirst(),
                style: const TextStyle(
                  height: 1.5,
                ),
              ),
              content: Text(
                context.t.showSecretDesc.capitalizeFirst(),
              ),
            ),
          );
        } else {
          if (isUsingSigner) {
            BotToastUtils.showError(
              context.t.usingExternalSignDesc.capitalizeFirst(),
            );
          } else {
            Clipboard.setData(
              ClipboardData(
                text: Nip19.encodePrivkey(
                  secKey,
                ),
              ),
            );

            BotToastUtils.showSuccess(
              context.t.privKeyCopied.capitalizeFirst(),
            );
          }
        }
      },
      fullText: true,
      value: isUsingSigner
          ? context.t.usingExternalSign.capitalizeFirst()
          : Nip19.encodePrivkey(
              secKey,
            ),
    );
  }
}

class DottedContainer extends StatelessWidget {
  const DottedContainer({
    super.key,
    required this.onClicked,
    required this.value,
    required this.title,
    this.isShown,
    this.fullText,
  });

  final Function() onClicked;
  final String value;
  final String title;
  final bool? isShown;
  final bool? fullText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isShown != null
              ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  )
              : Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
        ),
        const SizedBox(
          height: kDefaultPadding / 1.5,
        ),
        DottedBorder(
          color: Theme.of(context).primaryColorDark,
          strokeCap: StrokeCap.round,
          borderType: BorderType.rRect,
          radius: const Radius.circular(kDefaultPadding - 5),
          dashPattern: const [4],
          child: Row(
            children: [
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              _shownText(context),
              IconButton(
                onPressed: onClicked,
                icon: isShown == null || isShown!
                    ? AppIcon(
                        FeatureIcons.copy,
                        size: 20,
                        color: Theme.of(context).primaryColorDark,
                      )
                    : Text(
                        context.t.show.capitalizeFirst(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Expanded _shownText(BuildContext context) {
    return Expanded(
      child: Text(
        isShown == null || isShown!
            ? fullText != null
                ? value
                : '${value.substring(0, 10)}...${value.substring(value.length - 10, value.length)}'
            : '●●●●●●●●●●●●●●●●',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
