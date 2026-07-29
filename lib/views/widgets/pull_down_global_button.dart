import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/app_models/popup_menu_common_item.dart';
import '../../models/flash_news_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../utils/utils.dart';
import 'app_icon.dart';
import 'buttons_containers_widgets.dart';

class PullDownGlobalButton extends StatelessWidget {
  const PullDownGlobalButton({
    super.key,
    this.model,
    this.altModel,
    this.enableCopyNaddr = false,
    this.enableCopyNpub = false,
    this.enableCopyNpubHex = false,
    this.enableCopyText = false,
    this.enableCopyId = false,
    this.enableCopyUrl = false,
    this.enableCopyHash = false,
    this.enableShare = false,
    this.enableShareImage = false,
    this.enableMute = false,
    this.enableMuteEvent = false,
    this.enableBookmark = false,
    this.enableShowRawEvent = false,
    this.enablePostInNote = false,
    this.enableAddToCuration = false,
    this.enableEdit = false,
    this.enableClone = false,
    this.enableShareWidgetImage = false,
    this.enableCheckValidity = false,
    this.enableDelete = false,
    this.enableRefresh = false,
    this.enableUserRelays = false,
    this.enableSecureMessage = false,
    this.enableZap = false,
    this.enableRepublish = false,
    this.enablePin = false,
    this.enableMirror = false,
    this.enableDownload = false,
    this.enableView = false,
    this.muteStatus = false,
    this.muteEventStatus = false,
    this.bookmarkStatus = false,
    this.secureMessagesStatus = false,
    this.enableReschedule = false,
    this.onZap,
    this.onSecureMessage,
    this.onRefresh,
    this.onShowUserRelays,
    this.onDelete,
    this.onCheckValidity,
    this.onShareWidgetImage,
    this.onShareImage,
    this.onClone,
    this.isCloning,
    this.onEdit,
    this.onAddToCuration,
    this.onPostInNote,
    this.onShowRawEvent,
    this.onBookmark,
    this.onMute,
    this.onMuteEvent,
    this.onShare,
    this.onCopyNaddr,
    this.onCopyNpub,
    this.onCopyNpubHex,
    this.onCopyText,
    this.onCopyNoteId,
    this.onCopyUrl,
    this.onCopyHash,
    this.onMirror,
    this.onDownload,
    this.onView,
    this.onPin,
    this.widgetImage,
    this.menuBackgroundColor,
    this.buttonColor,
    this.iconColor,
    this.iconSize,
    this.size,
    this.onMuteActionSuccess,
    this.onRepublish,
    this.onReschedule,
    this.publishTitle,
    this.customItems,
    this.useFluidMode = false,
    this.iconBackgroundColor,
  });

  final BaseEventModel? model;
  final BaseEventModel? altModel;

  final bool enableRefresh;
  final bool enableUserRelays;
  final bool enablePostInNote;
  final bool enableCopyNpub;
  final bool enableCopyNpubHex;
  final bool enableCopyText;
  final bool enableCopyId;
  final bool enableCopyUrl;
  final bool enableCopyHash;
  final bool enableCopyNaddr;
  final bool enableBookmark;
  final bool enableAddToCuration;
  final bool enableShare;
  final bool enableShareImage;
  final bool enableMute;
  final bool enableMuteEvent;
  final bool enableShowRawEvent;
  final bool enableEdit;
  final bool enableClone;
  final bool enableShareWidgetImage;
  final bool enableCheckValidity;
  final bool enableDelete;
  final bool enableZap;
  final bool enableSecureMessage;
  final bool enableRepublish;
  final bool enablePin;
  final bool enableReschedule;
  final bool enableMirror;
  final bool enableDownload;
  final bool enableView;

  final Function()? onRefresh;
  final Function()? onShowUserRelays;
  final Function()? onPostInNote;
  final Function()? onMute;
  final Function()? onMuteEvent;
  final Function()? onShare;
  final Function()? onShareImage;
  final Function()? onCopyNaddr;
  final Function()? onCopyNpub;
  final Function()? onCopyText;
  final Function()? onAddToCuration;
  final Function()? onCopyNpubHex;
  final Function()? onCopyNoteId;
  final Function()? onCopyUrl;
  final Function()? onCopyHash;
  final Function()? onDownload;
  final Function()? onMirror;
  final Function()? onView;
  final Function()? onBookmark;
  final Function()? onShowRawEvent;
  final Function()? onEdit;
  final Function()? onClone;
  final Function()? onShareWidgetImage;
  final Function()? onCheckValidity;
  final Function()? onDelete;
  final Function()? onZap;
  final Function()? onSecureMessage;
  final Function()? onRepublish;
  final Function()? onPin;
  final Function(String, bool)? onMuteActionSuccess;
  final Function()? onReschedule;

  final bool muteStatus;
  final bool muteEventStatus;
  final bool bookmarkStatus;
  final bool secureMessagesStatus;
  final bool? isCloning;
  final String? widgetImage;

  final Color? menuBackgroundColor;
  final Color? buttonColor;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? iconSize;
  final double? size;
  final String? publishTitle;
  final List<PullDownMenuEntry>? customItems;

  final bool? useFluidMode;

  @override
  Widget build(BuildContext context) {
    final isDark = themeCubit.isDark;

    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: menuBackgroundColor ?? Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        return [
          if (enableRefresh)
            _pullDownItem(
              context: context,
              title: context.t.refresh.capitalizeFirst(),
              onTap: () => onRefresh?.call(),
              icon: FeatureIcons.refresh,
            ),
          if (enableView)
            _pullDownItem(
              context: context,
              title: context.t.view.capitalizeFirst(),
              onTap: () => onView?.call(),
              icon: FeatureIcons.visible,
            ),
          if (enableDownload)
            _pullDownItem(
              context: context,
              title: context.t.downloadFile.capitalizeFirst(),
              onTap: () => onDownload?.call(),
              icon: FeatureIcons.download,
            ),
          if (enablePostInNote && (model != null || onPostInNote != null))
            _pullDownItem(
              context: context,
              title: context.t.postInNote.capitalizeFirst(),
              onTap: () => onPostInNote != null
                  ? onPostInNote!.call()
                  : (model != null
                      ? PdmCommonActions.postInNote(context, altModel ?? model!)
                      : null),
              icon: FeatureIcons.addUncensoredNote,
            ),
          if (enableCopyHash)
            _pullDownItem(
              context: context,
              title: context.t.copyHash.capitalizeFirst(),
              onTap: () => onCopyHash?.call(),
              icon: FeatureIcons.copyNaddr,
            ),
          if (enableCopyUrl)
            _pullDownItem(
              context: context,
              title: context.t.copyUrl.capitalizeFirst(),
              onTap: () => onCopyUrl?.call(),
              icon: FeatureIcons.copy,
            ),
          if (enableMirror)
            _pullDownItem(
              context: context,
              title: context.t.mirror.capitalizeFirst(),
              onTap: () => onMirror?.call(),
              icon: FeatureIcons.refresh,
            ),
          if (canSign() && enableZap && model != null)
            _pullDownItem(
              context: context,
              title: context.t.zap.capitalizeFirst(),
              onTap: () => onZap != null
                  ? onZap!.call()
                  : PdmCommonActions.onZap(context, model!),
              icon: FeatureIcons.zap,
            ),
          if (canSign() && enableSecureMessage)
            _pullDownItem(
              context: context,
              title: secureMessagesStatus
                  ? context.t.disableSecureDms.capitalizeFirst()
                  : context.t.enableSecureDms.capitalizeFirst(),
              onTap: () => onSecureMessage != null
                  ? onSecureMessage!.call()
                  : PdmCommonActions.onSecureStorage(context),
              icon: FeatureIcons.link,
              iconColor: secureMessagesStatus
                  ? kRed
                  : Theme.of(context).primaryColorDark,
              isDestructive: secureMessagesStatus,
            ),
          if (enableCopyNpub && model != null)
            _pullDownItem(
              context: context,
              title: context.t.copyNpub.capitalizeFirst(),
              icon: FeatureIcons.keys,
              onTap: () => onCopyNpub != null
                  ? onCopyNpub!.call()
                  : PdmCommonActions.copyNpub(model!.pubkey),
            ),
          if (enableCopyNpubHex && model != null)
            _pullDownItem(
              context: context,
              title: context.t.copyNpub.capitalizeFirst(),
              icon: FeatureIcons.hex,
              onTap: () => onCopyNpub != null
                  ? onCopyNpub!.call()
                  : PdmCommonActions.copyNpub(model!.pubkey, isHex: true),
            ),
          if (enableCopyNaddr && model != null)
            _pullDownItem(
              context: context,
              title: context.t.copyNaddr.capitalizeFirst(),
              icon: FeatureIcons.copyNaddr,
              onTap: () => onCopyNaddr != null
                  ? onCopyNaddr!.call()
                  : PdmCommonActions.copyNaddr(model!),
            ),
          if (enableCopyId && model != null)
            _pullDownItem(
              context: context,
              title: context.t.copyId.capitalizeFirst(),
              icon: FeatureIcons.copyNaddr,
              onTap: () => onCopyNoteId != null
                  ? onCopyNoteId!.call()
                  : PdmCommonActions.copyId(model!),
            ),
          if (enableCopyText && model != null)
            _pullDownItem(
              context: context,
              title: context.t.copyText.capitalizeFirst(),
              icon: FeatureIcons.codeText,
              onTap: () => onCopyText != null
                  ? onCopyText!.call()
                  : PdmCommonActions.copyText(model!),
            ),
          if (enableUserRelays)
            _pullDownItem(
              context: context,
              title: context.t.userRelays.capitalizeFirst(),
              onTap: () => onShowUserRelays?.call(),
              icon: FeatureIcons.relays,
            ),
          if (enableShowRawEvent && model != null)
            _pullDownItem(
              context: context,
              title: context.t.showRawEvent.capitalizeFirst(),
              icon: FeatureIcons.showRawEvent,
              onTap: () => onShowRawEvent != null
                  ? onShowRawEvent!.call()
                  : PdmCommonActions.showRawEvent(context, model!),
            ),
          if (canSign() && enableAddToCuration && model != null)
            _pullDownItem(
              context: context,
              title: context.t.addToCuration.capitalizeFirst(),
              icon: FeatureIcons.addCuration,
              onTap: () => onAddToCuration != null
                  ? onAddToCuration!.call()
                  : PdmCommonActions.addToCuration(context, model!),
            ),
          if (canSign() && enableClone && model != null)
            _pullDownItem(
              context: context,
              title: context.t.clone.capitalizeFirst(),
              icon: FeatureIcons.clone,
              onTap: () => onClone != null
                  ? onClone!.call()
                  : PdmCommonActions.editEvent(
                      context,
                      model!,
                      isCloning != null ? true : null,
                    ),
            ),
          if (canSign() && enablePin && model != null)
            _pullDownItem(
              context: context,
              title: nostrRepository.pinnedNotes.contains(model!.id)
                  ? context.t.unpin.capitalizeFirst()
                  : context.t.pin.capitalizeFirst(),
              icon: nostrRepository.pinnedNotes.contains(model!.id)
                  ? FeatureIcons.unpin
                  : FeatureIcons.pin,
              onTap: () => onPin != null
                  ? onPin!.call()
                  : PdmCommonActions.pinEvent(model!),
            ),
          if (canSign() && enableShareWidgetImage)
            _pullDownItem(
              context: context,
              title: context.t.shareWidgetImage.capitalizeFirst(),
              icon: FeatureIcons.share,
              onTap: () => onShareWidgetImage != null
                  ? onShareWidgetImage!.call()
                  : PdmCommonActions.shareWidgetImage(context, widgetImage!),
            ),
          if (enableCheckValidity && model != null)
            _pullDownItem(
              context: context,
              title: context.t.checkValidity.capitalizeFirst(),
              icon: FeatureIcons.swChecker,
              onTap: () => onCheckValidity != null
                  ? onCheckValidity!.call()
                  : PdmCommonActions.checkValidity(
                      context, model! as SmartWidget),
            ),
          if (canSign() && enableEdit && model != null)
            _pullDownItem(
              context: context,
              title: context.t.edit.capitalizeFirst(),
              icon: FeatureIcons.editArticle,
              onTap: () => onEdit != null
                  ? onEdit!.call()
                  : PdmCommonActions.editEvent(
                      context,
                      model!,
                      isCloning != null ? false : null,
                    ),
            ),
          if (canSign() && enableBookmark && model != null)
            _pullDownItem(
              context: context,
              title: context.t.bookmark.capitalizeFirst(),
              icon: bookmarkStatus
                  ? isDark
                      ? FeatureIcons.bookmarkFilledWhite
                      : FeatureIcons.bookmarkFilledBlack
                  : isDark
                      ? FeatureIcons.bookmarkEmptyWhite
                      : FeatureIcons.bookmarkEmptyBlack,
              onTap: () => onBookmark != null
                  ? onBookmark!.call()
                  : PdmCommonActions.bookmarkBaseEventModel(context, model!),
            ),
          if (canSign() && enableRepublish && model != null)
            _pullDownItem(
              context: context,
              title: publishTitle ?? context.t.republish.capitalizeFirst(),
              icon: FeatureIcons.republish,
              onTap: () => onRepublish != null
                  ? onRepublish!.call()
                  : PdmCommonActions.republish(
                      model: model!,
                      context: context,
                    ),
            ),
          if (enableShareImage && model != null)
            _pullDownItem(
              context: context,
              title: context.t.shareAsImage.capitalizeFirst(),
              icon: FeatureIcons.image,
              onTap: () => onShareImage != null
                  ? onShareImage!.call()
                  : PdmCommonActions.shareBaseEventImage(context, model!),
            ),
          if (enableShare && model != null)
            _pullDownItem(
              context: context,
              title: context.t.share.capitalizeFirst(),
              icon: FeatureIcons.shareGlobal,
              onTap: () => onShare != null
                  ? onShare!.call()
                  : PdmCommonActions.shareBaseEventModel(context, model!),
            ),
          if (canSign() && enableReschedule)
            _pullDownItem(
              context: context,
              title: context.t.reschedule.capitalizeFirst(),
              onTap: () => onReschedule?.call(),
              icon: FeatureIcons.calendar,
            ),
          if (customItems != null) ...customItems!,
          if (canSign() && (enableMute || enableDelete || enableMuteEvent))
            const PullDownMenuDivider.large(),
          if (canSign() && enableMuteEvent && model != null)
            _pullDownItem(
              context: context,
              title: muteEventStatus
                  ? context.t.unmuteThread.capitalizeFirst()
                  : context.t.muteThread.capitalizeFirst(),
              icon: !muteEventStatus ? FeatureIcons.mute : FeatureIcons.unmute,
              iconColor:
                  !muteEventStatus ? kRed : Theme.of(context).primaryColorDark,
              isDestructive: true,
              onTap: () => onMuteEvent != null
                  ? onMuteEvent!.call()
                  : PdmCommonActions.muteThread(
                      model!.id,
                      muteEventStatus,
                      context,
                      onMuteActionSuccess: onMuteActionSuccess,
                    ),
            ),
          if (canSign() && enableMute && model != null)
            _pullDownItem(
              context: context,
              title: muteStatus
                  ? context.t.unmute.capitalizeFirst()
                  : context.t.mute.capitalizeFirst(),
              icon: !muteStatus ? FeatureIcons.mute : FeatureIcons.unmute,
              iconColor:
                  !muteStatus ? kRed : Theme.of(context).primaryColorDark,
              isDestructive: true,
              onTap: () => onMute != null
                  ? onMute!.call()
                  : PdmCommonActions.muteUser(
                      model!.pubkey,
                      muteStatus,
                      context,
                      onMuteActionSuccess: onMuteActionSuccess,
                    ),
            ),
          if (enableDelete)
            _pullDownItem(
              context: context,
              title: context.t.delete.capitalizeFirst(),
              icon: FeatureIcons.trash,
              iconColor: kRed,
              isDestructive: true,
              onTap: () => onDelete?.call(),
            ),
        ];
      },
      buttonBuilder: (context, showMenu) => AppIconButton(
        onClicked: showMenu,
        icon: LucideIcons.ellipsisVertical,
        iconColor: iconColor ?? Theme.of(context).primaryColorDark,
        iconSize: iconSize,
        backgroundColor: iconBackgroundColor,
        size: size,
        enableFluid: useFluidMode,
      ),
    );
  }

  PullDownMenuItem _pullDownItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Function() onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    final textStyle = Theme.of(context).textTheme.labelLarge;

    return PullDownMenuItem(
      title: title,
      onTap: onTap,
      itemTheme: PullDownMenuItemTheme(
        textStyle: textStyle,
      ),
      isDestructive: isDestructive,
      iconWidget: AppIcon(
        icon,
        size: 20,
        color: iconColor ?? Theme.of(context).primaryColorDark,
      ),
    );
  }
}
