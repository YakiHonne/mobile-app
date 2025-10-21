// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../common/common_regex.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../profile_view/profile_view.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';

class ProfileShareView extends HookWidget {
  final Metadata metadata;

  ProfileShareView({
    super.key,
    required this.metadata,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Profile share view');
  }

  @override
  Widget build(BuildContext context) {
    final width =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 40.w : 60.w;
    final isPubkeyToggled = useState(true);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Scaffold(
        backgroundColor: kTransparent,
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          leading: Center(
            child: CustomIconButton(
              onClicked: () {
                Navigator.pop(context);
              },
              icon: FeatureIcons.closeRaw,
              size: 20,
              iconColor: kWhite,
              backgroundColor: kBlack.withValues(alpha: 0.5),
            ),
          ),
        ),
        body: _contentBox(isPubkeyToggled, context, width),
      ),
    );
  }

  SafeArea _contentBox(
      ValueNotifier<bool> isPubkeyToggled, BuildContext context, double width) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
        ),
        child: ListView(
          children: [
            _profilePicture(),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _metadataInfo(),
            const SizedBox(
              height: kDefaultPadding / 1.5,
            ),
            _tabOptions(isPubkeyToggled, context),
            const SizedBox(
              height: kDefaultPadding * 1.5,
            ),
            _qrCodeBox(width, context, isPubkeyToggled),
            const SizedBox(
              height: kDefaultPadding,
            ),
            _profileInfoRowLink(context),
            const SizedBox(
              height: kDefaultPadding / 1.5,
            ),
            profileInfoRow(
              icon: FeatureIcons.keys,
              context: context,
              title: context.t.publicKey.capitalizeFirst(),
              content: Nip19.encodePubkey(metadata.pubkey),
              copyText: context.t.profileCopied.capitalizeFirst(),
            ),
            if (metadata.lud16.isNotEmpty && metadata.lud16.contains('@')) ...[
              const SizedBox(
                height: kDefaultPadding / 1.5,
              ),
              profileInfoRow(
                icon: FeatureIcons.zap,
                context: context,
                title: context.t.lightningAddress.capitalizeFirst(),
                content: metadata.lud16,
                copyText: context.t.lnCopied.capitalizeFirst(),
              ),
            ],
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoRowLink(BuildContext context) {
    return profileInfoRow(
      context: context,
      title: context.t.profileLink.capitalizeFirst(),
      content: '${baseUrl}profile/${Nip19.encodeShareableEntity(
        'nprofile',
        metadata.pubkey,
        null,
        metadata.pubkey,
        EventKind.METADATA,
      )}',
      copyText: context.t.profileCopied.capitalizeFirst(),
      icon: FeatureIcons.link,
    );
  }

  Center _qrCodeBox(
      double width, BuildContext context, ValueNotifier<bool> isPubkeyToggled) {
    return Center(
      child: Container(
        width: width,
        height: width,
        padding: const EdgeInsets.all(
          kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          border: Border.all(
            color: Theme.of(context).primaryColorDark,
            width: 3,
          ),
        ),
        child: QrImageView(
          data: isPubkeyToggled.value
              ? 'nostr:${Nip19.encodePubkey(metadata.pubkey)}'
              : metadata.lud16,
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
    );
  }

  Row _tabOptions(ValueNotifier<bool> isPubkeyToggled, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: tabContainer(
            isPubkey: true,
            isPubkeyToggled: isPubkeyToggled,
            title: context.t.publicKey.capitalizeFirst(),
          ),
        ),
        Expanded(
          child: tabContainer(
            isPubkey: false,
            isPubkeyToggled: isPubkeyToggled,
            title: context.t.lightningAddress.capitalizeFirst(),
          ),
        ),
      ],
    );
  }

  FutureBuilder<bool> _metadataInfo() {
    return FutureBuilder(
      future: metadataCubit.isNip05Valid(metadata),
      builder: (context, snapshot) {
        final showVerified = snapshot.data != null && snapshot.data!;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                metadata.getName(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showVerified) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              SvgPicture.asset(
                FeatureIcons.verified,
                width: 15,
                height: 15,
              ),
            ],
          ],
        );
      },
    );
  }

  Center _profilePicture() {
    return Center(
      child: ProfilePicture3(
        size: 80,
        image:
            metadata.picture.isEmpty ? profileImages.first : metadata.picture,
        pubkey: metadata.pubkey,
        padding: 0,
        strokeWidth: 0,
        strokeColor: kTransparent,
        onClicked: () {},
      ),
    );
  }

  LayoutBuilder tabContainer({
    required ValueNotifier<bool> isPubkeyToggled,
    required String title,
    required bool isPubkey,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          isPubkeyToggled.value = isPubkey;
        },
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            AnimatedContainer(
              height: 4,
              width: isPubkeyToggled.value && isPubkey ||
                      !isPubkeyToggled.value && !isPubkey
                  ? constraints.maxWidth
                  : 0,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: BorderRadius.circular(kDefaultPadding),
              ),
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileInfoRow({
    required BuildContext context,
    required String title,
    required String content,
    required String copyText,
    required String icon,
  }) {
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
          width: 20,
          height: 20,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                content,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: content,
              ),
            );

            BotToastUtils.showSuccess(copyText);
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            visualDensity: const VisualDensity(
              vertical: -4,
              horizontal: -2,
            ),
          ),
          icon: SvgPicture.asset(
            FeatureIcons.copy,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}

class ConnectedUserProfileShareView extends StatefulWidget {
  ConnectedUserProfileShareView({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Profile share view');
  }

  @override
  State<ConnectedUserProfileShareView> createState() =>
      _ConnectedUserProfileShareViewState();
}

class _ConnectedUserProfileShareViewState
    extends State<ConnectedUserProfileShareView> {
  bool isQRcodeShown = true;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
      } else if (Platform.isIOS) {
        controller!.resumeCamera();
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 50.w : 70.w;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange,
            Colors.purple,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: kTransparent,
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          leading: Center(
            child: CustomIconButton(
              onClicked: () {
                Navigator.pop(context);
              },
              icon: FeatureIcons.closeRaw,
              size: 20,
              iconColor: kWhite,
              backgroundColor: kBlack.withValues(alpha: 0.5),
            ),
          ),
        ),
        body: _contentBox(context, width),
      ),
    );
  }

  SafeArea _contentBox(BuildContext context, double width) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
        ),
        child: Column(
          children: [
            _qrCode(context, width),
            const SizedBox(
              height: kDefaultPadding,
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    isQRcodeShown = !isQRcodeShown;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: kWhite,
                ),
                child: Text(
                  isQRcodeShown
                      ? context.t.scanQrCode.capitalizeFirst()
                      : context.t.viewQrCode.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: kBlack,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _qrCode(BuildContext context, double width) {
    return Expanded(
      child: isQRcodeShown
          ? const CurrentUserQrCode()
          : Column(
              children: [
                Center(
                  child: Text(
                    context.t.scanQrCode.capitalizeFirst(),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: kWhite,
                        ),
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                SizedBox(
                  width: width,
                  height: width,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding + 5,
                    ),
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: (controller) => _onQRViewCreated(
                        controller,
                        context: context,
                      ),
                      overlay: QrScannerOverlayShape(
                        borderRadius: kDefaultPadding,
                        borderColor: kWhite,
                        borderWidth: 5,
                        cutOutSize: width,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _onQRViewCreated(
    QRViewController controller, {
    required BuildContext context,
  }) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        final RegExpMatch? selectedMatch = userRegex.firstMatch(scanData.code!);
        if (selectedMatch != null) {
          final key = selectedMatch.group(2)! + selectedMatch.group(3)!;
          String pubkey = '';

          if (key.startsWith('npub')) {
            pubkey = Nip19.decodePubkey(key);
          } else if (key.startsWith('nprofile')) {
            final data = Nip19.decodeShareableEntity(key);
            pubkey = data['special'];
          }

          if (context.mounted) {
            Navigator.pop(context);

            Navigator.pushNamed(
              context,
              ProfileView.routeName,
              arguments: [pubkey],
            );
          }
        }
      }
    });
  }
}

class CurrentUserQrCode extends StatelessWidget {
  const CurrentUserQrCode({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 50.w : 70.w;

    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        final npub = 'nostr:${Nip19.encodePubkey(state.pubKey)}';

        return ListView(
          children: [
            Center(
              child: ProfilePicture2(
                size: 90,
                image: state.image.isEmpty ? profileImages.first : state.image,
                pubkey: state.random,
                padding: 0,
                strokeWidth: 3,
                strokeColor: kWhite,
                onClicked: () {
                  openProfileFastAccess(
                    context: context,
                    pubkey: state.pubKey,
                  );
                },
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Center(
              child: Text(
                state.name,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                    ),
              ),
            ),
            Center(
              child: MetadataProvider(
                pubkey: state.pubKey,
                child: (metadata, isNip05Valid) {
                  final nip05 = metadata.nip05;

                  if (nip05.isNotEmpty) {
                    return Text(
                      '@${metadata.getName()}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: kWhite,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            _qrImage(width, npub, context),
            const SizedBox(
              height: kDefaultPadding,
            ),
            _actionsRow(context, state, npub),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Center(
              child: Text(
                context.t.followMeOnNostr.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  Center _actionsRow(BuildContext context, MainState state, String npub) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                ProfileView.routeName,
                arguments: [state.pubKey],
              );
            },
            style: TextButton.styleFrom(
                backgroundColor: kWhite,
                visualDensity: const VisualDensity(
                  vertical: -2,
                )),
            icon: Text(
              context.t.visitProfile.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kBlack,
                  ),
            ),
            label: const Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: kBlack,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: npub,
                ),
              );

              BotToastUtils.showSuccess(
                context.t.publicKeyCopied.capitalizeFirst(),
              );
            },
            style: TextButton.styleFrom(
                backgroundColor: kWhite,
                visualDensity: const VisualDensity(
                  vertical: -2,
                )),
            icon: Text(
              context.t.copyNpub.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kBlack,
                  ),
            ),
            label: SvgPicture.asset(
              FeatureIcons.copy,
              width: 15,
              height: 15,
            ),
          ),
        ],
      ),
    );
  }

  Center _qrImage(double width, String npub, BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: width,
        padding: const EdgeInsets.all(
          kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          border: Border.all(
            color: kWhite,
            width: 5,
          ),
        ),
        child: QrImageView(
          data: npub,
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
    );
  }
}
