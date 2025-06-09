import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _uuidKey = 'device_uuid';
  static const String _tokenKey = 'auth_token';

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