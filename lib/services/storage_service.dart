import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _uuidKey = 'device_uuid';
  static const String _tokenKey = 'auth_token';

  // Token operations use secure storage (persist after uninstall)
  Future<void> saveToken(String token) async => 
    await _secureStorage.write(key: _tokenKey, value: token);
  
  Future<String?> getToken() async => 
    await _secureStorage.read(key: _tokenKey);
  
  Future<void> clearToken() async => 
    await _secureStorage.delete(key: _tokenKey);

  // UUID operations use SharedPreferences (cleared on uninstall)
  Future<void> saveUUID(String uuid) async {
    print('[Storage] Saving UUID to shared preferences: $uuid');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uuidKey, uuid);
  }
  
  Future<String?> getUUID() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString(_uuidKey);
    print('[Storage] Retrieved UUID from shared preferences: $uuid');
    return uuid;
  }
  
  Future<void> clearUUID() async {
    print('[Storage] Clearing UUID from shared preferences');
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