import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomSamlAuth {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _uuidKey = 'device_id';

  final String clientId = '3kfl9g8p032atbj43rnildrrgr';
  final String cognitoDomain = 'us-east-1id8zqgdw7.auth.us-east-1.amazoncognito.com';
  final String redirectUri = 'myapp://callback/';
  final String signOutRedirectUri = 'myapp://signout/';
  final String provider = 'sdosecurity.com';

  Future<String?> signIn() async {
    final url =
        'https://$cognitoDomain/login?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&identity_provider=$provider';

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
      await _storage.deleteAll();
      
      print('[ClearLocal] Clearing shared preferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
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
      await _storage.deleteAll();
      
      print('[LocalSignOut] Clearing shared preferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
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

  Future<String> getAuthUrl() async {
    return '$_cognitoUrl/login?response_type=code&client_id=$_clientId&redirect_uri=$_redirectUri&identity_provider=$_identityProvider';
  }

  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    try {
      // TODO: Implement actual token exchange with Cognito
      // For now, return success with the token from Cognito's response
      return {
        'status': 'success',
        'token': code // The code from Cognito is actually the token in this setup
      };
    } catch (e) {
      print('[Auth] Error exchanging code for token: $e');
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }
}