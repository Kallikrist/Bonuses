import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/services/password_service.dart';
import 'package:bonuses/providers/app_provider.dart';

void main() {
  group('Security Sanitization Tests', () {
    group('Password Service', () {
      test('should hash password and return bcrypt format', () {
        final password = 'testpassword123';
        final hashed = PasswordService.hashPassword(password);

        // Should be in bcrypt format (starts with $2a$, $2b$, or $2y$)
        expect(PasswordService.isBcryptHash(hashed), isTrue);

        // Should not contain the plaintext password
        expect(hashed.contains(password), isFalse);

        // Should be different on each call (due to random salt)
        final hashed2 = PasswordService.hashPassword(password);
        expect(hashed, isNot(equals(hashed2)));
      });

      test('should verify correct password against hash', () {
        final password = 'testpassword123';
        final hashed = PasswordService.hashPassword(password);

        final isValid = PasswordService.verifyPassword(password, hashed);
        expect(isValid, isTrue);
      });

      test('should reject incorrect password', () {
        final password = 'testpassword123';
        final wrongPassword = 'wrongpassword';
        final hashed = PasswordService.hashPassword(password);

        final isValid = PasswordService.verifyPassword(wrongPassword, hashed);
        expect(isValid, isFalse);
      });

      test('should identify plaintext passwords', () {
        expect(PasswordService.isPlaintext('plaintext'), isTrue);
        expect(PasswordService.isPlaintext('password123'), isTrue);
        expect(PasswordService.isPlaintext('salt:hash'), isFalse);
        expect(PasswordService.isPlaintext('abc123:def456'), isFalse);
        expect(
            PasswordService.isPlaintext('\$2a\$10\$hash'), isFalse); // bcrypt
      });

      test('should identify bcrypt hashes', () {
        final bcryptHash = PasswordService.hashPassword('test123');
        expect(PasswordService.isBcryptHash(bcryptHash), isTrue);
        expect(PasswordService.isBcryptHash('\$2a\$10\$abcdefgh'), isTrue);
        expect(PasswordService.isBcryptHash('\$2b\$10\$abcdefgh'), isTrue);
        expect(PasswordService.isBcryptHash('salt:hash'), isFalse); // SHA-256
        expect(PasswordService.isBcryptHash('plaintext'), isFalse);
      });

      test('should identify SHA-256 hashes', () {
        expect(PasswordService.isSha256Hash('salt:hash'), isTrue);
        expect(PasswordService.isSha256Hash('abc123:def456'), isTrue);
        expect(
            PasswordService.isSha256Hash('\$2a\$10\$hash'), isFalse); // bcrypt
        expect(PasswordService.isSha256Hash('plaintext'), isFalse);
      });

      test('should verify legacy SHA-256 hashes via package:crypto', () {
        // Product SHA-256 path: utf8(password + salt) then sha256.convert.
        // hashPassword() now emits bcrypt, so this constructs the legacy format.
        const password = 'testpassword123';
        const salt = 'testsalt';
        final digest =
            crypto_lib.sha256.convert(utf8.encode(password + salt));
        final legacyHash = '$salt:${digest.toString()}';

        expect(PasswordService.isSha256Hash(legacyHash), isTrue);
        expect(PasswordService.needsUpgrade(legacyHash), isTrue);
        expect(PasswordService.verifyPassword(password, legacyHash), isTrue);
        expect(PasswordService.verifyPassword('wrongpassword', legacyHash),
            isFalse);
      });

      test('sha256.convert matches NIST empty-string and abc vectors', () {
        expect(
          crypto_lib.sha256.convert(utf8.encode('')).toString(),
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        );
        expect(
          crypto_lib.sha256.convert(utf8.encode('abc')).toString(),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        );
      });

      test('pubspec pins crypto 3.0.8 after the dependabot bump', () {
        final yaml = File('pubspec.yaml').readAsStringSync();
        final lock = File('pubspec.lock').readAsStringSync();
        expect(yaml, contains('crypto: ^3.0.8'));
        expect(
          RegExp(r'  crypto:\n(?:    .*\n)*    version: "3\.0\.8"',
                  multiLine: true)
              .hasMatch(lock),
          isTrue,
        );
      });

      test('should detect if password needs upgrade', () {
        expect(PasswordService.needsUpgrade('plaintext'), isTrue);
        expect(PasswordService.needsUpgrade('salt:hash'), isTrue); // SHA-256
        expect(
            PasswordService.needsUpgrade(PasswordService.hashPassword('test')),
            isFalse); // bcrypt
      });
    });

    group('ID Sanitization', () {
      test('should sanitize long IDs (show first 6 chars)', () {
        final longId = '1761702124040_very_long_user_id';
        final sanitized = AppProvider.sanitizeId(longId);

        expect(sanitized, equals('176170...'));
        expect(sanitized.length, lessThan(longId.length));
        expect(sanitized.contains('...'), isTrue);
        // Verify the original ID is not exposed
        expect(sanitized, isNot(equals(longId)));
      });

      test('should sanitize short IDs (show ***)', () {
        final shortId = 'admin1';
        final sanitized = AppProvider.sanitizeId(shortId);

        expect(sanitized, equals('***'));
        // Even short IDs should be sanitized
        expect(sanitized, isNot(equals(shortId)));
      });

      test('should sanitize IDs of exactly 6 characters', () {
        final id = '123456';
        final sanitized = AppProvider.sanitizeId(id);

        expect(sanitized, equals('***'));
      });

      test('should sanitize IDs of 7 characters', () {
        final id = '1234567';
        final sanitized = AppProvider.sanitizeId(id);

        expect(sanitized, equals('123456...'));
      });

      test('should not expose full user IDs', () {
        final sensitiveIds = [
          'admin1',
          '1761702124040',
          'company_1762212736183',
          'sample_target_2015',
          '1761952761774_redeem_bonus2',
        ];

        for (final id in sensitiveIds) {
          final sanitized = AppProvider.sanitizeId(id);
          // Sanitized version should never be the full ID (unless it's very short)
          if (id.length > 6) {
            expect(sanitized, isNot(equals(id)));
            expect(sanitized.length, lessThan(id.length));
          }
        }
      });

      test('should sanitize various ID formats consistently', () {
        final testCases = [
          {'input': 'emp1', 'expected': '***'},
          {'input': 'emp2', 'expected': '***'},
          {'input': 'admin1', 'expected': '***'},
          {'input': '1761702124040', 'expected': '176170...'},
          {'input': 'company_1762212736183', 'expected': 'compan...'},
          {'input': 'sample_target_2015', 'expected': 'sample...'},
        ];

        for (final testCase in testCases) {
          final sanitized = AppProvider.sanitizeId(testCase['input'] as String);
          expect(sanitized, equals(testCase['expected']));
        }
      });
    });

    group('Password Storage Security', () {
      test('should not expose password in hash verification logs', () {
        // This test verifies that we don't log passwords
        // In practice, we check that PasswordService methods don't expose plaintext
        final password = 'sensitive_password';
        final hashed = PasswordService.hashPassword(password);

        // The hash should not contain the password
        expect(hashed.contains(password), isFalse);

        // Verification should work without exposing the password
        final isValid = PasswordService.verifyPassword(password, hashed);
        expect(isValid, isTrue);
      });

      test('should handle password migration securely', () {
        // Test that plaintext passwords are migrated to hashed without exposure
        final plaintextPassword = 'password123';

        // Simulate migration: hash a plaintext password
        final hashed = PasswordService.hashPassword(plaintextPassword);

        // Verify the plaintext is not in the hash
        expect(hashed.contains(plaintextPassword), isFalse);

        // Verify we can still check if it's plaintext
        expect(PasswordService.isPlaintext(plaintextPassword), isTrue);
        expect(PasswordService.isPlaintext(hashed), isFalse);
      });
    });
  });
}
