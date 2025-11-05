import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for secure storage of sensitive data (passwords, tokens, etc.)
/// Uses flutter_secure_storage which encrypts data on device
class SecureStorageService {
  // iOS options - keychain accessible when device is unlocked
  static const _iosOptions = IOSOptions();

  // Android options - encrypted shared preferences
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // Web options - use localStorage (less secure, but required for web)
  static const _webOptions = WebOptions();

  static const _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
    webOptions: _webOptions,
  );

  /// Save a password securely
  /// Key format: "password_<userId>"
  static Future<void> savePassword(String userId, String password) async {
    try {
      final key = 'password_$userId';
      await _storage.write(key: key, value: password);
      if (kDebugMode) {
        print(
            'DEBUG: Password saved securely for user: ${_sanitizeUserId(userId)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error saving password to secure storage: $e');
      }
      rethrow;
    }
  }

  /// Get a password from secure storage
  /// Returns null if not found
  static Future<String?> getPassword(String userId) async {
    try {
      final key = 'password_$userId';
      final password = await _storage.read(key: key);
      if (kDebugMode && password != null) {
        print(
            'DEBUG: Password retrieved from secure storage for user: ${_sanitizeUserId(userId)}');
      }
      return password;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error reading password from secure storage: $e');
      }
      return null;
    }
  }

  /// Delete a password from secure storage
  static Future<void> deletePassword(String userId) async {
    try {
      final key = 'password_$userId';
      await _storage.delete(key: key);
      if (kDebugMode) {
        print(
            'DEBUG: Password deleted from secure storage for user: ${_sanitizeUserId(userId)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error deleting password from secure storage: $e');
      }
    }
  }

  /// Get all password keys (for migration)
  static Future<List<String>> getAllPasswordKeys() async {
    try {
      final allKeys = await _storage.readAll();
      return allKeys.keys
          .where((key) => key.startsWith('password_'))
          .map((key) => key.substring(9)) // Remove 'password_' prefix
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error reading all password keys: $e');
      }
      return [];
    }
  }

  /// Delete all passwords (for testing/reset)
  static Future<void> deleteAllPasswords() async {
    try {
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith('password_')) {
          await _storage.delete(key: key);
        }
      }
      if (kDebugMode) {
        print('DEBUG: All passwords deleted from secure storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error deleting all passwords: $e');
      }
    }
  }

  /// Sanitize user ID for logging (show first 6 chars only)
  static String _sanitizeUserId(String userId) {
    if (userId.length <= 6) {
      return '***';
    }
    return '${userId.substring(0, 6)}...';
  }
}
