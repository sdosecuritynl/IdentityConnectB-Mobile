import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen2.dart';
import 'dart:async';

class OTPScreen extends StatefulWidget {
  const OTPScreen({Key? key}) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  final _encryptionService = EncryptionService();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _error;
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _authService.sendOTP(_phoneController.text);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            _otpSent = true;
            _error = null;
            _startResendTimer();
          } else {
            _error = 'Failed to send OTP. Please try again.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _error = 'Please enter the OTP code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _authService.verifyOTP(
        _phoneController.text,
        _otpController.text,
      );

      if (success) {
        print('[OTP] OTP verification successful');
        
        // Generate key pair after successful verification
        print('[OTP] Generating encryption key pair...');
        try {
          await _encryptionService.generateKeyPairIfNeeded();
          print('[OTP] Key pair generated/verified successfully');
          
          // Test the encryption (for debugging purposes)
          final publicKey = await _encryptionService.getPublicKey();
          final testData = {'test': 'data', 'timestamp': DateTime.now().toIso8601String()};
          final encrypted = await _encryptionService.encrypt(testData, publicKey);
          print('[OTP] Test encryption successful: ${encrypted.substring(0, 50)}...');
          
          // Continue to main screen
          if (!mounted) return;
          print('[OTP] Navigation to main screen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } catch (e) {
          print('[OTP] Error during key generation/encryption: $e');
          setState(() {
            _isLoading = false;
            _error = 'Error setting up security. Please try again.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid OTP code. Please try again.';
        });
      }
    } catch (e) {
      print('[OTP] Error during verification process: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Device Verification', style: AppTheme.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryBlue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Please verify your device by completing the OTP verification process.',
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 32),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryBlue,
                  secondary: AppTheme.primaryBlue,
                ),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppTheme.primaryBlue,
                  selectionColor: AppTheme.primaryBlue.withOpacity(0.2),
                  selectionHandleColor: AppTheme.primaryBlue,
                ),
              ),
              child: CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                enabled: !_otpSent || _resendTimer == 0,
              ),
            ),
            const SizedBox(height: 16),
            if (_otpSent) ...[
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primaryBlue,
                    secondary: AppTheme.primaryBlue,
                  ),
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: AppTheme.primaryBlue,
                    selectionColor: AppTheme.primaryBlue.withOpacity(0.2),
                    selectionHandleColor: AppTheme.primaryBlue,
                  ),
                ),
                child: CustomTextField(
                  controller: _otpController,
                  labelText: 'OTP Code',
                  prefixIcon: Icons.lock,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: AppTheme.bodyText.copyWith(color: Colors.red),
                ),
              ),
            Container(
              decoration: AppTheme.buttonDecoration,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                style: AppTheme.primaryButtonStyle,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _otpSent ? 'Verify OTP' : 'Send OTP',
                        style: AppTheme.buttonText,
                      ),
              ),
            ),
            if (_otpSent && _resendTimer > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Resend OTP in $_resendTimer seconds',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText.copyWith(color: AppTheme.textGrey),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 