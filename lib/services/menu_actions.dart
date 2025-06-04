import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/identity_center_screen.dart';
import '../screens/user_info_screen.dart';
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

  // Navigate to User Info screen
  void goToUserInfo(BuildContext context, String email) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => UserInfoScreen(email: email)),
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

  // Show delete account confirmation dialog
  Future<void> showDeleteConfirmation(BuildContext context) async {
    print('[MenuActions] Showing delete confirmation dialog');
    Navigator.pop(context); // Close drawer first
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => _handleDeleteAccount(dialogContext),
            ),
          ],
        );
      },
    );
  }

  // Handle the delete account action
  Future<void> _handleDeleteAccount(BuildContext context) async {
    print('[MenuActions] Starting delete account process');
    
    // Store both navigator and scaffold messenger state before any async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Close confirmation dialog
    navigator.pop();
    
    try {
      // Delete the user
      print('[MenuActions] Calling deleteUser');
      final success = await _authService.deleteUser();
      print('[MenuActions] Delete user result: $success');
      
      if (success) {
        print('[MenuActions] Delete successful, clearing local data');
        // Clear local data directly instead of going through signOut
        await _authService.clearLocalData();
        
        // Navigate to login screen using stored navigator
        print('[MenuActions] Navigating to login screen after deletion');
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
        
        // Show success message
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Account successfully deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('[MenuActions] Delete failed, showing error');
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('[MenuActions] Error during account deletion: $e');
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 