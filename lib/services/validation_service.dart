/// Comprehensive input validation and sanitization service
/// Provides validation for all user inputs to prevent injection attacks,
/// XSS, and other security vulnerabilities
class ValidationService {
  // Constants
  static const int maxEmailLength = 255;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxTitleLength = 200;
  static const int maxMessageLength = 5000;

  // Email validation regex (RFC 5322 compliant, simplified)
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Dangerous patterns that should be removed/sanitized
  static final RegExp _scriptTagPattern = RegExp(
    r'<script[^>]*>.*?</script>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _javascriptPattern = RegExp(
    r'javascript:',
    caseSensitive: false,
  );
  static final RegExp _onEventPattern = RegExp(
    r'on\w+\s*=',
    caseSensitive: false,
  );
  // Note: SQL injection patterns are not checked here as Supabase uses parameterized queries
  // This is kept as a comment for reference but not actively used
  // static final RegExp _sqlInjectionPattern = RegExp(
  //   r'(union|select|insert|update|delete|drop|create|alter|exec|execute|script|--|/\*|\*/)',
  //   caseSensitive: false,
  // );

  /// Validate email address
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmed = email.trim();

    // Length check
    if (trimmed.length > maxEmailLength) {
      return 'Email must be less than $maxEmailLength characters';
    }

    // Format check
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    // Check for dangerous patterns (additional security)
    if (_containsDangerousPatterns(trimmed)) {
      return 'Email contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate password with strength requirements
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? password,
      {bool isNewPassword = false}) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    // Length check
    if (password.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }

    if (password.length > maxPasswordLength) {
      return 'Password must be less than $maxPasswordLength characters';
    }

    // Strength requirements for new passwords
    if (isNewPassword) {
      // Check for uppercase letter
      if (!password.contains(RegExp(r'[A-Z]'))) {
        return 'Password must contain at least one uppercase letter';
      }

      // Check for lowercase letter
      if (!password.contains(RegExp(r'[a-z]'))) {
        return 'Password must contain at least one lowercase letter';
      }

      // Check for number
      if (!password.contains(RegExp(r'[0-9]'))) {
        return 'Password must contain at least one number';
      }

      // Optional: Check for special character (can be relaxed based on requirements)
      // if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      //   return 'Password must contain at least one special character';
      // }
    }

    // Check for dangerous patterns
    if (_containsDangerousPatterns(password)) {
      return 'Password contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate name (for users, companies, etc.)
  /// Returns null if valid, error message if invalid
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.trim().isEmpty) {
      return '$fieldName is required';
    }

    final trimmed = name.trim();

    // Length check
    if (trimmed.length > maxNameLength) {
      return '$fieldName must be less than $maxNameLength characters';
    }

    // Check for dangerous patterns
    if (_containsDangerousPatterns(trimmed)) {
      return '$fieldName contains invalid characters';
    }

    // Check for only whitespace
    if (trimmed.isEmpty) {
      return '$fieldName cannot be empty';
    }

    return null; // Valid
  }

  /// Validate description or text field
  /// Returns null if valid, error message if invalid
  static String? validateDescription(
    String? description, {
    String fieldName = 'Description',
    int? maxLength,
  }) {
    if (description == null) {
      return null; // Optional field
    }

    final trimmed = description.trim();
    final actualMaxLength = maxLength ?? maxDescriptionLength;

    // Length check
    if (trimmed.length > actualMaxLength) {
      return '$fieldName must be less than $actualMaxLength characters';
    }

    // Check for dangerous patterns
    if (_containsDangerousPatterns(trimmed)) {
      return '$fieldName contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate title
  /// Returns null if valid, error message if invalid
  static String? validateTitle(String? title, {String fieldName = 'Title'}) {
    if (title == null || title.trim().isEmpty) {
      return '$fieldName is required';
    }

    final trimmed = title.trim();

    // Length check
    if (trimmed.length > maxTitleLength) {
      return '$fieldName must be less than $maxTitleLength characters';
    }

    // Check for dangerous patterns
    if (_containsDangerousPatterns(trimmed)) {
      return '$fieldName contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate numeric input (for amounts, points, etc.)
  /// Returns null if valid, error message if invalid
  static String? validateNumeric(
    String? value, {
    String fieldName = 'Value',
    double? min,
    double? max,
    bool allowNegative = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final trimmed = value.trim();

    // Try to parse as double
    final numericValue = double.tryParse(trimmed);
    if (numericValue == null) {
      return '$fieldName must be a valid number';
    }

    // Check for negative values
    if (!allowNegative && numericValue < 0) {
      return '$fieldName cannot be negative';
    }

    // Check min/max bounds
    if (min != null && numericValue < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && numericValue > max) {
      return '$fieldName must be at most $max';
    }

    return null; // Valid
  }

  /// Validate message content
  /// Returns null if valid, error message if invalid
  static String? validateMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'Message is required';
    }

    final trimmed = message.trim();

    // Length check
    if (trimmed.length > maxMessageLength) {
      return 'Message must be less than $maxMessageLength characters';
    }

    // Check for dangerous patterns
    if (_containsDangerousPatterns(trimmed)) {
      return 'Message contains invalid characters';
    }

    return null; // Valid
  }

  /// Sanitize input string by removing dangerous patterns
  /// This is a safety measure even though Flutter Text widgets are generally safe
  static String sanitizeInput(String? input, {int? maxLength}) {
    if (input == null) {
      return '';
    }

    String sanitized = input;

    // Remove script tags
    sanitized = sanitized.replaceAll(_scriptTagPattern, '');

    // Remove javascript: protocol
    sanitized = sanitized.replaceAll(_javascriptPattern, '');

    // Remove onEvent handlers (onclick, onload, etc.)
    sanitized = sanitized.replaceAll(_onEventPattern, '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Apply length limit if specified
    if (maxLength != null && sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Check if input contains dangerous patterns
  /// Used for validation (rejects input) vs sanitization (removes patterns)
  static bool _containsDangerousPatterns(String input) {
    // Check for script tags
    if (_scriptTagPattern.hasMatch(input)) {
      return true;
    }

    // Check for javascript: protocol
    if (_javascriptPattern.hasMatch(input)) {
      return true;
    }

    // Check for onEvent handlers
    if (_onEventPattern.hasMatch(input)) {
      return true;
    }

    // Note: SQL injection patterns are less relevant for Supabase (parameterized queries)
    // but we check for very obvious patterns as defense in depth
    // This is a conservative check - may need to be relaxed for legitimate use cases
    // if (_sqlInjectionPattern.hasMatch(input)) {
    //   return true;
    // }

    return false;
  }

  /// Validate URL (if needed for future features)
  /// Returns null if valid, error message if invalid
  static String? validateUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'URL is required';
    }

    final trimmed = url.trim();

    // Basic URL format check
    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'URL must start with http:// or https://';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }

    return null; // Valid
  }

  /// Validate phone number (basic format)
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return null; // Optional field
    }

    final trimmed = phone.trim();

    // Remove common formatting characters
    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's all digits (basic validation)
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null; // Valid
  }

  /// Validate date string (if needed)
  /// Returns null if valid, error message if invalid
  static String? validateDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      return 'Date is required';
    }

    // Try to parse as DateTime
    try {
      DateTime.parse(date.trim());
    } catch (e) {
      return 'Please enter a valid date';
    }

    return null; // Valid
  }
}
