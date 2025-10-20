import 'package:flutter/foundation.dart';

/// Utility class for consistent validation patterns across the app
class ValidationUtils {
  /// Standard email validation regex pattern
  /// This pattern covers most common email formats while being permissive enough
  /// for international domains and various email providers
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validate email address format
  /// Returns true if email is valid, false otherwise
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validate email address format with detailed error message
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String email, {String? customErrorMessage}) {
    if (email.trim().isEmpty) {
      return 'Email address is required';
    }

    if (!isValidEmail(email)) {
      return customErrorMessage ?? 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate name format (letters and spaces only)
  /// Returns true if name is valid, false otherwise
  static bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim());
  }

  /// Validate name format with detailed error message
  /// Returns null if valid, error message if invalid
  static String? validateName(String name, {String? customErrorMessage}) {
    if (name.trim().isEmpty) {
      return 'Name is required';
    }

    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim())) {
      return customErrorMessage ?? 'Name can only contain letters and spaces';
    }

    return null;
  }

  /// Validate password strength
  /// Returns true if password meets requirements, false otherwise
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;

    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    return hasUpperCase && hasLowerCase && hasNumbers && hasSpecialChar;
  }

  /// Validate password strength with detailed error message
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String password,
      {String? customErrorMessage}) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    if (!hasUpperCase || !hasLowerCase || !hasNumbers || !hasSpecialChar) {
      return customErrorMessage ??
          'Password must contain uppercase, lowercase, number, and special character';
    }

    return null;
  }

  /// Validate URL format
  /// Returns true if URL is valid, false otherwise
  static bool isValidUrl(String url) {
    if (url.trim().isEmpty) return false;

    // Basic URL validation - can be enhanced for more specific requirements
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Validate URL format with detailed error message
  /// Returns null if valid, error message if invalid
  static String? validateUrl(String url, {String? customErrorMessage}) {
    if (url.trim().isEmpty) {
      return 'URL is required';
    }

    if (!isValidUrl(url)) {
      return customErrorMessage ?? 'Please enter a valid URL';
    }

    return null;
  }

  /// Validate phone number format (basic international format)
  /// Returns true if phone number is valid, false otherwise
  static bool isValidPhoneNumber(String phone) {
    if (phone.trim().isEmpty) return false;

    // Remove all non-digit characters for validation
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Phone numbers should be between 7 and 15 digits
    return digitsOnly.length >= 7 && digitsOnly.length <= 15;
  }

  /// Validate phone number format with detailed error message
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumber(String phone,
      {String? customErrorMessage}) {
    if (phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (!isValidPhoneNumber(phone)) {
      return customErrorMessage ?? 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate required field
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  /// Returns null if valid, error message if invalid
  static String? validateMinLength(
      String value, int minLength, String fieldName) {
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  /// Returns null if valid, error message if invalid
  static String? validateMaxLength(
      String value, int maxLength, String fieldName) {
    if (value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }

  /// Validate numeric value
  /// Returns null if valid, error message if invalid
  static String? validateNumeric(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value.trim()) == null) {
      return '$fieldName must be a valid number';
    }

    return null;
  }

  /// Validate integer value
  /// Returns null if valid, error message if invalid
  static String? validateInteger(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (int.tryParse(value.trim()) == null) {
      return '$fieldName must be a valid integer';
    }

    return null;
  }

  /// Validate positive number
  /// Returns null if valid, error message if invalid
  static String? validatePositiveNumber(String value, String fieldName) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value.trim());
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Validate date format (ISO 8601)
  /// Returns null if valid, error message if invalid
  static String? validateDate(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return '$fieldName is required';
    }

    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return '$fieldName must be a valid date';
    }
  }

  /// Validate future date
  /// Returns null if valid, error message if invalid
  static String? validateFutureDate(String value, String fieldName) {
    final dateError = validateDate(value, fieldName);
    if (dateError != null) return dateError;

    final date = DateTime.parse(value.trim());
    if (date.isBefore(DateTime.now())) {
      return '$fieldName must be a future date';
    }

    return null;
  }

  /// Validate past date
  /// Returns null if valid, error message if invalid
  static String? validatePastDate(String value, String fieldName) {
    final dateError = validateDate(value, fieldName);
    if (dateError != null) return dateError;

    final date = DateTime.parse(value.trim());
    if (date.isAfter(DateTime.now())) {
      return '$fieldName must be a past date';
    }

    return null;
  }

  /// Get the email regex pattern for custom validation
  static RegExp get emailRegex => _emailRegex;

  /// Debug method to test email validation
  static void debugEmailValidation(String email) {
    if (kDebugMode) {
      final isValid = isValidEmail(email);
      print(
          '🔍 Email validation test: "$email" -> ${isValid ? "✅ Valid" : "❌ Invalid"}');

      if (!isValid) {
        print('   Pattern: ${_emailRegex.pattern}');
        print('   Matches: ${_emailRegex.hasMatch(email)}');
      }
    }
  }
}
