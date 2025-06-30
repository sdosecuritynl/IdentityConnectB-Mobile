// File: screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/device_service.dart';
import '../services/cognito_service.dart';
import '../services/encryption_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import 'otp_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SecureStorageService _storage = SecureStorageService();
  final DeviceService _deviceService = DeviceService();
  final CognitoService _cognitoService = CognitoService();
  final _emailController = TextEditingController();
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() async {
    if (_isLoading) return;
    
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    // Validate email
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        _message = 'Please enter a valid email address.';
      });
      return;
    }
    
    // Check for social login domains
    if (_shouldUseSocialLogin(email)) {
      setState(() {
        _message = 'Please proceed with social logins instead.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      print('[Login] Starting Cognito authentication with email: $email');
      // Switch to email client configuration
      _cognitoService.useEmailClient();
      final success = await _cognitoService.authenticate(context);
      
      if (success) {
        print('[Login] Email authentication successful, checking registration status...');
        if (!mounted) return;
        
        // Check if user is already registered
        final isRegistered = await _checkIfUserIsRegistered();
        
        if (mounted) {
          if (isRegistered) {
            print('[Login] User is already registered, navigating to main screen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          } else {
            print('[Login] User is not registered, navigating to OTP screen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OTPScreen()),
            );
          }
        }
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

  void _handleSocialLogin(String provider) async {
    if (provider == 'Google') {
      await _handleGoogleLogin();
    } else if (provider == 'Facebook') {
      await _handleFacebookLogin();
    } else {
      // TODO: Implement Apple login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$provider login coming soon!'),
          backgroundColor: AppTheme.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Switch to Google client configuration
      _cognitoService.useGoogleClient();
      
      // Perform authentication
      final success = await _cognitoService.authenticate(context);
      
      if (success) {
        print('[Login] Google authentication successful, checking registration status...');
        if (mounted) {
          // Check if user is already registered
          final isRegistered = await _checkIfUserIsRegistered();
          
          if (mounted) {
            if (isRegistered) {
              print('[Login] User is already registered, navigating to home screen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            } else {
              print('[Login] User is not registered, navigating to OTP screen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OTPScreen()),
              );
            }
          }
        }
      } else {
        print('[Login] Google authentication failed');
        if (mounted) {
          setState(() {
            _message = 'Google login failed. Please try again.';
          });
        }
      }
    } catch (e, stackTrace) {
      print('Google login error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          // Check if user canceled the login
          if (e.toString().contains('CANCELED') || e.toString().contains('User canceled')) {
            _message = null; // Don't show error message for user cancellation
          } else {
            _message = 'An error occurred during Google login. Please try again.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFacebookLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Switch to Facebook client configuration
      _cognitoService.useFacebookClient();
      
      // Perform authentication
      final success = await _cognitoService.authenticate(context);
      
      if (success) {
        print('[Login] Facebook authentication successful, checking registration status...');
        if (mounted) {
          // Check if user is already registered
          final isRegistered = await _checkIfUserIsRegistered();
          
          if (mounted) {
            if (isRegistered) {
              print('[Login] User is already registered, navigating to main screen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            } else {
              print('[Login] User is not registered, navigating to OTP screen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OTPScreen()),
              );
            }
          }
        }
      } else {
        print('[Login] Facebook authentication failed');
        if (mounted) {
          setState(() {
            _message = 'Facebook login failed. Please try again.';
          });
        }
      }
    } catch (e, stackTrace) {
      print('Facebook login error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          // Check if user canceled the login
          if (e.toString().contains('CANCELED') || e.toString().contains('User canceled')) {
            _message = null; // Don't show error message for user cancellation
          } else {
            _message = 'An error occurred during Facebook login. Please try again.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
  }

  bool _shouldUseSocialLogin(String email) {
    final domain = email.toLowerCase().split('@').last;
    final socialDomains = ['gmail.com', 'icloud.com', 'facebook.com'];
    return socialDomains.contains(domain);
  }

  Future<bool> _checkIfUserIsRegistered() async {
    try {
      print('[Login] Checking if user is already registered...');
      
      // Get required data for registration check
      final deviceService = DeviceService();
      final encryptionService = EncryptionService();
      final notificationService = NotificationService();
      
      final deviceUuid = await deviceService.getOrGenerateUUID();
      await encryptionService.generateKeyPairIfNeeded();
      final publicKeyPem = await encryptionService.getPublicKey();
      final deviceToken = await notificationService.getDeviceToken();
      
      // Make the registration check request
      final idToken = await _storage.getIdToken();
      if (idToken == null) {
        print('[Login] No ID token available for registration check');
        return false;
      }

      final requestBody = {
        "uuid": deviceUuid,
        "publicKey": publicKeyPem,
        if (deviceToken != null) "deviceToken": deviceToken,
      };

      print('[Login] Registration check request body: ${jsonEncode(requestBody)}');
      print('[Login] Using bearer token (first 20 chars): ${idToken.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse('https://d3oyxmwcqyuai5.cloudfront.net/isRegisteredUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(requestBody),
      );

      print('[Login] Registration check response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final isRegistered = responseData['registered'] ?? false;
        print('[Login] User registered status: $isRegistered');
        return isRegistered;
      } else {
        print('[Login] Registration check failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[Login] Error checking registration status: $e');
      return false;
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
                          child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo and Title
                    Image.asset('assets/logo.png', height: 100),
                    const SizedBox(height: 16),
                    Text(
                      'IdentityConnect.io',
                      textAlign: TextAlign.center,
                      style: AppTheme.titleLarge.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'One Identity. Everywhere.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 32),
                  
                  // Email Login Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Get Started',
                          style: AppTheme.titleMedium.copyWith(
                            fontSize: 18,
                            color: AppTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // Email Input
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          forceLowercase: true,
                        ),
                        const SizedBox(height: 16),
                        
                        // Sign In Button
                        Container(
                          decoration: AppTheme.buttonDecoration,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleEmailLogin,
                            style: AppTheme.primaryButtonStyle.copyWith(
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: AppTheme.buttonText.copyWith(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.textGrey.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.textGrey.withOpacity(0.3))),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Social Login Icons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialIconButtonWithImage(
                        'assets/icons/google_logo.png',
                        Colors.white,
                        () => _handleSocialLogin('Google'),
                      ),
                      _buildSocialIconButtonWithImage(
                        'assets/icons/apple_logo.png',
                        Colors.white,
                        () => _handleSocialLogin('Apple'),
                      ),
                      _buildSocialIconButtonWithImage(
                        'assets/icons/facebook_logo.png',
                        Colors.white,
                        () => _handleSocialLogin('Facebook'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Error Message
                  if (_message != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIconButtonWithImage(
    String imagePath,
    Color backgroundColor,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.textGrey.withOpacity(0.2),
              width: 1,
            ),
          ),
          minimumSize: const Size(64, 64),
        ),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Image.asset(
            imagePath,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

