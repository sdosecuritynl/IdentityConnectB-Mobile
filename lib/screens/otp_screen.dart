import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/encryption_service.dart';
import '../services/cognito_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';
import 'login_screen.dart';
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
  final _cognitoService = CognitoService();
  final _notificationService = NotificationService();
  final _storage = SecureStorageService();
  static const String _baseUrl = 'https://d3oyxmwcqyuai5.cloudfront.net';
  bool _isLoading = false;
  bool _otpSent = false;
  String? _error;
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

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

  String _sanitizePhoneNumber(String phoneNumber) {
    // Remove any potentially harmful characters and keep only valid phone number characters
    // Allow only digits, spaces, hyphens, parentheses, and plus sign
    final sanitized = phoneNumber.replaceAll(RegExp(r'[^0-9\s\-\(\)\+]'), '');
    
    // Limit length to prevent extremely long strings
    if (sanitized.length > 20) {
      return '${sanitized.substring(0, 17)}...';
    }
    
    return sanitized;
  }



  // Register public key with backend
  Future<bool> _registerPublicKey(String publicKey) async {
    try {
      print('[OTP] Registering public key with backend...');
      
      // Get ID token for authentication
      final idToken = await _storage.getIdToken();
      if (idToken == null) {
        print('[OTP] ❌ No ID token available for public key registration');
        return false;
      }

      // Get device UUID
      final uuid = await _storage.getUUID();
      if (uuid == null) {
        print('[OTP] ❌ No device UUID available for public key registration');
        return false;
      }

      // Prepare request body
      final requestBody = {
        "publicKey": publicKey,
        "uuid": uuid,
      };

      print('[OTP] Public key registration request body: ${jsonEncode(requestBody)}');
      print('[OTP] Using bearer token (first 20 chars): ${idToken.substring(0, 20)}...');

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/registerPublicKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(requestBody),
      );

      print('[OTP] Public key registration response status: ${response.statusCode}');
      print('[OTP] Public key registration response body: ${response.body}');

      if (response.statusCode == 200) {
        print('[OTP] ✅ Public key registered successfully');
        return true;
      } else {
        print('[OTP] ❌ Failed to register public key: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[OTP] ❌ Error registering public key: $e');
      return false;
    }
  }

  // Register UUID with backend
  Future<bool> _registerUUID(String uuid) async {
    try {
      print('[OTP] Registering UUID with backend...');
      
      // Get ID token for authentication
      final idToken = await _storage.getIdToken();
      if (idToken == null) {
        print('[OTP] ❌ No ID token available for UUID registration');
        return false;
      }

      // Prepare request body
      final requestBody = {
        "uuid": uuid,
      };

      print('[OTP] UUID registration request body: ${jsonEncode(requestBody)}');
      print('[OTP] Using bearer token (first 20 chars): ${idToken.substring(0, 20)}...');

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/registerUUID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(requestBody),
      );

      print('[OTP] UUID registration response status: ${response.statusCode}');
      print('[OTP] UUID registration response body: ${response.body}');

      if (response.statusCode == 200) {
        print('[OTP] ✅ UUID registered successfully');
        return true;
      } else {
        print('[OTP] ❌ Failed to register UUID: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[OTP] ❌ Error registering UUID: $e');
      return false;
    }
  }

  // Show error dialog and return to login screen
  void _showErrorAndReturnToLogin(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _backToLogin(); // Return to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _backToLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign out from Cognito
      await _cognitoService.signOut();
      
      if (mounted) {
        // Navigate back to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('[OTP] Error during sign out: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            _error = 'Failed to send verification code. Please try again.';
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
        _error = 'Please enter the verification code';
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
          
          // Get UUID for registrations
          final uuid = await _storage.getUUID();
          if (uuid == null) {
            print('[OTP] ❌ No UUID available for backend registrations');
            throw Exception('UUID not available');
          }

          // Run all registrations in parallel for better performance
          print('[OTP] Starting parallel registration of UUID, push token, and public key...');
          try {
            final results = await Future.wait([
              _registerUUID(uuid),
              _notificationService.registerStoredToken(),
              _registerPublicKey(publicKey),
            ]);

            final uuidRegistered = results[0];
            final tokenRegistered = results[1];
            final publicKeyRegistered = results[2];

            print('[OTP] Registration results - UUID: $uuidRegistered, Token: $tokenRegistered, PublicKey: $publicKeyRegistered');

            // Check if any registration failed
            if (!uuidRegistered || !tokenRegistered || !publicKeyRegistered) {
              print('[OTP] ❌ One or more registrations failed');
              _showErrorAndReturnToLogin('Registration failed. Please try logging in again.');
              return;
            }

            print('[OTP] ✅ All registrations completed successfully');
          } catch (e) {
            print('[OTP] ❌ Error during parallel registrations: $e');
            _showErrorAndReturnToLogin('Registration failed. Please try logging in again.');
            return;
          }
          
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
            // Extract the actual error message from the exception
            final errorMsg = e.toString();
            if (errorMsg.contains('Failed to access secure storage')) {
              _error = 'Unable to access secure storage. Please check app permissions.';
            } else if (errorMsg.contains('Failed to generate RSA key pair')) {
              _error = 'Unable to generate security keys. Please try again.';
            } else if (errorMsg.contains('Failed to validate')) {
              _error = 'Security setup validation failed. Please try again.';
            } else {
              _error = 'Error setting up security. Please try again.';
            }
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid verification code. Please try again.';
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
              'Please verify your device by entering a phone number. We\'ll send you a verification code via SMS.',
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
                  labelText: 'Verification Code',
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
                        _otpSent ? 'Verify Code' : 'Send Code',
                        style: AppTheme.buttonText,
                      ),
              ),
            ),
            if (_otpSent) ...[
              if (_resendTimer > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Resend code in $_resendTimer seconds',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyText.copyWith(color: AppTheme.textGrey),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    child: Text(
                      'Resend Code',
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextButton(
                onPressed: _isLoading ? null : _backToLogin,
                child: Text(
                  'Back',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.primaryBlue
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 