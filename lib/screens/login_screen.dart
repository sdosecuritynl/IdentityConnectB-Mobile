// File: screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/device_service.dart';
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
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkDeviceSecurity();
  }

  Future<void> _checkDeviceSecurity() async {
    final securityResult = await _deviceService.checkDeviceSecurity();
    if (securityResult['status'] != 'secure') {
      setState(() {
        _message = securityResult['reason'];
      });
    }
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // Navigate directly to OTP screen
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OTPScreen(),
      ),
    );

    setState(() => _isLoading = false);
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
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: _isLoading ? null : _handleLogin,
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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

