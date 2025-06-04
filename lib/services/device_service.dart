import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:crypto/crypto.dart';
import 'storage_service.dart';

class DeviceService {
  final SecureStorageService _storage = SecureStorageService();
  final String baseUrl = 'https://d3oyxmwcqyuai5.cloudfront.net';
  final _uuid = Uuid();

  Map<String, String> _getAuthHeaders(String token) {
    // Ensure token is properly formatted without line breaks
    final cleanToken = token.trim().replaceAll(RegExp(r'\s+'), '');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $cleanToken',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache'
    };
    
    print('[Headers] Token length: ${cleanToken.length}');
    print('[Headers] Token starts with: ${cleanToken.substring(0, math.min(50, cleanToken.length))}');
    print('[Headers] Is JWT format: ${cleanToken.split('.').length == 3}');
    
    return headers;
  }

  Future<String> getOrGenerateUUID() async {
    print('[Device] Attempting to get or generate UUID');
    // Try to get existing UUID
    String? existingUUID = await _storage.getUUID();
    if (existingUUID != null) {
      print('[Device] Using existing UUID from storage: $existingUUID');
      return existingUUID;
    }

    // Generate new UUID only if one doesn't exist
    final newUUID = _uuid.v4();
    print('[Device] No UUID found in storage. Generated new UUID: $newUUID');
    await _storage.saveUUID(newUUID);
    print('[Device] Saved new UUID to storage');
    return newUUID;
  }

  Future<Map<String, dynamic>?> registerDevice(String email, String token, String phoneNumber) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown';
      String deviceId = _uuid.v4(); // Generate a new UUID for deviceId

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model ?? 'Android Device';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} ${iosInfo.model}' ?? 'iOS Device';
      }

      // Get existing UUID or generate a new one if it doesn't exist
      final uuid4 = await getOrGenerateUUID();

      final body = {
        'email': email,  // Add email to the request
        'deviceName': deviceName,
        'deviceId': deviceId,
        'uuid4': uuid4,
      };

      print('[Device] Registering device with body: $body');
      final response = await http.post(
        Uri.parse('$baseUrl/registerDevice'),
        headers: _getAuthHeaders(token),
        body: jsonEncode(body),
      );

      print('[Device] Registration response status: ${response.statusCode}');
      print('[Device] Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['registered'] == false) {
          print('[Device] Registration failed, but keeping UUID for consistency');
        }
        return data;
      } else {
        print('[Device] Registration failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[Device] Error during registration: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> verifyUUID(String uuid, String token) async {
    print('[Device] Verifying UUID with backend: $uuid');
    try {
      // Log the full request details
      final requestBody = jsonEncode({'uuid4': uuid});
      print('[Device] Request body: $requestBody');
      
      final headers = _getAuthHeaders(token);
      print('[Device] Using headers: $headers');

    final response = await http.post(
        Uri.parse('$baseUrl/checkDeviceUUID'),
        headers: headers,
        body: requestBody,
      );

      print('[Device] Response status: ${response.statusCode}');
      print('[Device] Response headers: ${response.headers}');
      print('[Device] Response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        print('[Device] Auth error - Token details:');
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = json.decode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
            );
            print('[Device] Token payload: $payload');
            print('[Device] Token expiration: ${payload['exp']}');
            print('[Device] Current time: ${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
          }
        } catch (e) {
          print('[Device] Error decoding token: $e');
        }
      }

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['verified'] == true) {
        return {
          'status': 'verified',
          'verified': true
        };
      } else if (response.statusCode == 403) {
        if (result['error'] == 'No device registration found for user') {
          return {
            'status': 'not_registered',
            'verified': false,
            'error': result['error']
          };
        } else if (result['error'] == 'UUID4 mismatch') {
          return {
            'status': 'mismatch',
            'verified': false,
            'error': result['error']
          };
    }
      }

      return {
        'status': 'error',
        'verified': false,
        'error': result['error'] ?? 'Unknown error occurred'
      };
    } catch (e) {
      print('Error verifying UUID: $e');
      return {
        'status': 'error',
        'verified': false,
        'error': 'Network or server error occurred'
      };
    }
  }

  Future<bool> sendOTP(String phoneNumber, String token) async {
    try {
      print('Sending OTP for phone: $phoneNumber');
      print('Using token (first 50 chars): ${token.substring(0, math.min(50, token.length))}...');
      
      final headers = _getAuthHeaders(token);
      final body = jsonEncode({'phoneNumber': phoneNumber});
      print('Request body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/sendOtp'),
        headers: headers,
        body: body,
      );

      print('Send OTP response status: ${response.statusCode}');
      print('Send OTP response headers: ${response.headers}');
      print('Send OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }
      print('Send OTP failed: ${response.body}');
      return false;
    } catch (e) {
      print('Error sending OTP: $e');
    return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp, String token) async {
    try {
      print('Verifying OTP for phone: $phoneNumber');
      final response = await http.post(
        Uri.parse('$baseUrl/verifyOtp'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      print('Verify OTP response status: ${response.statusCode}');
      print('Verify OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] == true;
      }
      print('Verify OTP failed: ${response.body}');
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  Future<Map<String, String>> checkDeviceSecurity() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      bool isSimulator = false;

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        isSimulator = !iosInfo.isPhysicalDevice;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        isSimulator = !androidInfo.isPhysicalDevice;
      }

      // In debug mode, allow simulator/emulator
      if (isSimulator) {
        print('[Security] Running on simulator/emulator');
        assert(() {
          print('[Security] Debug mode - bypassing security checks for simulator');
          return true;
        }());
        
        // In release mode, block simulator usage
        if (!const bool.fromEnvironment('dart.vm.product')) {
          return {
            'status': 'blocked',
            'reason': 'This app cannot run on simulators or emulators in production mode.'
          };
        }
      }

      final isJailBroken = await FlutterJailbreakDetection.jailbroken;
      final isDevelopmentMode = await FlutterJailbreakDetection.developerMode;
      
      print('[Security] Device security check results:');
      print('[Security] Jailbroken/Rooted: $isJailBroken');
      print('[Security] Developer Mode: $isDevelopmentMode');

      if (isJailBroken) {
        return {
          'status': 'blocked',
          'reason': 'This device appears to be jailbroken or rooted. For security reasons, the app cannot run on compromised devices.'
        };
      }

      if (isDevelopmentMode && !Platform.isAndroid) {
        return {
          'status': 'blocked',
          'reason': 'Developer mode is enabled on this device. Please disable it to use the app.'
        };
      }

      return {'status': 'secure'};
    } catch (e) {
      print('[Security] Error during security check: $e');
      return {
        'status': 'error',
        'reason': 'Unable to verify device security. Please ensure your device meets security requirements.'
      };
    }
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown';
    String deviceId = _uuid.v4();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model ?? 'Android Device';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = '${iosInfo.name} ${iosInfo.model}' ?? 'iOS Device';
    }

    return {
      'deviceName': deviceName,
      'deviceId': deviceId,
    };
  }
}
