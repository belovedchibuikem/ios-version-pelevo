class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final Map<String, dynamic>? errors;

  AuthException({
    required this.message,
    this.code,
    this.originalError,
    this.errors,
  });

  @override
  String toString() => message;
}

class ValidationException extends AuthException {
  ValidationException(String message, {Map<String, dynamic>? errors})
      : super(message: message, errors: errors);
}

class NetworkException extends AuthException {
  NetworkException()
      : super(message: 'Network error. Please check your connection.');
}

class ServerException extends AuthException {
  ServerException(String message) : super(message: message);
}

class TokenException extends AuthException {
  TokenException(String message) : super(message: message);
}

class RateLimitException extends AuthException {
  final int retryAfter;

  RateLimitException(String message, {required this.retryAfter})
      : super(message: message);
}

class EmailVerificationException extends AuthException {
  EmailVerificationException(String message) : super(message: message);
}

class AccountDeactivatedException extends AuthException {
  AccountDeactivatedException(String message) : super(message: message);
}
