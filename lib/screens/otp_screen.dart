import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
      appBar: AppBar(
        title: const Text('Device Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please verify your device by completing the OTP verification process.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_otpSent || _resendTimer == 0,
              ),
            ),
            const SizedBox(height: 16),
            if (_otpSent) ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'OTP Code',
                    prefixIcon: const Icon(Icons.lock),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
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
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              if (_resendTimer > 0)
                Text(
                  'Resend OTP in ${_resendTimer}s',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                )
              else
                TextButton(
                  onPressed: _sendOTP,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
} 