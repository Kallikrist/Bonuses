import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../models/user.dart';
import 'storage_service.dart';
import 'password_service.dart';
import 'rate_limit_service.dart';
import 'supabase_service.dart';

/// Exception thrown when account is rate limited
class RateLimitException implements Exception {
  final String message;
  final Duration? remainingTime;

  RateLimitException(this.message, [this.remainingTime]);

  @override
  String toString() => message;
}

class AuthService {
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  /// True when login/session go through Supabase Auth (configured + initialized).
  static bool get usesSupabaseAuth => SupabaseService.isAuthReady;

  static Future<bool> login(String email, String password) async {
    try {
      // Check rate limiting BEFORE attempting authentication
      final isRateLimited = await RateLimitService.isRateLimited(email);
      if (isRateLimited) {
        final remainingTime =
            await RateLimitService.getRemainingLockoutTime(email);
        final timeString = RateLimitService.formatRemainingTime(remainingTime);
        throw RateLimitException(
          'Account temporarily locked. Please try again in $timeString.',
          remainingTime,
        );
      }

      if (usesSupabaseAuth) {
        return await _loginWithSupabaseAuth(email, password);
      }
      return await _loginLocal(email, password);
    } catch (e) {
      // Re-throw rate limit exceptions so they can be handled by caller
      if (e is RateLimitException) {
        rethrow;
      }
      print('DEBUG: Login error: $e');
      return false;
    }
  }

  /// Supabase Auth is the credential check. Local storage still holds the
  /// app profile (roles, companies) keyed by email.
  static Future<bool> _loginWithSupabaseAuth(
    String email,
    String password,
  ) async {
    if (kDebugMode) {
      print('DEBUG: Using Supabase Auth for $email');
    }
    try {
      await SupabaseService.signIn(email: email, password: password);
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG: Supabase Auth login failed: ${e.message}');
      }
      await RateLimitService.recordFailedAttempt(email);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Supabase Auth login error: $e');
      }
      await RateLimitService.recordFailedAttempt(email);
      return false;
    }

    final localUser = await _findLocalUserByEmail(email);
    if (localUser == null) {
      if (kDebugMode) {
        print('DEBUG: No local app profile for $email');
      }
      await _signOutSupabaseQuietly();
      await RateLimitService.recordFailedAttempt(email);
      return false;
    }

    if (!await _passesCompanyCheck(localUser)) {
      await _signOutSupabaseQuietly();
      await RateLimitService.recordFailedAttempt(email);
      return false;
    }

    _currentUser = localUser;
    await StorageService.setCurrentUser(localUser);
    await RateLimitService.recordSuccessfulLogin(email);
    if (kDebugMode) {
      print('DEBUG: Supabase Auth login successful for ${localUser.email}');
    }
    return true;
  }

  static Future<bool> _loginLocal(String email, String password) async {
    print('DEBUG: Using local storage authentication for $email');

    bool loginSuccessful = false;
    try {
      final users = await StorageService.getUsers();
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Check password
      final storedPassword = await StorageService.getPassword(user.id);
      if (storedPassword == null) {
        print('DEBUG: No password found for user $email');
        await RateLimitService.recordFailedAttempt(email);
        return false;
      }

      // Verify password (handles plaintext, SHA-256, and bcrypt formats)
      bool passwordValid = false;
      bool isPlaintext = PasswordService.isPlaintext(storedPassword);

      if (isPlaintext) {
        // Legacy plaintext password - verify and migrate to bcrypt
        if (storedPassword == password) {
          passwordValid = true;
          // Re-hash the password with bcrypt for future use
          await StorageService.savePassword(user.id, password);
          if (kDebugMode) {
            print('DEBUG: Migrated plaintext password to bcrypt for $email');
          }
        }
      } else {
        // Hashed password - use verification (handles both SHA-256 and bcrypt)
        passwordValid =
            PasswordService.verifyPassword(password, storedPassword);

        // If password is valid but stored in legacy SHA-256 format, upgrade to bcrypt
        if (passwordValid && PasswordService.isSha256Hash(storedPassword)) {
          if (kDebugMode) {
            print(
                'DEBUG: Upgrading SHA-256 password hash to bcrypt for $email');
          }
          // Re-hash the password with bcrypt
          await StorageService.savePassword(user.id, password);
        }
      }

      if (!passwordValid) {
        if (kDebugMode) {
          print('DEBUG: Invalid password for $email');
        }
        final isLockedOut = await RateLimitService.recordFailedAttempt(email);
        if (isLockedOut) {
          final remainingTime =
              await RateLimitService.getRemainingLockoutTime(email);
          final timeString =
              RateLimitService.formatRemainingTime(remainingTime);
          throw RateLimitException(
            'Too many failed login attempts. Account locked for $timeString.',
            remainingTime,
          );
        }
        return false;
      }

      if (!await _passesCompanyCheck(user)) {
        await RateLimitService.recordFailedAttempt(email);
        return false;
      }

      _currentUser = user;
      await StorageService.setCurrentUser(user);

      // Clear rate limit on successful login
      await RateLimitService.recordSuccessfulLogin(email);

      print('DEBUG: Local storage login successful for ${user.email}');
      loginSuccessful = true;
    } catch (e) {
      // Handle user not found - also record as failed attempt
      if (e.toString().contains('User not found')) {
        print('DEBUG: User not found: $email');
        await RateLimitService.recordFailedAttempt(email);
      } else if (e is RateLimitException) {
        // Re-throw rate limit exceptions
        rethrow;
      } else {
        print('DEBUG: Login failed: $e');
        await RateLimitService.recordFailedAttempt(email);
      }
      return false;
    }

    return loginSuccessful;
  }

  static Future<void> logout() async {
    try {
      print('DEBUG: Logging out user');
      await _signOutSupabaseQuietly();
    } catch (e) {
      print('DEBUG: Logout error (non-critical): $e');
    }

    await StorageService.clearCurrentUser();
    _currentUser = null;
    print('DEBUG: Local logout completed');
  }

  /// Restore the app user after process start.
  ///
  /// When Supabase Auth is ready, a live Auth session is required. A leftover
  /// local current-user row is not enough. When Auth is not ready (tests /
  /// missing config), the local current user is used as before.
  static Future<User?> restoreSession() async {
    if (!usesSupabaseAuth) {
      try {
        final user = await StorageService.getCurrentUser();
        _currentUser = user;
        return user;
      } catch (e) {
        print('DEBUG: Error checking login status: $e');
        _currentUser = null;
        return null;
      }
    }

    try {
      final authUser = SupabaseService.client.auth.currentUser;
      final email = authUser?.email;
      if (authUser == null || email == null || email.isEmpty) {
        await StorageService.clearCurrentUser();
        _currentUser = null;
        return null;
      }
      final localUser = await _findLocalUserByEmail(email);
      if (localUser == null) {
        await StorageService.clearCurrentUser();
        _currentUser = null;
        return null;
      }
      _currentUser = localUser;
      await StorageService.setCurrentUser(localUser);
      return localUser;
    } catch (e) {
      print('DEBUG: Error restoring Supabase Auth session: $e');
      await StorageService.clearCurrentUser();
      _currentUser = null;
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final user = await restoreSession();
    return user != null;
  }

  static Future<User?> _findLocalUserByEmail(String email) async {
    final users = await StorageService.getUsers();
    final needle = email.toLowerCase();
    for (final user in users) {
      if (user.email.toLowerCase() == needle) {
        return user;
      }
    }
    return null;
  }

  static Future<void> _signOutSupabaseQuietly() async {
    if (!usesSupabaseAuth) return;
    try {
      await SupabaseService.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Supabase signOut skipped: $e');
      }
    }
  }

  static Future<bool> _passesCompanyCheck(User user) async {
    // Check if user has any active companies (skip check for super admin)
    if (user.role != UserRole.superAdmin &&
        user.email != 'superadmin@platform.com') {
      print('DEBUG: Login - Checking active companies for ${user.email}');
      final hasActiveCompany = await _checkUserHasActiveCompany(user);
      print('DEBUG: Login - Has active company: $hasActiveCompany');
      if (!hasActiveCompany) {
        print(
            'DEBUG: Login blocked - No active companies for user ${user.email}');
        return false;
      }
    } else {
      print('DEBUG: Login - Bypassing company check for ${user.email}');
    }
    return true;
  }

  // Helper method to check if user has active companies
  static Future<bool> _checkUserHasActiveCompany(User user) async {
    try {
      final companies = await StorageService.getCompanies();

      // Check if any of the user's companies are active
      for (final companyId in user.companyIds) {
        final company = companies.firstWhere(
          (c) => c.id == companyId,
          orElse: () => throw Exception('Company not found'),
        );
        if (company.isActive) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('DEBUG: Error checking user companies: $e');
      return false;
    }
  }
}
