import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final MethodChannel _channel = const MethodChannel('com.identityconnect.business/notifications');
  final SecureStorageService _storage = SecureStorageService();
  static const String _deviceTokenKey = 'device_token';

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

  // Call this method after successful authentication
  Future<void> registerStoredToken() async {
    print('[Flutter] Attempting to register stored device token');
    final token = await getDeviceToken();
    if (token != null) {
      print('[Flutter] Found stored token, sending to native layer for registration');
      try {
        final result = await _channel.invokeMethod('registerStoredToken', token);
        print('[Flutter] Token registration initiated: $result');
      } catch (e) {
        print('[Flutter] ❌ Error registering token: $e');
      }
    } else {
      print('[Flutter] ❌ No stored device token found');
    }
  }
} 