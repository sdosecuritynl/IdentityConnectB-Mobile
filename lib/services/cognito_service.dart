import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class CognitoService {
  static final CognitoService _instance = CognitoService._internal();
  final SecureStorageService _storage = SecureStorageService();
  
  factory CognitoService() => _instance;
  CognitoService._internal();

  // Cognito configuration
  static const String authority = 'https://cognito-idp.us-east-1.amazonaws.com/us-east-1_yNsZDdSUn';
  static const String redirectUri = 'identityconnect://callback';
  static const String scope = 'email openid phone';
  
  // Default client (for email login)
  static const String defaultClientId = '1n3jip62lajg0ep8eji6e4udno';
  static const String defaultClientSecret = '1pbsk43e4iq5d05h7p4tnkgc14b2i5be4vhqmobgtcf9i4s6mhn8';
  
  // Google client
  static const String googleClientId = '47jjine5sl9sb2t2tlj42m194t';
  static const String googleClientSecret = '1kdehemc63fpi8dahifjhtkrfr7jc4mdepfp8806ad20ih5v7pvc';
  
  // Current client configuration
  String _currentClientId = defaultClientId;
  String _currentClientSecret = defaultClientSecret;

  // Cache for server metadata
  Map<String, dynamic>? _serverMetadata;

  // Set client configuration for email login
  void useEmailClient() {
    _currentClientId = defaultClientId;
    _currentClientSecret = defaultClientSecret;
    print('[Cognito] Switched to email client: $_currentClientId');
  }

  // Set client configuration for Google login
  void useGoogleClient() {
    _currentClientId = googleClientId;
    _currentClientSecret = googleClientSecret;
    print('[Cognito] Switched to Google client: $_currentClientId');
  }

  // Fetch server metadata from well-known configuration
  Future<Map<String, dynamic>> _getServerMetadata() async {
    if (_serverMetadata != null) return _serverMetadata!;

    try {
      final response = await http.get(
        Uri.parse('$authority/.well-known/openid-configuration'),
      );

      if (response.statusCode == 200) {
        _serverMetadata = jsonDecode(response.body);
        print('[Cognito] Server metadata loaded');
        return _serverMetadata!;
      } else {
        throw Exception('Failed to load server metadata: ${response.statusCode}');
      }
    } catch (e) {
      print('[Cognito] Error loading server metadata: $e');
      rethrow;
    }
  }

  // Generate code verifier for PKCE
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (i) => chars[random.nextInt(chars.length)]).join();
  }

  // Generate code challenge from verifier
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // Generate state parameter
  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Build authorization URL using server metadata
  Future<String> _buildAuthUrl(String codeChallenge, String state) async {
    final metadata = await _getServerMetadata();
    final authorizationEndpoint = metadata['authorization_endpoint'] as String;

    final params = {
      'client_id': _currentClientId,
      'response_type': 'code',
      'scope': scope,
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final authUrl = '$authorizationEndpoint?$queryString';
    print('[Cognito] Authorization URL: $authUrl');
    return authUrl;
  }

  // Exchange authorization code for tokens using server metadata
  Future<Map<String, dynamic>?> _exchangeCodeForTokens(String code, String codeVerifier) async {
    try {
      print('[Cognito] Starting token exchange...');
      final metadata = await _getServerMetadata();
      final tokenEndpoint = metadata['token_endpoint'] as String;
      print('[Cognito] Token endpoint: $tokenEndpoint');

      // Create the authorization header for client authentication
      final credentials = base64Encode(utf8.encode('$_currentClientId:$_currentClientSecret'));
      print('[Cognito] Client credentials prepared');

      final requestBody = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      };

      print('[Cognito] Request body: $requestBody');

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: requestBody,
      );

      print('[Cognito] Token exchange response status: ${response.statusCode}');
      print('[Cognito] Token exchange response headers: ${response.headers}');
      print('[Cognito] Token exchange response body: ${response.body}');

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        print('[Cognito] Token exchange successful');
        print('[Cognito] Received tokens: ${tokenData.keys.toList()}');
        return tokenData;
      } else {
        print('[Cognito] Token exchange failed with status: ${response.statusCode}');
        print('[Cognito] Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[Cognito] Error exchanging code for tokens: $e');
      print('[Cognito] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Parse JWT payload
  Map<String, dynamic>? _parseJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (e) {
      print('[Cognito] Error parsing JWT: $e');
      return null;
    }
  }

  // Get user info from userinfo endpoint
  Future<Map<String, dynamic>?> _getUserInfo(String accessToken) async {
    try {
      print('[Cognito] Getting server metadata for userinfo...');
      final metadata = await _getServerMetadata();
      final userinfoEndpoint = metadata['userinfo_endpoint'] as String?;
      
      if (userinfoEndpoint == null) {
        print('[Cognito] No userinfo endpoint available in metadata');
        return null;
      }

      print('[Cognito] Calling userinfo endpoint: $userinfoEndpoint');
      final response = await http.get(
        Uri.parse(userinfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('[Cognito] Userinfo response status: ${response.statusCode}');
      print('[Cognito] Userinfo response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('[Cognito] Parsed userinfo data: $userData');
        return userData;
      } else {
        print('[Cognito] Failed to get user info: ${response.statusCode}');
        print('[Cognito] Error response: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('[Cognito] Error getting user info: $e');
      print('[Cognito] Stack trace: $stackTrace');
      return null;
    }
  }

  // Show authentication web view
  Future<bool> authenticate(BuildContext context) async {
    try {
      print('[Cognito] === STARTING AUTHENTICATION ===');
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();
      final authUrl = await _buildAuthUrl(codeChallenge, state);

      print('[Cognito] Code verifier: ${codeVerifier.substring(0, 20)}...');
      print('[Cognito] Code challenge: ${codeChallenge.substring(0, 20)}...');
      print('[Cognito] State: ${state.substring(0, 20)}...');
      print('[Cognito] Opening web authentication with URL: ${authUrl.substring(0, 100)}...');

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'identityconnect',
      );

      print('[Cognito] Web authentication result: $result');

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final receivedState = uri.queryParameters['state'];

      if (code != null && receivedState == state) {
        print('[Cognito] Received authorization code: ${code.substring(0, 10)}...');
        print('[Cognito] Received state: ${receivedState?.substring(0, 20)}...');
        print('[Cognito] Expected state: ${state.substring(0, 20)}...');
        print('[Cognito] State matches: ${receivedState == state}');

        print('[Cognito] === STARTING TOKEN EXCHANGE ===');
        final tokens = await _exchangeCodeForTokens(code, codeVerifier);
        
        if (tokens != null) {
          print('[Cognito] === TOKEN EXCHANGE SUCCESSFUL ===');
          final accessToken = tokens['access_token'];
          final idToken = tokens['id_token'];
          final refreshToken = tokens['refresh_token'];

          if (accessToken != null) {
            print('[Cognito] Access token received: ${accessToken.toString().substring(0, 20)}...');
            
            print('[Cognito] === GETTING USER INFO ===');
            // Get user info from userinfo endpoint (similar to Python implementation)
            final userInfo = await _getUserInfo(accessToken);
            print('[Cognito] User info from endpoint: $userInfo');
            
            // Also parse ID token if available
            Map<String, dynamic>? idTokenPayload;
            if (idToken != null) {
              print('[Cognito] ID token received, parsing...');
              idTokenPayload = _parseJWT(idToken);
              print('[Cognito] ID token payload: $idTokenPayload');
            }

            print('[Cognito] === STORING TOKENS AND USER DATA ===');
            // Store tokens
            await _storage.saveToken(accessToken);
            if (refreshToken != null) {
              await _storage.saveRefreshToken(refreshToken);
              print('[Cognito] Refresh token stored');
            }
            
            // Store user info (prefer userinfo endpoint data, fallback to ID token)
            final userData = userInfo ?? idTokenPayload;
            if (userData != null) {
              final email = userData['email'];
              final phone = userData['phone_number'] ?? userData['phone'];
              
              print('[Cognito] User data: email=$email, phone=$phone');
              
              if (email != null) {
                await _storage.saveEmail(email);
                print('[Cognito] Email stored: $email');
              }
              if (phone != null) {
                await _storage.savePhoneNumber(phone);
                print('[Cognito] Phone stored: $phone');
              }
            } else {
              print('[Cognito] WARNING: No user data available');
            }

            print('[Cognito] === AUTHENTICATION COMPLETED SUCCESSFULLY ===');
            return true;
          } else {
            print('[Cognito] ERROR: No access token in response');
          }
        } else {
          print('[Cognito] ERROR: Token exchange failed');
        }
      } else {
        print('[Cognito] ERROR: No authorization code received or state mismatch');
        print('[Cognito] Code: $code, Expected state: $state, Received state: $receivedState');
      }

      print('[Cognito] === AUTHENTICATION FAILED ===');
      return false;
    } catch (e) {
      print('[Cognito] === AUTHENTICATION ERROR ===');
      print('[Cognito] Error during authentication: $e');
      print('[Cognito] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    if (token == null) return false;

    // Parse token to check expiration
    final payload = _parseJWT(token);
    if (payload == null) return false;

    final exp = payload['exp'] as int?;
    if (exp == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp > now;
  }

  // Refresh tokens using server metadata
  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final metadata = await _getServerMetadata();
      final tokenEndpoint = metadata['token_endpoint'] as String;

      final credentials = base64Encode(utf8.encode('$_currentClientId:$_currentClientSecret'));

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final tokens = jsonDecode(response.body);
        final accessToken = tokens['access_token'];
        final newRefreshToken = tokens['refresh_token'];

        if (accessToken != null) {
          await _storage.saveToken(accessToken);
          if (newRefreshToken != null) {
            await _storage.saveRefreshToken(newRefreshToken);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('[Cognito] Error refreshing tokens: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _storage.clearToken();
    await _storage.clearRefreshToken();
    await _storage.clearEmail();
    await _storage.clearPhoneNumber();
  }
}

 