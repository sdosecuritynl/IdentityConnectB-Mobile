import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/address.dart';

class AddressService {
  static const String _storageKey = 'addresses';
  final _storage = const FlutterSecureStorage();

  Future<List<Address>> getAddresses() async {
    try {
      final data = await _storage.read(key: _storageKey);
      if (data == null) return [];

      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => Address.fromJson(json)).toList();
    } catch (e) {
      print('[AddressService] Error getting addresses: $e');
      return [];
    }
  }

  Future<void> saveAddress(Address address) async {
    try {
      final addresses = await getAddresses();
      addresses.add(address);
      
      final jsonList = addresses.map((addr) => addr.toJson()).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(jsonList));
      
      print('[AddressService] Address saved successfully');
    } catch (e) {
      print('[AddressService] Error saving address: $e');
      throw Exception('Failed to save address');
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      final addresses = await getAddresses();
      addresses.removeWhere((addr) => addr.id == id);
      
      final jsonList = addresses.map((addr) => addr.toJson()).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(jsonList));
      
      print('[AddressService] Address deleted successfully');
    } catch (e) {
      print('[AddressService] Error deleting address: $e');
      throw Exception('Failed to delete address');
    }
  }
} 