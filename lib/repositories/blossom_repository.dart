import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../models/blossom_media.dart';
import '../utils/utils.dart';

class BlossomRepository {
  final Dio _dio = Dio();

  Future<List<BlossomMedia>> fetchMediaList({
    required String serverUrl,
    required String pubkey,
    required Event authEvent,
  }) async {
    try {
      final baseUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final listUrl = '${baseUrl}list/$pubkey';

      final authBytes = utf8.encode(authEvent.toJsonString());
      final authBase64 = base64.encode(authBytes);

      final response = await _dio.get(
        listUrl,
        options: Options(
          headers: {
            'Authorization': 'Nostr $authBase64',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => BlossomMedia.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      lg.e('Error fetching Blossom media list from $serverUrl: $e');
      return [];
    }
  }

  Future<bool> deleteMedia({
    required String serverUrl,
    required String hash,
    required Event authEvent,
  }) async {
    try {
      final baseUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final deleteUrl = '$baseUrl$hash';

      final authBytes = utf8.encode(authEvent.toJsonString());
      final authBase64 = base64.encode(authBytes);

      final response = await _dio.delete(
        deleteUrl,
        options: Options(
          headers: {
            'Authorization': 'Nostr $authBase64',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      lg.e('Error deleting Blossom media $hash from $serverUrl: $e');
      return false;
    }
  }

  Future<bool> mirrorMedia({
    required String serverUrl,
    required String sourceUrl,
    required Event authEvent,
  }) async {
    try {
      final baseUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final mirrorUrl = '${baseUrl}mirror';

      final authBytes = utf8.encode(authEvent.toJsonString());
      final authBase64 = base64.encode(authBytes);

      final response = await _dio.put(
        mirrorUrl,
        data: jsonEncode({'url': sourceUrl}),
        options: Options(
          headers: {
            'Authorization': 'Nostr $authBase64',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      lg.e('Error mirroring Blossom media to $serverUrl: ${e.message}');
      return false;
    }
  }

  Future<bool> uploadMedia({
    required String serverUrl,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    required Event authEvent,
    Function(int, int)? onProgress,
  }) async {
    try {
      final baseUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final uploadUrl = '${baseUrl}upload';

      final authBytes = utf8.encode(authEvent.toJsonString());
      final authBase64 = base64.encode(authBytes);

      final response = await _dio.put(
        uploadUrl,
        data: Stream.fromIterable([fileBytes]),
        onSendProgress: onProgress,
        options: Options(
          headers: {
            'Authorization': 'Nostr $authBase64',
            'Content-Type': mimeType,
            'Content-Length': fileBytes.length.toString(),
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      lg.e('Error uploading Blossom media to $serverUrl: $e');
      return false;
    }
  }
}
