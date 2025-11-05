import 'package:flutter/foundation.dart';

/// Utility for handling error messages securely
/// Prevents information disclosure by showing generic messages to users
/// while keeping detailed information in debug logs
class ErrorHandler {
  /// Get a user-friendly error message
  /// Shows generic message to users, detailed info only in debug mode
  static String getUserMessage(dynamic error, {String? defaultMessage}) {
    final genericMessage =
        defaultMessage ?? 'An error occurred. Please try again.';

    if (kDebugMode) {
      // In debug mode, show detailed error for developers
      if (error is Exception) {
        return 'Error: ${error.toString()}';
      } else if (error is String) {
        return 'Error: $error';
      } else {
        return 'Error: ${error.toString()}';
      }
    }

    // In production, show generic message
    return genericMessage;
  }

  /// Log error details (only in debug mode)
  /// Use this for logging errors without exposing to users
  static void logError(dynamic error, {String? context}) {
    if (kDebugMode) {
      final contextMsg = context != null ? '[$context] ' : '';
      if (error is Exception) {
        print('DEBUG ERROR $contextMsg${error.toString()}');
      } else if (error is String) {
        print('DEBUG ERROR $contextMsg$error');
      } else {
        print('DEBUG ERROR $contextMsg${error.toString()}');
      }
    }
  }

  /// Get a sanitized error message for specific error types
  /// Maps common errors to user-friendly messages
  static String getSanitizedMessage(dynamic error, {String? defaultMessage}) {
    final errorString = error.toString().toLowerCase();

    // Network/connection errors
    if (errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout')) {
      return 'Connection error. Please check your internet connection and try again.';
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('constraint') ||
        errorString.contains('duplicate key')) {
      return 'A database error occurred. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('invalid credentials')) {
      return 'Authentication failed. Please check your credentials.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('forbidden') ||
        errorString.contains('access denied')) {
      return 'You do not have permission to perform this action.';
    }

    // Validation errors (these are usually safe to show)
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      // Validation errors are usually user-friendly, so show them
      if (error is String) {
        return error;
      }
      return error.toString();
    }

    // File/IO errors
    if (errorString.contains('file') ||
        errorString.contains('io') ||
        errorString.contains('not found')) {
      return 'File operation failed. Please try again.';
    }

    // Rate limiting errors (already user-friendly)
    if (errorString.contains('rate limit') ||
        errorString.contains('locked') ||
        errorString.contains('too many')) {
      if (error is String) {
        return error; // Rate limit messages are already user-friendly
      }
      return error.toString();
    }

    // Generic fallback
    return getUserMessage(error, defaultMessage: defaultMessage);
  }

  /// Check if error message is safe to show to users
  /// Returns true if the error is user-friendly and doesn't expose system details
  static bool isSafeForUser(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Safe error types (user-friendly messages)
    final safePatterns = [
      'required',
      'invalid',
      'validation',
      'rate limit',
      'locked',
      'too many',
      'please',
      'check your',
    ];

    // Dangerous patterns (system details)
    final dangerousPatterns = [
      'exception:',
      'stack trace',
      'at ',
      'file://',
      'line ',
      'column ',
      'sqlstate',
      'postgresql',
      'supabase',
      'database',
      'internal error',
      'server error',
    ];

    // Check for dangerous patterns
    for (final pattern in dangerousPatterns) {
      if (errorString.contains(pattern)) {
        return false;
      }
    }

    // Check if it contains safe patterns (user-friendly)
    for (final pattern in safePatterns) {
      if (errorString.contains(pattern)) {
        return true;
      }
    }

    // If it's a short, simple message, it's probably safe
    final message = error.toString();
    if (message.length < 100 && !message.contains('Exception')) {
      return true;
    }

    // Default to unsafe (show generic message)
    return false;
  }
}
