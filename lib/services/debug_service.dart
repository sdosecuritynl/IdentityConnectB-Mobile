import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DebugService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> printAllStoredData() async {
    print('================ STORED DATA REPORT ================');
    // SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    print('\SharedPreferences:');
    if (keys.isEmpty) {
      print('  (empty)');
    } else {
      for (final key in keys) {
        final value = prefs.get(key);
        print('  $key: ${_formatValue(value)}');
      }
    }

    // SecureStorage
    final secureData = await _secureStorage.readAll();
    print('\SecureStorage:');
    if (secureData.isEmpty) {
      print('  (empty)');
    } else {
      for (final entry in secureData.entries) {
        print('  ${entry.key}: ${_formatValue(entry.value)}');
      }
    }
    print('====================================================\n');
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      try {
        final jsonVal = jsonDecode(value);
        return const JsonEncoder.withIndent('  ').convert(jsonVal);
      } catch (_) {
        return value;
      }
    }
    return value.toString();
  }
} 