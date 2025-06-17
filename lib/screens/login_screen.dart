// File: screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/device_service.dart';
import '../services/cognito_service.dart';
import '../theme/app_theme.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SecureStorageService _storage = SecureStorageService();
  final DeviceService _deviceService = DeviceService();
  final CognitoService _cognitoService = CognitoService();
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkDeviceSecurity();
    _checkExistingAuth();
  }

  Future<void> _checkDeviceSecurity() async {
    final securityResult = await _deviceService.checkDeviceSecurity();
    if (securityResult['status'] != 'secure') {
      setState(() {
        _message = securityResult['reason'];
      });
    }
  }

  Future<void> _checkExistingAuth() async {
    // Check if user is already authenticated
    final isAuthenticated = await _cognitoService.isAuthenticated();
    if (isAuthenticated) {
      print('[Login] User already authenticated, redirecting to OTP screen');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OTPScreen()),
      );
    }
  }

  void _handleLogin() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      print('[Login] Starting Cognito authentication');
      final success = await _cognitoService.authenticate(context);
      
      if (success) {
        print('[Login] Authentication successful, redirecting to OTP screen');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OTPScreen()),
        );
      } else {
        setState(() {
          _message = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      print('[Login] Authentication error: $e');
      setState(() {
        _message = 'An error occurred during login. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 120),
                    const SizedBox(height: 24),
                    Text(
                      'IdentityConnect.io',
                      textAlign: TextAlign.center,
                      style: AppTheme.titleLarge.copyWith(
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      GestureDetector(
                        onTap: _handleLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    if (_message != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

