import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:logger/logger.dart';

/// Service for managing encrypted local database using Sembast
class EncryptedDatabaseService {
  static const String _dbName = 'chime_encrypted.db';
  static const String _encryptionKeyKey = 'db_encryption_key';
  static const String _encryptionIvKey = 'db_encryption_iv';

  final Logger _log = Logger();
  Database? _database;
  final FlutterSecureStorage _secureStorage;
  late final Key _encryptionKey;
  late final IV _encryptionIv;

  EncryptedDatabaseService(this._secureStorage);

  /// Initialize the database and encryption keys
  Future<void> initialize() async {
    try {
      // Ensure encryption keys exist
      await _ensureEncryptionKeys();

      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, _dbName);

      // Open the database
      _database = await databaseFactoryIo.openDatabase(dbPath);
      _log.d('EncryptedDatabaseService: Database initialized at $dbPath');
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error initializing database: $e');
      rethrow;
    }
  }

  /// Ensure encryption keys exist, create if they don't
  Future<void> _ensureEncryptionKeys() async {
    try {
      String? keyString = await _secureStorage.read(key: _encryptionKeyKey);
      String? ivString = await _secureStorage.read(key: _encryptionIvKey);

      if (keyString == null || ivString == null) {
        // Generate new encryption key and IV
        final key = Key.fromSecureRandom(32); // AES-256 key
        final iv = IV.fromSecureRandom(16); // AES block size

        // Store them securely
        await _secureStorage.write(key: _encryptionKeyKey, value: key.base64);
        await _secureStorage.write(key: _encryptionIvKey, value: iv.base64);

        _encryptionKey = key;
        _encryptionIv = iv;
        _log.d('EncryptedDatabaseService: Generated new encryption keys');
      } else {
        // Load existing keys
        _encryptionKey = Key.fromBase64(keyString);
        _encryptionIv = IV.fromBase64(ivString);
        _log.d('EncryptedDatabaseService: Loaded existing encryption keys');
      }
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error ensuring encryption keys: $e');
      rethrow;
    }
  }

  /// Encrypt data before storing
  String _encrypt(String plainText) {
    try {
      final encrypter = Encrypter(AES(_encryptionKey, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: _encryptionIv);
      return encrypted.base64;
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error encrypting data: $e');
      rethrow;
    }
  }

  /// Decrypt data after retrieving
  String _decrypt(String encryptedText) {
    try {
      final encrypter = Encrypter(AES(_encryptionKey, mode: AESMode.cbc));
      final encrypted = Encrypted.fromBase64(encryptedText);
      return encrypter.decrypt(encrypted, iv: _encryptionIv);
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error decrypting data: $e');
      rethrow;
    }
  }

  /// Get the database instance
  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Store data in an encrypted store
  Future<void> put(String storeName, String key, dynamic value) async {
    try {
      final store = stringMapStoreFactory.store(storeName);
      final jsonString = jsonEncode(value);
      final encryptedValue = _encrypt(jsonString);
      await store.record(key).put(database, {'data': encryptedValue});
      _log.d('EncryptedDatabaseService: Stored data in $storeName with key $key');
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error storing data: $e');
      rethrow;
    }
  }

  /// Get data from an encrypted store
  Future<dynamic> get(String storeName, String key) async {
    try {
      final store = stringMapStoreFactory.store(storeName);
      final record = await store.record(key).get(database);
      if (record == null) {
        return null;
      }
      final encryptedValue = record['data'] as String;
      final decryptedValue = _decrypt(encryptedValue);
      return jsonDecode(decryptedValue);
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error retrieving data: $e');
      rethrow;
    }
  }

  /// Get all records from a store
  Future<List<dynamic>> getAll(String storeName) async {
    try {
      final store = stringMapStoreFactory.store(storeName);
      final records = await store.find(database);
      final List<dynamic> result = [];
      for (final record in records) {
        try {
          final encryptedValue = (record.value as Map)['data'] as String;
          final decryptedValue = _decrypt(encryptedValue);
          result.add(jsonDecode(decryptedValue));
        } catch (e) {
          _log.w('EncryptedDatabaseService: Error decrypting record ${record.key}: $e');
        }
      }
      return result;
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error retrieving all data: $e');
      rethrow;
    }
  }

  /// Delete a record from a store
  Future<void> delete(String storeName, String key) async {
    try {
      final store = stringMapStoreFactory.store(storeName);
      await store.record(key).delete(database);
      _log.d('EncryptedDatabaseService: Deleted data from $storeName with key $key');
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error deleting data: $e');
      rethrow;
    }
  }

  /// Clear all data from a store
  Future<void> clearStore(String storeName) async {
    try {
      final store = stringMapStoreFactory.store(storeName);
      await store.delete(database);
      _log.d('EncryptedDatabaseService: Cleared store $storeName');
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error clearing store: $e');
      rethrow;
    }
  }

  /// Check if a key exists in a store
  Future<bool> exists(String storeName, String key) async {
    try {
      final store = stringMapStoreFactory.store(storeName);
      final record = await store.record(key).get(database);
      return record != null;
    } catch (e) {
      _log.e('EncryptedDatabaseService: Error checking existence: $e');
      return false;
    }
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _log.d('EncryptedDatabaseService: Database closed');
  }
}
