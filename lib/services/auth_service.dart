import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'storage_service.dart';

class AuthService {
  final _storage = SecureStorageService();
  final String _baseUrl = 'https://d3oyxmwcqyuai5.cloudfront.net';

  Future<void> clearLocalData() async {
    try {
      print('[ClearLocal] Clearing secure storage...');
      await _storage.clearToken();
      
      print('[ClearLocal] Clearing shared preferences...');
      final prefs = await SharedPreferences.getInstance();
      // Clear everything except device ID
      final deviceId = await _storage.getUUID();
      await prefs.clear();
      if (deviceId != null) {
        await _storage.saveUUID(deviceId);
      }
      
      print('[ClearLocal] All local data cleared');
    } catch (e) {
      print('[ClearLocal] Error during cleanup: $e');
    }
  }

  Future<void> signOutLocally(BuildContext context) async {
    try {
      await clearLocalData();
      
      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('[LocalSignOut] Error during local sign out process: $e');
    }
  }

  Future<bool> sendOTP(String phoneNumber) async {
    try {
      print('[Auth] Sending OTP for phone: $phoneNumber');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/sendOtp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      print('[Auth] Send OTP response status: ${response.statusCode}');
      print('[Auth] Send OTP response body: ${response.body}');

      return true; //DEBUG
      return response.statusCode == 200;
    } catch (e) {
      print('[Auth] Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    try {
      print('[Auth] Verifying OTP for phone: $phoneNumber');
      final response = await http.post(
        Uri.parse('$_baseUrl/verifyOtp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      print('[Auth] Verify OTP response status: ${response.statusCode}');
      print('[Auth] Verify OTP response body: ${response.body}');

      return true; //DEBUG

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] == true;
      }
      return false;
    } catch (e) {
      print('[Auth] Error verifying OTP: $e');
      return false;
    }
  }
}