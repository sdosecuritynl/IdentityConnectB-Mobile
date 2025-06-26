import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final MethodChannel _channel = const MethodChannel('com.identityconnect.business/notifications');
  final SecureStorageService _storage = SecureStorageService();
  static const String _deviceTokenKey = 'device_token';
  static const String _baseUrl = 'https://d3oyxmwcqyuai5.cloudfront.net';

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initializeMethodChannel();
  }

  void _initializeMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'storeDeviceToken':
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_deviceTokenKey, call.arguments as String);
          print('[Flutter] Stored device token in SharedPreferences: ${call.arguments}');
          break;
        case 'getAuthToken':
          final token = await _storage.getToken();
          print('[Flutter] Providing auth token for device registration');
          return token;
        case 'handleNotificationTap':
          final payload = jsonDecode(call.arguments as String);
          _handleNotificationTap(payload);
          break;
      }
      return null;
    });
  }

  void _handleNotificationTap(Map<String, dynamic> payload) {
    print('[Flutter] Notification tapped with payload: $payload');
    
    if (payload.containsKey('sessionID')) {
      final sessionId = payload['sessionID'] as String;
      print('[Flutter] Navigating to approval request screen with session ID: $sessionId');
      
      // Use the global navigator key to navigate
      navigatorKey.currentState?.pushNamed(
        '/approval_request',
        arguments: {'sessionId': sessionId},
      );
    } else {
      print('[Flutter] No session ID found in notification payload');
    }
  }

  Future<String?> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  // Get platform-specific information
  String _getPlatform() {
    if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    }
    return 'unknown';
  }

  String _getTokenType() {
    if (Platform.isIOS) {
      return 'apns';
    } else if (Platform.isAndroid) {
      return 'fcm';
    }
    return 'unknown';
  }

  // Get ID token for authentication
  Future<String?> _getIdToken() async {
    try {
      return await _storage.getIdToken();
    } catch (e) {
      print('[Notification] Error getting ID token: $e');
      return null;
    }
  }

  // Call this method after successful authentication
  Future<bool> registerStoredToken() async {
    print('[Notification] Attempting to register stored device token');
    
    try {
      // Get device token
      final deviceToken = await getDeviceToken();
      if (deviceToken == null) {
        print('[Notification] ❌ No stored device token found');
        return false;
      }

      // Get ID token for authentication
      final idToken = await _getIdToken();
      if (idToken == null) {
        print('[Notification] ❌ No ID token available for authentication');
        return false;
      }

      // Prepare request body
      final requestBody = {
        "deviceToken": deviceToken,
        "platform": _getPlatform(),
        "tokenType": _getTokenType(),
      };

      print('[Notification] Registering token with body: ${jsonEncode(requestBody)}');
      print('[Notification] Using bearer token (first 20 chars): ${idToken.substring(0, 20)}...');

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/registerPushNotificationToken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(requestBody),
      );

      print('[Notification] Registration response status: ${response.statusCode}');
      print('[Notification] Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        print('[Notification] ✅ Push notification token registered successfully');
        return true;
      } else {
        print('[Notification] ❌ Failed to register token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[Notification] ❌ Error registering token: $e');
      return false;
    }
  }
} 