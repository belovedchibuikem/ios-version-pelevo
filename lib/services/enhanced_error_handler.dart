import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Enhanced error handling service with better error reporting and user feedback
class EnhancedErrorHandler {
  static final EnhancedErrorHandler _instance =
      EnhancedErrorHandler._internal();
  factory EnhancedErrorHandler() => _instance;
  EnhancedErrorHandler._internal();

  // Error tracking
  final List<_ErrorRecord> _errorHistory = [];
  final Map<String, int> _errorCounts = {};
  final List<Function(String, dynamic, StackTrace?)> _errorListeners = [];

  // Error handling configuration
  bool _isInitialized = false;
  bool _showUserFriendlyErrors = true;
  bool _logErrorsToConsole = true;
  bool _trackErrorHistory = true;
  int _maxErrorHistory = 100;

  // Error categories
  static const String _networkError = 'network';
  static const String _databaseError = 'database';
  static const String _validationError = 'validation';
  static const String _permissionError = 'permission';
  static const String _systemError = 'system';
  static const String _unknownError = 'unknown';

  /// Initialize error handler
  void initialize({
    bool showUserFriendlyErrors = true,
    bool logErrorsToConsole = true,
    bool trackErrorHistory = true,
    int maxErrorHistory = 100,
  }) {
    if (_isInitialized) return;

    _showUserFriendlyErrors = showUserFriendlyErrors;
    _logErrorsToConsole = logErrorsToConsole;
    _trackErrorHistory = trackErrorHistory;
    _maxErrorHistory = maxErrorHistory;

    // Set up global error handling
    FlutterError.onError = _handleFlutterError;

    _isInitialized = true;

    if (kDebugMode) {
      developer.log('🚨 Enhanced error handler initialized',
          name: 'ErrorHandler');
    }
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    _handleError(
      'Flutter Error',
      details.exception,
      details.stack,
      category: _systemError,
    );
  }

  /// Handle errors with automatic categorization
  void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    String? category,
    bool showUserFeedback = true,
  }) {
    final errorMessage = error.toString();
    final errorCategory = category ?? _categorizeError(errorMessage);

    _handleError(
      context ?? 'Application Error',
      error,
      stackTrace,
      category: errorCategory,
      showUserFeedback: showUserFeedback,
    );
  }

  /// Handle network errors
  void handleNetworkError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool showUserFeedback = true,
  }) {
    _handleError(
      context ?? 'Network Error',
      error,
      stackTrace,
      category: _networkError,
      showUserFeedback: showUserFeedback,
    );
  }

  /// Handle database errors
  void handleDatabaseError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool showUserFeedback = true,
  }) {
    _handleError(
      context ?? 'Database Error',
      error,
      stackTrace,
      category: _databaseError,
      showUserFeedback: showUserFeedback,
    );
  }

  /// Handle validation errors
  void handleValidationError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool showUserFeedback = true,
  }) {
    _handleError(
      context ?? 'Validation Error',
      error,
      stackTrace,
      category: _validationError,
      showUserFeedback: showUserFeedback,
    );
  }

  /// Handle permission errors
  void handlePermissionError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool showUserFeedback = true,
  }) {
    _handleError(
      context ?? 'Permission Error',
      error,
      stackTrace,
      category: _permissionError,
      showUserFeedback: showUserFeedback,
    );
  }

  /// Main error handling method
  void _handleError(
    String context,
    dynamic error,
    StackTrace? stackTrace, {
    required String category,
    bool showUserFeedback = true,
  }) {
    final errorRecord = _ErrorRecord(
      context: context,
      error: error,
      stackTrace: stackTrace,
      category: category,
      timestamp: DateTime.now(),
    );

    // Track error
    if (_trackErrorHistory) {
      _addErrorToHistory(errorRecord);
      _updateErrorCounts(category);
    }

    // Log error
    if (_logErrorsToConsole) {
      _logError(errorRecord);
    }

    // Notify listeners
    _notifyErrorListeners(context, error, stackTrace);

    // Show user feedback if requested
    if (showUserFeedback && _showUserFriendlyErrors) {
      _showUserFriendlyError(errorRecord);
    }
  }

  /// Add error to history
  void _addErrorToHistory(_ErrorRecord errorRecord) {
    _errorHistory.add(errorRecord);

    // Maintain history size limit
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeRange(0, _errorHistory.length - _maxErrorHistory);
    }
  }

  /// Update error counts
  void _updateErrorCounts(String category) {
    _errorCounts[category] = (_errorCounts[category] ?? 0) + 1;
  }

  /// Log error to console
  void _logError(_ErrorRecord errorRecord) {
    final timestamp = errorRecord.timestamp.toIso8601String();
    final category = errorRecord.category.toUpperCase();

    developer.log(
      '🚨 [$category] ${errorRecord.context}: ${errorRecord.error}',
      name: 'ErrorHandler',
      error: errorRecord.error,
      stackTrace: errorRecord.stackTrace,
    );
  }

  /// Notify error listeners
  void _notifyErrorListeners(
      String context, dynamic error, StackTrace? stackTrace) {
    for (final listener in _errorListeners) {
      try {
        listener(context, error, stackTrace);
      } catch (e) {
        // Prevent listener errors from causing infinite loops
        developer.log('Error in error listener: $e', name: 'ErrorHandler');
      }
    }
  }

  /// Show user-friendly error message
  void _showUserFriendlyError(_ErrorRecord errorRecord) {
    final message = _getUserFriendlyMessage(errorRecord);
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getErrorIcon(errorRecord.category),
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: _getErrorColor(errorRecord.category),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Details',
        textColor: Colors.white,
        onPressed: () => _showErrorDetails(errorRecord),
      ),
    );

    // Show snackbar using global scaffold messenger
    final context = _getGlobalContext();
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  /// Get user-friendly error message
  String _getUserFriendlyMessage(_ErrorRecord errorRecord) {
    switch (errorRecord.category) {
      case _networkError:
        return 'Connection issue. Please check your internet connection and try again.';
      case _databaseError:
        return 'Data storage issue. Your data is safe, but some features may be temporarily unavailable.';
      case _validationError:
        return 'Invalid input. Please check your information and try again.';
      case _permissionError:
        return 'Permission denied. Please check your app permissions and try again.';
      case _systemError:
        return 'System issue. Please restart the app and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Get error icon
  IconData _getErrorIcon(String category) {
    switch (category) {
      case _networkError:
        return Icons.wifi_off;
      case _databaseError:
        return Icons.storage;
      case _validationError:
        return Icons.error_outline;
      case _permissionError:
        return Icons.lock;
      case _systemError:
        return Icons.bug_report;
      default:
        return Icons.error;
    }
  }

  /// Get error color
  Color _getErrorColor(String category) {
    switch (category) {
      case _networkError:
        return Colors.orange;
      case _databaseError:
        return Colors.red;
      case _validationError:
        return Colors.amber;
      case _permissionError:
        return Colors.purple;
      case _systemError:
        return Colors.red.shade800;
      default:
        return Colors.red;
    }
  }

  /// Show detailed error information
  void _showErrorDetails(_ErrorRecord errorRecord) {
    final context = _getGlobalContext();
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(errorRecord.category),
              color: _getErrorColor(errorRecord.category),
            ),
            SizedBox(width: 8),
            Text('Error Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Context:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(errorRecord.context),
              SizedBox(height: 16),
              Text(
                'Error:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(errorRecord.error.toString()),
              if (errorRecord.stackTrace != null) ...[
                SizedBox(height: 16),
                Text(
                  'Stack Trace:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    errorRecord.stackTrace.toString(),
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Categorize error based on message content
  String _categorizeError(String errorMessage) {
    final message = errorMessage.toLowerCase();

    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('unreachable')) {
      return _networkError;
    } else if (message.contains('database') ||
        message.contains('sql') ||
        message.contains('storage') ||
        message.contains('query')) {
      return _databaseError;
    } else if (message.contains('validation') ||
        message.contains('invalid') ||
        message.contains('format') ||
        message.contains('required')) {
      return _validationError;
    } else if (message.contains('permission') ||
        message.contains('denied') ||
        message.contains('unauthorized') ||
        message.contains('access')) {
      return _permissionError;
    } else if (message.contains('system') ||
        message.contains('internal') ||
        message.contains('exception') ||
        message.contains('crash')) {
      return _systemError;
    } else {
      return _unknownError;
    }
  }

  /// Get global context (simplified approach)
  BuildContext? _getGlobalContext() {
    // This is a simplified approach - in a real app you might use a global navigator key
    // or other methods to get the current context
    return null;
  }

  /// Add error listener
  void addErrorListener(Function(String, dynamic, StackTrace?) listener) {
    _errorListeners.add(listener);
  }

  /// Remove error listener
  void removeErrorListener(Function(String, dynamic, StackTrace?) listener) {
    _errorListeners.remove(listener);
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    return {
      'total_errors': _errorHistory.length,
      'error_counts_by_category': Map.unmodifiable(_errorCounts),
      'recent_errors': _errorHistory
          .take(10)
          .map((e) => {
                'context': e.context,
                'category': e.category,
                'timestamp': e.timestamp.toIso8601String(),
                'error': e.error.toString(),
              })
          .toList(),
    };
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
    _errorCounts.clear();

    if (kDebugMode) {
      developer.log('🧹 Error history cleared', name: 'ErrorHandler');
    }
  }

  /// Check if error handler is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _errorHistory.clear();
    _errorCounts.clear();
    _errorListeners.clear();
    _isInitialized = false;

    if (kDebugMode) {
      developer.log('🚨 Enhanced error handler disposed', name: 'ErrorHandler');
    }
  }
}

/// Error record class
class _ErrorRecord {
  final String context;
  final dynamic error;
  final StackTrace? stackTrace;
  final String category;
  final DateTime timestamp;

  _ErrorRecord({
    required this.context,
    required this.error,
    this.stackTrace,
    required this.category,
    required this.timestamp,
  });
}

