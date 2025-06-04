import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('[Biometric] Error checking availability: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      // Check if biometrics are available
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!isAvailable || !isDeviceSupported) {
        print('[Biometric] Biometrics not available on this device');
        return true; // Allow access if biometrics are not available
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('[Biometric] No biometrics enrolled on this device');
        return true;
      }

      print('[Biometric] Requesting biometric authentication');
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: "Please verify your identity to continue",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false, // Changed to false to prevent issues when app goes to background
          useErrorDialogs: true,
        ),
      );

      print('[Biometric] Authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      print('[Biometric] Platform exception during authentication: ${e.message}');
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return true; // Allow access if biometrics become unavailable
      }
      return false;
    } catch (e) {
      print('[Biometric] Authentication error: $e');
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