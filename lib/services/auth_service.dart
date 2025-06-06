import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class CustomSamlAuth {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _uuidKey = 'device_id';

  final String clientId = '3kfl9g8p032atbj43rnildrrgr';
  final String cognitoDomain = 'us-east-1id8zqgdw7.auth.us-east-1.amazoncognito.com';
  final String redirectUri = 'myapp://callback/';
  final String signOutRedirectUri = 'myapp://signout/';

  Future<String?> signIn() async {
    final url =
        'https://$cognitoDomain/login?response_type=code&client_id=$clientId&redirect_uri=$redirectUri';

    try {
      print('[Auth] Starting authentication flow with URL: $url');
      
      // Add error handling for the web auth
      try {
        final result = await FlutterWebAuth2.authenticate(
          url: url,
          callbackUrlScheme: 'myapp',
          preferEphemeral: true,
        );

        print('[Auth] Received auth result: $result');

        final code = Uri.parse(result).queryParameters['code'];
        if (code == null) {
          print('[Auth] No authorization code received in callback');
          return null;
        }

        print('[Auth] Exchanging code for token...');
        final tokenEndpoint = Uri.parse('https://$cognitoDomain/oauth2/token');
        print('[Auth] Token endpoint: $tokenEndpoint');

        final tokenResponse = await http.post(
          tokenEndpoint,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'grant_type': 'authorization_code',
            'client_id': clientId,
            'code': code,
            'redirect_uri': redirectUri,
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('[Auth] Token exchange request timed out');
            throw TimeoutException('Token exchange request timed out');
          },
        );

        print('[Auth] Token response status: ${tokenResponse.statusCode}');
        print('[Auth] Token response headers: ${tokenResponse.headers}');
        
        if (tokenResponse.statusCode != 200) {
          print('[Auth] Token exchange failed with status ${tokenResponse.statusCode}');
          print('[Auth] Error response: ${tokenResponse.body}');
          return null;
        }

        final data = json.decode(tokenResponse.body);
        
        // Use id_token for API calls as confirmed working in Postman
        final idToken = data['id_token'];
        if (idToken != null) {
          print('[Auth] Received valid JWT token');
          print('[Auth] Token type: ${idToken.startsWith('eyJ') ? 'JWT' : 'Unknown'}');
          await _storage.write(key: _tokenKey, value: idToken);
          return idToken;
        } else {
          print('[Auth] No ID token found in response. Available keys: ${data.keys.join(', ')}');
          return null;
        }
      } on PlatformException catch (e) {
        print('[Auth] Platform error during web authentication: ${e.message}');
        print('[Auth] Error details: ${e.details}');
        print('[Auth] Error code: ${e.code}');
        return null;
      } catch (e) {
        print('[Auth] Error during web authentication: $e');
        return null;
      }
    } catch (e, stackTrace) {
      print('[Auth] Authentication error: $e');
      print('[Auth] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<String?> getStoredToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      print('Retrieved stored token first 20 chars: ${token.substring(0, 20)}...');
    } else {
      print('No stored token found');
    }
    return token;
  }

  Future<bool> deleteUser() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        print('[DeleteUser] No token found');
        return false;
      }

      print('[DeleteUser] Making request to delete user...');
      final response = await http.delete(
        Uri.parse('https://d3oyxmwcqyuai5.cloudfront.net/deleteUser'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('[DeleteUser] Response status: ${response.statusCode}');
      print('[DeleteUser] Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('[DeleteUser] Error: $e');
      return false;
    }
  }

  // Clear all local data without calling Cognito
  Future<void> clearLocalData() async {
    try {
      print('[ClearLocal] Clearing secure storage...');
      await _storage.delete(key: _tokenKey);
      
      print('[ClearLocal] Clearing shared preferences...');
      final prefs = await SharedPreferences.getInstance();
      // Clear everything except device ID
      final deviceId = await _storage.read(key: _uuidKey);
      await prefs.clear();
      if (deviceId != null) {
        await _storage.write(key: _uuidKey, value: deviceId);
      }
      
      print('[ClearLocal] All local data cleared');
    } catch (e) {
      print('[ClearLocal] Error during cleanup: $e');
      // Even if there's an error, we've tried our best to clear data
    }
  }

  // Regular sign out that calls Cognito
  Future<void> signOut() async {
    try {
      // Clear local data first
      await clearLocalData();
      
      // Then handle Cognito sign-out
      final signOutUrl = 'https://$cognitoDomain/logout?client_id=$clientId&logout_uri=$signOutRedirectUri';
      print('[SignOut] Initiating sign out with URL: $signOutUrl');
      
      // Set a timeout for the web auth
      try {
        await Future.delayed(const Duration(seconds: 1));
        await FlutterWebAuth2.authenticate(
          url: signOutUrl,
          callbackUrlScheme: 'myapp',
          preferEphemeral: true,
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        print('[SignOut] Web auth timed out or failed: $e');
        // This is okay - we've already cleared local data
      }
    } catch (e) {
      print('[SignOut] Error during sign out process: $e');
      // Even if there's an error, we've tried our best to clear data
    }
  }

  // New method for local-only sign out without calling Cognito
  Future<void> signOutLocally(BuildContext context) async {
    try {
      print('[LocalSignOut] Clearing secure storage...');
      await _storage.delete(key: _tokenKey);
      
      print('[LocalSignOut] Clearing shared preferences...');
      final prefs = await SharedPreferences.getInstance();
      // Clear everything except device ID
      final deviceId = await _storage.read(key: _uuidKey);
      await prefs.clear();
      if (deviceId != null) {
        await _storage.write(key: _uuidKey, value: deviceId);
      }
      
      print('[LocalSignOut] All local data cleared');

      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('[LocalSignOut] Error during local sign out process: $e');
    }
  }

  // Handle token expiration
  void handleTokenExpiration(BuildContext context, String error) {
    // Check if error message indicates token expiration
    if (error.toLowerCase().contains('token') && 
        (error.toLowerCase().contains('expired') || 
         error.toLowerCase().contains('invalid'))) {
      print('[Auth] Token expired or invalid, signing out user');
      // Clear local data
      clearLocalData().then((_) {
        // Navigate to login screen
        if (context.mounted) {
          print('[Auth] Redirecting to login screen');
          Navigator.of(context).popUntil((route) => route.isFirst);
          // Show message to user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please sign in again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
  }

  // Check if response indicates token expiration
  bool isTokenExpired(http.Response response) {
    if (response.statusCode == 401) {
      return true;
    }
    
    if (response.statusCode == 400) {
      final body = response.body.toLowerCase();
      return body.contains('token') && 
             (body.contains('expired') || 
              body.contains('invalid token') ||
              body.contains('malformed token'));
    }
    
    return false;
  }
}

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _cognitoUrl = 'https://us-east-1id8zqgdw7.auth.us-east-1.amazoncognito.com';
  final String _clientId = '3kfl9g8p032atbj43rnildrrgr';
  final String _redirectUri = 'myapp://callback/';
  final String _identityProvider = 'sdosecurity.com';
  static const String _uuidKey = 'device_id';
  final String _baseUrl = 'https://d3oyxmwcqyuai5.cloudfront.net';

  Map<String, String> _getAuthHeaders(String token) {
    // Ensure token is properly formatted without line breaks
    final cleanToken = token.trim().replaceAll(RegExp(r'\s+'), '');
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $cleanToken',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache'
    };
  }

  Future<String> getDeviceId() async {
    String? uuid = await _storage.read(key: _uuidKey);
    if (uuid == null) {
      // Generate a proper UUID instead of timestamp
      uuid = const Uuid().v4();
      await _storage.write(key: _uuidKey, value: uuid);
      print('[Auth] Generated new device ID: $uuid');
    } else {
      // If the stored UUID is a timestamp (old format), generate a new UUID
      if (uuid.length <= 13 && int.tryParse(uuid) != null) {
        uuid = const Uuid().v4();
        await _storage.write(key: _uuidKey, value: uuid);
        print('[Auth] Converted old timestamp ID to UUID: $uuid');
      } else {
        print('[Auth] Retrieved existing device ID: $uuid');
      }
    }
    return uuid;
  }

  Future<String> getAuthUrl() async {
    final deviceId = await getDeviceId();
    return '$_cognitoUrl/login?response_type=code&client_id=$_clientId&redirect_uri=$_redirectUri&identity_provider=$_identityProvider&state=$deviceId&prompt=login&max_age=0&autofocus=false';
  }

  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    try {
      final deviceId = await getDeviceId();
      final tokenEndpoint = Uri.parse('$_cognitoUrl/oauth2/token');
      final response = await http.post(
        tokenEndpoint,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'code': code,
          'redirect_uri': _redirectUri,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Token exchange request timed out');
        },
      );

      if (response.statusCode != 200) {
        print('[Auth] Token exchange failed with status ${response.statusCode}');
        print('[Auth] Error response: ${response.body}');
        return {
          'status': 'error',
          'error': 'Token exchange failed: ${response.statusCode}'
        };
      }

      final data = json.decode(response.body);
      final idToken = data['id_token'];
      
      if (idToken != null) {
        return {
          'status': 'success',
          'token': idToken
        };
      } else {
        return {
          'status': 'error',
          'error': 'No ID token found in response'
        };
      }
    } catch (e) {
      print('[Auth] Error exchanging code for token: $e');
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> verifyUUID(String token) async {
    print('[Auth] Verifying UUID with backend');
    try {
      final uuid = await getDeviceId();
      final requestBody = jsonEncode({'uuid4': uuid});
      print('[Auth] Request body: $requestBody');
      
      final headers = _getAuthHeaders(token);
      print('[Auth] Using headers: $headers');

      final response = await http.post(
        Uri.parse('$_baseUrl/checkDeviceUUID'),
        headers: headers,
        body: requestBody,
      );

      print('[Auth] Response status: ${response.statusCode}');
      print('[Auth] Response headers: ${response.headers}');
      print('[Auth] Response body: ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['verified'] == true) {
        return {
          'status': 'verified',
          'verified': true
        };
      }
      
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

      return {
        'status': 'error',
        'verified': false,
        'error': result['error'] ?? 'Unknown error occurred'
      };
    } catch (e) {
      print('[Auth] Error verifying UUID: $e');
      return {
        'status': 'error',
        'verified': false,
        'error': 'Network or server error occurred'
      };
    }
  }

  Future<Map<String, dynamic>?> registerDevice(String email, String token) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown';
      String deviceId = const Uuid().v4(); // Generate a new UUID for deviceId

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model ?? 'Android Device';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} ${iosInfo.model}' ?? 'iOS Device';
      }

      // Get existing UUID or generate a new one if it doesn't exist
      final uuid4 = await getDeviceId();

      final body = {
        'email': email,
        'deviceName': deviceName,
        'deviceId': deviceId,
        'uuid4': uuid4,
      };

      print('[Auth] Registering device with body: $body');
      final response = await http.post(
        Uri.parse('$_baseUrl/registerDevice'),
        headers: _getAuthHeaders(token),
        body: jsonEncode(body),
      );

      print('[Auth] Registration response status: ${response.statusCode}');
      print('[Auth] Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['registered'] == false) {
          print('[Auth] Registration failed, but keeping UUID for consistency');
        }
        return data;
      } else {
        print('[Auth] Registration failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[Auth] Error during registration: $e');
      return null;
    }
  }

  Future<bool> sendOTP(String phoneNumber, String token) async {
    try {
      print('[Auth] Sending OTP for phone: $phoneNumber');
      print('[Auth] Using token (first 50 chars): ${token.substring(0, math.min(50, token.length))}...');
      
      final headers = _getAuthHeaders(token);
      final body = jsonEncode({'phoneNumber': phoneNumber});
      print('[Auth] Request body: $body');

      final response = await http.post(
        Uri.parse('$_baseUrl/sendOtp'),
        headers: headers,
        body: body,
      );

      print('[Auth] Send OTP response status: ${response.statusCode}');
      print('[Auth] Send OTP response headers: ${response.headers}');
      print('[Auth] Send OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }
      print('[Auth] Send OTP failed: ${response.body}');
      return false;
    } catch (e) {
      print('[Auth] Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp, String token) async {
    try {
      print('[Auth] Verifying OTP for phone: $phoneNumber');
      final response = await http.post(
        Uri.parse('$_baseUrl/verifyOtp'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      print('[Auth] Verify OTP response status: ${response.statusCode}');
      print('[Auth] Verify OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] == true;
      }
      print('[Auth] Verify OTP failed: ${response.body}');
      return false;
    } catch (e) {
      print('[Auth] Error verifying OTP: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> registerPushToken(String token, String deviceToken) async {
    try {
      print('[Auth] Registering push notification token');
      
      final body = {
        'deviceToken': deviceToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'tokenType': Platform.isIOS ? 'apns' : 'fcm'
      };

      print('[Auth] Registering push token with body: $body');
      final response = await http.post(
        Uri.parse('$_baseUrl/registerDeviceToken'),
        headers: _getAuthHeaders(token),
        body: jsonEncode(body),
      );

      print('[Auth] Push token registration response status: ${response.statusCode}');
      print('[Auth] Push token registration response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'registered': true,
          'data': data
        };
      }

      return {
        'status': 'error',
        'registered': false,
        'error': 'Failed to register push token'
      };
    } catch (e) {
      print('[Auth] Error registering push token: $e');
      return {
        'status': 'error',
        'registered': false,
        'error': e.toString()
      };
    }
  }
}