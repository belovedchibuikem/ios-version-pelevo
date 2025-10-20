import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// Network error handler utility for providing user-friendly error messages
class NetworkErrorHandler {
  /// Handle network errors with user-friendly messages
  static void handleNetworkError(
    BuildContext context,
    DioException error, {
    String? errorContext,
    VoidCallback? onRetry,
  }) {
    String message;
    String title;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        title = 'Connection Timeout';
        message =
            'The request took too long to complete. Please check your internet connection and try again.';
        break;
      case DioExceptionType.sendTimeout:
        title = 'Send Timeout';
        message = 'Failed to send data to the server. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        title = 'Receive Timeout';
        message = 'The server took too long to respond. Please try again.';
        break;
      case DioExceptionType.badResponse:
        title = 'Server Error';
        message = _getServerErrorMessage(
            error.response?.statusCode, error.response?.data);
        break;
      case DioExceptionType.cancel:
        title = 'Request Cancelled';
        message = 'The request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        title = 'Connection Error';
        message =
            'Unable to connect to the server. Please check your internet connection.';
        break;
      case DioExceptionType.badCertificate:
        title = 'Security Error';
        message =
            'There was a security issue with the connection. Please try again later.';
        break;
      case DioExceptionType.unknown:
        title = 'Network Error';
        message = 'An unexpected network error occurred. Please try again.';
        break;
    }

    // Add context if provided
    if (errorContext != null) {
      title = '$title ($errorContext)';
    }

    _showErrorDialog(context, title, message, onRetry: onRetry);
  }

  /// Get user-friendly server error messages
  static String _getServerErrorMessage(int? statusCode, dynamic data) {
    if (statusCode == null) return 'Unknown server error occurred.';

    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input and try again.';
      case 401:
        return 'Authentication required. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'Conflict detected. The resource may have been modified by another user.';
      case 422:
        return 'Validation error. Please check your input and try again.';
      case 429:
        return 'Too many requests. Please wait a moment before trying again.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. The server is temporarily down for maintenance.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';
      default:
        if (statusCode >= 500) {
          return 'Server error. Please try again later.';
        } else if (statusCode >= 400) {
          return 'Client error. Please check your request and try again.';
        } else {
          return 'Unknown error occurred.';
        }
    }
  }

  /// Show error dialog with retry option
  static void _showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) {
    // Check if the context is still mounted before showing dialog
    if (!context.mounted) {
      debugPrint(
          '⚠️ BuildContext is no longer valid, falling back to SnackBar');
      // Fallback to SnackBar if context is invalid
      _showErrorSnackBarFallback(context, title, message, onRetry: onRetry);
      return;
    }

    try {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onRetry();
                  },
                  child: const Text('Retry'),
                ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint(
          '⚠️ Failed to show error dialog: $e, falling back to SnackBar');
      // Fallback to SnackBar if dialog fails
      _showErrorSnackBarFallback(context, title, message, onRetry: onRetry);
    }
  }

  /// Fallback method to show error as SnackBar when dialog fails
  static void _showErrorSnackBarFallback(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) {
    // Check if the context is still mounted before showing SnackBar
    if (!context.mounted) {
      debugPrint('⚠️ BuildContext is no longer valid for SnackBar either');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Failed to show error SnackBar: $e');
    }
  }

  /// Show snackbar with error message
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    // Check if the context is still mounted before showing SnackBar
    if (!context.mounted) {
      debugPrint('⚠️ BuildContext is no longer valid for SnackBar');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: Theme.of(context).colorScheme.error,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Failed to show error SnackBar: $e');
    }
  }

  /// Show toast-like message
  static void showToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    // Check if the context is still mounted before showing SnackBar
    if (!context.mounted) {
      debugPrint('⚠️ BuildContext is no longer valid for Toast');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor:
              backgroundColor ?? Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Failed to show toast: $e');
    }
  }

  /// Check if error is retryable
  static bool isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badResponse:
        return error.response?.statusCode != null &&
            error.response!.statusCode! >= 500;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Get retry delay based on error type
  static Duration getRetryDelay(DioException error, int attempt) {
    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: 1 << attempt); // 1, 2, 4, 8, 16...
    final jitter =
        Duration(milliseconds: (baseDelay.inMilliseconds * 0.1).round());

    return baseDelay + jitter;
  }

  /// Handle DioException and return NetworkError
  static NetworkError handleDioException(DioException error) {
    return NetworkError.fromDioException(error);
  }

  /// Log error for debugging
  static void logError(NetworkError error, {String? context}) {
    debugPrint(
        'Network Error${context != null ? ' in $context' : ''}: ${error.message}');
  }
}

/// Network error model
class NetworkError {
  final String message;
  final String userMessage;
  final NetworkErrorType type;
  final int? statusCode;
  final bool isRetryable;
  final Color color;
  final IconData icon;

  NetworkError({
    required this.message,
    required this.userMessage,
    required this.type,
    this.statusCode,
    required this.isRetryable,
    required this.color,
    required this.icon,
  });

  factory NetworkError.fromDioException(DioException error) {
    final type = _getErrorType(error);
    final statusCode = error.response?.statusCode;
    final isRetryable = NetworkErrorHandler.isRetryable(error);

    return NetworkError(
      message: error.message ?? 'Unknown network error',
      userMessage: _getUserMessage(error),
      type: type,
      statusCode: statusCode,
      isRetryable: isRetryable,
      color: _getErrorColor(type),
      icon: _getErrorIcon(type),
    );
  }

  static NetworkErrorType _getErrorType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkErrorType.timeout;
      case DioExceptionType.connectionError:
        return NetworkErrorType.noConnection;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == null) return NetworkErrorType.unknown;
        if (statusCode >= 500) return NetworkErrorType.serverError;
        if (statusCode == 401) return NetworkErrorType.unauthorized;
        if (statusCode == 403) return NetworkErrorType.forbidden;
        if (statusCode == 404) return NetworkErrorType.notFound;
        if (statusCode >= 400) return NetworkErrorType.badRequest;
        return NetworkErrorType.unknown;
      default:
        return NetworkErrorType.unknown;
    }
  }

  static String _getUserMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request took too long to complete. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == null)
          return 'An unexpected error occurred. Please try again.';
        if (statusCode == 401)
          return 'Authentication required. Please log in again.';
        if (statusCode == 403)
          return 'Access denied. You don\'t have permission to perform this action.';
        if (statusCode == 404) return 'The requested resource was not found.';
        if (statusCode >= 500) return 'Server error. Please try again later.';
        if (statusCode >= 400)
          return 'Invalid request. Please check your input and try again.';
        return 'An unexpected error occurred. Please try again.';
      default:
        return 'An unexpected network error occurred. Please try again.';
    }
  }

  static Color _getErrorColor(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.timeout:
      case NetworkErrorType.noConnection:
        return Colors.orange;
      case NetworkErrorType.serverError:
        return Colors.red;
      case NetworkErrorType.unauthorized:
      case NetworkErrorType.forbidden:
        return Colors.red;
      case NetworkErrorType.notFound:
        return Colors.blue;
      case NetworkErrorType.badRequest:
        return Colors.orange;
      case NetworkErrorType.unknown:
        return Colors.grey;
    }
  }

  static IconData _getErrorIcon(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.timeout:
        return Icons.timer_off;
      case NetworkErrorType.noConnection:
        return Icons.wifi_off;
      case NetworkErrorType.serverError:
        return Icons.error_outline;
      case NetworkErrorType.unauthorized:
        return Icons.lock;
      case NetworkErrorType.forbidden:
        return Icons.block;
      case NetworkErrorType.notFound:
        return Icons.search_off;
      case NetworkErrorType.badRequest:
        return Icons.report_problem;
      case NetworkErrorType.unknown:
        return Icons.help_outline;
    }
  }
}

/// Network error types
enum NetworkErrorType {
  timeout,
  noConnection,
  serverError,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  unknown,
}
