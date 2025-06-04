// File: screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:async';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
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
  final CustomSamlAuth _auth = CustomSamlAuth();
  final BiometricService _biometrics = BiometricService();
  final SecureStorageService _storage = SecureStorageService();
  final DeviceService _deviceService = DeviceService();
  final AuthService _authService = AuthService();

  String? _message;
  bool _isLoading = false;
  String _phoneNumber = '';
  String _otp = '';
  bool _otpSent = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Reset any existing state
    _message = null;
    _isLoading = false;
    _phoneNumber = '';
    _otp = '';
    _otpSent = false;
    _resendCountdown = 0;
    _countdownTimer?.cancel();
    
    // Check for existing session
    _checkExistingSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUUIDAndVerify() async {
    // First check if we have a UUID
    final localUUID = await _storage.getUUID();
    print('[Login] Checking device UUID: ${localUUID ?? 'none'}');

    // Always get a fresh authentication token
    print('[Login] Starting authentication flow');
    final token = await _auth.signIn();
    if (token == null) {
      print('[Login] Failed to get authentication token');
      return _logout();
    }

    try {
      final decoded = JwtDecoder.decode(token);
      final email = decoded['email'] ?? decoded['sub'];
      print('[Login] Authentication successful for email: $email');

      // Save the new authentication token
      await _storage.saveToken(token);

      if (localUUID != null) {
        // If we have a UUID, verify it with the backend
        print('[Login] Verifying existing device UUID: $localUUID');
        final verificationResult = await _deviceService.verifyUUID(localUUID, token);
        
        switch (verificationResult['status']) {
          case 'verified':
            print('[Login] Device UUID verified successfully');
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
            );
            return;
            
          case 'not_registered':
            print('[Login] Device not registered, proceeding to phone verification');
            _showPhoneVerificationDialog(email, token);
            return;
            
          case 'mismatch':
            print('[Login] UUID mismatch detected, showing security notice');
            _showSecurityNotice();
            return;
            
          default:
            print('[Login] Device verification error: ${verificationResult['error']}');
            setState(() {
              _message = "Device verification failed. Please try again.";
              _isLoading = false;
            });
            return;
        }
      } else {
        // No UUID means this is a fresh install or reinstall
        print('[Login] No device UUID found, proceeding to phone verification');
        _showPhoneVerificationDialog(email, token);
      }
    } catch (e) {
      print('[Login] Error during authentication process: $e');
      _logout();
    }
  }

  void _logout() async {
    print('[Login] Starting logout process');
    final uuidBeforeLogout = await _storage.getUUID();
    print('[Login] UUID before logout: $uuidBeforeLogout');
    
    await _auth.signOut();
    // Instead of clearAll, only clear the token
    await _storage.clearToken();
    
    final uuidAfterLogout = await _storage.getUUID();
    print('[Login] UUID after logout: $uuidAfterLogout');

    if (mounted) {
      setState(() {
        _isLoading = false;
        _message = "Session expired. Please log in again.";
      });
    }
  }

  Future<void> _checkExistingSession() async {
    print('[Login] Starting _checkExistingSession');
    try {
      final token = await _storage.getToken();
      print('[Login] Token check result: ${token != null ? 'Found token' : 'No token found'}');
      
      if (token == null) {
        print('[Login] No token found, proceeding to regular login flow');
        _startRegularLogin();
        return;
      }

      // Check if token is expired
      try {
        if (JwtDecoder.isExpired(token)) {
          print('[Login] Token is expired, proceeding to regular login flow');
          await _storage.clearToken();
          _startRegularLogin();
          return;
        }
      } catch (e) {
        print('[Login] Error checking token expiration: $e');
        await _storage.clearToken();
        _startRegularLogin();
        return;
      }

      // We have a valid token, check biometrics
      final biometricEnabled = await _biometrics.getBiometricEnabled();
      final biometricAvailable = await _biometrics.isBiometricAvailable();
      print('[Login] Biometric status - Enabled: $biometricEnabled, Available: $biometricAvailable');
      
      if (biometricEnabled && biometricAvailable) {
        if (!mounted) return;
        
        setState(() {
          _isLoading = true;
          _message = null;
        });

        try {
          print('[Login] Requesting biometric authentication');
          final authenticated = await _biometrics.authenticate();
          print('[Login] Biometric authentication result: $authenticated');
          
          if (!mounted) return;

          if (!authenticated) {
            setState(() {
              _isLoading = false;
              _message = "Biometric authentication failed. Please try again.";
            });
            return;
          }

          // Biometric succeeded, proceed to home
          print('[Login] Biometric authentication successful, proceeding to home');
          final decoded = JwtDecoder.decode(token);
          final email = decoded['email'] ?? decoded['sub'];
          
          if (!mounted) return;
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
          );
        } catch (e) {
          print('[Login] Error during biometric authentication: $e');
          if (!mounted) return;
          
          setState(() {
            _isLoading = false;
            _message = "Biometric authentication error. Please try again.";
          });
        }
      } else {
        // No biometrics available/enabled but we have a valid token
        // For security, force them through regular login flow
        print('[Login] No biometrics available/enabled, proceeding to regular login flow');
        _startRegularLogin();
      }
    } catch (e) {
      print('[Login] Error checking existing session: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _message = "Error checking session. Please try again.";
      });
    }
  }

  void _startResendTimer() {
    _resendCountdown = 60; // 1 minute
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _showPhoneVerificationDialog(String email, String token) {
    print('[Login] Showing phone verification dialog');
    
    // Reset states when showing dialog
    _otpSent = false;
    _resendCountdown = 0;
    _countdownTimer?.cancel();
    _isLoading = false; // Reset loading state when dialog opens
    _message = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Create a local loading state for the dialog
          bool isDialogLoading = false;
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Phone Verification',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+1234567890',
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                    onChanged: (value) => _phoneNumber = value,
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'OTP Code',
                        border: UnderlineInputBorder(),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple),
                        ),
                      ),
                      onChanged: (value) => _otp = value,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _message!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: isDialogLoading ? null : () async {
                      if (_phoneNumber.isEmpty) {
                        setDialogState(() {
                          _message = "Please enter a valid phone number";
                        });
                        return;
                      }
                      
                      setDialogState(() {
                        isDialogLoading = true;
                        _message = null;
                      });

                      try {
                        if (_otpSent) {
                          // Verify OTP
                          final otpVerified = await _deviceService.verifyOTP(_phoneNumber, _otp, token);
                          if (!otpVerified) {
                            setDialogState(() {
                              _message = "Invalid OTP. Please try again.";
                              isDialogLoading = false;
                            });
                            return;
                          }

                          // Register device after OTP verification
                          final result = await _deviceService.registerDevice(
                            email,
                            token,
                            _phoneNumber,
                          );

                          if (result == null) {
                            setDialogState(() {
                              _message = "An error occurred during device registration. Please try again.";
                              isDialogLoading = false;
                            });
                            return;
                          }

                          if (result['registered'] != true) {
                            print('[Login] Device registration failed: ${result['reason'] ?? 'Unknown reason'}');
                            _showSecurityNotice();
                            return;
                          }

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(email: email),
                            ),
                          );
                        } else {
                          // Send initial OTP
                          final otpSent = await _deviceService.sendOTP(_phoneNumber, token);
                          if (otpSent) {
                            setDialogState(() {
                              _otpSent = true;
                              _message = null;
                              _resendCountdown = 60;
                              isDialogLoading = false;
                            });
                            
                            // Start countdown timer
                            _countdownTimer?.cancel();
                            _countdownTimer = Timer.periodic(
                              const Duration(seconds: 1),
                              (timer) {
                                setDialogState(() {
                                  if (_resendCountdown > 0) {
                                    _resendCountdown--;
                                  } else {
                                    timer.cancel();
                                  }
                                });
                              },
                            );
                          } else {
                            setDialogState(() {
                              _message = "Failed to send OTP. Please check your phone number and try again.";
                              isDialogLoading = false;
                            });
                          }
                        }
                      } catch (e) {
                        print("[Login] Phone verification error: $e");
                        setDialogState(() {
                          _message = "An error occurred. Please try again.";
                          isDialogLoading = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isDialogLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _otpSent ? 'Verify OTP' : 'Send OTP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                  if (_otpSent && _resendCountdown > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Resend OTP in ${_resendCountdown}s',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSecurityNotice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF8F5FA),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "Security Alert",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "This email account is associated with a different device. Please contact your administrator.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text("Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecurityWarning(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF8F5FA),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                "Security Warning",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text(
                  "Close App",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
