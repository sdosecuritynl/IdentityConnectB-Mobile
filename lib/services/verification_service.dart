import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/verification_request.dart';

class VerificationService {
  static final VerificationService _instance = VerificationService._internal();
  final String _baseUrl = 'https://d3oyxmwcqyuai5.cloudfront.net';
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  factory VerificationService() {
    return _instance;
  }

  VerificationService._internal();

  Future<String?> _getAuthToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<VerificationRequest> getRequestData(String sessionId) async {
    try {
      print('[Verification] Fetching request data for session: $sessionId');
      
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/requestData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'sessionId': sessionId,
        }),
      );

      print('[Verification] Request data response status: ${response.statusCode}');
      print('[Verification] Request data response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VerificationRequest.fromJson(data);
      }

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      }

      throw Exception('Failed to fetch request data: ${response.statusCode}');
    } catch (e) {
      print('[Verification] Error fetching request data: $e');
      throw Exception('Failed to fetch request data: $e');
    }
  }

  Future<bool> submitResponse(String sessionId, bool approved) async {
    try {
      print('[Verification] Submitting response for session: $sessionId (approved: $approved)');
      
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/submitResponse'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'sessionId': sessionId,
          'decision': approved ? 'approved' : 'rejected',
        }),
      );

      print('[Verification] Submit response status: ${response.statusCode}');
      print('[Verification] Submit response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      }

      throw Exception('Failed to submit response: ${response.statusCode}');
    } catch (e) {
      print('[Verification] Error submitting response: $e');
      throw Exception('Failed to submit response: $e');
    }
  }
} 