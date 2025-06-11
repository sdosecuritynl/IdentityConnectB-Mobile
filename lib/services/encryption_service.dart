import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _publicKeyKey = 'public_key';
  static const String _privateKeyKey = 'private_key';
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  // Generate RSA key pair
  Future<AsymmetricKeyPair<PublicKey, PrivateKey>> _generateRSAKeyPair(SecureRandom secureRandom) async {
    print('[Encryption] Configuring RSA key generator...');
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        secureRandom,
      ));

    print('[Encryption] Generating RSA key pair...');
    return keyGen.generateKeyPair();
  }

  // Convert public key to PEM format
  String _publicKeyToPem(RSAPublicKey publicKey) {
    return CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
  }

  // Convert private key to PEM format
  String _privateKeyToPem(RSAPrivateKey privateKey) {
    return CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
  }

  // Check if secure storage is accessible
  Future<bool> _checkStorageAccess() async {
    try {
      print('[Encryption] Testing secure storage access...');
      const testKey = 'storage_test';
      const testValue = 'test_value';
      
      await _storage.write(key: testKey, value: testValue);
      final readValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      
      if (readValue == testValue) {
        print('[Encryption] Secure storage access test successful');
        return true;
      } else {
        print('[Encryption] Secure storage access test failed: values do not match');
        return false;
      }
    } catch (e) {
      print('[Encryption] Secure storage access test failed with error: $e');
      return false;
    }
  }

  // Generate key pair if not exists
  Future<void> generateKeyPairIfNeeded() async {
    print('[Encryption] Starting key pair generation/verification process...');
    
    if (!await _checkStorageAccess()) {
      throw Exception('Cannot access secure storage. Please check app permissions and try again.');
    }

    try {
      final publicKey = await _storage.read(key: _publicKeyKey);
      final privateKey = await _storage.read(key: _privateKeyKey);
      print('[Encryption] Successfully read from secure storage. Public key exists: ${publicKey != null}, Private key exists: ${privateKey != null}');

      if (publicKey == null || privateKey == null) {
        print('[Encryption] No existing key pair found, generating new pair...');
        try {
          // Create a secure random number generator
          final secureRandom = FortunaRandom();
          final random = Random.secure();
          final seeds = List<int>.generate(32, (i) => random.nextInt(256));
          secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

          // Generate the RSA key pair
          final keyPair = await _generateRSAKeyPair(secureRandom);
          print('[Encryption] Key pair generated, converting to PEM format...');

          // Convert keys to PEM format
          final publicKeyPem = _publicKeyToPem(keyPair.publicKey as RSAPublicKey);
          final privateKeyPem = _privateKeyToPem(keyPair.privateKey as RSAPrivateKey);
          
          print('[Encryption] Storing keys...');
          await _storage.write(key: _publicKeyKey, value: publicKeyPem);
          print('[Encryption] Public key stored successfully');
          
          await _storage.write(key: _privateKeyKey, value: privateKeyPem);
          print('[Encryption] Private key stored successfully');
          
          print('[Encryption] Key pair generated and stored successfully');
        } catch (e) {
          print('[Encryption] Error during key generation: $e');
          throw Exception('Failed to generate RSA key pair: $e');
        }
      } else {
        print('[Encryption] Existing key pair found');
      }
    } catch (e) {
      print('[Encryption] Fatal error in generateKeyPairIfNeeded: $e');
      throw Exception('Failed to setup encryption: $e');
    }
  }

  // Get public key
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

  // Get private key
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

  // Encrypt data
  Future<String> encrypt(Map<String, dynamic> data, String publicKeyPem) async {
    print('[Encryption] Starting encryption process...');
    try {
      // Convert data to JSON string
      final jsonStr = jsonEncode(data);
      final dataToEncrypt = Uint8List.fromList(utf8.encode(jsonStr));
      print('[Encryption] Data converted to bytes successfully');

      // Parse PEM public key
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);

      // Create encrypter
      final cipher = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      // Encrypt data
      final encrypted = cipher.process(dataToEncrypt);
      print('[Encryption] Data encrypted successfully');

      return base64.encode(encrypted);
    } catch (e) {
      print('[Encryption] Error during encryption: $e');
      throw Exception('Failed to encrypt data: $e');
    }
  }

  // Decrypt data
  Future<Map<String, dynamic>> decrypt(String encryptedBase64, String privateKeyPem) async {
    print('[Encryption] Starting decryption process...');
    try {
      final encrypted = base64.decode(encryptedBase64);
      
      // Parse PEM private key
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

      // Create decrypter
      final cipher = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      // Decrypt data
      final decrypted = cipher.process(Uint8List.fromList(encrypted));
      print('[Encryption] Data decrypted successfully');

      // Parse JSON string back to dictionary
      final jsonStr = utf8.decode(decrypted);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      print('[Encryption] Data parsed back to dictionary successfully');

      return data;
    } catch (e) {
      print('[Encryption] Error during decryption: $e');
      throw Exception('Failed to decrypt data: $e');
    }
  }
} 