import 'package:flutter/services.dart';

import '../utils/utils.dart';

class NostrPasswordManager {
  static const MethodChannel _channel = MethodChannel('nostr.credentials');

  /// Saves npub + nsec into iOS Passwords (Shared Web Credentials)
  static Future<void> saveNsecToPasswords({
    required String npub,
    required String nsec,
  }) async {
    try {
      lg.i('message');
      await _channel.invokeMethod('saveCredential', {
        'domain': baseUrl3,
        'username': npub,
        'password': nsec,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to save credential: ${e.message}');
    }
  }

  static Future<String?> requestSavedNsec() async {
    try {
      final result = await _channel.invokeMethod<Map>('requestCredential', {
        'domain': baseUrl3,
      });

      if (result == null) {
        return null;
      }

      return result['password'];
    } catch (e) {
      return null;
    }
  }
}
