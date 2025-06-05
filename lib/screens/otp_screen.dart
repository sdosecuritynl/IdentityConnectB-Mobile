import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'dart:async';

class OTPScreen extends StatefulWidget {
  final String email;
  final String token;

  const OTPScreen({
    Key? key,
    required this.email,
    required this.token,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
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
      final success = await _authService.sendOTP(_phoneController.text, widget.token);
      
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
        widget.token,
      );

      if (success) {
        // Register the device after successful OTP verification
        final registrationResult = await _authService.registerDevice(
          widget.email,
          widget.token,
        );

        if (registrationResult != null && registrationResult['registered'] == true) {
          if (!mounted) return;
          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(email: widget.email)),
          );
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid OTP code. Please try again.';
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
              child: TextField(
                controller: _phoneController,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: AppTheme.primaryBlue),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryBlue),
                  ),
                ),
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
                child: TextField(
                  controller: _otpController,
                  decoration: AppTheme.textFieldDecoration.copyWith(
                    labelText: 'OTP Code',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.primaryBlue),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
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
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _otpSent ? Icons.check_circle : Icons.send,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _otpSent ? 'Verify OTP' : 'Send OTP',
                            style: AppTheme.buttonText.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            if (_otpSent && _resendTimer > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Resend code in $_resendTimer seconds',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 