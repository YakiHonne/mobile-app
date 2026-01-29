// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

import 'utils.dart';

enum AppTheme { purpleWhite, purpleDark }

enum CurrentRoute { logify, disclosure, main }

enum UpdatingState {
  idle,
  progress,
  failure,
  success,
  networkFailure,
  wrongCredentials
}

enum MainViews {
  notifications,
  uncensoredNotes,
  dms,
  leading,
  wallet,
  smartWidgets,
  articles,
  media,
  hidden,
}

enum FlashNewsType {
  userActive,
  userPending,
  public,
  display,
  publicWithoutSealed
}

enum AuthenticationViews {
  initial,
  login,
  generateKeys,
  pictureSelection,
  nameSelection
}

enum SearchResultsType { noSearch, content, loading }

enum NoteStatType { reaction, repost, quote }

enum PropertiesViews { main, banner, profilePicture, relays }

enum PicturesType { defaultPicture, localPicture, linkPicture }

enum PropertiesToggle {
  none,
  nip05,
  lightning,
  personal,
  contentModeration,
  wallets
}

enum AccountStatus { available, deleted, error }

enum ThreadsType { flash, article, curation, horizontalVideo, aiFeedDetails }

enum ContentType { article, curation, video, smart }

enum ArticleFilter { All, Published, Drafts }

enum VideoFilter { All, horizontal, vertical }

enum ProfileStatus { available, notAvailable, loading }

enum CommentPrefixStatus { notUsed, used, notSet }

enum AddUncensoredNote { enabled, added, disabled }

enum ArticleCuration { curationsList, curationContent, zaps }

enum WritingNoteStatus { disabled, alreadyWritten, canBeWritten }

enum RewardStatus { not_claimed, in_progress, claimed }

enum UrlType { image, video, text, audio }

enum VideosKinds { youtube, vimeo, regular }

enum DmsType { all, followings, known, unknown }

enum GiphyType { gifs, stickers }

enum ArticlePublishSteps { content, details, zaps }

enum FlashNewsPublishSteps { content, payment }

enum VideoPublishSteps { content, specifications, zaps }

enum SmartWidgetPublishSteps { content, specifications }

enum CurationPublishSteps { content, zaps }

enum FlashNewsKinds { plain, article, curation }

enum VideoSourceType { gallery, link, kind1063 }

enum MediaType { cameraImage, cameraVideo, image, video, gallery }

enum TagType { article, video, notes }

enum NoteRelatedEventsType { replies, reposts, quotes, reactions, zaps }

enum TextContentType { flashnews, uncensoredNote, buzzFeed, note, smartWidget }

// enum UserStatus { notConnected, UsingPubKey, UsingPrivKey }

enum AppClientExtensionType { web, ios, android, linux }

enum SmartWidgetButtonType {
  Regular,
  Nostr,
  Zap,
  Youtube,
  Telegram,
  Discord,
  X
}

enum SWType { basic, action, tool }

enum SWBType { Redirect, Nostr, Zap, Post, App }

enum TextSize { H1, H2, Regular, Small }

enum TextWeight { Bold, Regular }

enum InternalWalletTransactionOption { none, receive, send }

enum NotesType { trending, universal, followings, widgets }

enum SmartWidgetType { community, self }

enum ButtonStatus { disabled, active, inactive, loading }

enum PropertyStatus { valid, invalid, unknown }

enum PollStatsStatus { idle, visible, invisible }

enum ArticleNaddrTypes { article, curation, smart }

enum CommonFeedTypes {
  recent,
  recentWithReplies,
  explore,
  following,
  global,
  trending,
  highlights,
  widgets,
  paid,
  others
}

enum ExploreType { all, articles, videos, curations }

enum RelayContentType { notes, articles, media, curations }

enum DashboardType { home, content, smart, bookmarks, interests }

enum InterestStatus { add, delete, available }

enum AppContentType { note, article, smartWidget, video, curation, picture }

enum AppMediaType {
  image,
  video;

  String getDisplayName(BuildContext context) {
    switch (this) {
      case AppMediaType.image:
        return context.t.image.capitalizeFirst();
      case AppMediaType.video:
        return context.t.video.capitalizeFirst();
    }
  }
}

enum AppContentSource {
  community,
  relay,
  relaySet,
}

enum TranslationsServices {
  deeplPro,
  deeplFree,
  libreTranslateFree,
  libreTranslatePro,
  wineTranslate,
}

enum EventStatus {
  success,
  error,
}

enum MediaServer {
  nostrBuild('nostr.build'),
  nostrMedia('nostr media'),
  nostrCheck('nostr check'),
  voidCat('void cat');

  const MediaServer(this.displayName);
  final String displayName;
}

enum PlaceholderType { loading, error }

enum RelayConnectivity { idle, searching, found, notFound }

enum AppSigner { nSec, nPub, Amber, Bunker }

enum ExternalKeyType { Amber, Bunker }

enum SendZapViewType {
  invoice,
  amount,
  result,
}

enum WalletSendingType {
  invoice,
  send,
  none,
}

enum ZapPaymentMethod {
  cashu,
  internal,
  external,
}

enum RedeemCodeStatus {
  options,
  loading,
  result,
}

enum ShareContentUserStatus { idle, sending, success, failure }

enum AddingRelayOptions { dms, relays, favorite }

enum DmDataState { disabled, enabled, canBeLoaded }

enum ArticleWritingState { edit, preview, editPreview }

enum ProfileData {
  notes,
  pinned,
  replies,
  mentions,
  articles,
  curations,
  smartWidgets,
  allMedia,
  videos,
  pictures;

  String getDisplayName(BuildContext context) {
    switch (this) {
      case ProfileData.notes:
        return context.t.notes.capitalizeFirst();
      case ProfileData.pinned:
        return context.t.pinned.capitalizeFirst();
      case ProfileData.replies:
        return context.t.replies.capitalizeFirst();
      case ProfileData.mentions:
        return context.t.mentions.capitalizeFirst();
      case ProfileData.articles:
        return context.t.articles.capitalizeFirst();
      case ProfileData.curations:
        return context.t.curations.capitalizeFirst();
      case ProfileData.smartWidgets:
        return context.t.smartWidgets.capitalizeFirst();
      case ProfileData.allMedia:
        return context.t.all.capitalizeFirst();
      case ProfileData.videos:
        return context.t.videos.capitalizeFirst();
      case ProfileData.pictures:
        return context.t.pictures.capitalizeFirst();
    }
  }

  String getType() {
    switch (this) {
      case ProfileData.notes:
        return 'notes';
      case ProfileData.pinned:
        return 'notes';
      case ProfileData.replies:
        return 'notes';
      case ProfileData.mentions:
        return 'notes';
      case ProfileData.articles:
        return 'articles';
      case ProfileData.curations:
        return 'others';
      case ProfileData.smartWidgets:
        return 'others';
      case ProfileData.allMedia:
        return 'media';
      case ProfileData.videos:
        return 'media';
      case ProfileData.pictures:
        return 'media';
    }
  }
}

enum NoteTypes {
  pinned,
  notes,
  replies,
  mentions;

  String getDisplayName(BuildContext context) {
    switch (this) {
      case NoteTypes.pinned:
        return context.t.pinned.capitalizeFirst();
      case NoteTypes.notes:
        return context.t.notes.capitalizeFirst();
      case NoteTypes.replies:
        return context.t.replies.capitalizeFirst();
      case NoteTypes.mentions:
        return context.t.mentions.capitalizeFirst();
    }
  }
}

enum ViewDataTypes {
  notes,
  articles,
  media;
}

enum PublishMediaStatus { idle, uploading, publishing }
