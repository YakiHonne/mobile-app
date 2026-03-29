import UIKit
import Flutter
import UserNotifications
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var channel: FlutterMethodChannel?
    private var pendingNotification: [AnyHashable: Any]? = nil

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("Root view controller must be FlutterViewController")
        }

        // -------------------------------
        // Push Notification Channel
        // -------------------------------
        self.channel = FlutterMethodChannel(
            name: "apn_notifications",
            binaryMessenger: controller.binaryMessenger
        )

        channel?.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "requestNotificationPermission":
                self?.registerForPushNotifications()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // -------------------------------
        // Nostr Credential Channel
        // -------------------------------
        let credentialChannel = FlutterMethodChannel(
            name: "nostr.credentials",
            binaryMessenger: controller.binaryMessenger
        )

        credentialChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "requestCredential":
                guard
                    let args = call.arguments as? [String: String],
                    let domain = args["domain"]
                else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                        message: "Missing domain",
                                        details: nil))
                    return
                }

                self?.requestCredential(domain: domain) { username, password in
                    DispatchQueue.main.async {
                        if let username = username, let password = password {
                            result([
                                "username": username,
                                "password": password
                            ])
                        } else {
                            result(nil)
                        }
                    }
                }
            case "saveCredential":
                guard
                    let args = call.arguments as? [String: String],
                    let domain = args["domain"],
                    let username = args["username"],
                    let password = args["password"]
                else {
                    result(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Missing domain/username/password",
                        details: nil
                    ))
                    return
                }

                self?.saveCredential(domain: domain,
                                     account: username,
                                     password: password)

                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        registerForPushNotifications()

        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.channel?.invokeMethod("onNotificationTapped", arguments: remoteNotification)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ---------------------------------
    // Shared Web Credential Save
    // ---------------------------------
    private func saveCredential(domain: String, account: String, password: String) {
        SecAddSharedWebCredential(domain as CFString,
                                  account as CFString,
                                  password as CFString) { error in
            if let error = error {
                print("Error saving credential: \(error)")
            } else {
                print("Credential saved successfully")
            }
        }
    }

    private func requestCredential(domain: String,
                                completion: @escaping (String?, String?) -> Void) {
        SecRequestSharedWebCredential(domain as CFString, nil) { credentials, error in
            print("DEBUG: SecRequestSharedWebCredential callback")
            if let error = error {
                print("DEBUG: Error = \(error)")
                completion(nil, nil)
                return
            }

            print("DEBUG: credentials = \(String(describing: credentials))")

            guard
                let credentials = credentials as? [[String: Any]],
                let first = credentials.first,
                let account = first[kSecAttrAccount as String] as? String,
                let password = first[kSecSharedPassword as String] as? String
            else {
                print("DEBUG: No credentials found or password is nil")
                completion(nil, nil)
                return
            }

            print("DEBUG: Found credential \(account) / \(password)")
            completion(account, password)
        }
    }

    // ---------------------------------
    // Push Notification Setup
    // ---------------------------------
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

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
        print("Received APN token: \(token)")
        channel?.invokeMethod("onAPNToken", arguments: token)
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        channel?.invokeMethod("onAPNTokenError", arguments: error.localizedDescription)
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        channel?.invokeMethod("onNotificationReceived", arguments: userInfo)

        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        channel?.invokeMethod("onNotificationTapped", arguments: userInfo)
        completionHandler()
    }
}