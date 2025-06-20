import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _uuidKey = 'device_uuid';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'user_email';
  static const String _phoneKey = 'user_phone';
  static const String _fullNameKey = 'user_full_name';
  static const String _dateOfBirthKey = 'user_date_of_birth';
  static const String _licenseNumberKey = 'user_license_number';
  static const String _licenseExpirationKey = 'user_license_expiration';
  static const String _passportNumberKey = 'user_passport_number';
  static const String _passportExpirationKey = 'user_passport_expiration';
  
  // Session data keys (stored in SharedPreferences)
  static const String _sessionKey = 'app_session';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _loginAttemptCountKey = 'login_attempt_count';

  // Auth token operations - NOW USE SECURE STORAGE
  Future<void> saveToken(String token) async {
    print('[Storage] Saving auth token to secure storage');
    await _secureStorage.write(key: _tokenKey, value: token);
    
    // Remove from SharedPreferences if it exists (migration cleanup)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  Future<String?> getToken() async {
    // Get from secure storage
    final token = await _secureStorage.read(key: _tokenKey);
    
    // Check if it's in SharedPreferences and migrate if found
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsToken = prefs.getString(_tokenKey);
      if (sharedPrefsToken != null) {
        print('[Storage] Found token in SharedPreferences, migrating to secure storage');
        await saveToken(sharedPrefsToken);
        return sharedPrefsToken;
      }
    }
    
    return token;
  }
  
  Future<void> clearToken() async {
    print('[Storage] Clearing auth token from all storages');
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Refresh token operations (already in secure storage)
  Future<void> saveRefreshToken(String refreshToken) async {
    print('[Storage] Saving refresh token to secure storage');
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }
  
  Future<void> clearRefreshToken() async {
    print('[Storage] Clearing refresh token from secure storage');
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // Session data operations - USE SHARED PREFERENCES (cleared on uninstall)
  Future<void> saveSession(String sessionData) async {
    print('[Storage] Saving session data to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, sessionData);
  }
  
  Future<String?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }
  
  Future<void> clearSession() async {
    print('[Storage] Clearing session data from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
  
  Future<void> saveLastLoginTime(DateTime loginTime) async {
    print('[Storage] Saving last login time to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginTimeKey, loginTime.toIso8601String());
  }
  
  Future<DateTime?> getLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastLoginTimeKey);
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }
  
  Future<void> saveLoginAttemptCount(int count) async {
    print('[Storage] Saving login attempt count to SharedPreferences: $count');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginAttemptCountKey, count);
  }
  
  Future<int> getLoginAttemptCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loginAttemptCountKey) ?? 0;
  }
  
  Future<void> clearLoginAttemptCount() async {
    print('[Storage] Clearing login attempt count from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginAttemptCountKey);
  }

  // Email operations (secure storage)
  Future<void> saveEmail(String email) async {
    print('[Storage] Saving email to secure storage');
    await _secureStorage.write(key: _emailKey, value: email);
  }
  
  Future<String?> getEmail() async {
    return await _secureStorage.read(key: _emailKey);
  }
  
  Future<void> clearEmail() async {
    print('[Storage] Clearing email from secure storage');
    await _secureStorage.delete(key: _emailKey);
  }

  // Phone number operations (secure storage)
  Future<void> savePhoneNumber(String phoneNumber) async {
    print('[Storage] Saving phone number to secure storage');
    await _secureStorage.write(key: _phoneKey, value: phoneNumber);
  }
  
  Future<String?> getPhoneNumber() async {
    return await _secureStorage.read(key: _phoneKey);
  }
  
  Future<void> clearPhoneNumber() async {
    print('[Storage] Clearing phone number from secure storage');
    await _secureStorage.delete(key: _phoneKey);
  }

  // UUID operations (secure storage - persist after uninstall)
  Future<void> saveUUID(String uuid) async {
    print('[Storage] Saving UUID to secure storage: $uuid');
    await _secureStorage.write(key: _uuidKey, value: uuid);
    
    // Remove from SharedPreferences if exists
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uuidKey);
  }
  
  Future<String?> getUUID() async {
    final uuid = await _secureStorage.read(key: _uuidKey);
    print('[Storage] Retrieved UUID from secure storage: $uuid');
    
    // Check if it's in SharedPreferences and migrate if found
    final prefs = await SharedPreferences.getInstance();
    final prefsUuid = prefs.getString(_uuidKey);
    if (prefsUuid != null) {
      print('[Storage] Found UUID in SharedPreferences, migrating to secure storage');
      await saveUUID(prefsUuid);
      return prefsUuid;
    }
    
    return uuid;
  }
  
  Future<void> clearUUID() async {
    print('[Storage] Clearing UUID from all storages');
    await _secureStorage.delete(key: _uuidKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uuidKey);
  }

  // User information operations (secure storage)
  Future<void> saveFullName(String fullName) async {
    print('[Storage] Saving full name to secure storage');
    await _secureStorage.write(key: _fullNameKey, value: fullName);
  }
  
  Future<String?> getFullName() async {
    return await _secureStorage.read(key: _fullNameKey);
  }
  
  Future<void> saveDateOfBirth(String dateOfBirth) async {
    print('[Storage] Saving date of birth to secure storage');
    await _secureStorage.write(key: _dateOfBirthKey, value: dateOfBirth);
  }
  
  Future<String?> getDateOfBirth() async {
    return await _secureStorage.read(key: _dateOfBirthKey);
  }
  
  Future<void> saveLicenseNumber(String licenseNumber) async {
    print('[Storage] Saving license number to secure storage');
    await _secureStorage.write(key: _licenseNumberKey, value: licenseNumber);
  }
  
  Future<String?> getLicenseNumber() async {
    return await _secureStorage.read(key: _licenseNumberKey);
  }
  
  Future<void> saveLicenseExpiration(String licenseExpiration) async {
    print('[Storage] Saving license expiration to secure storage');
    await _secureStorage.write(key: _licenseExpirationKey, value: licenseExpiration);
  }
  
  Future<String?> getLicenseExpiration() async {
    return await _secureStorage.read(key: _licenseExpirationKey);
  }
  
  Future<void> savePassportNumber(String passportNumber) async {
    print('[Storage] Saving passport number to secure storage');
    await _secureStorage.write(key: _passportNumberKey, value: passportNumber);
  }
  
  Future<String?> getPassportNumber() async {
    return await _secureStorage.read(key: _passportNumberKey);
  }
  
  Future<void> savePassportExpiration(String passportExpiration) async {
    print('[Storage] Saving passport expiration to secure storage');
    await _secureStorage.write(key: _passportExpirationKey, value: passportExpiration);
  }
  
  Future<String?> getPassportExpiration() async {
    return await _secureStorage.read(key: _passportExpirationKey);
  }

  // Clear operations
  Future<void> clearSessionData() async {
    print('[Storage] Clearing session data only (SharedPreferences)');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  Future<void> clearSecureData() async {
    print('[Storage] Clearing secure data only');
    await _secureStorage.deleteAll();
  }
  
  Future<void> clearAll() async {
    print('[Storage] Clearing all storage (secure + session)');
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}