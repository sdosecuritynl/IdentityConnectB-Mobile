import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _uuidKey = 'device_uuid';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'user_email';
  static const String _phoneKey = 'user_phone';

  // Token operations use SharedPreferences (cleared on uninstall)
  Future<void> saveToken(String token) async {
    print('[Storage] Saving token to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // Ensure it's not in secure storage
    await _secureStorage.delete(key: _tokenKey);
  }
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    // Check if it's in secure storage and migrate if found
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null) {
      print('[Storage] Found token in secure storage, migrating to SharedPreferences');
      await saveToken(secureToken);
      return secureToken;
    }
    
    return token;
  }
  
  Future<void> clearToken() async {
    print('[Storage] Clearing token from all storages');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await _secureStorage.delete(key: _tokenKey);
  }

  // Refresh token operations
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

  // Email operations
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

  // Phone number operations
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

  // UUID operations use secure storage (persist after uninstall)
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

  // Clear all storage
  Future<void> clearAll() async {
    print('[Storage] Clearing all storage');
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}