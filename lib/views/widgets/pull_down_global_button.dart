import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/app_models/popup_menu_common_item.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../utils/utils.dart';

class PullDownGlobalButton extends StatelessWidget {
  const PullDownGlobalButton({
    super.key,
    required this.model,
    this.altModel,
    this.enableCopyNaddr = false,
    this.enableCopyNpub = false,
    this.enableCopyNpubHex = false,
    this.enableCopyId = false,
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
    this.muteStatus = false,
    this.muteEventStatus = false,
    this.bookmarkStatus = false,
    this.secureMessagesStatus = false,
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
    this.onCopyNoteId,
    this.widgetImage,
    this.backgroundColor,
    this.buttonColor,
    this.iconColor,
    this.visualDensity,
    this.onMuteActionSuccess,
    this.onRepublish,
  });

  final BaseEventModel model;
  final BaseEventModel? altModel;

  final bool enableRefresh;
  final bool enableUserRelays;
  final bool enablePostInNote;
  final bool enableCopyNpub;
  final bool enableCopyNpubHex;
  final bool enableCopyId;
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

  final Function()? onRefresh;
  final Function()? onShowUserRelays;
  final Function()? onPostInNote;
  final Function()? onMute;
  final Function()? onMuteEvent;
  final Function()? onShare;
  final Function()? onShareImage;
  final Function()? onCopyNaddr;
  final Function()? onCopyNpub;
  final Function()? onAddToCuration;
  final Function()? onCopyNpubHex;
  final Function()? onCopyNoteId;
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
  final Function(String, bool)? onMuteActionSuccess;

  final bool muteStatus;
  final bool muteEventStatus;
  final bool bookmarkStatus;
  final bool secureMessagesStatus;
  final bool? isCloning;
  final String? widgetImage;

  final Color? backgroundColor;
  final Color? buttonColor;
  final Color? iconColor;
  final double? visualDensity;

  @override
  Widget build(BuildContext context) {
    final isDark = themeCubit.isDark;

    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
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
          if (canSign() && enablePostInNote)
            _pullDownItem(
              context: context,
              title: context.t.postInNote.capitalizeFirst(),
              onTap: () => onPostInNote != null
                  ? onPostInNote!.call()
                  : PdmCommonActions.postInNote(context, altModel ?? model),
              icon: FeatureIcons.addUncensoredNote,
            ),
          if (canSign() && enableZap)
            _pullDownItem(
              context: context,
              title: context.t.zap.capitalizeFirst(),
              onTap: () => onZap != null
                  ? onZap!.call()
                  : PdmCommonActions.onZap(context, model),
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
          if (enableCopyNpub)
            _pullDownItem(
              context: context,
              title: context.t.copyNpub.capitalizeFirst(),
              icon: FeatureIcons.keys,
              onTap: () => onCopyNpub != null
                  ? onCopyNpub!.call()
                  : PdmCommonActions.copyNpub(model.pubkey),
            ),
          if (enableCopyNpubHex)
            _pullDownItem(
              context: context,
              title: context.t.copyNpub.capitalizeFirst(),
              icon: FeatureIcons.hex,
              onTap: () => onCopyNpub != null
                  ? onCopyNpub!.call()
                  : PdmCommonActions.copyNpub(model.pubkey, isHex: true),
            ),
          if (enableCopyNaddr)
            _pullDownItem(
              context: context,
              title: context.t.copyNaddr.capitalizeFirst(),
              icon: FeatureIcons.copyNaddr,
              onTap: () => onCopyNaddr != null
                  ? onCopyNaddr!.call()
                  : PdmCommonActions.copyNaddr(model),
            ),
          if (enableCopyId)
            _pullDownItem(
              context: context,
              title: context.t.copyId.capitalizeFirst(),
              icon: FeatureIcons.copyNaddr,
              onTap: () => onCopyNoteId != null
                  ? onCopyNoteId!.call()
                  : PdmCommonActions.copyId(model as DetailedNoteModel),
            ),
          if (enableUserRelays)
            _pullDownItem(
              context: context,
              title: context.t.userRelays.capitalizeFirst(),
              onTap: () => onShowUserRelays?.call(),
              icon: FeatureIcons.relays,
            ),
          if (enableShowRawEvent)
            _pullDownItem(
              context: context,
              title: context.t.showRawEvent.capitalizeFirst(),
              icon: FeatureIcons.showRawEvent,
              onTap: () => onShowRawEvent != null
                  ? onShowRawEvent!.call()
                  : PdmCommonActions.showRawEvent(context, model),
            ),
          if (canSign() && enableAddToCuration)
            _pullDownItem(
              context: context,
              title: context.t.addToCuration.capitalizeFirst(),
              icon: FeatureIcons.addCuration,
              onTap: () => onAddToCuration != null
                  ? onAddToCuration!.call()
                  : PdmCommonActions.addToCuration(context, model),
            ),
          if (canSign() && enableClone)
            _pullDownItem(
              context: context,
              title: context.t.clone.capitalizeFirst(),
              icon: FeatureIcons.clone,
              onTap: () => onClone != null
                  ? onClone!.call()
                  : PdmCommonActions.editEvent(
                      context,
                      model,
                      isCloning != null ? true : null,
                    ),
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
          if (enableCheckValidity)
            _pullDownItem(
              context: context,
              title: context.t.checkValidity.capitalizeFirst(),
              icon: FeatureIcons.swChecker,
              onTap: () => onCheckValidity != null
                  ? onCheckValidity!.call()
                  : PdmCommonActions.checkValidity(
                      context, model as SmartWidget),
            ),
          if (canSign() && enableEdit)
            _pullDownItem(
              context: context,
              title: context.t.edit.capitalizeFirst(),
              icon: FeatureIcons.article,
              onTap: () => onEdit != null
                  ? onEdit!.call()
                  : PdmCommonActions.editEvent(
                      context,
                      model,
                      isCloning != null ? false : null,
                    ),
            ),
          if (canSign() && enableBookmark)
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
                  : PdmCommonActions.bookmarkBaseEventModel(context, model),
            ),
          if (canSign() && enableRepublish)
            _pullDownItem(
              context: context,
              title: context.t.republish.capitalizeFirst(),
              icon: FeatureIcons.republish,
              onTap: () => onRepublish != null
                  ? onRepublish!.call()
                  : PdmCommonActions.republish(
                      model: model,
                      context: context,
                    ),
            ),
          if (enableShareImage)
            _pullDownItem(
              context: context,
              title: context.t.shareAsImage.capitalizeFirst(),
              icon: FeatureIcons.image,
              onTap: () => onShareImage != null
                  ? onShareImage!.call()
                  : PdmCommonActions.shareBaseEventImage(context, model),
            ),
          if (enableShare)
            _pullDownItem(
              context: context,
              title: context.t.share.capitalizeFirst(),
              icon: FeatureIcons.shareGlobal,
              onTap: () => onShare != null
                  ? onShare!.call()
                  : PdmCommonActions.shareBaseEventModel(context, model),
            ),
          if (canSign() && (enableMute || enableDelete))
            const PullDownMenuDivider.large(),
          if (canSign() && enableMuteEvent)
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
                      model.id,
                      muteEventStatus,
                      context,
                      onMuteActionSuccess: onMuteActionSuccess,
                    ),
            ),
          if (canSign() && enableMute)
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
                      model.pubkey,
                      muteStatus,
                      context,
                      onMuteActionSuccess: onMuteActionSuccess,
                    ),
            ),
          if (canSign() && enableDelete)
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
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: buttonColor ?? kTransparent,
          visualDensity: VisualDensity(
            horizontal: visualDensity ?? -4,
            vertical: visualDensity ?? -1,
          ),
        ),
        icon: Icon(
          Icons.more_vert_rounded,
          color: iconColor ?? Theme.of(context).primaryColorDark,
          size: 20,
        ),
      ),
    );
  }

  PullDownMenuItem _pullDownItem({
    required BuildContext context,
    required String title,
    required String icon,
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
      iconWidget: SvgPicture.asset(
        icon,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          iconColor ?? Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
