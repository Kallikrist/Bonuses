import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart' as crypto_lib;

/// Service for hashing and verifying passwords
/// Uses bcrypt for password hashing (upgraded from SHA-256)
/// Supports migration from legacy SHA-256 hashes
class PasswordService {
  /// Hash a password using bcrypt
  /// Returns: bcrypt hash string (includes salt automatically)
  /// Uses default rounds (10) which is a good balance of security and performance
  static String hashPassword(String password) {
    final salt = BCrypt.gensalt();
    return BCrypt.hashpw(password, salt);
  }

  /// Verify a password against a stored hash
  /// Supports multiple hash formats:
  /// - bcrypt: Modern format (starts with $2a$, $2b$, or $2y$)
  /// - SHA-256: Legacy format (salt:hash)
  /// - Plaintext: Legacy format (for migration)
  static bool verifyPassword(String password, String storedHash) {
    try {
      // Handle legacy plaintext passwords (for migration)
      if (isPlaintext(storedHash)) {
        return false; // Will trigger re-hash on successful login
      }

      // Check if it's a bcrypt hash (starts with $2a$, $2b$, or $2y$)
      if (isBcryptHash(storedHash)) {
        return BCrypt.checkpw(password, storedHash);
      }

      // Handle legacy SHA-256 hashes (for backward compatibility)
      if (isSha256Hash(storedHash)) {
        return _verifySha256Password(password, storedHash);
      }

      // Unknown format
      if (kDebugMode) {
        print('DEBUG: Unknown password hash format');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error verifying password: $e');
      }
      return false;
    }
  }

  /// Check if a stored hash is in plaintext format (for migration)
  static bool isPlaintext(String storedHash) {
    // Plaintext passwords don't contain ':' and don't start with '$'
    return !storedHash.contains(':') && !storedHash.startsWith('\$');
  }

  /// Check if a hash is in bcrypt format
  static bool isBcryptHash(String storedHash) {
    return storedHash.startsWith('\$2a\$') ||
        storedHash.startsWith('\$2b\$') ||
        storedHash.startsWith('\$2y\$');
  }

  /// Check if a hash is in legacy SHA-256 format
  static bool isSha256Hash(String storedHash) {
    // SHA-256 format: "salt:hash" (salt is base64-like, hash is hex)
    return storedHash.contains(':') && !storedHash.startsWith('\$');
  }

  /// Verify password against legacy SHA-256 hash
  /// This is kept for backward compatibility during migration
  static bool _verifySha256Password(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) {
        return false;
      }

      final salt = parts[0];
      final storedPasswordHash = parts[1];

      // Hash the provided password with the stored salt using SHA-256
      final bytes = utf8.encode(password + salt);
      final hash = _getSha256Digest(bytes);
      final providedHash = hash.toString();

      // Constant-time comparison
      return _constantTimeEquals(providedHash, storedPasswordHash);
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error verifying SHA-256 password: $e');
      }
      return false;
    }
  }

  /// Get crypto library for legacy SHA-256 verification
  static crypto_lib.Digest _getSha256Digest(List<int> bytes) {
    return crypto_lib.sha256.convert(bytes);
  }

  /// Constant-time string comparison to prevent timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Re-hash a password using the new bcrypt algorithm
  /// Used for migrating from plaintext or SHA-256 to bcrypt
  static String rehashPassword(String plaintextPassword) {
    return hashPassword(plaintextPassword);
  }

  /// Check if a password hash needs to be upgraded
  /// Returns true if hash is plaintext or SHA-256 (needs upgrade to bcrypt)
  static bool needsUpgrade(String storedHash) {
    return isPlaintext(storedHash) || isSha256Hash(storedHash);
  }
}
