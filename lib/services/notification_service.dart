import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final MethodChannel _channel = const MethodChannel('com.identityconnect.business/notifications');
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
          await _storage.write(key: _deviceTokenKey, value: call.arguments as String);
          print('[Flutter] Stored device token: ${call.arguments}');
          break;
        case 'getAuthToken':
          final token = await _storage.read(key: 'auth_token');
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
    // You can implement navigation or other actions based on the payload
  }

  Future<String?> getDeviceToken() async {
    return await _storage.read(key: _deviceTokenKey);
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