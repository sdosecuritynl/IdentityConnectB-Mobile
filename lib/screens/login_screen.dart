import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final CustomSamlAuth _auth = CustomSamlAuth();
  String? _message;
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final token = await _auth.signIn();

    setState(() {
      _isLoading = false;
      if (token != null) {
        final decoded = JwtDecoder.decode(token);
        _message = '✅ Welcome ${decoded['email'] ?? decoded['sub']}';
      } else {
        _message = '❌ Login failed.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SSO Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login via SSO'),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(_message!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
