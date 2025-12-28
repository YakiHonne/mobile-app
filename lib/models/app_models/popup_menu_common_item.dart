// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:string_validator/string_validator.dart';

import '../../common/media_handler/media_handler.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/add_bookmark_view/add_bookmark_view.dart';
import '../../views/add_content_view/add_content_view.dart';
import '../../views/article_view/widgets/article_curations_add.dart';
import '../../views/smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../views/wallet_view/send_zaps_view/send_zaps_view.dart';
import '../../views/widgets/data_providers.dart';
import '../../views/widgets/republish_view.dart';
import '../../views/widgets/response_snackbar.dart';
import '../../views/widgets/share_content_image.dart';
import '../../views/widgets/share_view.dart';
import '../../views/widgets/show_raw_event_view.dart';
import '../article_model.dart';
import '../bookmark_list_model.dart';
import '../curation_model.dart';
import '../detailed_note_model.dart';
import '../flash_news_model.dart';
import '../picture_model.dart';
import '../smart_widgets_components.dart';
import '../video_model.dart';

class PdmCommonActions {
  static Future<void> muteUser(
    String pubkey,
    bool isMuted,
    BuildContext context, {
    Function(String, bool)? onMuteActionSuccess,
  }) async {
    final metadata = await metadataCubit.getAvailableMetadata(pubkey);

    final description = isMuted
        ? context.t
            .unmuteUserDesc(
              name: metadata.getName(),
            )
            .capitalizeFirst()
        : context.t
            .muteUserDesc(
              name: metadata.getName(),
            )
            .capitalizeFirst();

    showCupertinoCustomDialogue(
      context: context,
      title: isMuted
          ? context.t.unmuteUser.capitalizeFirst()
          : context.t.muteUser.capitalizeFirst(),
      description: description,
      setDescriptionMaxLine: true,
      buttonText: isMuted
          ? context.t.unmute.capitalizeFirst()
          : context.t.mute.capitalizeFirst(),
      buttonTextColor: isMuted ? kGreen : kRed,
      onClicked: () => setMuteStatus(
        muteKey: metadata.pubkey,
        onSuccess: () {
          onMuteActionSuccess?.call(pubkey, !isMuted);
          Navigator.pop(context);
        },
      ),
    );
  }

  static Future<void> muteThread(
    String id,
    bool isMuted,
    BuildContext context, {
    Function(String, bool)? onMuteActionSuccess,
  }) async {
    final description = isMuted
        ? context.t.unmuteThreadDesc.capitalizeFirst()
        : context.t.muteThreadDesc.capitalizeFirst();

    showCupertinoCustomDialogue(
      context: context,
      title: isMuted
          ? context.t.unmuteThread.capitalizeFirst()
          : context.t.muteThread.capitalizeFirst(),
      description: description,
      buttonText: isMuted
          ? context.t.unmute.capitalizeFirst()
          : context.t.mute.capitalizeFirst(),
      buttonTextColor: isMuted ? kGreen : kRed,
      setDescriptionMaxLine: true,
      onClicked: () => setMuteStatus(
        muteKey: id,
        isPubkey: false,
        onSuccess: () {
          onMuteActionSuccess?.call(id, !isMuted);
          Navigator.pop(context);
        },
      ),
    );
  }

  static void bookmarkBaseEventModel(
    BuildContext context,
    BaseEventModel item,
  ) {
    late int kind;
    late String identifier;
    late String eventPubkey;

    if (item is DetailedNoteModel) {
      kind = EventKind.TEXT_NOTE;
      identifier = item.id;
      eventPubkey = item.pubkey;
    } else if (item is Article) {
      kind = EventKind.LONG_FORM;
      identifier = item.identifier;
      eventPubkey = item.pubkey;
    } else if (item is Curation) {
      kind = item.kind;
      identifier = item.identifier;
      eventPubkey = item.pubkey;
    } else if (item is VideoModel) {
      kind = item.kind;
      identifier = item.id;
      eventPubkey = item.pubkey;
    } else if (item is BookmarkOtherType) {
      kind = -1;
      identifier = item.id;
      eventPubkey = item.pubkey;
    } else {
      throw ArgumentError('Unsupported item type: ${item.runtimeType}');
    }

    showModalBottomSheet(
      context: context,
      elevation: 0,
      builder: (_) {
        return AddBookmarkView(
          kind: kind,
          identifier: identifier,
          eventPubkey: eventPubkey,
          model: item,
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  static Future<void> shareBaseEventImage(
    BuildContext context,
    BaseEventModel model,
  ) async {
    showModalBottomSheet(
      elevation: 0,
      context: context,
      builder: (_) {
        return ShareContentImage(model: model);
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  static Future<void> shareBaseEventModel(
      BuildContext context, BaseEventModel item) async {
    late String url;
    late String nostrScheme;
    late VoidCallback onShareUrl;
    late VoidCallback onShareNostrScheme;

    nostrScheme = await item.getSchemeWithRelays();
    // Extract values based on item type
    if (item is Article) {
      url = await externalShearableLink(
        kind: EventKind.LONG_FORM,
        pubkey: item.pubkey,
        id: item.identifier,
      );
    } else if (item is Curation) {
      url = await externalShearableLink(
        kind: item.kind,
        pubkey: item.pubkey,
        id: item.identifier,
      );
    } else if (item is VideoModel) {
      url = await externalShearableLink(
        kind: item.kind,
        pubkey: item.pubkey,
        id: item.isRepleaceableVideo() ? item.identifier : item.id,
      );
    } else if (item is DetailedNoteModel) {
      url = await externalShearableLink(
        kind: EventKind.TEXT_NOTE,
        pubkey: item.pubkey,
        id: item.id,
      );
    } else if (item is LightMetadata) {
      url = await externalShearableLink(
        kind: EventKind.METADATA,
        pubkey: '',
        id: item.pubkey,
      );
    } else if (item is SmartWidget) {
      url = await externalShearableLink(
        kind: EventKind.SMART_WIDGET_ENH,
        pubkey: item.pubkey,
        id: item.identifier,
      );
    } else if (item is PictureModel) {
      url = await externalShearableLink(
        kind: EventKind.PICTURE,
        pubkey: item.pubkey,
        id: item.id,
      );
    } else {
      return;
    }

    RenderBox? box;
    if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
      box = context.findRenderObject() as RenderBox?;
    }

    onShareUrl = () {
      shareContent(
        text: url,
        renderBox: box,
      );
    };

    onShareNostrScheme = () {
      shareContent(
        text: nostrScheme,
        renderBox: box,
      );
    };

    showModalBottomSheet(
      elevation: 0,
      context: context,
      builder: (_) {
        return ShareView(
          nostrScheme: nostrScheme,
          url: url,
          onShareUrl: onShareUrl,
          onShareNostrScheme: onShareNostrScheme,
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  static Future<void> shareWidgetImage(
    BuildContext context,
    String swImage,
  ) async {
    String? image;

    if (isBase64(swImage)) {
      image = await MediaHandler.uploadMediaFileFromData(
        swImage,
      );
    } else {
      image = swImage;
    }

    if (image != null && context.mounted) {
      YNavigator.pushPage(
        context,
        (context) => AddContentView(
          contentType: AppContentType.note,
          content: image,
        ),
      );
    } else {
      BotToastUtils.showError(
        context.t.errorUploadingImage,
      );
    }
  }

  static void copyNpub(String npub, {bool isHex = false}) {
    Clipboard.setData(
      ClipboardData(
        text: isHex ? npub : Nip19.encodePubkey(npub),
      ),
    );

    BotToastUtils.showSuccess(t.publicKeyCopied);
  }

  static Future<void> republish({
    required BaseEventModel model,
    required BuildContext context,
  }) async {
    bool isReplaceable = false;
    String id = '';

    if (model is Article) {
      isReplaceable = true;
      id = model.identifier;
    } else if (model is Curation) {
      isReplaceable = true;
      id = model.identifier;
    } else if (model is SmartWidget) {
      isReplaceable = true;
      id = model.identifier;
    } else if (model is VideoModel) {
      isReplaceable = false;
      id = model.id;
    } else {
      isReplaceable = false;
      id = model.id;
    }

    final e = await nc.db.loadEventById(id, isReplaceable);

    if (e != null) {
      showModalBottomSheet(
        elevation: 0,
        context: context,
        builder: (_) {
          return RepublishView(event: e);
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    } else {
      BotToastUtils.showError(t.eventNotFound);
    }
  }

  static void copyId(BaseEventModel model) {
    final isNote = model is DetailedNoteModel;

    final ev = Event.fromString(isNote
        ? model.stringifiedEvent
        : model is VideoModel
            ? model.stringifiedEvent
            : (model as PictureModel).stringifiedEvent);

    final id = Nip19.encodeShareableEntity(
      'nevent',
      model.id,
      ev?.seenOn ?? [],
      model.pubkey,
      model is DetailedNoteModel ? EventKind.TEXT_NOTE : EventKind.PICTURE,
    );

    Clipboard.setData(ClipboardData(text: id));
    BotToastUtils.showSuccess(t.idCopied);
  }

  static void copyNaddr(BaseEventModel model) {
    final data = getReplaceableEventData(model);

    final identifier = data['identifier'];
    final pubkey = data['pubkey'];
    final kind = data['kind'];

    final List<int> charCodes = identifier.runes.toList();
    final special = charCodes.map((code) => code.toRadixString(16)).join();

    final naddr = Nip19.encodeShareableEntity(
      'naddr',
      special,
      [],
      pubkey,
      kind,
    );

    Clipboard.setData(
      ClipboardData(text: naddr),
    );

    BotToastUtils.showSuccess('Naddr was copied! 👏');
  }

  static void onZap(BuildContext context, BaseEventModel model) {
    showModalBottomSheet(
      elevation: 0,
      context: context,
      builder: (_) {
        return MetadataProvider(
          pubkey: model.pubkey,
          child: (m, n05) => SendZapsView(
            isZapSplit: false,
            zapSplits: const [],
            metadata: m,
          ),
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  static void onSecureStorage(BuildContext context) {
    final currentStatus = dmsCubit.state.isUsingNip44;
    dmsCubit.setUsedMessagingNip(!currentStatus);

    if (currentStatus) {
      BotToastUtils.showSuccess(
        context.t.notUsingSecureDms.capitalizeFirst(),
      );
    } else {
      BotToastUtils.showSuccess(
        context.t.usingSecureDms.capitalizeFirst(),
      );
    }
  }

  static void postInNote(BuildContext context, BaseEventModel model) {
    YNavigator.pushPage(
      context,
      (context) => AddContentView(
        contentType: AppContentType.note,
        attachedEvent: model,
        isMention: true,
      ),
    );
  }

  static void showRawEvent(BuildContext context, BaseEventModel model) {
    String attachedEvent = '';

    if (model is Article) {
      attachedEvent = model.stringifiedEvent;
    } else if (model is Curation) {
      attachedEvent = model.stringifiedEvent;
    } else if (model is VideoModel) {
      attachedEvent = model.stringifiedEvent;
    } else if (model is SmartWidget) {
      attachedEvent = model.stringifiedEvent;
    } else if (model is DetailedNoteModel) {
      attachedEvent = model.stringifiedEvent;
    } else if (model is BookmarkListModel) {
      attachedEvent = model.stringifiedEvent;
    } else if (model is PictureModel) {
      attachedEvent = model.stringifiedEvent;
    }

    showModalBottomSheet(
      elevation: 0,
      context: context,
      builder: (_) {
        return ShowRawEventView(
          attachedEvent: attachedEvent,
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  static void checkValidity(
    BuildContext context,
    SmartWidget smartWidgetModel,
  ) {
    Navigator.pushNamed(
      context,
      SmartWidgetChecker.routeName,
      arguments: [
        smartWidgetModel.getScheme(),
        smartWidgetModel,
      ],
    );
  }

  static void editEvent(
    BuildContext context,
    BaseEventModel model,
    bool? isCloning,
  ) {
    AppContentType? contentType;

    Article? article;
    VideoModel? video;
    Curation? curation;
    SmartWidget? smartWidget;

    if (model is Article) {
      contentType = AppContentType.article;
      article = model;
    } else if (model is Curation) {
      contentType = AppContentType.curation;
      curation = model;
    } else if (model is VideoModel) {
      contentType = AppContentType.video;
      video = model;
    } else if (model is SmartWidget) {
      contentType = AppContentType.smartWidget;
      smartWidget = model;
    }

    YNavigator.pushPage(
      context,
      (context) => AddContentView(
        video: video,
        article: article,
        curation: curation,
        smartWidgetModel: smartWidget,
        contentType: contentType,
        isCloning: isCloning,
      ),
    );
  }

  static void pinEvent(
    BaseEventModel model,
  ) {
    nostrRepository.setPinnedNote(noteId: model.id);
  }

  static void addToCuration(BuildContext context, BaseEventModel model) {
    final data = getReplaceableEventData(model);

    final identifier = data['identifier'];
    final pubkey = data['pubkey'];
    final kind = data['kind'];

    showModalBottomSheet(
      context: context,
      elevation: 0,
      builder: (_) {
        return AddItemToCurationView(
          articleId: identifier,
          articlePubkey: pubkey,
          kind: kind,
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  static Map<String, dynamic> getReplaceableEventData(BaseEventModel model) {
    String identifier = '';
    String pubkey = '';
    int kind = 0;

    if (model is Article) {
      identifier = model.identifier;
      pubkey = model.pubkey;
      kind = EventKind.LONG_FORM;
    } else if (model is Curation) {
      identifier = model.identifier;
      pubkey = model.pubkey;
      kind = model.kind;
    } else if (model is SmartWidget) {
      identifier = model.identifier;
      pubkey = model.pubkey;
      kind = EventKind.SMART_WIDGET_ENH;
    }

    return {
      'identifier': identifier,
      'pubkey': pubkey,
      'kind': kind,
    };
  }
}
