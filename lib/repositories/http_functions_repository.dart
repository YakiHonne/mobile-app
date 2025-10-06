import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:dio/dio.dart' as dioinstance;
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:path_provider/path_provider.dart';

import '../common/common_regex.dart';
import '../models/app_models/diverse_functions.dart';
import '../models/app_models/extended_model.dart';
import '../models/article_model.dart';
import '../models/flash_news_model.dart';
import '../models/points_system_models.dart';
import '../models/smart_widgets_components.dart';
import '../models/uncensored_notes_models.dart';
import '../utils/utils.dart';

// ==================================================
// MAIN HTTP REPOSITORY CLASS
// ==================================================

class HttpFunctionsRepository {
  static final _firestore = FirebaseFirestore.instance;

  // Private Dio instances
  static Dio? _dio;
  static Dio? _smDio;

  // ==================================================
  // DIO FACTORY METHODS (PRESERVED EXACTLY)
  // ==================================================

  static Future<Dio> getDio({
    Map<String, dynamic>? headers,
  }) async {
    if (_dio == null) {
      PersistCookieJar? cookieJar;
      Directory appDocDir;
      appDocDir = await getApplicationDocumentsDirectory();
      final appDocPath = appDocDir.path;
      cookieJar = PersistCookieJar(
        storage: FileStorage('$appDocPath/cookies'),
      );

      _dio = Dio(
        BaseOptions(
          headers: headers ??
              {
                'yakihonne-api-key': dotenv.env['API_KEY'],
              },
        ),
      );

      _dio!.options.headers['user-agent'] = 'Yakihonne';
      _dio!.options.headers['accept-encoding'] = 'gzip';
      _dio!.interceptors.add(CookieManager(cookieJar));
    }

    return _dio!;
  }

  static Future<Dio> getSmDio() async {
    if (_smDio == null) {
      PersistCookieJar? cookieJar;
      Directory appDocDir;
      appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      cookieJar = PersistCookieJar(
        storage: FileStorage('$appDocPath/cookies'),
      );

      _smDio = Dio();

      _smDio!.options.headers['user-agent'] = 'Yakihonne';
      _smDio!.options.headers['accept-encoding'] = 'gzip';
      _smDio!.interceptors.add(CookieManager(cookieJar));
    }
    return _smDio!;
  }

  /// Create form data Dio for file uploads

  static Dio getDio2() {
    final dio = Dio();
    dio.options.headers['accept-encoding'] = 'gzip, deflate, br';
    dio.options.headers['accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7';
    return dio;
  }

  // ==================================================
  // BASIC HTTP METHODS (PRESERVED EXACTLY)
  // ==================================================

  static Future<Map<String, dynamic>?> get(
    String link, [
    Map<String, dynamic>? queryParameters,
    Map<String, String>? header,
  ]) async {
    final dio = await getDio();

    if (header != null) {
      dio.options.headers.addAll(header);
    }

    try {
      final Response resp =
          await dio.get(link, queryParameters: queryParameters);

      if (resp.statusCode == 200) {
        if (resp.data is String) {
          final data = json.decode(resp.data);
          return data;
        }
        return resp.data is Map ? resp.data : {'data': resp.data};
      } else {
        return null;
      }
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
    }

    return null;
  }

  static Future<String?> getStr(
    String link, [
    Map<String, dynamic>? queryParameters,
    Map<String, String>? header,
  ]) async {
    final dio = await getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    try {
      final Response resp =
          await dio.get<String>(link, queryParameters: queryParameters);
      if (resp.statusCode == 200) {
        return resp.data;
      } else {
        return null;
      }
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
    }
    return null;
  }

  static Future<dynamic> getSpecified(
    String link, [
    Map<String, dynamic>? queryParameters,
    Map<String, String>? header,
  ]) async {
    final dio = await getDio();

    if (header != null) {
      dio.options.headers.addAll(header);
    }

    try {
      final Response resp = await dio.get(
        link,
        queryParameters: queryParameters,
      );

      if (resp.statusCode == 200) {
        return resp.data;
      } else {
        return null;
      }
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> post(
    String link,
    Map<String, dynamic> parameters, [
    Map<String, String>? header,
    bool? addRedirectOption,
  ]) async {
    try {
      final dio = await getDio();
      if (header != null) {
        dio.options.headers.addAll(header);
      }

      final resp = await dio.post(
        link,
        data: parameters,
      );
      return resp.data;
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      return null;
    }
  }

  // ==================================================
  // CONTENT TYPE & URL UTILITIES
  // ==================================================

  static Future<UrlType> getUrlType(String link) async {
    try {
      final dio = await getDio();

      final Response resp = await dio.get(link);
      if (resp.statusCode == 200) {
        final contentType = resp.headers.map['content-Type']?.first ?? '';

        if (contentType.toLowerCase().startsWith('image')) {
          return UrlType.image;
        } else if (contentType.startsWith('video')) {
          return UrlType.video;
        } else if (contentType.startsWith('audio')) {
          return UrlType.audio;
        } else {
          return UrlType.text;
        }
      } else {
        return UrlType.text;
      }
    } catch (_) {
      return UrlType.text;
    }
  }

  // ==================================================
  // NOSTR STATS METHODS
  // ==================================================

  static Future<Map<String, num>> getUserReceivedZaps(String pubkey) async {
    try {
      final response = await HttpFunctionsRepository.get(
          '$nostrBandURl${'stats/profile/'}$pubkey');

      return {
        'zaps_sent':
            (response?['stats']?[pubkey]?['zaps_sent']?['msats'] ?? 0) / 1000,
        'zaps_sent_count':
            response?['stats']?[pubkey]?['zaps_sent']?['count'] ?? 0,
      };
    } catch (_) {
      return {};
    }
  }

  static Future<int> getUserFollowers(String pubkey) async {
    try {
      final response = await HttpFunctionsRepository.get(
          '$nostrBandURl${'stats/profile/'}$pubkey');

      return response?['stats']?[pubkey]?['followers_pubkey_count'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<Event>> getTrendingNotes() async {
    try {
      final response =
          await HttpFunctionsRepository.get('$nostrBandURl${'trending/notes'}');

      if (response?['notes'] != null) {
        final notesMap = response!['notes'] as List;
        final List<Event> events = [];

        for (final note in notesMap) {
          final evMap = note['event'];

          if (evMap != null) {
            final ev = Event.fromJson(evMap);
            if (!nostrRepository.mutes.contains(ev.pubkey)) {
              events.add(ev);
            }
          }
        }

        return events;
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  // ==================================================
  // REDEEM CODE
  // ==================================================

  static Future<Map<String, dynamic>> redeemCode({
    required String code,
    required String pubkey,
    required String lightningAddress,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'x-api-key': dotenv.env['YAKIHONNE_REDEEM'],
          },
        ),
      );

      final resp = await dio.post(
        'https://api.yakihonne.com/code/redeem',
        data: {
          'code': code,
          'pubkey': pubkey,
          'lightning_address': lightningAddress,
        },
      );

      if (resp.statusCode == 200 && resp.data != null) {
        final statusCode = resp.data['statusCode'];

        return {
          'status': statusCode == 'codeRedeemed',
          'resultCode': statusCode,
          'amount': resp.data['amount'],
        };
      } else {
        return {
          'status': false,
          'resultCode': 'paymentFailed',
        };
      }
    } catch (_) {
      return {
        'status': false,
        'resultCode': 'paymentFailed',
      };
    }
  }
  // ==================================================
  // SMART WIDGET METHODS
  // ==================================================

  static Future<List<SmartWidget>> getDvmSmartWidgets(String search) async {
    final dio = await getDio();

    try {
      final resp = await dio.post(
        'https://yakihonne.com/api/v1/dvm-query',
        data: {'message': search},
      );

      if (resp.statusCode == 200 && resp.data != null) {
        try {
          final details = List.from(resp.data);

          return details.map(
            (e) {
              return SmartWidget.fromEvent(Event.fromJson(e));
            },
          ).toList();
        } catch (e) {
          lg.i(e);
          return [];
        }
      } else {
        return [];
      }
    } on DioException catch (ex) {
      lg.i(ex);
      if (kDebugMode) {
        print(ex.error);
      }
    }

    return [];
  }

  static Future<AppSmartWidget?> getAppSmartWidget(String url) async {
    final dio = await getDio();

    try {
      final widgetUrl = getWidgetUrl(url);

      final resp = await dio.get(widgetUrl);

      if (resp.statusCode == 200 && resp.data is Map) {
        try {
          final as = AppSmartWidget.fromMap(resp.data);

          return as;
        } catch (e, stack) {
          lg.i(stack);
          return null;
        }
      } else {
        return null;
      }
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
    }

    return null;
  }

  static String getWidgetUrl(String url) {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    if (cleanUrl.endsWith('/.well-known/widget.json')) {
      return cleanUrl;
    }

    return '$cleanUrl/.well-known/widget.json';
  }

  static Future<SmartWidget?> postSmartWidget({
    required String url,
    required String text,
    required String aTag,
    int redirectCount = 0,
  }) async {
    if (redirectCount > 5) {
      return null;
    }

    try {
      final dio = await getSmDio();

      final response = await dio.post(
        url,
        data: {
          'input': text,
          'aTag': aTag,
          if (canSign()) 'pubkey': currentSigner!.getPublicKey(),
        },
      );

      if (response.statusCode != null &&
          response.statusCode! >= 300 &&
          response.statusCode! < 400) {
        final redirectUrl = response.headers.value('location');

        if (redirectUrl != null) {
          return postSmartWidget(
            url: urlRegExp.hasMatch(redirectUrl)
                ? redirectUrl
                : '${getBaseUrl(url)}$redirectUrl',
            text: text,
            aTag: aTag,
            redirectCount: redirectCount + 1,
          );
        }
      }

      if (response.data == null) {
        return null;
      }

      try {
        final ev = Event.fromJson(response.data);
        ev.kind = EventKind.SMART_WIDGET_ENH;

        if (ev.kind == EventKind.SMART_WIDGET_ENH) {
          return SmartWidget.fromEvent(ev);
        }
      } catch (_) {}

      return null;
    } on DioException catch (e) {
      lg.i('Dio Error: ${e.response?.statusCode} - ${e.message}');

      return null;
    } catch (e) {
      lg.i('Unexpected error: $e');
      return null;
    }
  }

  static Future<List<SmartWidgetTemplate>> getSmartWidgetTemplates() async {
    try {
      final dio = await getDio();

      final response = await dio.post(swtUrl);

      if (response.data == null) {
        return [];
      }

      try {
        return getTemplates(response.data);
      } catch (_) {}

      return [];
    } on DioException catch (e) {
      lg.i('Dio Error: ${e.response?.statusCode} - ${e.message}');

      return [];
    } catch (e) {
      lg.i('Unexpected error: $e');
      return [];
    }
  }

  // ==================================================
  // AI CHAT METHODS
  // ==================================================

  static Future<MapEntry<bool, String>> getAiChatResponse(
    String message,
  ) async {
    final dio = await getDio();

    try {
      final secret = dotenv.env['REACT_APP_CHECKER_SEC'] ?? '';
      final pubkey = dotenv.env['REACT_APP_CHECKER_PUBKEY'] ?? '';
      final userPubkey = currentSigner?.getPublicKey() ?? '';

      final keys = Keychain(secret);
      final signer = Bip340EventSigner(secret, keys.public);

      final content = jsonEncode({
        'pubkey': userPubkey,
        'sent_at': DateTime.now().toSecondsSinceEpoch(),
      });

      final password = (await signer.encrypt44(content, pubkey))!;

      final resp = await dio.post(
        'https://yakiai.yakihonne.com/api/v1/ai',
        data: {'input': message},
        options: Options(
          headers: {
            'Authorization': password,
          },
        ),
      );

      if (resp.statusCode == 200 && resp.data != null) {
        try {
          return MapEntry(
            resp.data['status'] ?? false,
            resp.data['message'] ?? '',
          );
        } catch (e) {
          lg.i(e);
          return const MapEntry(
            false,
            'error',
          );
        }
      } else {
        return const MapEntry(
          false,
          'error',
        );
      }
    } on DioException catch (ex) {
      lg.i(ex.response);

      if (kDebugMode) {
        print(ex.error);
      }

      return const MapEntry(
        false,
        'error',
      );
    }
  }

  // ==================================================
  // TRANSLATION METHODS
  // ==================================================

  static Future<MapEntry<bool, String>> translateWithDeepL({
    required String content,
    required String targetLang,
    required String url,
    required String apiKey,
  }) async {
    try {
      final translator = Translator(authKey: apiKey);

      final result =
          await translator.translateTextSingular(content, targetLang);

      if (result.text.isNotEmpty) {
        return MapEntry(true, result.text);
      } else {
        return MapEntry(
          false,
          t.errorMissingKey.capitalizeFirst(),
        );
      }
    } catch (e) {
      return MapEntry(
        false,
        t.errorMissingKey.capitalizeFirst(),
      );
    }
  }

  static Future<MapEntry<bool, String>> customTranslate({
    required String content,
    required String targetLang,
    required String url,
    required String? apiKey,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          contentType: 'application/json',
        ),
      );

      final res = await dio.post(
        url,
        data: {
          'q': content,
          'source': 'auto',
          'target': targetLang,
          if (apiKey != null) 'apiKey': apiKey,
        },
      );

      return MapEntry(true, res.data['translatedText'] ?? '');
    } catch (e) {
      lg.i(e);
      return MapEntry(
        false,
        t.errorTranslating.capitalizeFirst(),
      );
    }
  }

  static Future<MapEntry<bool, String>> translateWithWine({
    required String content,
    required String targetLang,
    required String url,
    required String apiKey,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          contentType: 'application/json',
        ),
      );

      final res = await dio.post(
        url,
        data: {
          'q': content,
          'target': targetLang,
          'api_key': apiKey,
        },
      );

      final translatedText = res.data['translatedText'] ?? '';

      if (translatedText.contains('ERROR: Insufficient credits')) {
        return MapEntry(false, t.errorMissingKey.capitalizeFirst());
      } else {
        return MapEntry(true, translatedText);
      }
    } on DioException catch (e) {
      lg.i(e.response);
      return MapEntry(
        false,
        t.errorMissingKey.capitalizeFirst(),
      );
    }
  }

  // ==================================================
  // ALBY WALLET METHODS
  // ==================================================

  static Future<Map<String, dynamic>> handleAlbyApiToken({
    required String code,
    required bool isRefreshing,
  }) async {
    try {
      final dio = await getDio();
      final clientId = dotenv.env['CLIENT_ID']!;
      final clientSecret = dotenv.env['CLIENT_SECRET']!;
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';

      final data = dioinstance.FormData.fromMap(
        {
          'grant_type': isRefreshing ? 'refresh_token' : 'authorization_code',
          if (!isRefreshing) 'code': code,
          if (!isRefreshing) 'redirect_uri': albyRedirectUri,
          if (isRefreshing) 'refresh_token': code,
        },
      );

      final response = await dio.post(
        'https://api.getalby.com/oauth/token',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
          contentType: Headers.multipartFormDataContentType,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        return {
          'token': response.data['access_token'],
          'refreshToken': response.data['refresh_token'],
          'expiresIn': response.data['expires_in'],
          'createdAt': currentUnixTimestampSeconds(),
        };
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static Future<String> getAlbyLightningAddress({
    required String token,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.get(
        'https://api.getalby.com/user/me',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['lightning_address'];
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  static Future<num> getAlbyBalance({
    required String token,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.get(
        'https://api.getalby.com/balance',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['balance'];
      } else {
        return -1;
      }
    } catch (e) {
      return -1;
    }
  }

  static Future<List<WalletTransactionModel>> getAlbyTransactions({
    required String token,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.get(
        'https://api.getalby.com/invoices',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == 200) {
        return getAlbyWalletTransactions(response.data);
      } else {
        return <WalletTransactionModel>[];
      }
    } catch (e, stack) {
      lg.i(stack);
      return <WalletTransactionModel>[];
    }
  }

  static Future<String?> getAlbyInvoice({
    required String token,
    required int amount,
    required String message,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.post(
        'https://api.getalby.com/invoices',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
        data: {
          'amount': amount,
          if (message.isNotEmpty) 'comment': message,
          if (message.isNotEmpty) 'description': message,
          if (message.isNotEmpty) 'memno': message
        },
      );

      return response.data['payment_request'];
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  static Future<Map<String, dynamic>> sendAlbyPayment({
    required String token,
    required String invoice,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.post(
        'https://api.getalby.com/payments/bolt11',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
        data: {
          'invoice': invoice,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    } catch (e) {
      lg.i(e);
      return {};
    }
  }

  // ==================================================
  // NOSTR VERIFICATION METHODS
  // ==================================================

  static Future<bool> checkNip05Validity({
    required String domain,
    required String name,
    required String pubkey,
  }) async {
    try {
      final link = 'https://$domain/.well-known/nostr.json?name=$name';
      final response = await get(link);

      return (response?['names'] as Map?)?[name] == pubkey;
    } catch (e) {
      return false;
    }
  }

  // ==================================================
  // FLASH NEWS & CONTENT METHODS
  // ==================================================

  static Future<List<MainFlashNews>> getImportantFlashnews() async {
    try {
      final response = await getSpecified('${cacheUrl}mb/flashnews/important');

      if (response != null) {
        return mainFlashNewsFromJson(response);
      } else {
        return <MainFlashNews>[];
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getFlashNews({
    required DateTime date,
    required int page,
  }) async {
    try {
      final searchMap = {
        'from': DateTime(
          date.year,
          date.month,
          date.day,
        ).toSecondsSinceEpoch(),
        'to': DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).toSecondsSinceEpoch(),
        'elPerPage': 6,
        'page': page,
      };

      final response = await getSpecified(
        '${cacheUrl}mb/flashnews-v2',
        searchMap,
      );

      final mains = mainFlashNewsFromJson(response['flashnews']);
      metadataCubit
          .fetchMetadata(mains.map((e) => e.flashNews.pubkey).toList());

      return {
        'total': response['total'],
        'flashnews': mains,
      };
    } catch (e) {
      lg.i(e);
      rethrow;
    }
  }

  static Future<UnFlashNews?> getUnFlashNews(
    String id,
  ) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}flashnews/$id',
      );

      if (response != null) {
        return UnFlashNews.fromMap2(response);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<List<UnFlashNews>> getNewFlashnews(
    String extension,
    int page,
  ) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}flashnews/$extension',
        {
          'page': page,
          'elPerPage': kElPerPage2,
        },
      );

      if (response != null) {
        return newFNListFromJson(response['flashnews']);
      } else {
        return <UnFlashNews>[];
      }
    } catch (e) {
      return [];
    }
  }

  // ==================================================
  // UNCENSORED NOTES METHODS
  // ==================================================

  static Future<num> getBalance() async {
    try {
      final response = await getSpecified('${cacheUrl}balance');

      if (response != null) {
        return response['balance'];
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, num>> getImpacts(String pubkey) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}user-impact',
        {'pubkey': pubkey},
      );

      if (response != null) {
        return {
          'writing': response['writing_impact']['writing_impact'],
          'positiveWriting': response['writing_impact']
              ['positive_writing_impact'],
          'negativeWriting': response['writing_impact']
              ['negative_writing_impact'],
          'ongoingWriting': response['writing_impact']
              ['ongoing_writing_impact'],
          'rating': response['rating_impact']['rating_impact'],
          'positiveRatingH': response['rating_impact']
              ['positive_rating_impact_h'],
          'positiveRatingNh': response['rating_impact']
              ['positive_rating_impact_nh'],
          'negativeRatingNh': response['rating_impact']
              ['negative_rating_impact_nh'],
          'negativeRatingH': response['rating_impact']
              ['negative_rating_impact_h'],
          'ongoingRating': response['rating_impact']['ongoing_rating_impact'],
        };
      } else {
        return {
          'writing': 0,
          'rating': 0,
        };
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<RewardModel>> getRewards(String pubkey) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}my-rewards',
        {'pubkey': pubkey},
      );

      if (response != null) {
        return rewardFromJson(response);
      } else {
        return <RewardModel>[];
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Metadata>> getUsers(String search) async {
    try {
      final response = await getSpecified('${cacheUrl}users/search/$search');
      if (response != null) {
        final List<Metadata> users = [];

        for (final item in response) {
          try {
            final user = Metadata(
              pubkey: item['pubkey'],
              name: item['display_name'] == null ||
                      (item['display_name'] as String).isEmpty
                  ? item['name'] ?? ''
                  : item['display_name'],
              displayName: item['display_name'] ?? '',
              about: item['about'] ?? '',
              picture: item['picture'] ?? '',
              banner: item['banner'] ?? '',
              website: item['website'] ?? '',
              nip05: item['nip05'] ?? '',
              lud16: item['lud16'] ?? '',
              lud06: item['lud06'] ?? '',
              createdAt: item['created_at'],
              isDeleted: item['deleted'] ?? false,
            );

            users.add(user);
          } catch (e) {
            lg.i(e);
          }
        }

        return users;
      } else {
        return <Metadata>[];
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUncensoredNotes({
    required String flashNewsId,
  }) async {
    try {
      final response = await getSpecified('${cacheUrl}flashnews/$flashNewsId');

      if (response == null) {
        return {
          'notes': <UncensoredNote>[],
          'notHelpful': <SealedNote>[],
        };
      }

      List<SealedNote> notHelpful = [];
      final notHelpfulResponse = response['sealed_not_helpful_notes'];

      if (notHelpfulResponse != null) {
        notHelpful = (notHelpfulResponse as List? ?? <SealedNote>[])
            .map((e) => SealedNote.fromMap(e))
            .toList();
      }

      return {
        'notes': uncensoredNotesFromJson(
          notes: response['uncensored_notes'],
          flashNewsId: flashNewsId,
        ),
        'notHelpful': notHelpful.isEmpty ? <SealedNote>[] : notHelpful,
        if (response['sealed_note'] != null)
          'sealed': SealedNote.fromMap(response['sealed_note']),
      };
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, SealedNote>> getSealedNotesByIds({
    required List<String> flashNewsIds,
  }) async {
    try {
      final Map<String, SealedNote> sealedNotes = {};
      final response = await getSpecified(
        '${cacheUrl}flashnews/mb/bundle',
        {
          'flashnews_ids': flashNewsIds,
        },
      );

      if (response == null) {
        return <String, SealedNote>{};
      }

      for (final flashNews in response) {
        if (flashNews['sealed_note'] != null) {
          final sealed = SealedNote.fromMap(flashNews['sealed_note']);
          sealedNotes[sealed.flashNewsId] = sealed;
        }
      }

      return sealedNotes;
    } catch (e) {
      lg.i(e);
      rethrow;
    }
  }

  // ==================================================
  // POINTS SYSTEM METHODS
  // ==================================================

  static Future<Map<String, dynamic>?> loginPointsSystem() async {
    try {
      final currentUserPubkey = currentSigner?.getPublicKey();

      if ((currentSigner?.canSign() ?? false) && currentUserPubkey == null) {
        return null;
      }

      final map = {
        'pubkey': currentUserPubkey,
        'sent_at': DateTime.now().toSecondsSinceEpoch(),
      };

      final encryptedContent = await currentSigner!.encrypt44(
        json.encode(map),
        'db48fbfb9f89b2870bcfd96cb1d283af6da999dde248b9bed6660f3c1e591380',
      );

      final response = await post(
        '${pointsUrl}login',
        {
          'pubkey': currentUserPubkey,
          'password': encryptedContent,
        },
      );

      final actions =
          List<PointAction>.from((response?['actions'] as List? ?? []).map(
        (e) => PointAction.fromMap(e),
      ));

      final Map<String, PointStandard> standards = {};
      (response?['platform_standards'] as Map? ?? {}).forEach(
        (key, value) => standards[key] =
            PointStandard.fromMap(mapEntry: MapEntry(key, value)),
      );

      final xp = response?['xp'];

      if (response?['is_new'] ?? false) {
        return {
          'isNew': true,
          'actions': actions,
          'standards': standards,
          'xp': xp,
        };
      } else if ((response?['message'] as String?)?.isNotEmpty ?? false) {
        return {};
      } else {
        return null;
      }
    } on DioException catch (e) {
      lg.i(e.response);
      return null;
    }
  }

  static Future<bool> sendActionThroughEvent(Event ev) async {
    try {
      String action = '';
      final event = ExtendedEvent.fromEv(ev);
      if (event.kind == EventKind.CATEGORIZED_BOOKMARK) {
        action = PointsActions.BOOKMARK;
      } else if (event.kind == EventKind.TEXT_NOTE) {
        if (event.isFlashNews()) {
          action = PointsActions.FLASHNEWS_POST;
        } else if (event.isUncensoredNote()) {
          action = PointsActions.UN_WRITE;
        } else if (event.isReply()) {
          action = PointsActions.COMMENT_POST;
        }
      } else if (event.isVideo()) {
        action = PointsActions.VIDEO_POST;
      } else if (event.isRelaysList()) {
        action = PointsActions.RELAYS_SETUP;
      } else if (event.isFollowingYakihonne()) {
        action = PointsActions.FOLLOW_YAKI;
      } else if (event.isLongForm()) {
        action = PointsActions.ARTICLE_POST;
      } else if (event.isLongFormDraft()) {
        action = PointsActions.ARTICLE_DRAFT;
      } else if (event.isCuration()) {
        action = PointsActions.CURATION_POST;
      } else if (event.isUnRate()) {
        action = PointsActions.UN_RATE;
      } else if (event.isTopicEvent()) {
        action = PointsActions.TOPICS_SETUP;
      } else if (event.kind == EventKind.REACTION) {
        action = PointsActions.reaction;
      }

      if (action.isNotEmpty) {
        return sendAction(action);
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendAction(String action) async {
    try {
      final resp = await post('${pointsUrl}yaki-chest', {
        'action_key': action,
      });

      if (resp != null) {
        final update = resp['is_updated'];

        if (update != null && update is! bool) {
          // BotToastUtils.showSuccess(
          //   'You are rewarded ${update['points']} points',
          // );
        }

        final userStats = UserGlobalStats.fromMap(resp);
        pointsManagementCubit.setUserStats(userStats);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> logoutPointsSystem() async {
    try {
      await post('${pointsUrl}logout', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<UserGlobalStats?> getUserStats() async {
    try {
      final response = await get('${pointsUrl}yaki-chest/stats');

      if (response != null) {
        return UserGlobalStats.fromMap(response);
      } else {
        return null;
      }
    } catch (e, s) {
      lg.i(s);
      return null;
    }
  }

  static Future<List<dynamic>> getRewardsPrices() async {
    try {
      final response = await getSpecified('${cacheUrl}pricing');

      if (response != null) {
        return response;
      } else {
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> claimReward({
    required String encodedMessage,
    required String pubkey,
  }) async {
    try {
      final response = await post(
        '${cacheUrl}reward-claiming',
        {
          'pubkey': pubkey,
          '_data': encodedMessage,
        },
      );

      return response != null;
    } catch (e) {
      rethrow;
    }
  }

  // ==================================================
  // FIREBASE
  // ==================================================

  static Future<List<String>> getBannedPubkeys() async {
    try {
      final pubkeys = _firestore.collection('banned_pubkeys');

      return await pubkeys.get().then((value) {
        if (value.docs.first.exists) {
          return List<String>.from(value.docs.first.get('pubkeys'));
        } else {
          return <String>[];
        }
      });
    } catch (e) {
      lg.i(e);
      return <String>[];
    }
  }

  // ==================================================
  // RESOURCE MANAGEMENT
  // ==================================================

  /// Dispose of all Dio instances to free resources
  static void dispose() {
    _dio?.close();
    _smDio?.close();
    _dio = null;
    _smDio = null;
  }
}
