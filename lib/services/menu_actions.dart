import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/identity_center_screen.dart';
import 'auth_service.dart';

class MenuActions {
  final CustomSamlAuth _authService = CustomSamlAuth();

  // Navigate to Home screen
  void goToHome(BuildContext context, String email) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
    );
  }

  // Navigate to Identity Center screen
  void goToIdentityCenter(BuildContext context, String email) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => IdentityCenterScreen(email: email)),
    );
  }

  // Handle regular sign out (with Cognito call)
  Future<void> signOut(BuildContext context) async {
    print('[MenuActions] Starting sign out process');
    
    // Store navigator state before async operations
    final navigator = Navigator.of(context);
    
    // Close drawer first
    navigator.pop();
    
    await _authService.signOut();
    
    print('[MenuActions] Navigating to login screen');
    navigator.pushNamedAndRemoveUntil('/', (route) => false);
  }
} 