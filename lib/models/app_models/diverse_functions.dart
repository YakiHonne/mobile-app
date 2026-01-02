import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/logify_view/logify_view.dart';
import '../../views/logify_view/signup_direct_view/signup_direct_view.dart';
import '../article_model.dart';
import '../curation_model.dart';
import '../detailed_note_model.dart';
import '../flash_news_model.dart';
import '../parsed_text_optimizer.dart';
import '../picture_model.dart';
import '../poll_model.dart';
import '../smart_widgets_components.dart';
import '../video_model.dart';

bool useOutbox() {
  return (settingsCubit.gossip ?? false) && feedRelaySet != null;
}

bool canSign() {
  return currentSigner?.canSign() ?? false;
}

bool canRoam() {
  return currentSigner?.isGuest() ?? false;
}

bool isDisconnected() {
  return currentSigner == null;
}

TextDirection getTextDirectionFromLocale(Locale locale) {
  final rtlLanguageCodes = ['ar', 'fa', 'he', 'ps', 'ur'];

  return rtlLanguageCodes.contains(locale.languageCode)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

bool canBeTruncated(String input) {
  final matches = wordsRegExp.allMatches(input);

  return matches.length > collapseNoteWordsCount;
}

FeedOptimizationResult truncateTextWords(
  String input, {
  bool? isNotification,
  int? maxLines,
  int? maxWords,
}) {
  try {
    final matches = wordsRegExp.allMatches(input);

    final wasTruncated = matches.length >
        (isNotification != null
            ? collapseNotificationWordsCount
            : collapseNoteWordsCount);

    if (wasTruncated) {
      final int endIndex = matches
          .elementAt(isNotification != null
              ? collapseNotificationWordsCount
              : collapseNoteWordsCount)
          .start;

      input = input.substring(0, endIndex).trim();
    }

    return FeedOptimizationResult(
      optimizedText: input,
      wasTruncated: wasTruncated,
    );
  } catch (e) {
    return FeedOptimizationResult(
      optimizedText: input,
      wasTruncated: false,
    );
  }

  // try {
  //   final res = FeedTextOptimizer.optimizeForFeed(
  //     input,
  //     maxLines: maxLines,
  //     maxWords: isNotification != null
  //         ? collapseNotificationWordsCount
  //         : maxWords ?? collapseNoteWordsCount,
  //   );

  //   return res;
  // } catch (e) {
  //   return FeedOptimizationResult(
  //     optimizedText: input,
  //     wasTruncated: false,
  //   );
  // }
}

String getDomainFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host;
  } catch (e) {
    return url;
  }
}

String generateSpecialId(String input) {
  final hash = input.hashCode.abs();
  final base36 = hash.toRadixString(36);

  return base36.padLeft(10, '0').substring(0, 10);
}

Future<List<String>> broadcastRelays(
  String? inboxPubKey, {
  bool showMessage = true,
}) async {
  Set<String> urlsToBroadcast = {};

  if (inboxPubKey != null) {
    final relayList = await getInboxRelays(inboxPubKey).timeout(
      const Duration(seconds: 2),
      onTimeout: () => [],
    );

    final Set<String> cleanRelays = {};

    if (relayList.isNotEmpty) {
      for (final element in relayList) {
        final r = Relay.clean(element);

        if (r != null) {
          cleanRelays.add(r);
        }
      }
    }

    urlsToBroadcast = cleanRelays;

    if (urlsToBroadcast.length > 2) {
      urlsToBroadcast = urlsToBroadcast.take(2).toSet();
    }
  }

  urlsToBroadcast.addAll(currentUserRelayList.writes);

  return urlsToBroadcast.toList();
}

Future<List<String>> getDmInboxRelays(
  String? inboxPubKey, {
  bool forceRefresh = false,
}) async {
  Set<String> urlsToBroadcast = {};
  final gossip = settingsCubit.gossip ?? false;

  if (inboxPubKey != null) {
    urlsToBroadcast =
        (await getDmRelays(inboxPubKey, forceRefresh: forceRefresh)).toSet();

    if (urlsToBroadcast.length > 2) {
      urlsToBroadcast = urlsToBroadcast.take(2).toSet();
    }
  }

  if (urlsToBroadcast.isNotEmpty) {
    await nc.connectNonConnectedRelays(urlsToBroadcast);
  }

  urlsToBroadcast.addAll(
    gossip ? currentUserRelayList.writes : currentUserRelayList.relays.keys,
  );

  urlsToBroadcast.addAll(nostrRepository.dmRelays);

  return urlsToBroadcast.toList();
}

Future<List<String>> getDmRelays(
  String pubkey, {
  bool forceRefresh = false,
}) async {
  final timer = Timer(
    const Duration(milliseconds: 200),
    () {
      BotToastUtils.showInformation(
        t.fetchingUserInboxRelays.capitalizeFirst(),
      );
    },
  );

  final urlsToBroadcast = <String>[];

  if (!forceRefresh) {
    final ev = await nc.db.loadEvent(kind: EventKind.DM_RELAYS, pubkey: pubkey);

    if (ev != null) {
      urlsToBroadcast.addAll(getRelayFromTag(ev.tags));

      if (urlsToBroadcast.isNotEmpty) {
        timer.cancel();
        return urlsToBroadcast;
      }
    }
  }

  final rev = await NostrFunctionsRepository.getEventById(
    isIdentifier: false,
    author: pubkey,
    kinds: [
      EventKind.DM_RELAYS,
    ],
  );

  timer.cancel();

  if (rev != null) {
    nc.db.saveEvent(rev);
    urlsToBroadcast.addAll(getRelayFromTag(rev.tags));
  }

  return urlsToBroadcast;
}

List<String> getRelayFromTag(List<List<String>> tags) {
  final relays = <String>[];

  for (final t in tags) {
    if (t.first == 'relay' && t.length > 1) {
      final r = Relay.clean(t[1]);

      if (r != null) {
        relays.add(r);
      }
    }
  }

  return relays;
}

Future<List<String>> getInboxRelays(String pubKey,
    {bool showMessage = true}) async {
  final timer = Timer(
    const Duration(milliseconds: 200),
    () {
      if (showMessage) {
        BotToastUtils.showInformation(
          t.fetchingUserInboxRelays.capitalizeFirst(),
        );
      }
    },
  );

  List<String> urlsToBroadcast = [];
  final userRelayList = await nc.getSingleUserRelayList(pubKey);
  timer.cancel();

  if (userRelayList != null) {
    urlsToBroadcast = userRelayList.readUrls.toList();
  }

  return urlsToBroadcast;
}

Future<List<String>> getOutboxRelays(
  String pubkey, {
  bool showMessage = true,
  bool forceRefresh = false,
}) async {
  final timer = Timer(
    const Duration(milliseconds: 200),
    () {
      if (showMessage) {
        BotToastUtils.showInformation(
          t.fetchingUserOutboxRelays.capitalizeFirst(),
        );
      }
    },
  );

  List<String> urlsToBroadcast = [];

  final userRelayList = await nc.getSingleUserRelayList(
    pubkey,
    forceRefresh: forceRefresh,
  );

  timer.cancel();

  if (userRelayList != null) {
    urlsToBroadcast = userRelayList.writes.toList();
  }

  return urlsToBroadcast;
}

int estimateReadingTime(String articleText, {int wordsPerMinute = 200}) {
  final List<String> words = articleText.split(RegExp(r'\s+'));

  final int wordCount = words.length;

  final int readingTime = (wordCount / wordsPerMinute).ceil();

  return readingTime;
}

Set<String> getPtags(String content) {
  try {
    final matches = userRegex.allMatches(content);
    final pubkeys = <String>{};

    for (final match in matches) {
      String encoded = match.group(0)!;

      if (encoded.startsWith('@')) {
        encoded = encoded.split('@').last;
      }

      if (encoded.startsWith('nostr:')) {
        encoded = encoded.split('nostr:').last;
      }

      if (encoded.contains('nprofile1')) {
        final decode = Nip19.decodeShareableEntity(encoded);
        final p = decode['special'];
        if (p != null && p.isNotEmpty) {
          pubkeys.add(p);
        }
      } else {
        final p = Nip19.decodePubkey(encoded);
        if (p.isNotEmpty) {
          pubkeys.add(p);
        }
      }
    }

    return pubkeys;
  } catch (e) {
    lg.i(e);
    return <String>{};
  }
}

List<EventCoordinates> getNaddr(String content) {
  try {
    final matches = nostrNaddrRegex.allMatches(content);

    final naddr = <String>{};

    for (final match in matches) {
      String encoded = match.group(0)!;

      if (encoded.startsWith('nostr:')) {
        encoded = encoded.split('nostr:').last;
      }

      naddr.add(encoded);
    }

    return Nip33.getEventCoordinatesFromNaddr(naddr.toList());
  } catch (e) {
    lg.i(e);
    return <EventCoordinates>[];
  }
}

List<String> getTtags(String content) {
  final matches = hashtagsRegExp.allMatches(content);
  return matches.map((match) => match.group(0)!).toList();
}

Map<String, bool> getStandAloneEvents(String content) {
  try {
    final matches = nostrContentEventRegex.allMatches(content);
    final events = <String, bool>{};

    for (final match in matches) {
      String encoded = match.group(0)!;

      if (encoded.startsWith('nostr:')) {
        encoded = encoded.split('nostr:').last;
      }

      if (encoded.contains('nevent1')) {
        final entity = Nip19.decodeShareableEntity(encoded);
        final id = entity['special'];

        if (id != null) {
          events[id!] = false;
        }
      } else if (encoded.contains('note1')) {
        final noteId = Nip19.decodeNote(encoded);
        events[noteId] = false;
      } else if (encoded.contains('naddr1')) {
        final entity = Nip19.decodeShareableEntity(encoded);
        final eventKind = entity['kind'];

        if (eventKind == EventKind.LONG_FORM ||
            eventKind == EventKind.VIDEO_HORIZONTAL ||
            eventKind == EventKind.VIDEO_VERTICAL ||
            eventKind == EventKind.SMART_WIDGET_ENH ||
            eventKind == EventKind.CURATION_ARTICLES ||
            eventKind == EventKind.CURATION_VIDEOS) {
          final hexCode = hex.decode(entity['special']);
          final eventIdentifier = String.fromCharCodes(hexCode);
          events[eventIdentifier] = true;
        }
      }
    }

    return events;
  } catch (e) {
    lg.i(e);
    return <String, bool>{};
  }
}

// ** BaseEventModel related functions
String? naddr(BaseEventModel item) {
  return item.getScheme();
}

BaseEventModel? getBaseEventModel(Event? event) {
  if (event == null) {
    return null;
  }

  switch (event.kind) {
    case EventKind.TEXT_NOTE:
      return DetailedNoteModel.fromEvent(event);
    case EventKind.CURATION_ARTICLES:
      return Curation.fromEvent(event, '');
    case EventKind.CURATION_VIDEOS:
      return Curation.fromEvent(event, '');
    case EventKind.LONG_FORM:
      return Article.fromEvent(event);
    case EventKind.VIDEO_HORIZONTAL:
      return VideoModel.fromEvent(event);
    case EventKind.VIDEO_VERTICAL:
      return VideoModel.fromEvent(event);
    case EventKind.SMART_WIDGET_ENH:
      return SmartWidget.fromEvent(event);
    case EventKind.POLL:
      return PollModel.fromEvent(event);
    case EventKind.PICTURE:
      return PictureModel.fromEvent(event);

    default:
      return null;
  }
}

String? getBaseEventModelId(BaseEventModel item) {
  String? id;

  if (item is Article) {
    id = '${EventKind.LONG_FORM}:${item.pubkey}:${item.identifier}';
  } else if (item is Curation) {
    id = '${item.kind}:${item.pubkey}:${item.identifier}';
  } else if (item is VideoModel) {
    id = item.id;
  } else if (item is SmartWidget) {
    id = '${EventKind.SMART_WIDGET_ENH}:${item.pubkey}:${item.identifier}';
  } else if (item is DetailedNoteModel) {
    id = item.id;
  }

  return id;
}

List<String> getBaseEventModelData(BaseEventModel item) {
  try {
    if (item is Article) {
      return [item.image, item.title, item.summary];
    } else if (item is Curation) {
      return [item.image, item.title, item.description];
    } else if (item is VideoModel) {
      return [item.thumbnail, item.title, item.summary];
    } else if (item is PictureModel) {
      return [item.images.first.url, item.title, item.content];
    } else if (item is SmartWidget) {
      return ['', item.title, ''];
    }

    return <String>[];
  } catch (e) {
    lg.i(e);
    return <String>[];
  }
}

void doIfCanSign({required Function() func, required BuildContext context}) {
  if (canSign()) {
    func.call();
  } else {
    YNavigator.pushPage(
      context,
      (context) => LogifyView(),
    );
  }
}

void doIfCanSignDirect({
  required Function() func,
  required BuildContext context,
}) {
  if (canSign()) {
    func.call();
  } else {
    YNavigator.pushPage(
      context,
      (context) => const LogifyDirectView(),
    );
  }
}

String? sanitizeUrl(String url) {
  if (url.isEmpty) {
    return null;
  }

  url = url.trim();

  if (!url.startsWith(RegExp(r'http(s)?://'))) {
    url = 'https://$url';
  }

  try {
    Uri uri = Uri.parse(url);

    uri = uri.removeFragment();

    final allowedParams = ['id', 'q', 'ref'];
    final filteredQueryParams = Map.fromEntries(uri.queryParameters.entries
        .where((e) => allowedParams.contains(e.key)));

    final cleanedUri = Uri(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      queryParameters:
          filteredQueryParams.isNotEmpty ? filteredQueryParams : null,
    );

    return cleanedUri.toString();
  } catch (e) {
    return null;
  }
}

String sanitizeContent(String content) {
  final urlMatches = urlRegex2.allMatches(content);
  final preservedUrls = <int, String>{};

  for (final match in urlMatches) {
    preservedUrls[match.start] = content.substring(match.start, match.end);
  }

  final c = content.replaceAllMapped(nostrSchemeRegex, (match) {
    for (final start in preservedUrls.keys) {
      final url = preservedUrls[start]!;
      final urlEnd = start + url.length;

      if (match.start >= start && match.end <= urlEnd) {
        return match.group(0)!;
      }
    }

    if (match.group(1) == null) {
      return 'nostr:${match.group(0)}';
    }

    return match.group(0)!;
  });

  return c.replaceAllMapped(urlRegex3, (match) {
    return ' ${match.group(0)}';
  });
}

List<String> getClientTag() {
  final appClients = settingsCubit.state.appClients.values
      .where((element) => element.pubkey == yakihonneHex)
      .toList();

  return [
    'client',
    'YakiHonne',
    if (appClients.isEmpty)
      'YakiHonne'
    else
      '${EventKind.APPLICATION_INFO}:${appClients.first.pubkey}:${appClients.first.identifier}'
  ];
}

String getAppContentTypeName(AppContentType type) {
  return type == AppContentType.smartWidget ? 'smart widget' : type.name;
}

void appendTextToPosition({
  required TextEditingController controller,
  required String textToAppend,
}) {
  final selection = controller.selection;
  final text = controller.text;

  final newText = selection.start == -1
      ? textToAppend
      : text.replaceRange(
          selection.start,
          selection.end,
          textToAppend,
        );

  controller.value = TextEditingValue(
    text: newText,
  );
}

Map<String, dynamic> replaceWithIndexAndExtract({
  required String input,
}) {
  final regexes = [urlRegExp, nostrSchemeRegex, hashtagsRegExp];
  final combinedRegex = RegExp(regexes.map((r) => r.pattern).join('|'));

  final extractedData = <String>[];
  int index = 0;

  final replacedString = input.replaceAllMapped(combinedRegex, (match) {
    extractedData.add(match.group(0)!);
    return '{${index++}}';
  });

  return {
    'replacedString': replacedString,
    'extractedData': extractedData,
  };
}

String restoreOriginalString({
  required String replacedString,
  required List<String> extractedData,
}) {
  try {
    final placeholderRegex = RegExp(r'[\{\[](\d+)[\}\]]');

    return replacedString.replaceAllMapped(placeholderRegex, (match) {
      final index = int.parse(match.group(1)!);
      final et = extractedData[index];
      final asians = ['zh', 'ja', 'th'];
      return asians.contains(LocaleSettings.currentLocale.languageCode)
          ? ' $et '
          : et;
    });
  } catch (e) {
    lg.i(e);
    return replacedString;
  }
}

List<Metadata> orderMetadataByScore({
  required List<Metadata> metadatas,
  required String match,
}) {
  metadatas.sort((a, b) {
    final distanceA = levenshteinDistance(
      match.toLowerCase(),
      a.displayName.toLowerCase(),
    );

    final distanceB = levenshteinDistance(
      match.toLowerCase(),
      b.displayName.toLowerCase(),
    );

    return distanceA.compareTo(distanceB);
  });

  metadatas.sort((a, b) {
    final distanceA = a.nip05.isEmpty;
    final distanceB = b.nip05.isEmpty;

    return distanceA && !distanceB ? 1 : -1;
  });

  return metadatas;
}

int levenshteinDistance(String s1, String s2) {
  final int len1 = s1.length;
  final int len2 = s2.length;

  // Create a 2D list to hold the distances
  final List<List<int>> dp =
      List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

  // Initialize the base cases
  for (int i = 0; i <= len1; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= len2; j++) {
    dp[0][j] = j;
  }

  // Fill the DP table
  for (int i = 1; i <= len1; i++) {
    for (int j = 1; j <= len2; j++) {
      final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1, // Deletion
        dp[i][j - 1] + 1, // Insertion
        dp[i - 1][j - 1] + cost // Substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return dp[len1][len2];
}

bool isUserMuted(String pubkey) {
  return nostrRepository.muteModel.usersMutes.contains(pubkey);
}

bool isThreadMutedById(String id) {
  return nostrRepository.muteModel.eventsMutes.contains(id);
}

bool isThreadMutedByEvent(Event event) {
  final mutes = nostrRepository.muteModel.eventsMutes;
  if (mutes.contains(event.id)) {
    return true;
  }

  if (event.kind == EventKind.REACTION || event.kind == EventKind.REPOST) {
    final id = event.eTags.firstOrNull;
    return id != null && mutes.contains(id);
  }

  if (event.kind == EventKind.TEXT_NOTE) {
    final q = event.qTags.firstOrNull;
    final root = event.root;
    final reply = event.reply;

    return (q != null && mutes.contains(q)) ||
        (root != null && mutes.contains(root)) ||
        (reply != null && mutes.contains(reply));
  }

  return false;
}

String getBaseUrl(String url) {
  final uri = Uri.parse(url);
  return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
}

Future<SmartWidget?> getSmartWidgetFromNaddr(String naddr) async {
  final nostrDecode = Nip19.decodeShareableEntity(naddr);
  final hexCode = hex.decode(nostrDecode['special']);
  final special = String.fromCharCodes(hexCode);
  final ev = await singleEventCubit.getEvenById(
    id: special,
    isIdentifier: true,
    kinds: [EventKind.SMART_WIDGET_ENH],
  );

  if (ev != null && ev.kind == EventKind.SMART_WIDGET_ENH) {
    return SmartWidget.fromEvent(ev);
  } else {
    return null;
  }
}

bool? isLightningAddress(String val) {
  if (val.toLowerCase().startsWith('lnurl') || emailRegExp.hasMatch(val)) {
    return true;
  } else if (val.toLowerCase().startsWith('lnbc')) {
    return false;
  }

  return null;
}

Future<void> saveByteDataImage(ByteData image) async {
  final res = await ImageGallerySaverPlus.saveImage(image.buffer.asUint8List());

  if (res != null && res is Map && res['isSuccess']) {
    BotToastUtils.showSuccess(
      t.saveImageGallery.capitalizeFirst(),
    );
  } else {
    BotToastUtils.showSuccess(
      t.errorSavingImage.capitalizeFirst(),
    );
  }
}

bool isBase64(String image) {
  return base64ImageRegex.hasMatch(image);
}

Uint8List? decodeBase64(String base64String) {
  try {
    final String cleanBase64 = base64String.split(',').last;
    return base64Decode(cleanBase64);
  } catch (_) {
    return null;
  }
}

Future<double> getCachedMediaSizeInMB() async {
  return (await getCachedSizeBytes()) / (1024 * 1024);
}

int getCurrentUserDefaultZapAmount() {
  return nostrRepository.defaultZapAmounts[currentSigner!.getPublicKey()] ??
      defaultZapamount;
}

List<String> removeConsecutiveDuplicates(List<String> input) {
  if (input.isEmpty) {
    return [];
  }

  final result = [input[0]];
  for (int i = 1; i < input.length; i++) {
    if (input[i] != input[i - 1]) {
      result.add(input[i]);
    }
  }

  return result;
}
