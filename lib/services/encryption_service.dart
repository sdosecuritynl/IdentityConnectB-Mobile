import 'dart:convert';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _publicKeyKey = 'public_key';
  static const String _privateKeyKey = 'private_key';
  final _storage = const FlutterSecureStorage();

  // Generate key pair if not exists
  Future<void> generateKeyPairIfNeeded() async {
    print('[Encryption] Checking for existing key pair...');
    final publicKey = await _storage.read(key: _publicKeyKey);
    final privateKey = await _storage.read(key: _privateKeyKey);

    if (publicKey == null || privateKey == null) {
      print('[Encryption] No existing key pair found, generating new pair...');
      try {
        final keyPair = await RSA.generate(2048);
        await _storage.write(key: _publicKeyKey, value: keyPair.publicKey);
        await _storage.write(key: _privateKeyKey, value: keyPair.privateKey);
        print('[Encryption] Key pair generated and stored successfully');
      } catch (e) {
        print('[Encryption] Error generating key pair: $e');
        throw Exception('Failed to generate key pair: $e');
      }
    } else {
      print('[Encryption] Existing key pair found');
    }
  }

  // Fetch public key
  Future<String> getPublicKey() async {
    print('[Encryption] Fetching public key...');
    try {
      final publicKey = await _storage.read(key: _publicKeyKey);
      if (publicKey == null) {
        print('[Encryption] No public key found, generating new pair...');
        await generateKeyPairIfNeeded();
        return await _storage.read(key: _publicKeyKey) ?? '';
      }
      print('[Encryption] Public key fetched successfully');
      return publicKey;
    } catch (e) {
      print('[Encryption] Error fetching public key: $e');
      throw Exception('Failed to fetch public key: $e');
    }
  }

  // Fetch private key
  Future<String> getPrivateKey() async {
    print('[Encryption] Fetching private key...');
    try {
      final privateKey = await _storage.read(key: _privateKeyKey);
      if (privateKey == null) {
        print('[Encryption] No private key found, generating new pair...');
        await generateKeyPairIfNeeded();
        return await _storage.read(key: _privateKeyKey) ?? '';
      }
      print('[Encryption] Private key fetched successfully');
      return privateKey;
    } catch (e) {
      print('[Encryption] Error fetching private key: $e');
      throw Exception('Failed to fetch private key: $e');
    }
  }

  // Encrypt dictionary using public key
  Future<String> encrypt(Map<String, dynamic> data, String publicKey) async {
    print('[Encryption] Starting encryption process...');
    try {
      // Convert dictionary to JSON string
      final jsonStr = jsonEncode(data);
      print('[Encryption] Data converted to JSON successfully');

      // Encrypt the JSON string
      final encrypted = await RSA.encryptPKCS1v15(jsonStr, publicKey);
      print('[Encryption] Data encrypted successfully');

      return encrypted;
    } catch (e) {
      print('[Encryption] Error during encryption: $e');
      throw Exception('Failed to encrypt data: $e');
    }
  }

  // Decrypt data using private key (for testing purposes)
  Future<Map<String, dynamic>> decrypt(String encryptedData, String privateKey) async {
    print('[Encryption] Starting decryption process...');
    try {
      // Decrypt the data
      final decrypted = await RSA.decryptPKCS1v15(encryptedData, privateKey);
      print('[Encryption] Data decrypted successfully');

      // Parse JSON string back to dictionary
      final data = jsonDecode(decrypted) as Map<String, dynamic>;
      print('[Encryption] Data parsed back to dictionary successfully');

      return data;
    } catch (e) {
      print('[Encryption] Error during decryption: $e');
      throw Exception('Failed to decrypt data: $e');
    }
  }
} 