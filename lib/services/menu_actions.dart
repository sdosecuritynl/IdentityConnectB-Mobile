import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/identity_center_screen.dart';
import '../screens/login_screen.dart';
import 'auth_service.dart';

class MenuActions {
  final CustomSamlAuth _authService = CustomSamlAuth();

  // Navigate to Home screen
  void goToHome(BuildContext context, String email) {
    Navigator.pop(context); // Close drawer
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(email: email),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Navigate to Identity Center screen
  void goToIdentityCenter(BuildContext context, String email) {
    Navigator.pop(context); // Close drawer if open
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => IdentityCenterScreen(email: email),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
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
    navigator.pushNamedAndRemoveUntil(
      '/',
      (route) => false,
      arguments: PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const LoginScreen(),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
} 