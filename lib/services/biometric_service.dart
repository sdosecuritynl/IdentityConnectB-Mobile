import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isBiometricsAvailable() async {
    try {
      // Check if biometrics is available on device
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      
      if (canAuthenticate) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        print('[Biometric] Available biometrics: $availableBiometrics');
        return availableBiometrics.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      print('[Biometric] Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        print('[Biometric] Biometrics not available');
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      print('[Biometric] Authentication result: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('[Biometric] Error during authentication: ${e.message}');
      if (e.code == auth_error.notAvailable) {
        print('[Biometric] No biometrics available on device');
      } else if (e.code == auth_error.notEnrolled) {
        print('[Biometric] No biometrics enrolled on device');
      } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        print('[Biometric] Biometric authentication locked out');
      }
      return false;
    } catch (e) {
      print('[Biometric] Unexpected error during authentication: $e');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      print('[Biometric] Biometric authentication ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('[Biometric] Error setting biometric enabled state: $e');
    }
  }

  Future<bool> getBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('[Biometric] Error getting biometric enabled state: $e');
      return false;
    }
  }
}