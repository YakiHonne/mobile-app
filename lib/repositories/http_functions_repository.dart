import 'dart:async';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:dio/dio.dart' as dioinstance;
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/cashu/models/mint_info.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:path_provider/path_provider.dart';

import '../common/common_regex.dart';
import '../models/app_models/diverse_functions.dart';
import '../models/app_models/extended_model.dart';
import '../models/app_models/pricing_plan_model.dart';
import '../models/article_model.dart';
import '../models/creator_subscription_models.dart';
import '../models/flash_news_model.dart';
import '../models/points_system_models.dart';
import '../models/smart_widgets_components.dart';
import '../models/subscription_models.dart';
import '../models/uncensored_notes_models.dart';
import '../utils/utils.dart';

// ==================================================
// MAIN HTTP REPOSITORY CLASS
// ==================================================

class HttpFunctionsRepository {
  // Private Dio instances
  static Dio? _dio;
  static Dio? _smDio;

  // Shared timeout constants
  static const _kConnectTimeout = Duration(seconds: 10);
  static const _kReceiveTimeout = Duration(seconds: 15);
  static const _kSendTimeout = Duration(seconds: 15);

  // ==================================================
  // DIO FACTORY METHODS (PRESERVED EXACTLY)
  // ==================================================

  static Future<Dio> getDio({
    Map<String, dynamic>? headers,
  }) async {
    if (_dio == null) {
      final appDocPath = (await getApplicationDocumentsDirectory()).path;
      final cookieJar = PersistCookieJar(
        storage: FileStorage('$appDocPath/cookies'),
      );

      _dio = Dio(
        BaseOptions(
          connectTimeout: _kConnectTimeout,
          receiveTimeout: _kReceiveTimeout,
          sendTimeout: _kSendTimeout,
          headers: headers ?? {'yakihonne-api-key': dotenv.env['API_KEY']},
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
      final appDocPath = (await getApplicationDocumentsDirectory()).path;
      final cookieJar = PersistCookieJar(
        storage: FileStorage('$appDocPath/cookies'),
      );

      _smDio = Dio(
        BaseOptions(
          connectTimeout: _kConnectTimeout,
          receiveTimeout: _kReceiveTimeout,
          sendTimeout: _kSendTimeout,
        ),
      );

      _smDio!.options.headers['user-agent'] = 'Yakihonne';
      _smDio!.options.headers['accept-encoding'] = 'gzip';
      _smDio!.interceptors.add(CookieManager(cookieJar));
    }
    return _smDio!;
  }

  // ==================================================
  // BASIC HTTP METHODS (PRESERVED EXACTLY)
  // ==================================================

  static Future<Map<String, dynamic>?> get(
    String link, [
    Map<String, dynamic>? queryParameters,
    Map<String, String>? header,
    Map<String, dynamic>? data,
  ]) async {
    final dio = await getDio();

    if (header != null) {
      dio.options.headers.addAll(header);
    }

    try {
      final Response resp =
          await dio.get(link, queryParameters: queryParameters, data: data);

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
    Map<String, dynamic> data, [
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
        data: data,
      );

      return resp.data;
    } on DioException catch (_) {
      rethrow;
    } catch (e, stack) {
      lg.i(stack);
      return null;
    }
  }

  // ==================================================
  // CONTENT TYPE & URL UTILITIES
  // ==================================================

  static Future<UrlType> getUrlType(String link) async {
    try {
      final dio = await _getHeadDio();

      final Response resp = await dio.head(link);
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        final contentType = (resp.headers.map['content-type'] ??
                    resp.headers.map['Content-Type'])
                ?.first ??
            '';

        if (contentType.toLowerCase().startsWith('image')) {
          return UrlType.image;
        } else if (contentType.toLowerCase().startsWith('video')) {
          return UrlType.video;
        } else if (contentType.toLowerCase().startsWith('audio')) {
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

  static Dio? _headDio;

  static Future<Dio> _getHeadDio() async {
    if (_headDio == null) {
      _headDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          followRedirects: true,
          maxRedirects: 3,
        ),
      );
      _headDio!.options.headers['user-agent'] = 'Yakihonne';
    }
    return _headDio!;
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
    } catch (e) {
      lg.i(e);
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

  static Future<List<MintInfo>> getRecommendedMints() async {
    try {
      final response = await getSpecified(
        '${cacheUrl}mints',
      );

      if (response != null) {
        return List<MintInfo>.from(response.map((e) {
          return MintInfo.fromServerMap(e['data'], e['url']);
        }));
      } else {
        return [];
      }
    } catch (e, stack) {
      lg.i(stack);
      return [];
    }
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

  static Future<List<WalletTransactionModel>> getAlbyTransactions(
      {required String token, int? page}) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.get(
        'https://api.getalby.com/invoices',
        data: {
          'items': 10,
          if (page != null) 'page': page + 1,
        },
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
      final url = '${cacheUrl}users/search/$search';

      final response = await getSpecified(url);

      if (response != null) {
        final List<Metadata> users = [];

        for (final item in response) {
          try {
            final user = Metadata(
              pubkey: item['pubkey'],
              name: item['name'] ?? '',
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

  static Future<Map<String, dynamic>?> loginToAppSystem() async {
    try {
      final currentUserPubkey = currentSigner?.getPublicKey();

      if (currentSigner == null ||
          !currentSigner!.canSign() ||
          currentUserPubkey == null) {
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
        '${apiUrl}login',
        {
          'pubkey': currentUserPubkey,
          'password': encryptedContent,
        },
      );

      if (response == null) {
        return null;
      }

      final actions =
          List<PointAction>.from((response['actions'] as List? ?? []).map(
        (e) => PointAction.fromMap(e),
      ));

      final xp = response['xp'];

      return {
        'isNew': response['is_new'] ?? false,
        'actions': actions,
        'xp': xp,
      };
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
      final resp = await post('${apiUrl}yaki-chest', {
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
      lg.i(e);
      return false;
    }
  }

  static Future<bool> logoutAppSystem() async {
    try {
      await post('${apiUrl}logout', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<UserGlobalStats?> getUserStats() async {
    try {
      final response = await get('${apiUrl}online');

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
  // RESOURCE MANAGEMENT
  // ==================================================
  // RED PACKET METHODS
  // ==================================================

  static Future<Map<String, dynamic>?> checkRedPacket(String preimage) async {
    try {
      final response = await getSpecified(
        '${apiBaseUrl}check-redpacket',
        {'preimage': preimage},
      );
      return response is Map<String, dynamic> ? response : null;
    } catch (e) {
      lg.e('Error checking red packet: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> claimRedPacket({
    required String pubkey,
    required String token,
  }) async {
    try {
      final response = await post(
        '${apiBaseUrl}claim-redpacket',
        {
          'pubkey': pubkey,
          'token': token,
        },
      );
      return response;
    } catch (e) {
      lg.e('Error claiming red packet: $e');
      return null;
    }
  }

  // ==================================================

  /// Dispose of all Dio instances to free resources
  static void dispose() {
    _dio?.close();
    _smDio?.close();
    _dio = null;
    _smDio = null;
  }

  // ==================================================
  // SUBSCRIPTION BACKEND API
  // Reuses the points-system session (getDio + pointsUrl cookie jar).
  // ==================================================

  static Future<UsageData?> subscriptionGetUsage() async {
    final data = await get('${apiUrl}usage');
    if (data == null) {
      return null;
    }
    return UsageData.fromJson(data);
  }

  static Future<Map<String, dynamic>?> subscriptionGetStatus() async {
    try {
      final res = await get('${apiUrl}subscription-status');

      return res;
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  static Future<bool> subscriptionCancel() async {
    try {
      await post('${apiUrl}subscription-cancel', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> subscriptionResume() async {
    try {
      await post('${apiUrl}subscription-resume', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> subscriptionChangePlan({
    required String newPlan,
    required String newPriceId,
  }) async {
    try {
      await post('${apiUrl}subscription-change', {
        'new_plan': newPlan,
        'new_price_id': newPriceId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> subscriptionCancelPendingChange() async {
    try {
      await post('${apiUrl}subscription-change-cancel', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> subscriptionGetLink({
    required String planId,
  }) async {
    try {
      final data = await post(
        '${apiUrl}subscription-link',
        {'plan': planId, 'main': true},
      );

      return data?['url'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> subscriptionGetBillingPortal() async {
    try {
      final data = await post(
        '${apiUrl}billing-portal',
        {'main': true},
      );

      return data?['url'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ==================================================
  // IDENTITY ONBOARDING: username / NIP-05 / wallet
  // Same cookie session as the subscription calls above.
  // ==================================================

  /// One row's availability verdict. [owned] means this account already holds
  /// the name, so there is nothing left to claim.
  static Future<({bool available, bool owned, String? reason})>
      _checkAvailability(String route, String name) async {
    try {
      final data = await get('$apiUrl$route-availability/$name');

      if (data == null) {
        return (available: true, owned: false, reason: null);
      }

      return (
        available: data['available'] == true,
        owned: data['owned'] == true,
        reason: data['reason']?.toString(),
      );
    } catch (_) {
      // Network issues must not block claiming: let the backend decide on POST.
      return (available: true, owned: false, reason: null);
    }
  }

  static Future<({bool available, bool owned, String? reason})>
      checkUsernameAvailability(String name) =>
          _checkAvailability('user/username', name);

  static Future<({bool available, bool owned, String? reason})>
      checkNip05Availability(String name) =>
          _checkAvailability('user/nip05', name);

  static Future<({bool available, bool owned, String? reason})>
      checkWalletAvailability(String name) =>
          _checkAvailability('user/wallet', name);

  /// Claims a name. Returns null on success, otherwise the server's reason.
  /// An `already_set` conflict is success-shaped — the account already owns it,
  /// which is what makes a retry after a partial failure safe.
  static Future<String?> _claim(String path, Map<String, dynamic> body) async {
    try {
      await post('$apiUrl$path', body);
      return null;
    } on DioException catch (ex) {
      final data = ex.response?.data;
      final reason = data is Map ? data['reason']?.toString() : null;
      if (reason == 'already_set') {
        return null;
      }
      lg.i(ex.response);
      return reason ?? 'failed';
    }
  }

  /// Resolves a claimed username to its pubkey — the `/<username>` deeplink.
  /// Null means no such username.
  static Future<String?> getUsernamePubkey(String name) async {
    try {
      final data = await get('${apiUrl}user/username/$name');

      final pubkey = data?['pubkey'] ?? data?['user']?['pubkey'];

      return (pubkey is String && pubkey.isNotEmpty) ? pubkey : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> claimUsername(String name) =>
      _claim('user/username', {'username': name});

  static Future<String?> claimNip05({
    required String name,
    required String pubkey,
  }) =>
      _claim('user/nip05', {'name': name, 'pubkey': pubkey});

  /// Creates a `name@wallet.yakihonne.com` wallet.
  ///
  /// [rejected] separates "the server refused this name" from "the call went
  /// through but the body did not parse". Only the former means the name is
  /// unusable — a 2xx we cannot read must not be reported as a taken name,
  /// since the wallet may well have been created.
  static Future<
      ({
        String? lightningAddress,
        String? nwc,
        String? reason,
        bool rejected
      })> createLightningWallet(String name) async {
    try {
      final data = await post('${apiUrl}wallet', {'username': name});

      if (data != null && data['connectionSecret'] != null) {
        return (
          lightningAddress: data['lightningAddress']?.toString() ??
              '$name@wallet.yakihonne.com',
          nwc: data['connectionSecret'].toString(),
          reason: null,
          rejected: false,
        );
      }

      lg.i('[wallet] unreadable success body for $name: $data');
      return (lightningAddress: null, nwc: null, reason: null, rejected: false);
    } on DioException catch (ex) {
      final data = ex.response?.data;
      lg.i('[wallet] create failed: $data');
      final reason = data is Map ? data['reason']?.toString() : null;
      return (
        lightningAddress: null,
        nwc: null,
        reason: reason,
        rejected: true,
      );
    }
  }

  /// Flags the account as having been through onboarding. Fire-and-forget: a
  /// failure here must not trap the user on the screen.
  static Future<void> markOnboarded() async {
    try {
      await post('${apiUrl}user/onboarded', {});
    } catch (_) {}
  }

  /// [onReceiptOwnedByOtherAccount] fires when the backend rejects the receipt
  /// with 409 because it is already bound to a different pubkey — a distinct
  /// outcome from "no purchase found", which callers surface differently.
  ///
  /// [onAnotherSubscriptionActive] fires on the other 409: this account is
  /// already subscribed through a different store subscription (typically the
  /// companion app), so a second one would be charged but never honoured.
  static Future<Map<String, dynamic>?> subscriptionValidateIap({
    required String platform,
    required String receipt,
    required String productId,
    required String pubkey,
    VoidCallback? onReceiptOwnedByOtherAccount,
    VoidCallback? onAnotherSubscriptionActive,
  }) async {
    try {
      return await post('${apiUrl}iap/validate', {
        'platform': platform,
        'receipt': receipt,
        'product_id': productId,
        'pubkey': pubkey,
      });
    } catch (e) {
      if (e is DioException) {
        lg.i(
            '[IAP] validate failed: status=${e.response?.statusCode} body=${e.response?.data}');
        // Two distinct 409s share this path; `reason` marks the newer one.
        if (e.response?.statusCode == 409) {
          final reason = (e.response?.data as Map<String, dynamic>?)?['reason'];
          if (reason == 'another_iap_subscription_active') {
            onAnotherSubscriptionActive?.call();
          } else {
            onReceiptOwnedByOtherAccount?.call();
          }
        }
      } else {
        lg.i('[IAP] validate failed: $e');
      }
      return null;
    }
  }

  static Future<String?> creatorGetSubscriptionLink({
    required String creatorPubkey,
    required String subscriberPubkey,
    required String priceId,
  }) async {
    try {
      final dio = await getDio();
      final resp = await dio.post(
        '${apiUrl}subscribe',
        data: {
          'creator_pubkey': creatorPubkey,
          'subscriber_pubkey': subscriberPubkey,
          'price_id': priceId,
        },
      );
      if (resp.statusCode == 200 && resp.data is String) {
        return resp.data as String;
      }
      return null;
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
      return null;
    }
  }

  /// Creators the authenticated user pays, plus a flat cross-creator payment
  /// list. Never cache the result — `display_status` is reversible.
  static Future<
      ({
        List<SubscriberSubscription> subscriptions,
        List<SubscriptionPayment> payments,
      })> getSubscriberSubscriptions() async {
    final data = await get('${apiUrl}subscriber/subscriptions');

    return (
      subscriptions: (data?['subscriptions'] as List<dynamic>? ?? [])
          .map((e) => SubscriberSubscription.fromMap(e as Map<String, dynamic>))
          .toList(),
      payments: (data?['payments'] as List<dynamic>? ?? [])
          .map((e) => SubscriptionPayment.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Single-use Stripe portal url; request a fresh one every time. Returns null
  /// when the caller has no Stripe subscription to that creator (404) — gate the
  /// button on `has_stripe` to avoid hitting that.
  static Future<String?> getSubscriberBillingPortal(
    String creatorPubkey,
  ) async {
    try {
      final data = await post(
        '${apiUrl}subscriber/billing-portal',
        {'creator_pubkey': creatorPubkey},
      );
      final url = data?['url'] as String?;
      return (url?.isEmpty ?? true) ? null : url;
    } catch (e) {
      lg.i('[billing-portal] $e');
      return null;
    }
  }

  // -- Points API --

  static Future<PointsConfig?> getPointsConfig() async {
    final data = await get('${apiUrl}points/config');
    if (data == null) {
      return null;
    }
    return PointsConfig.fromJson(data);
  }

  static Future<PointsEligibility?> getSubscriptionEligibility() async {
    final data = await get('${apiUrl}points/subscription-eligibility');
    if (data == null) {
      return null;
    }
    return PointsEligibility.fromJson(data);
  }

  static Future<List<PricingPlan>> getSubscriptionPlans() async {
    final data = await get('${apiUrl}plans');
    final raw =
        (data?['plans'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    if (raw.isEmpty) {
      return [];
    }

    final mostExpensivePlan = raw.reduce(
      (a, b) => (a['usd_price'] as num) >= (b['usd_price'] as num) ? a : b,
    )['plan'] as String;

    return raw.map((p) {
      final plan = p['plan'] as String;
      final perks = (p['perks'] as List<dynamic>? ?? [])
          .map((e) => (text: e as String, dim: false))
          .toList();
      return (
        id: p['id'] as String? ?? '',
        plan: plan,
        priceId: p['price_id'] as String? ?? '',
        productId: p['product_id'] as String? ?? '',
        iapProductId: p['yakiv5_iap_prod_id'] as String? ?? '',
        yakiproIapProductId: p['yakipro_iap_prod_id'] as String? ?? '',
        paymentProvider: p['payment_provider'] as String? ?? '',
        name: p['name'] as String? ?? '',
        price: '\$${(p['usd_price'] as num).toStringAsFixed(2)}',
        satsRaw: (p['sats_price'] as num?)?.toInt() ?? 0,
        sats: formatSatsPrice((p['sats_price'] as num?)?.toInt() ?? 0),
        period: kPricingPeriod,
        desc: '',
        highlighted: plan == mostExpensivePlan,
        features: perks,
      );
    }).toList();
  }

  static Future<bool> redeemSubscriptionWithPoints(String plan) async {
    final data =
        await post('${apiUrl}points/subscription-redeem', {'plan': plan});
    return data?['success'] == true;
  }

  static Future<bool> publishPaidNoteWithPoints(
    String noteId,
  ) async {
    final data = await post('${apiUrl}points/publish-paid-note', {
      'note_id': noteId,
    });
    return data?['success'] == true;
  }

  static Future<List<PointsRedeemCode>> getRedeemCodes() async {
    final data = await get('${apiUrl}points/codes');
    if (data == null) {
      return [];
    }
    final list = data['codes'] as List<dynamic>? ?? [];
    return list
        .map((e) => PointsRedeemCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> requestRedeemCode() async {
    await post('${apiUrl}points/codes/request', {});
  }

  static Future<void> redeemPointsCode({
    required String code,
    required String lightningAddress,
  }) async {
    await post('${apiUrl}points/codes/redeem', {
      'code': code,
      'lightning_address': lightningAddress,
    });
  }

  // ==================================================
  // WORKSHOPS
  // ==================================================

  /// Returns the `/workshops/<id>` payload, or null on failure.
  /// The backend session is a cookie, so `authenticated: false` means the
  /// yaki-chest login never ran (or expired) — log in once and refetch.
  static Future<Map<String, dynamic>?> getWorkshop(String id) async {
    final res = await get('${apiUrl}workshops/$id');

    if (res == null || res['authenticated'] != true) {
      final login = await loginToAppSystem();
      if (login != null) {
        return get('${apiUrl}workshops/$id');
      }
    }

    return res;
  }

  static Future<bool> registerToWorkshop(String id) async {
    try {
      final res = await post('${apiUrl}workshops/$id/register', {});
      return res?['success'] == true;
    } catch (e) {
      lg.i(e);
      return false;
    }
  }

  // -- Lightning / LNURLP helpers --

  static Future<Map<String, dynamic>?> lnurlpFetch(
    String lightningAddress,
  ) async {
    try {
      final parts = lightningAddress.split('@');
      if (parts.length != 2) {
        return null;
      }
      final username = parts[0];
      final domain = parts[1];
      final dio = Dio();
      final resp = await dio.get(
        'https://$domain/.well-known/lnurlp/$username',
      );
      return resp.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> lnurlpInvoice({
    required String callback,
    required int amountSats,
    required String comment,
  }) async {
    try {
      final dio = Dio();
      final resp = await dio.get(
        callback,
        queryParameters: {'amount': amountSats * 1000, 'comment': comment},
      );
      return (resp.data as Map<String, dynamic>?)?['pr'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Stream<Map<String, dynamic>> subscriptionLightningPaymentStream(
    String pubkey,
  ) async* {
    try {
      final dio = await getDio();
      final apiKey = dotenv.env['API_KEY'] ?? '';
      final response = await dio.get<ResponseBody>(
        '${apiUrl}lightning/payment-stream/$pubkey',
        queryParameters: {'api_key': apiKey},
        options: Options(responseType: ResponseType.stream),
      );
      await for (final chunk in response.data!.stream) {
        final text = utf8.decode(chunk);
        for (final line in text.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data:')) {
            final jsonStr = trimmed.substring(5).trim();
            if (jsonStr.isEmpty) {
              continue;
            }
            try {
              final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
              yield parsed;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  // -- Paid notes payment verification --

  /// One-shot status check: GET /paid-notes/status/:note_id
  /// Re-logins once on an expired session and retries.
  static Future<bool> getPaidNoteStatus(String noteId) async {
    var res = await get('${apiUrl}paid-notes/status/$noteId');

    if (res == null) {
      final login = await loginToAppSystem();
      if (login != null) {
        res = await get('${apiUrl}paid-notes/status/$noteId');
      }
    }

    return res?['status'] == 'paid';
  }

  static Future<ResponseBody?> _openPaidNoteStream(
    String noteId,
    CancelToken? cancelToken,
  ) async {
    Future<ResponseBody?> attempt() async {
      try {
        final dio = await getDio();
        final response = await dio.get<ResponseBody>(
          '${apiUrl}paid-notes/payment-stream/$noteId',
          options: Options(
            responseType: ResponseType.stream,
            // Base receiveTimeout (15s) would abort during the silent gap
            // between `waiting` and the terminal event.
            receiveTimeout: const Duration(minutes: 1),
          ),
          cancelToken: cancelToken,
        );
        return response.data;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && cancelToken?.isCancelled != true) {
          final login = await loginToAppSystem();
          if (login == null) {
            return null;
          }
          try {
            final dio = await getDio();
            final response = await dio.get<ResponseBody>(
              '${apiUrl}paid-notes/payment-stream/$noteId',
              options: Options(
                responseType: ResponseType.stream,
                receiveTimeout: const Duration(minutes: 1),
              ),
              cancelToken: cancelToken,
            );
            return response.data;
          } catch (_) {
            return null;
          }
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    return attempt();
  }

  static Future<bool> waitForPaidNotePayment(
    String noteId, {
    CancelToken? cancelToken,
    void Function(String status)? onEvent,
  }) async {
    StreamSubscription? sub;
    Timer? timer;

    try {
      final body = await _openPaidNoteStream(noteId, cancelToken);

      if (body == null || (cancelToken?.isCancelled ?? false)) {
        return false;
      }

      final completer = Completer<bool>();

      void finish(bool paid) {
        if (!completer.isCompleted) {
          completer.complete(paid);
        }
      }

      timer = Timer(const Duration(seconds: 35), () => finish(false));
      lg.i(body);
      sub = body.stream.listen(
        (chunk) {
          final text = utf8.decode(chunk);
          for (final line in text.split('\n')) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('data:')) {
              continue;
            }

            final jsonStr = trimmed.substring(5).trim();
            if (jsonStr.isEmpty || completer.isCompleted) {
              continue;
            }

            try {
              final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
              final status = parsed['status'] as String?;
              lg.i(status);
              if (status == 'paid') {
                onEvent?.call('paid');
                finish(true);
              } else if (status == 'unpaid') {
                onEvent?.call('unpaid');
                finish(false);
              } else if (status == 'waiting') {
                onEvent?.call('waiting');
              }
            } catch (_) {}
          }
        },
        onError: (_) => finish(false),
        onDone: () => finish(false),
        cancelOnError: true,
      );

      return await completer.future;
    } catch (_) {
      return false;
    } finally {
      timer?.cancel();
      await sub?.cancel();
    }
  }

  // -- AI article chat --

  static Future<Map<String, dynamic>?> articleChatAI({
    required String message,
    required String article,
  }) async {
    final data = await post(
      '${apiUrl}chat/articles',
      {'message': message, 'article': article},
    );
    if (data == null || data['success'] == false) {
      return null;
    }
    return data['data'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>?> energyMapper(String note) async {
    final data = await post(
      '${apiUrl}chat/energy-mapper',
      {'note': note},
    );
    if (data == null || data['success'] == false) {
      return null;
    }
    return data['data'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>?> secondReaderAnalyze({
    required String article,
    required String personaId,
  }) async {
    final data = await post(
      '${apiUrl}chat/second-reader/full',
      {'article': article, 'personaId': personaId},
    );
    if (data == null || data['success'] == false) {
      return null;
    }
    return data['data'] as Map<String, dynamic>?;
  }
}
