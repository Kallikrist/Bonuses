import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle rate limiting for authentication attempts
/// Prevents brute force attacks by limiting failed login attempts
class RateLimitService {
  // Configuration constants
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(hours: 1);
  static const String _failedAttemptsPrefix = 'rate_limit_attempts_';
  static const String _lockoutUntilPrefix = 'rate_limit_lockout_';

  /// Check if an email is currently rate limited (locked out)
  /// Returns true if locked out, false otherwise
  static Future<bool> isRateLimited(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = _normalizeEmail(email);
      final lockoutUntilKey = '$_lockoutUntilPrefix$normalizedEmail';

      // Check if there's a lockout timestamp
      final lockoutUntilTimestamp = prefs.getInt(lockoutUntilKey);
      if (lockoutUntilTimestamp == null) {
        return false; // No lockout
      }

      final lockoutUntil =
          DateTime.fromMillisecondsSinceEpoch(lockoutUntilTimestamp);
      final now = DateTime.now();

      // If lockout period has expired, clear it and allow login
      if (now.isAfter(lockoutUntil)) {
        await _clearRateLimit(email);
        return false; // Lockout expired
      }

      return true; // Still locked out
    } catch (e) {
      // On error, don't block login (fail open for better UX)
      print('DEBUG: Rate limit check error: $e');
      return false;
    }
  }

  /// Get the remaining lockout time for an email
  /// Returns null if not locked out, otherwise returns the time remaining
  static Future<Duration?> getRemainingLockoutTime(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = _normalizeEmail(email);
      final lockoutUntilKey = '$_lockoutUntilPrefix$normalizedEmail';

      final lockoutUntilTimestamp = prefs.getInt(lockoutUntilKey);
      if (lockoutUntilTimestamp == null) {
        return null; // Not locked out
      }

      final lockoutUntil =
          DateTime.fromMillisecondsSinceEpoch(lockoutUntilTimestamp);
      final now = DateTime.now();

      if (now.isAfter(lockoutUntil)) {
        await _clearRateLimit(email);
        return null; // Lockout expired
      }

      return lockoutUntil.difference(now);
    } catch (e) {
      print('DEBUG: Rate limit time check error: $e');
      return null;
    }
  }

  /// Record a failed login attempt
  /// Returns true if account should be locked out (reached max attempts)
  static Future<bool> recordFailedAttempt(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = _normalizeEmail(email);
      final attemptsKey = '$_failedAttemptsPrefix$normalizedEmail';

      // Get current failed attempts count
      final currentAttempts = prefs.getInt(attemptsKey) ?? 0;
      final newAttempts = currentAttempts + 1;

      // Update attempts count
      await prefs.setInt(attemptsKey, newAttempts);

      print(
          'DEBUG: Rate limit - Failed attempts for $email: $newAttempts/$_maxFailedAttempts');

      // If max attempts reached, lock out the account
      if (newAttempts >= _maxFailedAttempts) {
        await _lockoutAccount(email);
        return true; // Account is now locked out
      }

      return false; // Not locked out yet
    } catch (e) {
      print('DEBUG: Rate limit record error: $e');
      return false; // Fail open
    }
  }

  /// Record a successful login attempt (clears rate limit tracking)
  static Future<void> recordSuccessfulLogin(String email) async {
    try {
      await _clearRateLimit(email);
      print('DEBUG: Rate limit - Cleared for successful login: $email');
    } catch (e) {
      print('DEBUG: Rate limit clear error: $e');
    }
  }

  /// Lock out an account for the configured duration
  static Future<void> _lockoutAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = _normalizeEmail(email);
      final lockoutUntilKey = '$_lockoutUntilPrefix$normalizedEmail';

      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      await prefs.setInt(lockoutUntilKey, lockoutUntil.millisecondsSinceEpoch);

      print('DEBUG: Rate limit - Account locked out until: $lockoutUntil');
    } catch (e) {
      print('DEBUG: Rate limit lockout error: $e');
    }
  }

  /// Clear all rate limit tracking for an email
  static Future<void> _clearRateLimit(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = _normalizeEmail(email);

      final attemptsKey = '$_failedAttemptsPrefix$normalizedEmail';
      final lockoutUntilKey = '$_lockoutUntilPrefix$normalizedEmail';

      await prefs.remove(attemptsKey);
      await prefs.remove(lockoutUntilKey);
    } catch (e) {
      print('DEBUG: Rate limit clear error: $e');
    }
  }

  /// Get the current failed attempts count for an email
  static Future<int> getFailedAttempts(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = _normalizeEmail(email);
      final attemptsKey = '$_failedAttemptsPrefix$normalizedEmail';

      return prefs.getInt(attemptsKey) ?? 0;
    } catch (e) {
      print('DEBUG: Rate limit get attempts error: $e');
      return 0;
    }
  }

  /// Normalize email for consistent key storage (lowercase)
  static String _normalizeEmail(String email) {
    return email.toLowerCase().trim();
  }

  /// Format remaining lockout time as a human-readable string
  static String formatRemainingTime(Duration? duration) {
    if (duration == null) {
      return '';
    }

    if (duration.inMinutes < 1) {
      return 'less than a minute';
    } else if (duration.inMinutes == 1) {
      return '1 minute';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return hours == 1 ? '1 hour' : '$hours hours';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes > 1 ? 's' : ''}';
      }
    }
  }
}

