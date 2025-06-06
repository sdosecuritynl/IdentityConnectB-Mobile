import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let backendURL = "https://d3oyxmwcqyuai5.cloudfront.net" // Your AWS API Gateway URL
  private var flutterMethodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("[Push Setup] Initializing push notification setup...")
    
    // Set up Flutter method channel for communication
    let controller = window?.rootViewController as! FlutterViewController
    flutterMethodChannel = FlutterMethodChannel(
      name: "com.identityconnect.business/notifications",
      binaryMessenger: controller.binaryMessenger)
    
    // Set up method channel handler
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
    
    print("[Push Setup] Flutter method channel initialized")
    
    // Request permission for push notifications
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge],
      completionHandler: { granted, error in
        print("[Push Setup] Notification permission request result - Granted: \(granted)")
        if let error = error {
          print("[Push Setup] ❌ Error requesting permissions: \(error.localizedDescription)")
          return
        }
        
        // Register for remote notifications on the main thread
        DispatchQueue.main.async {
          print("[Push Setup] Registering for remote notifications...")
          UIApplication.shared.registerForRemoteNotifications()
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle successful registration with APNs
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("[Push Setup] ✅ Successfully received APNs device token")
    print("[Push Setup] Token: \(token)")
    
    // Send token to Flutter to store in secure storage
    flutterMethodChannel?.invokeMethod("storeDeviceToken", arguments: token)
    print("[Push Setup] Token sent to Flutter for storage")
    print("[Push Setup] NOTE: Token will be registered with backend after user authentication")
  }

  // Handle registration errors
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[Push Setup] ❌ Failed to register for remote notifications")
    print("[Push Setup] Error: \(error.localizedDescription)")
  }

  // Handle receiving remote notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("[Push Received] 📱 Received notification while app in foreground")
    print("[Push Received] Payload: \(userInfo)")
    
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound]])
    } else {
      completionHandler([[.alert, .sound]])
    }
  }

  // Handle user tapping on notification
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("[Push Tapped] 👆 User tapped notification")
    print("[Push Tapped] Payload: \(userInfo)")
    
    // Pass notification data to Flutter
    if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
       let jsonString = String(data: jsonData, encoding: .utf8) {
      print("[Push Tapped] Forwarding payload to Flutter")
      flutterMethodChannel?.invokeMethod("handleNotificationTap", arguments: jsonString)
    }
    
    completionHandler()
  }
  
  // Send token to backend
  private func sendTokenToBackend(token: String) {
    print("[Backend Registration] Starting device token registration process")
    
    guard let url = URL(string: "\(backendURL)/registerDeviceToken") else {
      print("[Backend Registration] ❌ Invalid backend URL")
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    print("[Backend Registration] Getting auth token from Flutter...")
    // Get the stored auth token from Flutter
    flutterMethodChannel?.invokeMethod("getAuthToken", arguments: nil, result: { result in
      guard let authToken = result as? String else {
        print("[Backend Registration] ❌ No auth token available")
        return
      }
      
      print("[Backend Registration] Auth token retrieved successfully")
      request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
      
      let body: [String: Any] = [
        "deviceToken": token,
        "platform": "ios",
        "tokenType": "apns"
      ]
      
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        print("[Backend Registration] Request body prepared:")
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          print(jsonString)
        }
      } catch {
        print("[Backend Registration] ❌ Error encoding token data: \(error)")
        return
      }
      
      print("[Backend Registration] Sending request to backend...")
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          print("[Backend Registration] ❌ Network error: \(error)")
          return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
          print("[Backend Registration] Response status code: \(httpResponse.statusCode)")
          
          if httpResponse.statusCode == 200 {
            print("[Backend Registration] ✅ Device token successfully registered")
          } else {
            print("[Backend Registration] ❌ Registration failed")
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
              print("[Backend Registration] Error response: \(responseString)")
            }
          }
        }
      }
      task.resume()
    })
  }
}
