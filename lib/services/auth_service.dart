import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class CustomSamlAuth {
  final _storage = const FlutterSecureStorage();

  final String clientId = '3kfl9g8p032atbj43rnildrrgr';
  final String domain = 'us-east-1id8zqgdw7.auth.us-east-1.amazoncognito.com';
  final String redirectUri = 'myapp://callback/';
  final String provider = 'sdosecurity.com';

  Future<String?> signIn() async {
    final url =
        'https://$domain/login?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&identity_provider=$provider';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'myapp',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      final response = await http.post(
        Uri.parse('https://$domain/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      final data = json.decode(response.body);
      final idToken = data['id_token'];

      if (idToken != null) {
        await _storage.write(key: 'id_token', value: idToken);
        return idToken;
      }
    } catch (e) {
      print('Login error: $e');
    }

    return null;
  }

  Future<String?> getStoredToken() async {
    return await _storage.read(key: 'id_token');
  }

  Future<void> signOut() async {
    await _storage.deleteAll();
  }
}
