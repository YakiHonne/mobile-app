// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../logic/share_content_cubit/share_content_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../logify_view/logify_view.dart';
import 'content_manager/add_discover_filter.dart';
import 'custom_icon_buttons.dart';
import 'data_providers.dart';
import 'dotted_container.dart';
import 'profile_picture.dart';

class ShareView extends HookWidget {
  const ShareView({
    super.key,
    required this.url,
    required this.nostrScheme,
    required this.onShareUrl,
    required this.onShareNostrScheme,
  });

  final String url;
  final String nostrScheme;
  final Function() onShareUrl;
  final Function() onShareNostrScheme;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final color = Theme.of(context).primaryColorDark;

    return BlocProvider(
      create: (context) => ShareContentCubit(
        color: color,
        url: url,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 15.w : kDefaultPadding / 2,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(kDefaultPadding),
            topRight: Radius.circular(kDefaultPadding),
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: _content(),
      ),
    );
  }

  DraggableScrollableSheet _content() {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.40,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<ShareContentCubit, ShareContentState>(
          builder: (context, state) {
            return Column(
              children: [
                const ModalBottomSheetHandle(),
                Text(
                  context.t.share.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Expanded(
                  child: state.isSendingToFollowings
                      ? SendToFollowings(
                          url: url,
                        )
                      : ShareQrCode(
                          url: url,
                          controller: scrollController,
                        ),
                ),
                _actionsRow(context, state),
              ],
            );
          },
        );
      },
    );
  }

  SafeArea _actionsRow(BuildContext context, ShareContentState state) {
    return SafeArea(
      child: SizedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding / 2,
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButtonWithText(
                  onClicked: () {
                    context.read<ShareContentCubit>().setIsSending(true);
                  },
                  text: context.t.send.capitalizeFirst(),
                  icon: FeatureIcons.user,
                  isSelected: state.isSendingToFollowings,
                ),
                IconButtonWithText(
                  onClicked: () {
                    context.read<ShareContentCubit>().setIsSending(false);
                  },
                  text: context.t.qrCode.capitalizeFirst(),
                  icon: FeatureIcons.qr,
                  isSelected: !state.isSendingToFollowings,
                ),
                const VerticalDivider(
                  indent: kDefaultPadding / 2,
                  endIndent: kDefaultPadding / 2,
                ),
                IconButtonWithText(
                  onClicked: onShareUrl,
                  text: context.t.shareLink.capitalizeFirst(),
                  icon: FeatureIcons.link,
                ),
                IconButtonWithText(
                  onClicked: onShareNostrScheme,
                  text: url.contains('note')
                      ? context.t.shareNoteId.capitalizeFirst()
                      : url.contains('profile')
                          ? context.t.shareNprofile.capitalizeFirst()
                          : context.t.shareNaddr.capitalizeFirst(),
                  icon: FeatureIcons.shareExternal,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SendToFollowings extends HookWidget {
  const SendToFollowings({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final messageController = useTextEditingController();

    return BlocBuilder<ShareContentCubit, ShareContentState>(
      builder: (context, state) {
        final pubkeys = state.availablePubkeys.toList();
        final processedPubkeys = state.processedPubkeys.entries.toList();

        if (!canSign()) {
          return emptyList(context: context, canSign: false);
        }

        return Column(
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _buildSearchTextfield(context),
            const SizedBox(height: kDefaultPadding),
            if (pubkeys.isNotEmpty)
              _buildUsersList(context, pubkeys, state)
            else
              Expanded(
                child: emptyList(context: context, canSign: true),
              ),
            if (state.processedPubkeys.isNotEmpty)
              Flexible(
                flex: 0,
                child: _buildOngoingShare(
                  context,
                  processedPubkeys,
                  state,
                  messageController,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget emptyList({required BuildContext context, required bool canSign}) {
    return SizedBox(
      width: 70.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: kDefaultPadding,
        children: [
          SvgPicture.asset(
            FeatureIcons.user,
            width: 70,
            height: 70,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          Text(
            context.t.shareEmptyUsers,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
          if (!canSign) ...[
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  YNavigator.pushReplacement(context, LogifyView());
                },
                child: Text(context.t.login),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Column _buildOngoingShare(
    BuildContext context,
    List<MapEntry<String, ShareContentUserStatus>> processedPubkeys,
    ShareContentState state,
    TextEditingController messageController,
  ) {
    return Column(
      children: [
        const Divider(
          height: 0,
          thickness: 0.5,
        ),

        const SizedBox(height: kDefaultPadding / 2),
        _usersList(context, processedPubkeys, state),
        const SizedBox(height: kDefaultPadding / 2),
        // Fixed bottom input section
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom >
                    (kBottomNavigationBarHeight + kDefaultPadding)
                ? MediaQuery.of(context).viewInsets.bottom -
                    kBottomNavigationBarHeight -
                    kDefaultPadding
                : 0,
          ),
          child: Row(
            spacing: kDefaultPadding / 4,
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  style: Theme.of(context).textTheme.labelLarge,
                  decoration: InputDecoration(
                    hintText: context.t.message,
                  ),
                ),
              ),
              RegularLoadingButton(
                title: context.t.send,
                onClicked: () {
                  context
                      .read<ShareContentCubit>()
                      .sendUrl(messageController.text);
                },
                isLoading: state.isSending,
              ),
              if (state.hasFinished) _close(context, messageController)
            ],
          ),
        ),
      ],
    );
  }

  GestureDetector _close(
      BuildContext context, TextEditingController messageController) {
    return GestureDetector(
      onTap: () {
        context.read<ShareContentCubit>().refresh();
        messageController.clear();
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          border: Border.all(
            width: 0.5,
            color: Theme.of(context).dividerColor,
          ),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          FeatureIcons.closeRaw,
          width: 25,
          height: 25,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  SizedBox _usersList(
      BuildContext context,
      List<MapEntry<String, ShareContentUserStatus>> processedPubkeys,
      ShareContentState state) {
    return SizedBox(
      height: 15.w + 30,
      width: double.infinity,
      child: ScrollShadow(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(
              alpha: 0.3,
            ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (context, index) => const SizedBox(
            width: kDefaultPadding / 4,
          ),
          itemBuilder: (context, index) {
            final p = processedPubkeys[index];

            return ShareContentUser(
              pubkey: p.key,
              status: p.value,
              onRemove: () {
                context.read<ShareContentCubit>().removePubkey(p.key);
              },
            );
          },
          itemCount: state.processedPubkeys.length,
        ),
      ),
    );
  }

  Expanded _buildUsersList(
    BuildContext context,
    List<String> pubkeys,
    ShareContentState state,
  ) {
    return Expanded(
      child: ScrollShadow(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(
              alpha: 0.3,
            ),
        child: GridView.builder(
          shrinkWrap: true,
          primary: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisExtent: 15.w + kDefaultPadding * 2,
            crossAxisSpacing: kDefaultPadding / 4,
            mainAxisSpacing: kDefaultPadding / 4,
          ),
          itemBuilder: (context, index) {
            final p = pubkeys[index];

            return ShareContentUser(
              pubkey: p,
              onClicked: () {
                if (!state.isSending) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.read<ShareContentCubit>().addPubkey(p);
                }
              },
            );
          },
          itemCount: state.availablePubkeys.length,
        ),
      ),
    );
  }

  TextField _buildSearchTextfield(BuildContext context) {
    return TextField(
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: context.t.searchByUserName,
      ),
      onChanged: (search) {
        context.read<ShareContentCubit>().getUsers(search);
      },
    );
  }
}

class ShareContentUser extends StatelessWidget {
  const ShareContentUser({
    super.key,
    required this.pubkey,
    this.onClicked,
    this.onRemove,
    this.status,
  });

  final String pubkey;
  final Function()? onClicked;
  final Function()? onRemove;
  final ShareContentUserStatus? status;

  @override
  Widget build(BuildContext context) {
    final icon = status == ShareContentUserStatus.idle
        ? FeatureIcons.closeRaw
        : status == ShareContentUserStatus.success
            ? ToastsIcons.check
            : ToastsIcons.error;
    final iconColor = status == ShareContentUserStatus.success ||
            status == ShareContentUserStatus.failure
        ? kTransparent
        : null;

    final widget = status == ShareContentUserStatus.sending
        ? SpinKitCircle(
            size: 15,
            color: Theme.of(context).primaryColorDark,
          )
        : null;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onClicked,
        child: MetadataProvider(
          pubkey: pubkey,
          key: ValueKey(pubkey),
          child: (m, n05) => SizedBox(
            width: 20.w,
            child: Column(
              spacing: kDefaultPadding / 4,
              children: [
                _thumbnail(m, icon, widget, iconColor, context),
                _info(m, context, n05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row _info(Metadata m, BuildContext context, bool n05) {
    return Row(
      spacing: kDefaultPadding / 8,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            m.getName(),
            style: Theme.of(context).textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (n05)
          SvgPicture.asset(
            FeatureIcons.verified,
            width: 15,
            height: 15,
          ),
      ],
    );
  }

  Stack _thumbnail(Metadata m, String icon, SpinKitCircle? widget,
      Color? iconColor, BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 15.w,
          width: 15.w,
          padding: EdgeInsets.all(status != null ? 6 : 0),
          child: LayoutBuilder(
            builder: (context, constraints) => ProfilePicture3(
              size: constraints.maxHeight,
              image: m.picture,
              pubkey: pubkey,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: onClicked ?? () {},
            ),
          ),
        ),
        if (status != null)
          Positioned(
            right: 0,
            top: 0,
            child: CustomIconButton(
              onClicked: () {
                if (status == ShareContentUserStatus.idle) {
                  onRemove?.call();
                }
              },
              icon: icon,
              widget: widget,
              iconColor: iconColor,
              size: 15,
              vd: -4,
              backgroundColor: Theme.of(context).cardColor,
            ),
          ),
      ],
    );
  }
}

class ShareQrCode extends HookWidget {
  const ShareQrCode({
    super.key,
    required this.url,
    required this.controller,
  });
  final String url;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final screenshotController = useState(ScreenshotController());
    final colors = useState(
      [
        Theme.of(context).primaryColorDark,
        kBlue,
        kRed,
        kGreen,
        kMainColor,
        kPurple,
        kYellow,
      ],
    );

    return BlocBuilder<ShareContentCubit, ShareContentState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(kDefaultPadding),
          controller: controller,
          children: [
            _buildQrCodeSection(
              context: context,
              controller: screenshotController.value,
              color: state.selectedQrColor,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _buildColorPalette(
              context: context,
              color: state.selectedQrColor,
              colors: colors.value,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _buildShareButton(
              context: context,
              controller: screenshotController.value,
            ),
          ],
        );
      },
    );
  }

  Future<void> shareImage(
    ScreenshotController controller,
  ) async {
    final cancel = BotToast.showLoading();

    try {
      final temp = await getApplicationDocumentsDirectory();
      final img = await controller.captureAndSave(temp.path);
      cancel.call();

      if (img != null) {
        await Share.shareXFiles(
          [
            XFile(img),
          ],
        );
      }
    } catch (_) {
      cancel.call();
    }
  }

  Widget _buildShareButton({
    required BuildContext context,
    required ScreenshotController controller,
  }) {
    return Center(
      child: SizedBox(
        width: 70.w,
        child: TextButton(
          onPressed: () => shareImage(controller),
          child: Text(
            context.t.share.capitalizeFirst(),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette({
    required BuildContext context,
    required Color color,
    required List<Color> colors,
  }) {
    return Center(
      child: Container(
        width: 70.w,
        decoration: _buildColorPaletteDecoration(context: context),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ...colors.map(
              (e) => GestureDetector(
                onTap: () => context.read<ShareContentCubit>().setQrColor(e),
                behavior: HitTestBehavior.translucent,
                child: Container(
                  width: 5.w,
                  height: 5.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e,
                    border: Border.all(
                      color: e == color
                          ? Theme.of(context).highlightColor
                          : kTransparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildColorPaletteDecoration({
    required BuildContext context,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      color: kTransparent,
      border: Border.all(
        color: Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildQrCodeSection({
    required BuildContext context,
    required ScreenshotController controller,
    required Color color,
  }) {
    return Screenshot(
      controller: controller,
      child: Center(
        child: Container(
          width: 70.w,
          height: 70.w,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kDefaultPadding),
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Container(
            decoration: _buildQrCodeDecoration(color: color, context: context),
            child: _buildQrCodeImage(color: color, context: context),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildQrCodeDecoration({
    required BuildContext context,
    required Color color,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding),
      border: Border.all(
        color: color,
        width: 5,
      ),
    );
  }

  Widget _buildQrCodeImage({
    required BuildContext context,
    required Color color,
  }) {
    return QrImageView(
      data: url,
      dataModuleStyle: QrDataModuleStyle(
        color: color,
        dataModuleShape: QrDataModuleShape.circle,
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.circle,
        color: color,
      ),
      embeddedImage: const AssetImage(Images.logo),
    );
  }
}

class IconButtonWithText extends StatelessWidget {
  const IconButtonWithText({
    super.key,
    required this.onClicked,
    required this.text,
    required this.icon,
    this.isSelected = false,
  });

  final Function() onClicked;
  final String text;
  final String icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          CustomIconButton(
            onClicked: onClicked,
            icon: icon,
            size: 20,
            backgroundColor:
                isSelected ? kMainColor : Theme.of(context).cardColor,
            iconColor: isSelected ? kWhite : Theme.of(context).primaryColorDark,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
