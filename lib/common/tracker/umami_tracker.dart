import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../globals.dart';
import '../../utils/constants.dart';

class UmamiAnalytics {
  UmamiAnalytics() : _dio = Dio() {
    _dio.options
      ..baseUrl = trackingUrl
      ..headers = {'Content-Type': 'application/json'}
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 10);
  }

  final String trackingUrl = 'https://umami.yakihonne.com/api/send';
  final String websiteId = 'd6d9c70c-ecf9-4589-aef6-896b65cd08b3';
  final String hostname = 'com.yakihonne.app';
  final Dio _dio;
  late String agent;

  Future<void> getUserAgent() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    const appName = 'YakiHonne';

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      agent =
          'Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model}) $appName/$appVersion';
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      agent =
          "Mozilla/5.0 (iPhone; CPU iPhone OS ${iosInfo.systemVersion.replaceAll('.', '_')} like Mac OS X) $appName/$appVersion";
    }

    agent = '$appName/$appVersion (Unknown Device)';
  }

  Future<void> trackEvent({
    String? screenName,
  }) async {
    if (!nostrRepository.isCrashlyticsEnabled) {
      return;
    }

    try {
      final screenSize =
          '${MediaQuery.of(gc).size.width.round()}x${MediaQuery.of(gc).size.height.round()}';

      final payload = {
        'type': 'event',
        'payload': {
          'website': websiteId,
          'hostname': hostname,
          'event_type': 'Visiting',
          'event_value': 'View visited',
          'url': screenName != null ? '/$screenName' : '',
          'screen': screenSize,
          'userAgent': agent,
        },
      };

      final response = await _dio.post(
        '',
        data: payload,
      );

      if (response.statusCode != 200) {
        lg.i('Failed to track event: ${response.statusCode}');
      }
    } on DioException catch (_) {
      // lg.i('Error tracking event: ${e.message}');
    }
  }
}
