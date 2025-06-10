// File: screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'home_screen2.dart';
import 'web_view_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SecureStorageService _storage = SecureStorageService();
  final DeviceService _deviceService = DeviceService();
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  String? _message;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    try {
      final token = await _storage.getToken();
      if (token != null) {
        print('[Login] Found existing token, verifying device UUID');
        final uuidResult = await _authService.verifyUUID(token);
        final decoded = JwtDecoder.decode(token);
        final email = decoded['email'] ?? decoded['sub'];
        
        if (uuidResult['verified'] == true) {
          print('[Login] Device UUID verified, proceeding to biometric check');
          
          // Request biometric authentication
          final authenticated = await _biometricService.authenticateWithBiometrics();
          if (!authenticated) {
            print('[Login] Biometric authentication failed');
            setState(() {
              _message = 'Biometric authentication required to access the app';
              _isLoading = false;
            });
            return;
          }
          
          print('[Login] Biometric authentication successful, proceeding to main screen');
          if (!mounted) return;
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else if (uuidResult['status'] == 'not_registered' || uuidResult['status'] == 'mismatch') {
          print('[Login] Device not registered or UUID mismatch, starting OTP flow');
          if (!mounted) return;
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OTPScreen(
                email: email,
                token: token,
              ),
            ),
          );
        } else {
          print('[Login] UUID verification failed, clearing token');
          await _storage.clearToken();
        }
      } else {
        print('[Login] No existing token found');
      }
    } catch (e) {
      print('[Login] Error checking existing token: $e');
      // Only clear tokens on specific authentication errors
      if (e.toString().toLowerCase().contains('unauthorized') ||
          e.toString().toLowerCase().contains('forbidden') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        print('[Login] Authentication error detected, clearing tokens');
        await _storage.clearToken();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                Text(
                  'IdentityConnect.io\nBusiness',
                  textAlign: TextAlign.center,
                  style: AppTheme.titleLarge.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: AppTheme.buttonDecoration.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textGrey.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleSSOLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: AppTheme.textGrey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security, color: AppTheme.primaryBlue, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Login with your company SSO',
                          style: AppTheme.buttonText.copyWith(color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_message != null)
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyText.copyWith(color: AppTheme.textDark),
                  ),
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

                // Check device UUID after successful SAML auth
                print('[Login] Verifying device UUID');
                final uuidResult = await _authService.verifyUUID(token);
                
                if (uuidResult['verified'] == true) {
                  print('[Login] Device UUID verified, proceeding to biometric check');
                  
                  // Request biometric authentication
                  final authenticated = await _biometricService.authenticateWithBiometrics();
                  if (!authenticated) {
                    print('[Login] Biometric authentication failed');
                    setState(() {
                      _message = 'Biometric authentication required to access the app';
                      _isLoading = false;
                    });
                    return;
                  }
                  
                  print('[Login] Biometric authentication successful, proceeding to main screen');
                  if (!mounted) return;
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                } else {
                  print('[Login] Device not registered or UUID mismatch, starting OTP flow');
                  if (!mounted) return;
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OTPScreen(
                        email: email,
                        token: token,
                      ),
                    ),
                  );
                }
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
