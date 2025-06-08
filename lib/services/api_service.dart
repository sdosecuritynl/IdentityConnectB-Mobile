import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class ApiService {
  final CustomSamlAuth _authService = CustomSamlAuth();
  final SecureStorageService _storage = SecureStorageService();
  static const String baseUrl = 'https://d3oyxmwcqyuai5.cloudfront.net';

  // Generate a random challenge nonce
  String _generateNonce() {
    final random = math.Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Generic method to make authenticated API calls
  Future<http.Response> authenticatedRequest(
    BuildContext context,
    String endpoint,
    {
      String method = 'GET',
      Map<String, dynamic>? body,
    }
  ) async {
    final token = await _storage.getToken();
    if (token == null) {
      if (context.mounted) {
        _authService.handleTokenExpiration(context, 'No token found');
      }
      throw Exception('Authentication token not found');
    }

    // Ensure token is properly formatted without line breaks
    final cleanToken = token.trim().replaceAll(RegExp(r'\s+'), '');
    
    final headers = {
      'Authorization': 'Bearer $cleanToken',
      'Content-Type': 'application/json',
    };

    print('[ApiService] Making $method request to /$endpoint');
    print('[ApiService] Headers length: ${headers.toString().length}');
    print('[ApiService] Authorization header starts with: ${headers['Authorization']?.substring(0, math.min(50, headers['Authorization']?.length ?? 0))}...');
    if (body != null) {
      print('[ApiService] Request body: $body');
    }

    late http.Response response;
    try {
      final uri = Uri.parse('$baseUrl/$endpoint');

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('[ApiService] /$endpoint response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('[ApiService] /$endpoint error response: ${response.body}');
      }

      // Check for token expiration
      if (context.mounted && _authService.isTokenExpired(response)) {
        print('[ApiService] Token expired for /$endpoint');
        _authService.handleTokenExpiration(context, response.body);
        throw Exception('Token expired');
      }

      return response;
    } catch (e) {
      print('[ApiService] Error in /$endpoint request: $e');
      if (context.mounted) {
        // Check if error might be token related
        _authService.handleTokenExpiration(context, e.toString());
      }
      rethrow;
    }
  }

  // Specific API methods
  Future<bool> deleteUser(BuildContext context) async {
    try {
      final response = await authenticatedRequest(
        context,
        'deleteUser',
        method: 'DELETE',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] Error deleting user: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(BuildContext context) async {
    try {
      final response = await authenticatedRequest(context, 'getUserInfo');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('[ApiService] Error getting user info: $e');
      return null;
    }
  }

  Future<String?> getDeviceUUID(BuildContext context) async {
    try {
      final response = await authenticatedRequest(
        context, 
        'checkDeviceUUID',
        method: 'POST',
        body: {
          'uuid4': await _storage.getUUID() ?? '',
        },
      );
      
      final data = jsonDecode(response.body);
      
      // Both 200 and 403 are expected responses
      if (response.statusCode == 200) {
        print('[ApiService] Device UUID verified successfully');
        return data['uuid'];
      } else if (response.statusCode == 403 && data['error'] == 'UUID4 mismatch') {
        print('[ApiService] Device UUID mismatch - this is expected for new or changed devices');
        return null;
      }
      
      print('[ApiService] Unexpected response from checkDeviceUUID: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[ApiService] Error checking device UUID: $e');
      return null;
    }
  }

  Future<bool> submitP2PRequest(BuildContext context, String toEmail) async {
    try {
      final response = await authenticatedRequest(
        context,
        'submitRequest',
        method: 'POST',
        body: {
          'to': toEmail,
          'challengeNonce': _generateNonce(),
        },
      );
      print('[ApiService] P2P request response status: ${response.statusCode}');
      print('[ApiService] P2P request response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('[ApiService] P2P request successful');
        return true;
      }
      print('[ApiService] P2P request failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('[ApiService] Error submitting P2P request: $e');
      return false;
    }
  }

  Future<void> verifyIdentity(BuildContext context, String email) async {
    try {
      final response = await authenticatedRequest(
        context,
        'submitRequest',
        method: 'POST',
        body: {
          'to': email,
          'challengeNonce': _generateNonce(),
        },
      );

      print('[ApiService] Verify identity response status: ${response.statusCode}');
      print('[ApiService] Verify identity response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = response.body;
        print('[ApiService] Verify identity failed with status ${response.statusCode} and body: $errorBody');
        throw Exception('Failed to send verification request: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('[ApiService] Error sending verification request: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error while sending verification request: $e');
    }
  }
} 