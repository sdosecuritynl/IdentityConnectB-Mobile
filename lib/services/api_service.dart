import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class ApiService {
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
        // TODO: Handle token expiration
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

      return response;
    } catch (e) {
      print('[ApiService] Error in /$endpoint request: $e');
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
} 