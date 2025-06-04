// File: screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'web_view_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SecureStorageService _storage = SecureStorageService();
  final DeviceService _deviceService = DeviceService();
  final AuthService _authService = AuthService();

  String? _message;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 120),
                const SizedBox(height: 24),
                const Text(
                  'IdentityConnect.io\nBusiness',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _handleSSOLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: const Text('Login with your company SSO', style: TextStyle(color: Colors.black)),
                ),
                const SizedBox(height: 20),
                if (_message != null)
                  Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSSOLogin() async {
    print('[Login] SSO button clicked');
    
    try {
      // Check device security first
      final securityResult = await _deviceService.checkDeviceSecurity();
      print('[Login] Security check result: $securityResult');

      if (securityResult['status'] != 'secure') {
        setState(() {
          _message = "Device security check failed. Please ensure your device is not rooted/jailbroken.";
        });
        return;
      }

      // Start SAML authentication flow
      print('[Login] Starting SAML authentication flow');
      final authUrl = await _authService.getAuthUrl();
      
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebViewScreen(
            url: authUrl,
            onCodeReceived: (code) async {
              print('[Login] Received auth code, exchanging for token');
              final tokenResult = await _authService.exchangeCodeForToken(code);
              
              if (tokenResult['status'] == 'success') {
                final token = tokenResult['token'];
                await _storage.saveToken(token);
                
                final decoded = JwtDecoder.decode(token);
                final email = decoded['email'] ?? decoded['sub'];
                
                print('[Login] Authentication successful, proceeding to home');
                if (!mounted) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
                );
              } else {
                print('[Login] Token exchange failed: ${tokenResult['error']}');
                if (!mounted) return;
                setState(() {
                  _message = "Authentication failed. Please try again.";
                });
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('[Login] Error during login: $e');
      if (!mounted) return;
      
      setState(() {
        _message = "Login failed. Please try again.";
      });
    }
  }
}
