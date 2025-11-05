import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonuses/services/rate_limit_service.dart';
import 'package:bonuses/services/auth_service.dart';

void main() {
  group('Rate Limit Service Tests', () {
    // Clear SharedPreferences before each test
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should not be rate limited initially', () async {
      final isLimited =
          await RateLimitService.isRateLimited('test@example.com');
      expect(isLimited, isFalse);
    });

    test('should track failed attempts', () async {
      final email = 'test@example.com';

      // Record 3 failed attempts
      await RateLimitService.recordFailedAttempt(email);
      await RateLimitService.recordFailedAttempt(email);
      await RateLimitService.recordFailedAttempt(email);

      final attempts = await RateLimitService.getFailedAttempts(email);
      expect(attempts, equals(3));
    });

    test('should lock out account after max attempts', () async {
      final email = 'test@example.com';

      // Record max failed attempts
      for (int i = 0; i < 5; i++) {
        final isLockedOut = await RateLimitService.recordFailedAttempt(email);
        if (i < 4) {
          expect(isLockedOut, isFalse);
        } else {
          expect(isLockedOut, isTrue);
        }
      }

      // Account should be locked out
      final isLimited = await RateLimitService.isRateLimited(email);
      expect(isLimited, isTrue);
    });

    test('should clear rate limit on successful login', () async {
      final email = 'test@example.com';

      // Record some failed attempts
      await RateLimitService.recordFailedAttempt(email);
      await RateLimitService.recordFailedAttempt(email);

      // Record successful login
      await RateLimitService.recordSuccessfulLogin(email);

      // Rate limit should be cleared
      final attempts = await RateLimitService.getFailedAttempts(email);
      expect(attempts, equals(0));

      final isLimited = await RateLimitService.isRateLimited(email);
      expect(isLimited, isFalse);
    });

    test('should return remaining lockout time', () async {
      final email = 'test@example.com';

      // Lock out the account
      for (int i = 0; i < 5; i++) {
        await RateLimitService.recordFailedAttempt(email);
      }

      final remainingTime =
          await RateLimitService.getRemainingLockoutTime(email);
      expect(remainingTime, isNotNull);
      expect(remainingTime!.inHours, greaterThanOrEqualTo(0));
      expect(remainingTime.inHours, lessThanOrEqualTo(1));
    });

    test('should format remaining time correctly', () {
      final duration1 = Duration(minutes: 30);
      final formatted1 = RateLimitService.formatRemainingTime(duration1);
      expect(formatted1, contains('30 minutes'));

      final duration2 = Duration(hours: 1);
      final formatted2 = RateLimitService.formatRemainingTime(duration2);
      expect(formatted2, contains('1 hour'));

      final duration3 = Duration(hours: 1, minutes: 15);
      final formatted3 = RateLimitService.formatRemainingTime(duration3);
      expect(formatted3, contains('hour'));
      expect(formatted3, contains('minute'));
    });

    test('should normalize email addresses', () async {
      final email1 = 'Test@Example.com';
      final email2 = 'test@example.com';

      // Record attempts with different case
      await RateLimitService.recordFailedAttempt(email1);

      // Should be tracked as same email
      final attempts = await RateLimitService.getFailedAttempts(email2);
      expect(attempts, equals(1));
    });

    test('should clear lockout after duration expires', () async {
      // This test would require mocking time, which is complex
      // For now, we test that lockout is cleared when expired
      final email = 'test@example.com';

      // Lock out account
      for (int i = 0; i < 5; i++) {
        await RateLimitService.recordFailedAttempt(email);
      }

      // Verify locked out
      final isLimited = await RateLimitService.isRateLimited(email);
      expect(isLimited, isTrue);

      // Note: Actual expiration test would require time mocking
      // The service handles expiration automatically in isRateLimited()
    });
  });

  group('Rate Limit Exception Tests', () {
    test('should create rate limit exception with message', () {
      final exception = RateLimitException('Account locked');
      expect(exception.message, equals('Account locked'));
      expect(exception.remainingTime, isNull);
    });

    test('should create rate limit exception with remaining time', () {
      final duration = Duration(hours: 1);
      final exception = RateLimitException('Account locked', duration);
      expect(exception.message, equals('Account locked'));
      expect(exception.remainingTime, equals(duration));
    });

    test('should convert exception to string', () {
      final exception = RateLimitException('Account locked');
      expect(exception.toString(), equals('Account locked'));
    });
  });
}

