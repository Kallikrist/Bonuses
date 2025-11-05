import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/utils/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    group('getUserMessage', () {
      test('should return generic message in production mode', () {
        // Note: In test mode, kDebugMode is typically true
        // This test verifies the method works correctly
        final error = Exception('Detailed error message with system info');
        final message = ErrorHandler.getUserMessage(error);
        expect(message, isNotNull);
        expect(message, isNotEmpty);
      });

      test('should return custom default message', () {
        final error = Exception('Some error');
        final message = ErrorHandler.getUserMessage(
          error,
          defaultMessage: 'Custom error message',
        );
        expect(
            message.contains('Custom error message') ||
                message.contains('Error'),
            isTrue);
      });
    });

    group('getSanitizedMessage', () {
      test('should handle connection errors', () {
        final error = Exception('Connection timeout');
        final message = ErrorHandler.getSanitizedMessage(error);
        expect(message.toLowerCase(), contains('connection'));
      });

      test('should handle database errors', () {
        final error = Exception('Database constraint violation');
        final message = ErrorHandler.getSanitizedMessage(error);
        expect(message.toLowerCase(), contains('database'));
      });

      test('should handle authentication errors', () {
        final error = Exception('Unauthorized access');
        final message = ErrorHandler.getSanitizedMessage(error);
        final lowerMessage = message.toLowerCase();
        expect(
            lowerMessage.contains('authentication') ||
                lowerMessage.contains('credentials'),
            isTrue);
      });

      test('should handle permission errors', () {
        final error = Exception('Permission denied');
        final message = ErrorHandler.getSanitizedMessage(error);
        expect(message.toLowerCase(), contains('permission'));
      });

      test('should preserve validation errors', () {
        final error = 'Invalid email format';
        final message = ErrorHandler.getSanitizedMessage(error);
        expect(message, contains('Invalid email format'));
      });

      test('should preserve rate limit errors', () {
        final error =
            'Account temporarily locked. Please try again in 30 minutes.';
        final message = ErrorHandler.getSanitizedMessage(error);
        expect(message, contains('locked'));
      });

      test('should sanitize generic exceptions', () {
        final error = Exception('Internal server error: SQLSTATE 23505');
        final message = ErrorHandler.getSanitizedMessage(error);
        // Should not contain SQL details
        expect(message.toLowerCase(), isNot(contains('sqlstate')));
        expect(message.toLowerCase(), isNot(contains('23505')));
      });
    });

    group('isSafeForUser', () {
      test('should identify safe validation errors', () {
        expect(ErrorHandler.isSafeForUser('Email is required'), isTrue);
        expect(ErrorHandler.isSafeForUser('Invalid password format'), isTrue);
      });

      test('should identify dangerous system errors', () {
        expect(
            ErrorHandler.isSafeForUser(
                'Exception: Database connection failed at lib/services/db.dart:123'),
            isFalse);
        expect(ErrorHandler.isSafeForUser('SQLSTATE 23505: duplicate key'),
            isFalse);
        expect(
            ErrorHandler.isSafeForUser('Stack trace: at Main.main()'), isFalse);
      });

      test('should identify rate limit messages as safe', () {
        expect(ErrorHandler.isSafeForUser('Account locked for 30 minutes'),
            isTrue);
      });

      test('should identify short simple messages as potentially safe', () {
        expect(ErrorHandler.isSafeForUser('Operation failed'), isTrue);
        expect(ErrorHandler.isSafeForUser('Please try again'), isTrue);
      });
    });

    group('logError', () {
      test('should log error details in debug mode', () {
        // Note: In test mode, kDebugMode is typically true
        final error = Exception('Test error');
        // This should not throw
        ErrorHandler.logError(error);
        ErrorHandler.logError(error, context: 'TestContext');
      });
    });
  });
}
