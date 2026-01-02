// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'utils.dart';

// ** App version
const String appVersion = 'v1.9.8+179';

//** network
const uploadUrl = 'api/v1/file-upload';
const baseUrl = 'https://yakihonne.com/';
const apiBaseUrl = 'https://api.yakihonne.com/';
const cacheUrl = 'https://cache-v2.yakihonne.com/api/v1/';
const pointsUrl = 'https://api.yakihonne.com/api/v1/';
const nostrBandURl = 'https://api.nostr.band/v0/';
const relaysUrl = 'https://api.nostr.watch/v1/online';
const searchRelaysUrl = 'https://api.nostr.watch/v2/relays/by/nip';
const searchUrl = 'https://api.nostr.band/nostr?method=search&count=10&q=';
const topicsUrl = 'https://yakihonne.com/api/v1/yakihonne-topics';
const pointsSystemUrl = 'https://www.yakihonne.com/points-system';
const walletsUrl = 'https://wallet.yakihonne.com/api/wallets';
const swtUrl = 'https://swt.yakihonne.com';
const playgroundUrl = 'https://yakihonne.com/sw-playground';
const imgProxy = 'https://imgproxy.yakihonne.com';
const reposUrl =
    'https://github.com/search?q=topic%3Asmart-widget+org%3AYakiHonne&type=Repositories';
const docsUrl = 'https://yakihonne.com/docs/sw/intro';
const relaysCollection =
    'https://raw.githubusercontent.com/CodyTseng/awesome-nostr-relays/master/dist/collections.json';

final lg = Logger(
  printer: PrettyPrinter(
    colors: false,
  ),
);

//** Colors
const kBlack = Colors.black;
const kWhite = Colors.white;
const kScaffoldDark = Color(0xff171718);
const kTransparent = Colors.transparent;
const kCardDark = Color(0xff222525);
const kOutlineDark = Color(0xff393b3b);
const kOutlineLight = Color(0xffe5e5e5);

// main colors
const kMainColor = Color(0xffEE7700);
const kMainColor1 = Color(0xff6B218D);
const kMainColor2 = Color(0xffDD2222);
const kMainColor3 = Color(0xff00994D);
const kMainColor4 = Color(0xffFFC107);
const kMainColor5 = Color(0xff1565C0);

const mainColorsList = [
  kMainColor,
  kMainColor3,
  kMainColor1,
  kMainColor2,
  kMainColor4,
  kMainColor5,
];

const kPurple = Color(0xFF86318C);
const kLightPurple = Colors.purpleAccent;
const kDarkGrey = Color(0xff1C1B1F);
const kDimBgGrey = Color(0xff252429);
const kDimGrey2 = Color(0xff343434);
const kDimGrey3 = Color(0xff808080);
const kLightBgGrey = Color(0xfff7f7f7);
const kDimGrey = Color(0xffB3B3B3);
const kPaleGrey2 = Color(0xffF4F4F4);
const kPaleGrey = Color(0xffE5E5E5);
const kLightGrey = Color(0xffF2F2F2);
const kDimPurple = Color(0xff220038);
const kRed = Color(0xffFF4A4A);
const kRedSide = Color(0xfffff6f6);
const kYellow = Color(0xffFFE604);
const kYellowSide = Color(0xfffcd452);
const kGreen = Color(0xff00C04D);
const kGreenSide = Color(0xffF2FDF6);
const kBlue = Color(0xff504DFF);
const kNavyBlue = Color(0xff1d9bf0);
const kBlueSide = Color(0xffF6F6FF);

const kMainColorSide = Color(0xffFFFAF3);

const kBlackTheme = Color(0xff000000);
const kBlackSoft = Color(0xff1a1a1a);
const kBlackCard = Color(0xff2a2a2a);
const kBlackOutline = Color(0xff404040);

const kCreamTheme = Color(0xffFAF7F3);
const kCreamLight = Color(0xffFFFFFF);
const kCreamDark = Color(0xffF8F6F4);
const kCreamCard = Color(0xffF0ECE8);
const kCreamOutline = Color(0xffE6E4E2);
const kCreamHint = Color(0xffB8B6B4);

const kElPerPage = 20;
const kElPerPage2 = 10;

const suggestionLeadingSeparatorCount = 10;
const suggestionDiscoverSeparatorCount = 15;

const collapseNoteWordsCount = 100;
const collapseNotificationWordsCount = 20;

const defaultMaxMinumumWordsPerArticle = 1000.0;
const defaultMaxMinimumItemsPerCuration = 10.0;

const yakiAppSettingsTag = 'YakihonneAppSettings';

const noBlue = Color(0xff3984E9);
const noOrange = Color(0xffFFA02F);
const noGreen = Color(0xff03AC13);

//**  paddings
const kDefaultPadding = 20.0;

const defaultZapamount = 21;

//**  paddings
const cacheMaxSize = 2048;

const mentionToken = '‡';

//** containers
final containerBorder = OutlineInputBorder(
  borderSide: const BorderSide(
    color: kDimGrey,
    width: 0.5,
  ),
  borderRadius: BorderRadius.circular(
    kDefaultPadding / 1.5,
  ),
);

//** cacheManager
final imagesCacheManager = CacheManager(
  Config(
    'yakihonneCacheKey',
    stalePeriod: const Duration(days: 3),
    //one week cache period
  ),
);

//** nostr indexer urls

const nostrIndexersUrls = [
  'nstart.me',
  'njump.me',
  'yakihonne.com',
  'nostr.com',
  'nostr.band',
  'iris.to',
  'primal.net',
  'jumble.social',
  'coracle.social',
  'nostrudel.ninja',
  'phoenix.social',
  'habla.news',
  'nosotros.app',
  'nostter.app',
  'lumilumi.app',
  'fevela.me',
  'jumblekat.com',
];

//** available locales

const availableLocales = {
  'en': {
    'name': 'English',
    'icon': FeatureIcons.flagUs,
  },
  'es': {
    'name': 'Español',
    'icon': FeatureIcons.flagEs,
  },
  'it': {
    'name': 'Italiano',
    'icon': FeatureIcons.flagIt,
  },
  'ar': {
    'name': 'عربية',
    'icon': FeatureIcons.flagSa,
  },
  'fr': {
    'name': 'Français',
    'icon': FeatureIcons.flagFr,
  },
  'zh': {
    'name': '中国人',
    'icon': FeatureIcons.flagCn,
  },
  'pt': {
    'name': 'Português',
    'icon': FeatureIcons.flagPt,
  },
  'ja': {
    'name': '日本語',
    'icon': FeatureIcons.flagJa,
  },
  'th': {
    'name': 'ไทย',
    'icon': FeatureIcons.flagTh,
  },
  'hi': {
    'name': 'हिन्दी',
    'icon': FeatureIcons.flagInd,
  },
  'ru': {
    'name': 'Русский',
    'icon': FeatureIcons.flagRu,
  },
};

//** date format
final dateFormat = DateFormat('dd/MM/yyyy');
final dateFormat2 = DateFormat('MMM dd, yyyy');
final dateFormat3 = DateFormat('MMM dd yyyy, h:mma');
final dateFormat4 = DateFormat('MMM dd, yyyy HH:mm');
final dateformat5 = DateFormat('MMM y');
final dateFormat6 = DateFormat('MMM dd');
final dateFormat7 = DateFormat('HH:mm');

// ** number formatter
final thousandsFormatter = NumberFormat('###,000');

// ** events constants
const bookmarkTag = 'bookmark';
const yakihonneTopicTag = 'MyFavoriteTopicsInYakihonne';
const smartWidgetSavedTools = 'SmartWidgetSavedTools';
const yakihonneArticlesBookmarksTag = "YakiHonne's articles";
const yakihonneCurationsBookmarksTag = "YakiHonne's curation";
const yakihonneFlashNewsBookmarksTag = "YakiHonne's flash news";

const yakihonneHex =
    '20986fb83e775d96d188ca5c9df10ce6d613e0eb7e5768a0f0b12b37cdac21b3';

const readers =
    'Readers shared extra details they thought people might find relevant.';

const albyRedirectUri = 'https://yakihonne.com/wallet/alby';

const nostrHighlights =
    '9a500dccc084a138330a1d1b2be0d5e86394624325d25084d3eca164e7ea698a';

const timerTicks = 10;
const FN_MAX_LENGTH = 1000;
const INIT_RATING_REWARD = 21;
const INIT_UN_REWARD = 21;
const FINAL_SEALED_REWARD = 100;

const lorem =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

final fieldValidator = MultiValidator(
  [
    RequiredValidator(
      errorText: 'Requierd field',
    ),
  ],
);

const randomPfps = [
  RandomPfps.randomPfp1,
  RandomPfps.randomPfp2,
  RandomPfps.randomPfp3,
  RandomPfps.randomPfp4,
  RandomPfps.randomPfp5,
  RandomPfps.randomPfp6,
  RandomPfps.randomPfp7,
  RandomPfps.randomPfp8,
  RandomPfps.randomPfp9,
  RandomPfps.randomPfp10,
];

const defaultActionsArrangement = {
  'reactions': true,
  'replies': true,
  'reposts': true,
  'quotes': true,
  'zaps': true,
};

const profileImages = [
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_0.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_1.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_3.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_4.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_5.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_6.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_7.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_8.png',
];

const supportedPaths = [
  'article',
  'curation',
  'video',
  'smart-widget',
  'discover',
  'note',
];

const helpfulRatingPoints = [
  'Cites high-quality sources',
  'Easy to understand',
  "Directly addresses the post's claim",
  'Provides important context',
  'Other',
];

const notHelpfulRatingPoints = [
  'Sources not included or unreliable',
  'Sources do not support note',
  'Incorrect information',
  'Opinion or speculation',
  'Typos or unclear language',
  'Misses key points or irrelevant',
  'Argumentative or biased language',
  'Harassment or abuse',
  'Other',
];

const bookmarksTypes = [
  'All',
  'Articles',
  'Curations',
  'Notes',
  'Videos',
  'Links',
  'Hashtags'
];

const mandatoryRelays = [
  'wss://nostr-01.yakihonne.com',
  'wss://nostr-02.yakihonne.com',
  'wss://nostr-03.dorafactory.org',
];

const constantRelays = [
  'wss://nostr-01.yakihonne.com',
  'wss://nostr-02.yakihonne.com',
  'wss://nostr-03.dorafactory.org',
  'wss://nostr-02.dorafactory.org',
  'wss://relay.damus.io',
];

const defaultExternalWallet = 'satoshi';
const wallets = {
  'satoshi': {
    'name': 'Wallet of Satoshi',
    'icon': WalletsLogos.satoshi,
    'deeplink': 'walletofsatoshi:',
  },
  'albygo': {
    'name': 'Alby Go',
    'icon': WalletsLogos.albyGo,
    'deeplink': 'alby:',
  },
  'bluewallet': {
    'name': 'Blue Wallet',
    'icon': WalletsLogos.bluetwallet,
    'deeplink': 'bluewallet:lightning:',
  },
  'muun': {
    'name': 'Muun',
    'icon': WalletsLogos.muun,
    'deeplink': 'muun:',
  },
  'breez': {
    'name': 'Breez',
    'icon': WalletsLogos.breez,
    'deeplink': 'breez:lightning:',
  },
  'zebedee': {
    'name': 'Zebedee',
    'icon': WalletsLogos.zebedee,
    'deeplink': 'zbd:lightning:',
  },
  'zeusln': {
    'name': 'Zeus LN',
    'icon': WalletsLogos.zeusln,
    'deeplink': 'zeusln:',
  },
  'phoenix': {
    'name': 'Phoenix',
    'icon': WalletsLogos.phoenix,
    'deeplink': 'phoenix:lightning:',
  },
  'blitz': {
    'name': 'Blitz',
    'icon': WalletsLogos.blitz,
    'deeplink': 'blitz:lightning:',
  },
};

const defaultZaps = {
  '0': {
    'value': '20',
    'icon': ReactionsIcons.reaction1,
  },
  '1': {
    'value': '100',
    'icon': ReactionsIcons.reaction2,
  },
  '2': {
    'value': '500',
    'icon': ReactionsIcons.reaction3,
  },
  '3': {
    'value': '1000',
    'icon': ReactionsIcons.reaction4,
  },
  '4': {
    'value': '5000',
    'icon': ReactionsIcons.reaction5,
  },
  '5': {
    'value': '10000',
    'icon': ReactionsIcons.reaction6,
  },
  '6': {
    'value': '50000',
    'icon': ReactionsIcons.reaction7,
  },
  '7': {
    'value': '100000',
    'icon': ReactionsIcons.reaction8,
  },
};

const aspectRatios = ['16:9', '1:1'];

const eulaContent = {
  'Prohibited Content and Activities': {
    'Prohibited Content':
        'Users are strictly prohibited from uploading, sharing, or promoting content that is illegal, offensive, discriminatory, or violates the rights of others, including intellectual property rights.',
    'Security Compromise':
        'Users shall not engage in activities that compromise the security of the App, its users, or any associated networks.',
    'Spamming':
        'The App prohibits spamming activities, including but not limited to unsolicited messages, advertisements, or any form of intrusive communication.',
  },
  'Misrepresentation and Illegal Activities': {
    'Misrepresentation':
        'Users shall not engage in any form of misrepresentation, impersonation, or fraudulent activities within the App.',
    'Illegal Activities':
        'The App must not be used for any illegal activities, and users are responsible for complying with all applicable laws and regulations.',
  },
  'User Content Responsibility': {
    'User Content':
        'Users are solely responsible for the content they upload, share, or distribute through the App. YakiHonne disclaims any liability for user-generated content.',
    'Moderation':
        'YakiHonne reserves the right to moderate, remove, or disable content that violates this EULA or is deemed inappropriate without prior notice.',
  },
  'Intellectual Property': {
    'Ownership':
        "YakiHonne retains all rights, title, and interest in and to the App, including its intellectual property. This EULA does not grant users any rights to use YakiHonne's trade names, trademarks, service marks, logos, domain names, or other distinctive brand features."
  },
  'Governing Law': {
    'Applicable Law':
        'This EULA is governed by and construed in accordance with the laws of Singapore, without regard to its conflict of law principles.',
  },
  'Disclaimer of Warranty': {
    'As-Is Basis':
        'The App is provided "as is" without any warranty, express or implied, including but not limited to the implied warranties of fitness for a particular purpose, or non-infringement.',
    'No Warranty of Security':
        'YakiHonne does not warrant that the App will be error-free or uninterrupted, and YakiHonne does not make any warranty regarding the quality, accuracy, reliability, or suitability of our app for any particular purpose.',
  },
};

const postUrls = [
  '',
  'https://swt.yakihonne.com/user-search',
  'https://swt.yakihonne.com/quote',
  'https://swt.yakihonne.com/trending-notes/next',
  'https://swt.yakihonne.com/trending-users/next',
  'https://swt.yakihonne.com/event-countdown/countdown',
  'https://swt.yakihonne.com/memes/shuffle',
  'https://swt.yakihonne.com/generate-memes/list/0',
  'https://swt.yakihonne.com/quiz-game',
  'https://swt.yakihonne.com/user-stats-search',
  'https://swt.yakihonne.com/user-zaps/zap',
  'https://swt.yakihonne.com/jokes/joke',
  'https://swt.yakihonne.com/user-profile-zapping/profiles',
  'https://swt.yakihonne.com/user-profile-visiting/profiles',
];

final postFunctionsMap = {
  'My custom function': postUrls[0],
  'Search user': postUrls[1],
  'Quote of the day': postUrls[2],
  'Trending notes': postUrls[3],
  'Trending users': postUrls[4],
  'Event countdown': postUrls[5],
  'Funny memes': postUrls[6],
  'Meme generator': postUrls[7],
  'Quiz game': postUrls[8],
  'User network stats': postUrls[9],
  'Highest zapper': postUrls[10],
  'Funny jokes': postUrls[11],
  'Profile zapping': postUrls[12],
  'Profile visiting': postUrls[13],
};

const postRequireInput = {
  'https://swt.yakihonne.com/user-search',
  'https://swt.yakihonne.com/user-stats-search',
  'https://swt.yakihonne.com/user-zaps/zap',
  'https://swt.yakihonne.com/user-profile-zapping/profiles'
};

const postRequireParams = {
  'https://swt.yakihonne.com/event-countdown/countdown',
  'https://swt.yakihonne.com/user-zaps/zap',
  'https://swt.yakihonne.com/user-profile-zapping/profiles',
  'https://swt.yakihonne.com/user-profile-visiting/profiles'
};

const discoverDvms = [
  'fb8e142b06bf5651d35e66d2f4c789167f2ab580ab195d1357bcaeb27ec56955',
  'bf7506b3bb03da0bdbd3c437e47deb9a031dd3db4b47db93646fbeffbaa91b10',
  '0d328c49db379d3574ae13a49b035b45e68b391289e2482ffcf4501de0b1d3b7',
  '3ac9ed8bae8d214fd370102a15dedfe540c83e200b718c46362a07b12ff6a954',
  '3fad6b313fc94cdc067d845e307cff992f0d6d86594c5a47e76768e3ebab6714',
  '56ea2798a265b5381cc163bd244aceb13f9917cc3e789c8563c2f879f544a00e',
  '05371ca44e1b8a9f0044c083297dfda645182fba9cdcf70c84525b95aef9ae49',
  'df3fd2ad2f13b692f76abf533c0c1275c00c774c5d121c9c46ec74f80f08b224',
  '07ba215e8f0c8d1eafca0cab90ba956fd79dce60d87f91d1f08905f4d283613b',
  '86d2ed40db51925b0aa55d4e27e78696ab843b5202d01ce0004e144bca2e7af0',
  'dfe8f3861e397eda1bf0201296df7b99d733ffba3b44bc980224d3f6dec6fd6a',
  '9f1b20ad036a0085f8be8907e12797ab06893030d46354290c4cfc88d82cc2f4',
  '84e14e1d276181ac01565fac99b6f279fd0bb9c41a9b6d4143d1bfacdf18f3ab',
  '143ec592500517978521c0bd9861bd5cd2268495bd415b13edb4eb955f7d2093',
  '9142363004de55e5c8f1bc183497411bc825ddaf783f55788e3ff8a1b489ad57',
  'be22e63c96ee0340dc02bf6a0af1ddebe42e666df0cfb9215c5bcde5f02fce04',
  '83527f90ca297fba9318b41600a84e37656bf31a31352b9318e6b6be885dafd3',
  '32815db82c5c2b97971316cdee1a9518289ea63591fcaf5808da8b403237f538',
];

const notesDvms = [
  '9e09a914f41db178ba442b7372944b021135c08439516464a9bd436588af0b58',
  'bc3cf339d8eafbaac1057a8e4a3800c4e57dca6dd8a9a01d0c96410f95cf6d9d',
  'bb9b5961ac890ed6159172c399273b14f79b34cebad33ee6ca5ba14783528ebe',
  '4d14f2d106bdf0e65d527db75a5f832d8fff1a8047fd969db8e661ea9c383000',
  'ceb7e7d688e8a704794d5662acb6f18c2455df7481833dd6c384b65252455a95',
];

const Map<String, String> countryFlags = {
  'AF': '🇦🇫',
  'AL': '🇦🇱',
  'DZ': '🇩🇿',
  'AS': '🇦🇸',
  'AD': '🇦🇩',
  'AO': '🇦🇴',
  'AI': '🇦🇮',
  'AG': '🇦🇬',
  'AR': '🇦🇷',
  'AM': '🇦🇲',
  'AU': '🇦🇺',
  'AT': '🇦🇹',
  'AZ': '🇦🇿',
  'BS': '🇧🇸',
  'BH': '🇧🇭',
  'BD': '🇧🇩',
  'BB': '🇧🇧',
  'BY': '🇧🇾',
  'BE': '🇧🇪',
  'BZ': '🇧🇿',
  'BJ': '🇧🇯',
  'BM': '🇧🇲',
  'BT': '🇧🇹',
  'BO': '🇧🇴',
  'BA': '🇧🇦',
  'BW': '🇧🇼',
  'BR': '🇧🇷',
  'BN': '🇧🇳',
  'BG': '🇧🇬',
  'BF': '🇧🇫',
  'BI': '🇧🇮',
  'KH': '🇰🇭',
  'CM': '🇨🇲',
  'CA': '🇨🇦',
  'CV': '🇨🇻',
  'KY': '🇰🇾',
  'CF': '🇨🇫',
  'TD': '🇹🇩',
  'CL': '🇨🇱',
  'CN': '🇨🇳',
  'CO': '🇨🇴',
  'KM': '🇰🇲',
  'CG': '🇨🇬',
  'CD': '🇨🇩',
  'CR': '🇨🇷',
  'CI': '🇨🇮',
  'HR': '🇭🇷',
  'CU': '🇨🇺',
  'CY': '🇨🇾',
  'CZ': '🇨🇿',
  'DK': '🇩🇰',
  'DJ': '🇩🇯',
  'DM': '🇩🇲',
  'DO': '🇩🇴',
  'EC': '🇪🇨',
  'EG': '🇪🇬',
  'SV': '🇸🇻',
  'GQ': '🇬🇶',
  'ER': '🇪🇷',
  'EE': '🇪🇪',
  'SZ': '🇸🇿',
  'ET': '🇪🇹',
  'FJ': '🇫🇯',
  'FI': '🇫🇮',
  'FR': '🇫🇷',
  'GA': '🇬🇦',
  'GM': '🇬🇲',
  'GE': '🇬🇪',
  'DE': '🇩🇪',
  'GH': '🇬🇭',
  'GR': '🇬🇷',
  'GD': '🇬🇩',
  'GT': '🇬🇹',
  'GN': '🇬🇳',
  'GW': '🇬🇼',
  'GY': '🇬🇾',
  'HT': '🇭🇹',
  'HN': '🇭🇳',
  'HU': '🇭🇺',
  'IS': '🇮🇸',
  'IN': '🇮🇳',
  'ID': '🇮🇩',
  'IR': '🇮🇷',
  'IQ': '🇮🇶',
  'IE': '🇮🇪',
  'IL': '🇮🇱',
  'IT': '🇮🇹',
  'JM': '🇯🇲',
  'JP': '🇯🇵',
  'JO': '🇯🇴',
  'KZ': '🇰🇿',
  'KE': '🇰🇪',
  'KI': '🇰🇮',
  'KW': '🇰🇼',
  'KG': '🇰🇬',
  'LA': '🇱🇦',
  'LV': '🇱🇻',
  'LB': '🇱🇧',
  'LS': '🇱🇸',
  'LR': '🇱🇷',
  'LY': '🇱🇾',
  'LI': '🇱🇮',
  'LT': '🇱🇹',
  'LU': '🇱🇺',
  'MG': '🇲🇬',
  'MW': '🇲🇼',
  'MY': '🇲🇾',
  'MV': '🇲🇻',
  'ML': '🇲🇱',
  'MT': '🇲🇹',
  'MH': '🇲🇭',
  'MR': '🇲🇷',
  'MU': '🇲🇺',
  'MX': '🇲🇽',
  'FM': '🇫🇲',
  'MD': '🇲🇩',
  'MC': '🇲🇨',
  'MN': '🇲🇳',
  'ME': '🇲🇪',
  'MA': '🇲🇦',
  'MZ': '🇲🇿',
  'MM': '🇲🇲',
  'NA': '🇳🇦',
  'NR': '🇳🇷',
  'NP': '🇳🇵',
  'NL': '🇳🇱',
  'NZ': '🇳🇿',
  'NI': '🇳🇮',
  'NE': '🇳🇪',
  'NG': '🇳🇬',
  'KP': '🇰🇵',
  'NO': '🇳🇴',
  'OM': '🇴🇲',
  'PK': '🇵🇰',
  'PW': '🇵🇼',
  'PA': '🇵🇦',
  'PG': '🇵🇬',
  'PY': '🇵🇾',
  'PE': '🇵🇪',
  'PH': '🇵🇭',
  'PL': '🇵🇱',
  'PT': '🇵🇹',
  'QA': '🇶🇦',
  'RO': '🇷🇴',
  'RU': '🇷🇺',
  'RW': '🇷🇼',
  'WS': '🇼🇸',
  'SM': '🇸🇲',
  'SA': '🇸🇦',
  'SN': '🇸🇳',
  'RS': '🇷🇸',
  'SC': '🇸🇨',
  'SL': '🇸🇱',
  'SG': '🇸🇬',
  'SK': '🇸🇰',
  'SI': '🇸🇮',
  'SB': '🇸🇧',
  'SO': '🇸🇴',
  'ZA': '🇿🇦',
  'KR': '🇰🇷',
  'ES': '🇪🇸',
  'LK': '🇱🇰',
  'SD': '🇸🇩',
  'SR': '🇸🇷',
  'SE': '🇸🇪',
  'CH': '🇨🇭',
  'SY': '🇸🇾',
  'TW': '🇹🇼',
  'TJ': '🇹🇯',
  'TZ': '🇹🇿',
  'TH': '🇹🇭',
  'TL': '🇹🇱',
  'TG': '🇹🇬',
  'TO': '🇹🇴',
  'TT': '🇹🇹',
  'TN': '🇹🇳',
  'TR': '🇹🇷',
  'TM': '🇹🇲',
  'TV': '🇹🇻',
  'UG': '🇺🇬',
  'UA': '🇺🇦',
  'AE': '🇦🇪',
  'GB': '🇬🇧',
  'US': '🇺🇸',
  'UY': '🇺🇾',
  'UZ': '🇺🇿',
  'VU': '🇻🇺',
  'VA': '🇻🇦',
  'VE': '🇻🇪',
  'VN': '🇻🇳',
  'YE': '🇾🇪',
  'ZM': '🇿🇲',
  'ZW': '🇿🇼',
};

const Map<String, String> currencies = {
  'usd': '🇺🇸',
  'eur': '🇪🇺',
  'aed': '🇦🇪',
  'cad': '🇨🇦',
  'gbp': '🇬🇧',
  'cny': '🇨🇳',
  'aud': '🇦🇺',
  'myr': '🇲🇾',
  'jpy': '🇯🇵',
  'ars': '🇦🇷',
  'bhd': '🇧🇭',
  'bmd': '🇧🇲',
  'brl': '🇧🇷',
  'chf': '🇨🇭',
  'clp': '🇨🇱',
  'czk': '🇨🇿',
  'dkk': '🇩🇰',
  'gel': '🇬🇪',
  'hkd': '🇭🇰',
  'huf': '🇭🇺',
  'idr': '🇮🇩',
  'inr': '🇮🇳',
  'krw': '🇰🇷',
  'kwd': '🇰🇼',
  'lkr': '🇱🇰',
  'mmk': '🇲🇲',
  'mxn': '🇲🇽',
  'ngn': '🇳🇬',
  'nok': '🇳🇴',
  'nzd': '🇳🇿',
  'php': '🇵🇭',
  'pkr': '🇵🇰',
  'pln': '🇵🇱',
  'rub': '🇷🇺',
  'sar': '🇸🇦',
  'sek': '🇸🇪',
  'sgd': '🇸🇬',
  'thb': '🇹🇭',
  'try': '🇹🇷',
  'twd': '🇹🇼',
  'uah': '🇺🇦',
  'bdt': '🇧🇩',
};

const Map<String, String> currenciesSymbols = {
  'usd': r'$',
  'eur': '€',
  'aed': 'د.إ',
  'cad': r'C$',
  'gbp': '£',
  'cny': '¥',
  'aud': r'A$',
  'myr': 'RM',
  'jpy': '¥',
  'ars': r'$',
  'bhd': 'ب.د',
  'bmd': r'$',
  'brl': r'R$',
  'chf': 'Fr',
  'clp': r'$',
  'czk': 'Kč',
  'dkk': 'kr',
  'gel': '₾',
  'hkd': r'HK$',
  'huf': 'Ft',
  'idr': 'Rp',
  'inr': '₹',
  'krw': '₩',
  'kwd': 'د.ك',
  'lkr': 'Rs',
  'mmk': 'K',
  'mxn': r'$',
  'ngn': '₦',
  'nok': 'kr',
  'nzd': r'NZ$',
  'php': '₱',
  'pkr': 'Rs',
  'pln': 'zł',
  'rub': '₽',
  'sar': 'ر.س',
  'sek': 'kr',
  'sgd': r'S$',
  'thb': '฿',
  'try': '₺',
  'twd': r'NT$',
  'uah': '₴',
  'bdt': '৳',
};
