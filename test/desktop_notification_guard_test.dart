import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/common/notifications/local_notification_manager.dart';
import 'package:yakihonne/utils/platform_utils.dart';

void main() {
  testWidgets('desktop notification manager avoids unsupported plugin methods',
      (tester) async {
    expect(isDesktopPlatform, isTrue);
    await LocalNotificationManager.instance.initNotifications();
    await LocalNotificationManager.instance.showLocalNotification(
      1,
      'Disposable title',
      'Disposable message',
    );
    expect(notificationChannel, isNull);
    expect(tester.takeException(), isNull);
  });
}
