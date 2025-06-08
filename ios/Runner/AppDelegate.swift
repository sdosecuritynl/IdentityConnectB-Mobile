import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let backendURL = "https://d3oyxmwcqyuai5.cloudfront.net"
  private var flutterMethodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("[Push Setup] Initializing push notification setup...")

    let controller = window?.rootViewController as! FlutterViewController
    flutterMethodChannel = FlutterMethodChannel(
      name: "com.identityconnect.business/notifications",
      binaryMessenger: controller.binaryMessenger)

    flutterMethodChannel?.setMethodCallHandler({ [weak self] (call, result) in
      switch call.method {
      case "registerStoredToken":
        print("[Flutter Call] Received request to register stored token with backend")
        if let token = call.arguments as? String {
          self?.sendTokenToBackend(token: token)
          result(true)
        } else {
          print("[Flutter Call] ❌ No token provided in registerStoredToken call")
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge],
      completionHandler: { granted, error in
        print("[Push Setup] Notification permission granted: \(granted)")
        if let error = error {
          print("[Push Setup] ❌ Permission error: \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
    let token = tokenParts.joined()
    print("[Push Setup] ✅ APNs token: \(token)")
    flutterMethodChannel?.invokeMethod("storeDeviceToken", arguments: token)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[Push Setup] ❌ Failed to register for remote notifications: \(error.localizedDescription)")
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("[Push Received] 📱 Foreground notification: \(userInfo)")

    if let aps = userInfo["aps"] as? [String: Any],
       let alert = aps["alert"] as? [String: Any],
       let title = alert["title"] as? String,
       let body = alert["body"] as? String {
      print("[Push Received] Title: \(title)")
      print("[Push Received] Body: \(body)")
    }

    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("[Push Tapped] 👆 Notification tapped")
    print("[Push Tapped] Full userInfo: \(userInfo)")

    var payload: [String: Any] = [:]

    if let aps = userInfo["aps"] as? [String: Any],
       let alert = aps["alert"] as? [String: Any],
       let title = alert["title"] as? String,
       let body = alert["body"] as? String {
      payload["notification"] = [
        "title": title,
        "body": body
      ]
    }

    // Try sessionID from top-level
    if let sessionID = userInfo["sessionID"] as? String {
      payload["sessionID"] = sessionID
    } else if let apnsString = userInfo["APNS"] as? String,
              let apnsData = apnsString.data(using: .utf8),
              let apnsJson = try? JSONSerialization.jsonObject(with: apnsData) as? [String: Any],
              let sessionID = apnsJson["sessionID"] as? String {
      payload["sessionID"] = sessionID
    }

    if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
       let jsonString = String(data: jsonData, encoding: .utf8) {
      print("[Push Tapped] Forwarding to Flutter: \(jsonString)")
      flutterMethodChannel?.invokeMethod("handleNotificationTap", arguments: jsonString)
    }

    completionHandler()
  }

  private func sendTokenToBackend(token: String) {
    print("[Backend Registration] Registering device token to backend...")

    guard let url = URL(string: "\(backendURL)/registerDeviceToken") else {
      print("[Backend Registration] ❌ Invalid backend URL")
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    flutterMethodChannel?.invokeMethod("getAuthToken", arguments: nil, result: { result in
      guard let authToken = result as? String else {
        print("[Backend Registration] ❌ Missing auth token")
        return
      }

      request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
      let body: [String: Any] = [
        "deviceToken": token,
        "platform": "ios",
        "tokenType": "apns"
      ]

      do {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
      } catch {
        print("[Backend Registration] ❌ JSON encoding failed: \(error)")
        return
      }

      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          print("[Backend Registration] ❌ Network error: \(error)")
          return
        }

        if let httpResponse = response as? HTTPURLResponse {
          print("[Backend Registration] Response code: \(httpResponse.statusCode)")
          if httpResponse.statusCode == 200 {
            print("[Backend Registration] ✅ Token registered")
          } else {
            print("[Backend Registration] ❌ Backend error")
            if let data = data, let resp = String(data: data, encoding: .utf8) {
              print("[Backend Registration] Response: \(resp)")
            }
          }
        }
      }

      task.resume()
    })
  }
}
