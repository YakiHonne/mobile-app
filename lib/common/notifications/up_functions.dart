// ignore_for_file: constant_identifier_names

import 'package:unifiedpush/unifiedpush.dart';

const DISTRIBUTOR = 'com.yakihonne.yakihonne';

class UPFunctions {
  static Future<void> initRegisterApp([
    List<String>? features,
  ]) async {
    await saveDistributor(DISTRIBUTOR);
    await registerApp();
  }

  static Future<void> registerApp() async {
    await UnifiedPush.registerApp('yakihonne-instance');
  }

  static Future<void> unregister() async {
    return UnifiedPush.unregister();
  }

  static Future<List<String>> getDistributors(List<String>? features) async {
    return UnifiedPush.getDistributors(features);
  }

  static Future<String?> getDistributor() async {
    return UnifiedPush.getDistributor();
  }

  static Future<void> saveDistributor(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
  }

  static void onRegistrationFailed(String instance) {}

  static void onUnregistered(String instance) {}
}
