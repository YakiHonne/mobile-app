// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import '../../utils/utils.dart';

class AppCustomization {
  String pubkey;
  bool showLeadingSuggestions;
  bool showTrendingUsers;
  bool showRelatedContent;
  bool showSuggestedInterests;
  bool showDonationBox;
  bool showShareBox;
  bool useSingleColumnFeed;
  bool enableProfilePreview;
  bool hideNonFollowingMedia;
  bool enableLinkPreview;
  bool collapsedNote;
  bool openPromptedUrl;
  bool enablePushNotification;
  bool notifMentionsReplies;
  bool notifReactions;
  bool notifReposts;
  bool notifZaps;
  bool notifFollowings;
  bool notifPrivateMessage;
  String writingContentType;
  Map<String, bool> actionsArrangement;
  Map<String, bool> leadingFeedCustomization;

  AppCustomization({
    required this.pubkey,
    this.showLeadingSuggestions = true,
    this.showTrendingUsers = true,
    this.showRelatedContent = true,
    this.showSuggestedInterests = true,
    this.showDonationBox = true,
    this.showShareBox = true,
    this.useSingleColumnFeed = false,
    this.enableProfilePreview = true,
    this.collapsedNote = true,
    this.enablePushNotification = true,
    this.notifPrivateMessage = true,
    this.notifMentionsReplies = true,
    this.notifReactions = true,
    this.notifReposts = true,
    this.notifZaps = true,
    this.openPromptedUrl = true,
    this.hideNonFollowingMedia = true,
    this.enableLinkPreview = true,
    this.notifFollowings = true,
    this.writingContentType = 'note',
    this.actionsArrangement = defaultActionsArrangement,
    this.leadingFeedCustomization = defaultLeadingFeedCustomization,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'showLeadingSuggestions': showLeadingSuggestions,
      'showFastAccessProfile': enableProfilePreview,
      'leadingFeedCustomization': leadingFeedCustomization,
      'showTrendingUsers': showTrendingUsers,
      'showRelatedContent': showRelatedContent,
      'showSuggestedInterests': showSuggestedInterests,
      'showDonationBox': showDonationBox,
      'showShareBox': showShareBox,
      'useSingleColumnFeed': useSingleColumnFeed,
      'writingContentType': writingContentType,
      'collapsedNote': collapsedNote,
      'openPromptedUrl': openPromptedUrl,
      'hideNonFollowingMedia': hideNonFollowingMedia,
      'enableLinkPreview': enableLinkPreview,
      'enablePushNotification': enablePushNotification,
      'notifPrivateMessage': notifPrivateMessage,
      'notifMentionsReplies': notifMentionsReplies,
      'notifReactions': notifReactions,
      'notifReposts': notifReposts,
      'notifZaps': notifZaps,
      'actionsArrangement': actionsArrangement,
      'notifFollowings': notifFollowings,
    };
  }

  factory AppCustomization.fromMap(Map<String, dynamic> map) {
    return AppCustomization(
      pubkey: map['pubkey'] as String,
      showLeadingSuggestions: map['showLeadingSuggestions'] as bool? ?? true,
      enableProfilePreview: map['showFastAccessProfile'] as bool? ?? true,
      showTrendingUsers: map['showTrendingUsers'] as bool? ?? true,
      showRelatedContent: map['showRelatedContent'] as bool? ?? true,
      showSuggestedInterests: map['showSuggestedInterests'] as bool? ?? true,
      showDonationBox: map['showDonationBox'] as bool? ?? true,
      useSingleColumnFeed: map['useSingleColumnFeed'] as bool? ?? false,
      collapsedNote: map['collapsedNote'] as bool? ?? true,
      showShareBox: map['showShareBox'] as bool? ?? true,
      openPromptedUrl: map['openPromptedUrl'] as bool? ?? true,
      hideNonFollowingMedia: map['hideNonFollowingMedia'] as bool? ?? true,
      enableLinkPreview: map['enableLinkPreview'] as bool? ?? true,
      notifMentionsReplies: map['notifMentionsReplies'] as bool? ?? true,
      notifReactions: map['notifReactions'] as bool? ?? true,
      notifReposts: map['notifReposts'] as bool? ?? true,
      notifZaps: map['notifZaps'] as bool? ?? true,
      notifFollowings: map['notifFollowings'] as bool? ?? true,
      notifPrivateMessage: map['notifPrivateMessage'] as bool? ?? true,
      enablePushNotification: map['enablePushNotification'] as bool? ?? true,
      writingContentType:
          map['writingContentType'] as String? ?? AppContentType.note.name,
      leadingFeedCustomization: Map<String, bool>.from(
        map['leadingFeedCustomization'] as Map<String, dynamic>,
      ),
      actionsArrangement: map['actionsArrangement'] is List
          ? defaultActionsArrangement
          : Map<String, bool>.from(
              map['actionsArrangement'] as Map<String, dynamic>,
            ),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppCustomization.fromJson(String source) => AppCustomization.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}

const defaultLeadingFeedCustomization = {
  'recent': true,
  'recentWithReplies': true,
  'trending': true,
  'highlights': true,
  'paid': true,
  'widgets': true,
};

const defaultCommenLeadingType = [
  CommonFeedTypes.recent,
  CommonFeedTypes.recentWithReplies,
  CommonFeedTypes.trending,
  CommonFeedTypes.highlights,
  CommonFeedTypes.paid,
  CommonFeedTypes.widgets,
];
