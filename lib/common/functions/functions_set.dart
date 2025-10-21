// ignore_for_file: public_member_api_docs, sort_constructors_first, prefer_foreach, use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aescryptojs/aescryptojs.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_url_validator/video_url_validator.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/bookmark_list_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../models/vote_model.dart';
import '../../models/wallet_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/app_view/app_view.dart';
import '../../views/article_view/article_view.dart';
import '../../views/curation_view/curation_view.dart';
import '../../views/note_view/note_view.dart';
import '../../views/profile_view/profile_view.dart';
import '../../views/profile_view/widgets/profile_fast_access.dart';
import '../../views/relay_feed_view/relay_feed_view.dart';
import '../../views/search_view/search_view.dart';
import '../../views/smart_widgets_view/widgets/smart_widget_display.dart';
import '../../views/widgets/content_renderer/content_renderer.dart';
import '../../views/widgets/modal_with_blur.dart';
import '../../views/widgets/reactions_box.dart';
import '../../views/widgets/response_snackbar.dart';
import '../../views/widgets/scroll_to_top.dart';
import '../../views/widgets/video_components/horizontal_video_view.dart';
import '../../views/widgets/video_components/vertical_video_view.dart';
import '../common_regex.dart';
import '../linkify/linkifiers.dart';

Future<void> onScrollsToTop(
  ScrollsToTopEvent event,
  ScrollController controller,
) async {
  controller.animateTo(
    0,
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOut,
  );
}

List<String> getBookmarkIds(
  Map<String, BookmarkListModel> bookmarks,
) {
  final bookmarksList = <String>{};

  for (final bookmarkList in bookmarks.values) {
    bookmarksList.addAll(
      bookmarkList.bookmarkedReplaceableEvents.map((e) => e.identifier),
    );
    bookmarksList.addAll(
      bookmarkList.bookmarkedEvents,
    );
  }

  return bookmarksList.toSet().toList();
}

List<String> getLoadingBookmarkIds(
  Map<String, Set<String>> bookmarks,
) {
  final bookmarksList = <String>{};

  for (final bookmarkList in bookmarks.values) {
    bookmarksList.addAll(
      bookmarkList,
    );
  }

  return bookmarksList.toSet().toList();
}

List<String> getZapPubkey(List<List<String>> tags) {
  String? zapRequestEventStr;
  String senderPubkey = '';
  String content = '';

  for (final tag in tags) {
    if (tag.length > 1) {
      final key = tag[0];
      if (key == 'description') {
        zapRequestEventStr = tag[1];
      }
    }
  }

  if (StringUtil.isNotBlank(zapRequestEventStr)) {
    try {
      final eventJson = jsonDecode(zapRequestEventStr!);
      final zapRequestEvent = Event.fromJson(eventJson);
      senderPubkey = zapRequestEvent.pubkey;
      content = zapRequestEvent.content;
    } catch (e) {
      senderPubkey = SpiderUtil.subUntil(zapRequestEventStr!, 'pubkey":"', '"');
    }
  }

  return [senderPubkey, content];
}

String? getInvoiceFromEvent(List<List<String>> tags) {
  String? invoice;

  for (final tag in tags) {
    if (tag.length > 1) {
      final key = tag[0];
      if (key == 'bolt11') {
        invoice = tag[1];
      }
    }
  }

  return invoice;
}

Map<String, dynamic> getZapByPollStats(Event event) {
  String? zapRequestEventStr;
  final map = <String, dynamic>{};

  for (final tag in event.tags) {
    if (tag.length > 1) {
      final key = tag[0];
      if (key == 'description') {
        zapRequestEventStr = tag[1];
      }
    }
  }

  if (StringUtil.isNotBlank(zapRequestEventStr)) {
    try {
      final eventJson = jsonDecode(zapRequestEventStr!);
      final zapRequestEvent = Event.fromJson(eventJson);
      map['pubkey'] = zapRequestEvent.pubkey;
      map['index'] = -1;
      for (final tag in zapRequestEvent.tags) {
        if (tag.first == 'poll_option' && tag.length > 1) {
          map['index'] = int.tryParse(tag[1]) ?? -1;
        }
      }
      map['amount'] = getZapValue(event);
    } catch (e) {
      map['pubkey'] =
          SpiderUtil.subUntil(zapRequestEventStr!, 'pubkey":"', '"');
    }
  }

  return map;
}

double getZapValue(Event event) {
  final receipt = Nip57.getZapReceipt(event);
  if (receipt.bolt11.isNotEmpty) {
    final req = Bolt11PaymentRequest(receipt.bolt11);

    return (req.amount.toDouble() * 100000000).round().toDouble();
  } else {
    return 0;
  }
}

double getlnbcValue(String invoice) {
  double amount = -1;

  try {
    final req = Bolt11PaymentRequest(invoice);

    amount = (req.amount.toDouble() * 100000000).round().toDouble();
  } catch (_) {}

  return amount;
}

bool rootComments({
  required List<Comment> comments,
}) {
  final rootComments = comments.where((comment) => comment.isRoot).toList();

  return rootComments.isEmpty;
}

Future<void> openWebPage({
  required String url,
  bool openInternal = true,
}) async {
  try {
    final hasYakiHonne = url.contains('yakihonne.com') &&
        supportedPaths.any(
          (path) => url.contains(path),
        );

    if (hasYakiHonne && openInternal) {
      nostrRepository.mainCubit.forwardView(
        uriString: url,
        isNostrScheme: false,
        skipDelay: true,
      );
    } else {
      final context = nostrRepository.currentContext();

      if (nostrRepository.currentAppCustomization?.openPromptedUrl ?? true) {
        showCupertinoCustomDialogue(
          context: context,
          title: context.t.openUrl,
          description: context.t.openUrlDesc(url: url),
          buttonText: context.t.open,
          buttonTextColor: kGreen,
          setDescriptionMaxLine: true,
          onClicked: () {
            launchInstantUrl(url);
            YNavigator.pop(context);
          },
        );
      } else {
        launchInstantUrl(url);
      }
    }
  } catch (_) {
    BotToastUtils.showError(t.inaccessibleLink.capitalizeFirst());
  }
}

Future<void> launchInstantUrl(String url) async {
  String toAddUrl = url;

  if (!url.startsWith('http')) {
    toAddUrl = 'https://$toAddUrl';
  }

  final uri = Uri.parse(toAddUrl);
  await launchUrl(
    uri,
    mode: !settingsCubit.useExternalBrowser
        ? LaunchMode.inAppWebView
        : LaunchMode.externalApplication,
  );
}

Future<void> openApp({
  required String url,
  required BuildContext context,
  Function(String)? onCustomDataAdded,
  SmartWidget? smartWidget,
  AppSmartWidget? app,
  String? title,
}) async {
  showModalBottomSheet(
    context: context,
    elevation: 0,
    builder: (_) {
      return SmartWidgetAppView(
        url: url,
        onCustomDataAdded: onCustomDataAdded,
        smartWidget: smartWidget,
        app: app,
        title: title,
      );
    },
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    enableDrag: false,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  );
}

Future<String> _getOpenableFilePath(
  String originalPath,
  String fileName,
  String fileContent,
) async {
  if (!Platform.isIOS) {
    return originalPath;
  }

  try {
    // Try copying original file to Documents directory
    final originalFile = File(originalPath);
    if (originalFile.existsSync()) {
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsPath = '${documentsDir.path}/$fileName';
      await originalFile.copy(documentsPath);
      return documentsPath;
    }
  } catch (e) {
    lg.w('Failed to copy original file: $e');
  }

  // Fallback: create new file in Documents directory
  final Directory documentsDir = await getApplicationDocumentsDirectory();
  final String documentsPath = '${documentsDir.path}/$fileName';
  final File file = File(documentsPath);
  await file.writeAsString(fileContent);
  return documentsPath;
}

Future<ResultType> exportWalletToUserDirectory(
  Map<String, List<NostrWalletConnectModel>> wallets,
) async {
  try {
    const fileName = 'wallet.txt';

    String fileContent =
        'Important: Store this information securely. If you lose it, recovery may not be possible. Keep it private and protected at all times';
    fileContent = '$fileContent\n-----\n';

    for (final entry in wallets.entries) {
      if (entry.key.isNotEmpty) {
        fileContent =
            '${fileContent}Wallets for: ${Nip19.encodePubkey(entry.key)}';

        final sk = settingsCubit.getSecretKey(entry.key);

        if (sk != null) {
          fileContent = '$fileContent\nSecret key: ${Nip19.encodePrivkey(sk)}';
        }

        fileContent = '$fileContent\n-----\n';
      }

      for (final wallet in entry.value) {
        fileContent =
            '${fileContent}Address: ${wallet.lud16}\nNWC secret: ${wallet.connectionString}';
        fileContent = '$fileContent\n-----------\n';
      }
    }

    final path = await FlutterFileSaver().writeFileAsString(
      fileName: fileName,
      data: fileContent,
    );

    final openablePath = await _getOpenableFilePath(
      path,
      fileName,
      fileContent,
    );

    return (await OpenFilex.open(openablePath)).type;
  } catch (e) {
    lg.i(e);
    return ResultType.error;
  }
}

Future<ResultType> exportKeysToUserDirectory({
  required String publicKey,
  required String secretKey,
}) async {
  try {
    const fileName = 'keys.txt';
    String fileContent =
        'Important: Store this information securely. If you lose it, recovery may not be possible. Keep it private and protected at all times';
    fileContent = '$fileContent\n-----\n';
    fileContent = 'Public key: ${Nip19.encodePubkey(publicKey)}';
    fileContent = '$fileContent\nSecret key: ${Nip19.encodePrivkey(secretKey)}';

    final path = await FlutterFileSaver().writeFileAsString(
      fileName: fileName,
      data: fileContent,
    );

    final openablePath = await _getOpenableFilePath(
      path,
      fileName,
      fileContent,
    );

    return (await OpenFilex.open(openablePath)).type;
  } catch (e) {
    lg.i(e);
    return ResultType.error;
  }
}

Future<void> setMuteStatus({
  required String pubkey,
  required Function() onSuccess,
}) async {
  final cancel = BotToast.showLoading();
  final result = await NostrFunctionsRepository.setMuteList(pubkey);
  cancel();

  if (result) {
    final bool hasBeenMuted = nostrRepository.mutes.contains(pubkey);

    BotToastUtils.showSuccess(
      hasBeenMuted
          ? t.userHasBeenMuted.capitalizeFirst()
          : t.userHasBeenUnmuted.capitalizeFirst(),
    );

    onSuccess();
  } else {
    BotToastUtils.showUnreachableRelaysError();
  }
}

void shareContent({
  required String text,
  RenderBox? renderBox,
}) {
  Share.share(
    text,
    subject: 'Sharing: $text',
    sharePositionOrigin: renderBox != null
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null,
  );
}

Future<void> shareLink({
  required RenderBox? renderBox,
  required String pubkey,
  required String id,
  required int kind,
}) async {
  final res = await externalShearableLink(
    kind: kind,
    pubkey: pubkey,
    id: id,
  );

  Share.share(
    res,
    subject: 'Check out www.yakihonne.com for more',
    sharePositionOrigin: renderBox != null
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null,
  );
}

bool isReplaceable(int? kind) {
  return kind == EventKind.LONG_FORM ||
      kind == EventKind.CURATION_ARTICLES ||
      kind == EventKind.CURATION_VIDEOS ||
      kind == EventKind.SMART_WIDGET_ENH;
}

bool isSupportedEvent(int? kind) {
  return kind == EventKind.LONG_FORM ||
      kind == EventKind.CURATION_ARTICLES ||
      kind == EventKind.CURATION_VIDEOS ||
      kind == EventKind.SMART_WIDGET_ENH ||
      kind == EventKind.TEXT_NOTE ||
      kind == EventKind.VIDEO_HORIZONTAL ||
      kind == EventKind.VIDEO_VERTICAL ||
      kind == EventKind.POLL;
}

Future<String> externalShearableLink({
  required int kind,
  required String pubkey,
  required String id,
}) async {
  final nScheme = await createShareableLink(
    kind,
    pubkey,
    id,
  );

  final page = kind == EventKind.LONG_FORM
      ? 'article'
      : (kind == EventKind.CURATION_ARTICLES ||
              kind == EventKind.CURATION_VIDEOS)
          ? 'curation'
          : kind == EventKind.METADATA
              ? 'profile'
              : kind == EventKind.SMART_WIDGET_ENH
                  ? 'smart-widget'
                  : (kind == EventKind.VIDEO_HORIZONTAL ||
                          kind == EventKind.VIDEO_VERTICAL)
                      ? 'video'
                      : 'note';

  final link = '$baseUrl$page/$nScheme';

  return link;
}

List<dynamic> getVotes({
  required Map<String, VoteModel>? votes,
  required String? pubkey,
}) {
  int calculatedUpvotes = 0;
  int calculatedDownvotes = 0;
  bool userUpvote = false;
  bool userDownvote = false;

  if (votes == null) {
    return [
      calculatedUpvotes,
      userUpvote,
      calculatedDownvotes,
      userDownvote,
    ];
  }

  votes.forEach(
    (key, value) {
      if (value.vote) {
        calculatedUpvotes++;
        if (pubkey != null && key == pubkey) {
          userUpvote = true;
        }
      } else {
        calculatedDownvotes++;
        if (pubkey != null && key == pubkey) {
          userDownvote = true;
        }
      }
    },
  );

  return [
    calculatedUpvotes,
    userUpvote,
    calculatedDownvotes,
    userDownvote,
  ];
}

Future<String> createShareableLink(
  int kind,
  String pubkey,
  String id, {
  bool useDefault = true,
}) async {
  String shareableLink = '';
  String hexString = '';
  final m = await metadataCubit.getAvailableMetadata(pubkey);

  if (kind == EventKind.TEXT_NOTE ||
      kind == EventKind.VIDEO_HORIZONTAL ||
      kind == EventKind.VIDEO_VERTICAL ||
      kind == EventKind.METADATA) {
    hexString = id;
  } else {
    final List<int> charCodes = id.runes.toList();
    hexString = charCodes.map((code) => code.toRadixString(16)).join();
  }

  final isReplaceable = kind == EventKind.LONG_FORM ||
      kind == EventKind.CURATION_ARTICLES ||
      kind == EventKind.CURATION_VIDEOS ||
      kind == EventKind.SMART_WIDGET_ENH;

  if (isReplaceable) {
    if (emailRegExp.hasMatch(m.nip05) && useDefault) {
      if (kind == EventKind.CURATION_ARTICLES ||
          kind == EventKind.CURATION_VIDEOS) {
        shareableLink =
            '${kind == EventKind.CURATION_ARTICLES ? 'a' : 'v'}/${m.nip05}/${urlRegExp.hasMatch(id) ? Uri.encodeComponent(id) : id}';
      } else {
        shareableLink =
            's/${m.nip05}/${urlRegExp.hasMatch(id) ? Uri.encodeComponent(id) : id}';
      }
    } else {
      shareableLink = Nip19.encodeShareableEntity(
        'naddr',
        hexString,
        [],
        pubkey,
        kind,
      );
    }
  } else {
    shareableLink = Nip19.encodeShareableEntity(
      kind == EventKind.METADATA ? 'nprofile' : 'nevent',
      hexString,
      [],
      pubkey,
      kind,
    );
  }

  return shareableLink;
}

class ParsedText extends HookWidget {
  const ParsedText({
    super.key,
    required this.text,
    this.onClicked,
    this.pubkey,
    this.color,
    this.style,
    this.isScreenshot,
    this.disableNoteParsing,
    this.disableUrlParsing,
    this.inverseNoteColor,
    this.isMainNote,
    this.enableTruncation = true,
    this.enableHidingMedia = false,
    this.isDm = false,
    this.isNotification,
    this.scrollPhysics,
    this.maxLines,
    this.minLines,
    this.maxWords,
  });

  final String text;
  final Function()? onClicked;
  final String? pubkey;
  final Color? color;
  final TextStyle? style;
  final bool? isScreenshot;
  final bool? disableNoteParsing;
  final bool? disableUrlParsing;
  final bool? enableHidingMedia;
  final bool? inverseNoteColor;
  final bool? isMainNote;
  final bool? isNotification;
  final int? maxWords;
  final int? maxLines;
  final int? minLines;
  final ScrollPhysics? scrollPhysics;
  final bool isDm;
  final bool enableTruncation;

  @override
  Widget build(BuildContext context) {
    // Early return for muted users
    if (pubkey != null && isUserMuted(pubkey!)) {
      return Container(
        decoration: BoxDecoration(
          color: inverseNoteColor != null
              ? Theme.of(context).scaffoldBackgroundColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          context.t.commentHidden,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(color: kRed),
        ),
      );
    }

    final hideMedia = (enableHidingMedia ?? false) &&
        pubkey != null &&
        hideImageFromNonFollowing(pubkey!);

    final canTruncate = isNotification == null &&
        enableTruncation &&
        (nostrRepository.currentAppCustomization?.collapsedNote ?? true) &&
        (isMainNote == null || !isMainNote!);

    final content = useMemoized(() {
      if (canTruncate) {
        final res = truncateTextWords(
          text,
          isNotification: isNotification,
          maxLines: maxLines,
        );
        return MapEntry(canTruncate && res.wasTruncated, res.optimizedText);
      } else {
        return MapEntry(false, text);
      }
    }, isDm ? [text, canTruncate] : [text]);

    useMemoized(
      () {
        final pubkeys = getPtags(text);

        if (pubkeys.isNotEmpty) {
          metadataCubit.fetchMetadata(pubkeys.toList());
        }

        final events = getStandAloneEvents(text);

        if (events.isNotEmpty) {
          singleEventCubit.searchEvents(events);
        }
      },
      [],
    );

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentRenderer(
            text: content.value,
            onClicked: onClicked,
            maxLines: maxLines,
            minLines: minLines,
            overflow: TextOverflow.ellipsis,
            disableNoteParsing: disableNoteParsing,
            disableUrlParsing: disableUrlParsing,
            isScreenshot: isScreenshot,
            scrollPhysics: scrollPhysics,
            hideMedia: hideMedia,
            textDirection: intl.Bidi.detectRtlDirectionality(content.value)
                ? TextDirection.rtl
                : TextDirection.ltr,
            inverseNoteColor: inverseNoteColor,
            style: style ??
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: color,
                    ),
            linkStyle: style?.copyWith(color: kMainColor) ??
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: kMainColor,
                    ),
            linkifiers: const [
              CustomUrlLinkifier(),
              RelayLinkifier(),
              TagLinkifier(),
              NostrSchemeLinkifier(),
              InvoiceLinkifier(),
              Base64ImageLinkifier(),
            ],
            onOpen: (link) => _handleLinkOpen(link, context),
          ),
          if (content.key)
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: kMainColor,
                      fontWeight: FontWeight.w500,
                    ),
                children: [
                  const TextSpan(text: '... '),
                  TextSpan(text: context.t.seeMore),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLinkOpen(
    LinkableElement link,
    BuildContext context,
  ) async {
    // Extract link handling logic for better performance

    final linkStr = link.toString();

    if (linkStr.startsWith('user:')) {
      openProfileFastAccess(
        context: context,
        pubkey: link.url,
      );
    } else if (linkStr.startsWith('article:')) {
      if (link.url.isNotEmpty) {
        Navigator.pushNamed(
          context,
          ArticleView.routeName,
          arguments: Article.fromJson(link.url),
        );
      }
    } else if (linkStr.startsWith('curation:')) {
      if (link.url.isNotEmpty) {
        Navigator.pushNamed(
          context,
          CurationView.routeName,
          arguments: Curation.curation(link.url),
        );
      }
    } else if (linkStr.startsWith('video:')) {
      if (link.url.isNotEmpty) {
        final video = VideoModel.fromJson(link.url);
        Navigator.pushNamed(
          context,
          video.kind == EventKind.VIDEO_HORIZONTAL
              ? HorizontalVideoView.routeName
              : VerticalVideoView.routeName,
          arguments: [video],
        );
      }
    } else if (linkStr.startsWith('smartWidget:')) {
      if (link.url.isNotEmpty) {
        final swc = SmartWidget.fromJson(link.url);
        showBlurredModal(
          context: context,
          view: SmartWidgetDisplay(smartWidgetModel: swc),
        );
      }
    } else if (linkStr.startsWith('note:')) {
      if (link.url.isNotEmpty) {
        final note = await singleEventCubit.getEvenById(
          id: link.url,
          isIdentifier: false,
        );

        if (note != null) {
          Navigator.pushNamed(
            context,
            NoteView.routeName,
            arguments: [DetailedNoteModel.fromEvent(note)],
          );
        }
      }
    } else if (linkStr.startsWith('TagElement:')) {
      if (link.url.isNotEmpty) {
        YNavigator.pushPage(
          context,
          (context) => SearchView(
            search: link.url.split('#')[1],
            index: 1,
          ),
        );
      }
    } else if (linkStr.startsWith('RelayElement:')) {
      YNavigator.pushPage(
        context,
        (context) => RelayFeedView(
          relay: link.url,
        ),
      );
    } else if (linkStr.startsWith('LinkElement:')) {
      openWebPage.call(url: link.url);
    }
  }
}

void moveUp(List list, int index) {
  if (index > 0 && index < list.length) {
    final temp = list[index];
    list[index] = list[index - 1];
    list[index - 1] = temp;
  }
}

void moveDown(List list, int index) {
  if (index >= 0 && index < list.length - 1) {
    final temp = list[index];
    list[index] = list[index + 1];
    list[index + 1] = temp;
  }
}

bool hideImageFromNonFollowing(String pubkey) {
  return canSign() &&
      currentSigner!.getPublicKey() != pubkey &&
      (nostrRepository.currentAppCustomization?.hideNonFollowingMedia ??
          false) &&
      !contactListCubit.contacts.contains(pubkey);
}

Color? getColorFromHex(String hexColor) {
  try {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }

    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return null;
  }
}

bool canAddNote(List<String> tag, String noteId) {
  return (tag.first == 'e' &&
          tag.length > 3 &&
          tag[3] == 'root' &&
          tag[1] == noteId) ||
      tag.first == 'e' && tag.length > 1 && tag[1] == noteId;
}

Color randomColor() {
  return Color((Random().nextDouble() * 0xFFFFFF).toInt())
      .withValues(alpha: 1.0);
}

bool checkAuthenticity(
  String encryption,
  DateTime createdAt,
) {
  try {
    final decryptedDate = decryptAESCryptoJS(
      encryption,
      dotenv.env['FN_KEY']!,
    );

    final parsedDate = int.tryParse(decryptedDate);

    if (parsedDate != null) {
      final newDate = DateTime.fromMillisecondsSinceEpoch(parsedDate * 1000);
      return newDate.isAtSameMomentAs(createdAt);
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<File?> selectGalleryImage() async {
  try {
    final XFile? image;
    image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image != null) {
      return File(image.path);
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

bool isImageExtension(String extension) {
  return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
      .contains(extension.toLowerCase());
}

bool isAudioExtension(String extension) {
  return ['m4a', 'mp3', 'wav', 'wma', 'aac'].contains(extension.toLowerCase());
}

bool isVideoExtension(String extension) {
  return ['mp4', 'avi', 'mkv', 'mov', 'flv', 'webm']
      .contains(extension.toLowerCase());
}

final emptyComment = Comment(
  id: '',
  pubKey: '',
  content: '',
  createdAt: DateTime.now(),
  isRoot: false,
  replyTo: '',
);

final videoUrlValidator = VideoURLValidator();

int getUnixTimestampWithinOneWeek() {
  final now = DateTime.now();
  final weekBefore = now.subtract(
    const Duration(days: 7),
  );

  final random = Random();

  return weekBefore.toSecondsSinceEpoch() +
      random.nextInt(
          now.toSecondsSinceEpoch() - weekBefore.toSecondsSinceEpoch());
}

int getRemainingXp(int nextLevel) {
  if (nextLevel == 1) {
    return 0;
  } else {
    return getRemainingXp(nextLevel - 1) + (nextLevel - 1) * 50;
  }
}

int getCurrentLevel(int xp) {
  return ((1 + sqrt(1 + (8 * xp) / 50)) / 2).floor();
}

String formattedTime({required int timeInSecond}) {
  final int sec = timeInSecond % 60;
  final int min = (timeInSecond / 60).floor();
  final String minute = min.toString().length <= 1 ? '0$min' : '$min';
  final String second = sec.toString().length <= 1 ? '0$sec' : '$sec';
  return '$minute:$second';
}

Color getPercentageColor(double percentage) {
  if (percentage >= 0 && percentage <= 25) {
    return kRed;
  } else if (percentage >= 26 && percentage <= 50) {
    return kMainColor;
  } else if (percentage >= 51 && percentage <= 75) {
    return kYellow;
  } else {
    return kGreen;
  }
}

PageRouteBuilder createViewFromBottom(Widget widget) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

PageRouteBuilder createViewFromRight(Widget widget) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

void useInterval(VoidCallback callback, Duration delay) {
  final savedCallback = useRef(callback);
  savedCallback.value = callback;

  useEffect(() {
    final timer = Timer.periodic(delay, (_) => savedCallback.value());
    return timer.cancel;
  }, [delay]);
}

bool canUserBeZapped(Metadata user) {
  return canSign() &&
      (user.lud16.isNotEmpty || user.lud06.isNotEmpty) &&
      user.pubkey != currentSigner!.getPublicKey();
}

bool canUserBeFollowed(Metadata user) {
  return canSign() && user.pubkey != currentSigner!.getPublicKey();
}

void openProfileFastAccess({
  required BuildContext context,
  required String pubkey,
}) {
  if (nostrRepository.currentAppCustomization?.enableProfilePreview ?? true) {
    showCupertinoModalBottomSheet(
      context: context,
      elevation: 0,
      builder: (context) => ProfileFastAccess(
        pubkey: pubkey,
      ),
      useRootNavigator: true,
      backgroundColor: kTransparent,
    );
  } else {
    YNavigator.pushPage(
      context,
      (context) => ProfileView(pubkey: pubkey),
    );
  }
}

void moveItem(List<dynamic> list, int fromIndex, int toIndex) {
  if (fromIndex < 0 ||
      fromIndex >= list.length ||
      toIndex < 0 ||
      toIndex >= list.length) {
    return;
  }

  // Remove the item from the original position
  final item = list.removeAt(fromIndex);

  // Insert the item into the new position
  list.insert(toIndex, item);
}

double getTextSize(TextSize textSize, BuildContext context) {
  if (textSize == TextSize.H1) {
    return Theme.of(context).textTheme.titleMedium!.fontSize!;
  } else if (textSize == TextSize.H2) {
    return Theme.of(context).textTheme.titleSmall!.fontSize!;
  } else if (textSize == TextSize.Regular) {
    return Theme.of(context).textTheme.bodyMedium!.fontSize!;
  } else {
    return Theme.of(context).textTheme.labelMedium!.fontSize!;
  }
}

Map<String, dynamic> getSmartWidgetButtonProps(SmartWidgetButtonType action) {
  if (action == SmartWidgetButtonType.Youtube) {
    return {
      'color': '#FF0000',
      'icon': FeatureIcons.youtube,
    };
  } else if (action == SmartWidgetButtonType.Telegram) {
    return {
      'color': '#24A1DE',
      'icon': FeatureIcons.telegram,
    };
  } else if (action == SmartWidgetButtonType.Discord) {
    return {
      'color': '#7785cc',
      'icon': FeatureIcons.discord,
    };
  } else if (action == SmartWidgetButtonType.X) {
    return {
      'color': kBlack.toHex(),
      'icon': FeatureIcons.x,
    };
  } else if (action == SmartWidgetButtonType.Nostr) {
    return {
      'color': kPurple.toHex(),
      'icon': FeatureIcons.nostr,
    };
  } else {
    return {};
  }
}

bool isListOfMaps(List<dynamic> list) {
  for (final item in list) {
    if (item is! Map) {
      return false;
    }
  }

  return true;
}

PropertyStatus getPropertyStatus(SmartWidgetBoxComponent swComponent) {
  if (swComponent is SmartWidgetImage) {
    return urlRegExp.hasMatch(swComponent.url)
        ? PropertyStatus.valid
        : PropertyStatus.invalid;
  } else if (swComponent is SmartWidgetInputField) {
    return swComponent.placeholder.isNotEmpty
        ? PropertyStatus.valid
        : PropertyStatus.invalid;
  } else if (swComponent is SmartWidgetButton) {
    if (swComponent.type == SWBType.Zap) {
      if (swComponent.url.isNotEmpty &&
          (emailRegExp.hasMatch(swComponent.url) ||
              swComponent.url.toLowerCase().startsWith('lnbc') ||
              swComponent.url.toLowerCase().startsWith('lnurl'))) {
        return PropertyStatus.valid;
      } else {
        return PropertyStatus.invalid;
      }
    }

    if (swComponent.type == SWBType.Nostr &&
        !Nip19.nip19regex.hasMatch(swComponent.url)) {
      return PropertyStatus.invalid;
    }

    if (!urlRegExp.hasMatch(swComponent.url)) {
      return PropertyStatus.invalid;
    }

    return PropertyStatus.valid;
  } else {
    return PropertyStatus.unknown;
  }
}

String getYoutubeVideoId(String url) {
  final RegExp regExp = RegExp(
      r'(?:https?:\/\/)?(?:(?:www\.)?youtube\.com\/(?:(?:shorts\/)|(?:watch\?v=))|(?:youtu.be\/))([\-a-zA-Z0-9_]+)');
  final match = regExp.firstMatch(url);
  final result = match?.group(1) ?? '';
  return result;
}

String? keyValidator(String? usedKey, BuildContext context) {
  bool isValid = true;

  if (usedKey == null || usedKey.isEmpty) {
    isValid = false;
  } else {
    final cleanKey = usedKey.trim();

    if ((cleanKey.startsWith('nsec') || cleanKey.startsWith('npub')) &&
        cleanKey.length != 63) {
      isValid = false;
    } else if ((!cleanKey.startsWith('nsec') && !cleanKey.startsWith('npub')) &&
        cleanKey.length != 64) {
      isValid = false;
    }
  }

  return isValid ? null : context.t.setValidKey.capitalizeFirst();
}

int countWords(String text) {
  if (text.isEmpty) {
    return 0;
  }

  return text.trim().split(RegExp(r'\s+')).length;
}

bool hasMedia(String text) {
  final mediaRegex = RegExp(
    r'(https?://\S+\.(?:jpg|jpeg|png|gif|bmp|webm|mp4|mov|avi|mkv|wmv|flv))\b',
    caseSensitive: false,
  );

  return mediaRegex.hasMatch(text);
}

void showReactionPopup(
  BuildContext context,
  GlobalKey reactionButtonKey,
  Function(String) onReact, {
  bool displayOnLeft = false,
}) {
  final buttonRenderBox =
      reactionButtonKey.currentContext?.findRenderObject() as RenderBox?;
  final buttonPosition = buttonRenderBox?.localToGlobal(Offset.zero);
  final buttonSize = buttonRenderBox?.size;
  final popupHeight = 30.h;

  if (buttonPosition == null || buttonSize == null) {
    return;
  }

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => ReactionsBox(
      reactionButtonKey: reactionButtonKey,
      onReact: onReact,
      buttonPosition: buttonPosition,
      buttonSize: buttonSize,
      popupHeight: popupHeight,
      displayOnLeft: displayOnLeft,
    ),
  );
}

String getProperRelayUrl(String url) {
  if (relayRegExp.hasMatch(url)) {
    return url;
  } else if (urlRegExp.hasMatch(url)) {
    return url.replaceAll(RegExp(r'^https?://'), 'wss://');
  }

  return 'wss://$url';
}

void launchRemoteSignerAuth({
  required String url,
  Function()? onDismissed,
}) {
  openWebPage(url: url);
}

String? getCountryFlag(String countryCode) {
  return countryFlags[countryCode];
}

bool hasMention({required String content, required String pubkey}) {
  try {
    if (content.contains(Nip19.encodePubkey(pubkey))) {
      return true;
    }

    final nProfiles = userRegex.allMatches(content);

    if (nProfiles.isNotEmpty) {
      for (final match in nProfiles) {
        final content =
            Nip19.decodeShareableEntity(match.group(0)!.split(':').last);

        if ((content['special'] ?? content['author']) == pubkey) {
          return true;
        }
      }
    }

    return false;
  } catch (e) {
    return false;
  }
}

String cleanUrl(String url) {
  final uri = Uri.parse(url);
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  ).toString();
}
