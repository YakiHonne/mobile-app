import UIKit
import Flutter
import FirebaseCore
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var channel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()

        // Register Flutter plugins (includes shared_preferences)
        GeneratedPluginRegistrant.register(with: self)

        // Ensure the root view controller is FlutterViewController
        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("Root view controller must be FlutterViewController")
        }

        // Initialize the method channel for push notifications
        self.channel = FlutterMethodChannel(name: "apn_notifications", binaryMessenger: controller.binaryMessenger)
        
        channel?.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "requestNotificationPermission":
                self?.registerForPushNotifications()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        // Register for push notifications
        // registerForPushNotifications()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // Handle successful APN token registration
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
        print("Received APN token: \(token)")
        channel?.invokeMethod("onAPNToken", arguments: token)
    }

    // Handle APN token registration failure
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        channel?.invokeMethod("onAPNTokenError", arguments: error.localizedDescription)
    }

    // Handle incoming notifications (foreground)
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        channel?.invokeMethod("onNotificationReceived", arguments: userInfo)
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // Handle notification tap
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        channel?.invokeMethod("onNotificationTapped", arguments: userInfo)
        completionHandler()
    }
}