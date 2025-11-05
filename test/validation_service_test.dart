import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/services/validation_service.dart';

void main() {
  group('ValidationService Tests', () {
    group('Email Validation', () {
      test('should accept valid email addresses', () {
        expect(ValidationService.validateEmail('test@example.com'), isNull);
        expect(
            ValidationService.validateEmail('user.name@domain.co.uk'), isNull);
        expect(ValidationService.validateEmail('user+tag@example.com'), isNull);
      });

      test('should reject empty email', () {
        expect(ValidationService.validateEmail(null), isNotNull);
        expect(ValidationService.validateEmail(''), isNotNull);
        expect(ValidationService.validateEmail('   '), isNotNull);
      });

      test('should reject invalid email formats', () {
        expect(ValidationService.validateEmail('notanemail'), isNotNull);
        expect(ValidationService.validateEmail('@example.com'), isNotNull);
        expect(ValidationService.validateEmail('user@'), isNotNull);
        expect(ValidationService.validateEmail('user@domain'), isNotNull);
      });

      test('should reject emails exceeding max length', () {
        final longEmail = 'a' * 250 + '@example.com';
        expect(ValidationService.validateEmail(longEmail), isNotNull);
      });

      test('should reject emails with dangerous patterns', () {
        expect(ValidationService.validateEmail('test<script>@example.com'),
            isNotNull);
        expect(ValidationService.validateEmail('testjavascript:@example.com'),
            isNotNull);
      });
    });

    group('Password Validation', () {
      test('should accept valid passwords', () {
        expect(ValidationService.validatePassword('password123'), isNull);
        expect(ValidationService.validatePassword('P@ssw0rd123'), isNull);
      });

      test('should reject empty password', () {
        expect(ValidationService.validatePassword(null), isNotNull);
        expect(ValidationService.validatePassword(''), isNotNull);
      });

      test('should reject passwords that are too short', () {
        expect(ValidationService.validatePassword('short'), isNotNull);
        expect(ValidationService.validatePassword('1234567'), isNotNull);
      });

      test('should reject passwords that are too long', () {
        final longPassword = 'a' * 129;
        expect(ValidationService.validatePassword(longPassword), isNotNull);
      });

      test('should require strength for new passwords', () {
        // Missing uppercase
        expect(
            ValidationService.validatePassword('password123',
                isNewPassword: true),
            isNotNull);

        // Missing lowercase
        expect(
            ValidationService.validatePassword('PASSWORD123',
                isNewPassword: true),
            isNotNull);

        // Missing number
        expect(
            ValidationService.validatePassword('Password', isNewPassword: true),
            isNotNull);

        // Valid new password
        expect(
            ValidationService.validatePassword('Password123',
                isNewPassword: true),
            isNull);
      });
    });

    group('Name Validation', () {
      test('should accept valid names', () {
        expect(ValidationService.validateName('John Doe'), isNull);
        expect(ValidationService.validateName('Mary-Jane O\'Connor'), isNull);
      });

      test('should reject empty names', () {
        expect(ValidationService.validateName(null), isNotNull);
        expect(ValidationService.validateName(''), isNotNull);
        expect(ValidationService.validateName('   '), isNotNull);
      });

      test('should reject names exceeding max length', () {
        final longName = 'a' * 101;
        expect(ValidationService.validateName(longName), isNotNull);
      });

      test('should reject names with dangerous patterns', () {
        // Test that dangerous patterns are detected
        // Note: The validation should catch these in _containsDangerousPatterns
        final dangerousName = 'John<script>alert("xss")</script>Doe';
        expect(ValidationService.validateName(dangerousName), isNotNull);

        final jsName = 'Johnjavascript:alert("xss")Doe';
        expect(ValidationService.validateName(jsName), isNotNull);
      });
    });

    group('Description Validation', () {
      test('should accept valid descriptions', () {
        expect(ValidationService.validateDescription('This is a description'),
            isNull);
        expect(ValidationService.validateDescription(null), isNull); // Optional
      });

      test('should reject descriptions exceeding max length', () {
        final longDesc = 'a' * 1001;
        expect(ValidationService.validateDescription(longDesc), isNotNull);
      });

      test('should reject descriptions with dangerous patterns', () {
        expect(
            ValidationService.validateDescription(
                '<script>alert("xss")</script>'),
            isNotNull);
      });
    });

    group('Numeric Validation', () {
      test('should accept valid numbers', () {
        expect(ValidationService.validateNumeric('123'), isNull);
        expect(ValidationService.validateNumeric('123.45'), isNull);
        expect(ValidationService.validateNumeric('0'), isNull);
      });

      test('should reject empty values', () {
        expect(ValidationService.validateNumeric(null), isNotNull);
        expect(ValidationService.validateNumeric(''), isNotNull);
      });

      test('should reject non-numeric values', () {
        expect(ValidationService.validateNumeric('abc'), isNotNull);
        expect(ValidationService.validateNumeric('12.34.56'), isNotNull);
      });

      test('should enforce min/max bounds', () {
        expect(ValidationService.validateNumeric('5', min: 10), isNotNull);
        expect(ValidationService.validateNumeric('15', max: 10), isNotNull);
        expect(
            ValidationService.validateNumeric('10', min: 5, max: 15), isNull);
      });

      test('should handle negative values', () {
        expect(ValidationService.validateNumeric('-5'),
            isNotNull); // Default: no negatives
        expect(ValidationService.validateNumeric('-5', allowNegative: true),
            isNull);
      });
    });

    group('Input Sanitization', () {
      test('should remove script tags', () {
        final input = 'Hello <script>alert("xss")</script> World';
        final sanitized = ValidationService.sanitizeInput(input);
        expect(sanitized, equals('Hello  World'));
        expect(sanitized.contains('<script>'), isFalse);
      });

      test('should remove javascript: protocol', () {
        final input = 'Click here javascript:alert("xss")';
        final sanitized = ValidationService.sanitizeInput(input);
        expect(sanitized.contains('javascript:'), isFalse);
      });

      test('should remove onEvent handlers', () {
        final input = 'Text onclick="alert(\'xss\')" more text';
        final sanitized = ValidationService.sanitizeInput(input);
        expect(sanitized.contains('onclick='), isFalse);
      });

      test('should trim whitespace', () {
        expect(ValidationService.sanitizeInput('  hello  '), equals('hello'));
      });

      test('should enforce length limits', () {
        final longInput = 'a' * 200;
        final sanitized =
            ValidationService.sanitizeInput(longInput, maxLength: 100);
        expect(sanitized.length, equals(100));
      });

      test('should handle null input', () {
        expect(ValidationService.sanitizeInput(null), equals(''));
      });
    });

    group('Phone Number Validation', () {
      test('should accept valid phone numbers', () {
        expect(ValidationService.validatePhoneNumber('+1234567890'), isNull);
        expect(ValidationService.validatePhoneNumber('123-456-7890'), isNull);
        expect(ValidationService.validatePhoneNumber('(123) 456-7890'), isNull);
      });

      test('should accept empty phone numbers (optional)', () {
        expect(ValidationService.validatePhoneNumber(null), isNull);
        expect(ValidationService.validatePhoneNumber(''), isNull);
      });

      test('should reject invalid phone numbers', () {
        expect(ValidationService.validatePhoneNumber('abc'), isNotNull);
        expect(ValidationService.validatePhoneNumber('123'),
            isNotNull); // Too short
        expect(ValidationService.validatePhoneNumber('12345678901234567'),
            isNotNull); // Too long
      });
    });

    group('URL Validation', () {
      test('should accept valid URLs', () {
        expect(ValidationService.validateUrl('https://example.com'), isNull);
        expect(ValidationService.validateUrl('http://example.com'), isNull);
      });

      test('should reject empty URLs', () {
        expect(ValidationService.validateUrl(null), isNotNull);
        expect(ValidationService.validateUrl(''), isNotNull);
      });

      test('should reject invalid URLs', () {
        expect(ValidationService.validateUrl('not-a-url'), isNotNull);
        expect(ValidationService.validateUrl('ftp://example.com'),
            isNotNull); // Must be http/https
      });
    });

    group('Date Validation', () {
      test('should accept valid dates', () {
        expect(ValidationService.validateDate('2024-01-01'), isNull);
        expect(ValidationService.validateDate('2024-01-01T12:00:00Z'), isNull);
      });

      test('should reject empty dates', () {
        expect(ValidationService.validateDate(null), isNotNull);
        expect(ValidationService.validateDate(''), isNotNull);
      });

      test('should reject invalid dates', () {
        expect(ValidationService.validateDate('not-a-date'), isNotNull);
        // DateTime.parse is lenient, so we test with clearly invalid formats
        expect(
            ValidationService.validateDate('invalid-date-format'), isNotNull);
        expect(ValidationService.validateDate('abc'), isNotNull);
      });
    });
  });
}
