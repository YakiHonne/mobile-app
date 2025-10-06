// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names
import 'dart:convert';

import '../../utils/utils.dart';

const int DEFAULT_FOLLOWEES_RELAY_MIN_COUNT = 2;
const int DEFAULT_BROADCAST_TO_INBOX_MAX_COUNT = 10;

class SettingData {
  int? privateKeyIndex;

  bool? imagePreview;

  bool? linkPreview;

  bool? videoPreview;

  bool? urlPreview;

  bool? gossip;

  int? followeesRelayMinCount;

  int? broadcastToInboxMaxCount;

  bool? backgroundService;

  bool? useExternalBrowser;

  String uploadServer;

  String imageService;

  bool imgCompress;

  int themeColor;

  int updatedTime;

  bool useCompactReplies;

  SettingData({
    this.privateKeyIndex,
    this.imagePreview,
    this.linkPreview,
    this.videoPreview,
    this.urlPreview,
    this.backgroundService,
    this.gossip,
    this.followeesRelayMinCount = DEFAULT_FOLLOWEES_RELAY_MIN_COUNT,
    this.broadcastToInboxMaxCount = DEFAULT_BROADCAST_TO_INBOX_MAX_COUNT,
    this.imgCompress = false,
    this.useExternalBrowser = true,
    this.imageService = apiBaseUrl + uploadUrl,
    this.themeColor = 1,
    this.updatedTime = 0,
    this.uploadServer = 'nostr.build',
    this.useCompactReplies = true,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'privateKeyIndex': privateKeyIndex,
      'imagePreview': imagePreview,
      'linkPreview': linkPreview,
      'videoPreview': videoPreview,
      'urlPreview': urlPreview,
      'gossip': gossip,
      'followeesRelayMinCount': followeesRelayMinCount,
      'broadcastToInboxMaxCount': broadcastToInboxMaxCount,
      'useExternalBrowser': useExternalBrowser,
      'backgroundService': backgroundService,
      'imageService': imageService,
      'imgCompress': imgCompress,
      'themeColor': themeColor,
      'updatedTime': updatedTime,
      'uploadServer': uploadServer,
      'useCompactReplies': useCompactReplies,
    };
  }

  factory SettingData.fromMap(Map<String, dynamic> map) {
    return SettingData(
      privateKeyIndex:
          map['privateKeyIndex'] != null ? map['privateKeyIndex'] as int : null,
      imagePreview:
          map['imagePreview'] != null ? map['imagePreview'] as bool : null,
      linkPreview:
          map['linkPreview'] != null ? map['linkPreview'] as bool : null,
      videoPreview:
          map['videoPreview'] != null ? map['videoPreview'] as bool : null,
      urlPreview: map['urlPreview'] != null ? map['urlPreview'] as bool : null,
      gossip: map['gossip'] != null ? map['gossip'] as bool : null,
      followeesRelayMinCount: map['followeesRelayMinCount'] != null
          ? map['followeesRelayMinCount'] as int
          : null,
      broadcastToInboxMaxCount: map['broadcastToInboxMaxCount'] != null
          ? map['broadcastToInboxMaxCount'] as int
          : null,
      backgroundService: map['backgroundService'] != null
          ? map['backgroundService'] as bool
          : null,
      useExternalBrowser: map['useExternalBrowser'] != null
          ? map['useExternalBrowser'] as bool
          : null,
      useCompactReplies: map['useCompactReplies'] ?? true,
      imageService: map['imageService'] as String,
      imgCompress: map['imgCompress'] as bool,
      themeColor: map['themeColor'] as int,
      updatedTime: map['updatedTime'] as int,
      uploadServer: map['uploadServer'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SettingData.fromJson(String source) =>
      SettingData.fromMap(json.decode(source) as Map<String, dynamic>);
}
