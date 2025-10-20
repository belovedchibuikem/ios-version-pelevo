# Network Error Handling Guide

This guide explains how to properly handle network errors in the Flutter app using the updated error handling system with automatic snackbar notifications.

## Overview

The network error handling system has been updated to automatically display user-friendly snackbar notifications when network errors occur. This provides a better user experience by:

- Showing clear, user-friendly error messages
- Providing retry options for recoverable errors
- Logging errors for debugging
- Preventing silent failures

## Components

### 1. NotificationService

Located at `lib/core/services/notification_service.dart`

Provides centralized snackbar notification functionality:

```dart
// Show a basic snackbar
NotificationService.showSnackBar(context, message: 'Your message');

// Show success notification
NotificationService.showSuccess(context, message: 'Operation successful');

// Show error notification with retry option
NotificationService.showError(
  context, 
  message: 'Something went wrong',
  onRetry: () => retryOperation(),
);

// Show network error with retry
NotificationService.showNetworkError(
  context,
  message: 'Network connection failed',
  onRetry: () => retryNetworkCall(),
);
```

### 2. NetworkErrorHandler

Located at `lib/core/utils/network_error_handler.dart`

Handles Dio exceptions and converts them to user-friendly error messages:

```dart
// Handle network error with automatic snackbar
NetworkErrorHandler.handleNetworkError(
  context,
  dioException,
  context: 'getPlayHistory',
  onRetry: () => retryOperation(),
);

// Get network error without showing snackbar
final networkError = NetworkErrorHandler.handleDioException(dioException);
```

## Usage in Services

### Updated HistoryService

The `HistoryService` has been updated to include optional `BuildContext` and `onRetry` parameters:

```dart
// With error handling and snackbar notifications
final history = await historyService.getPlayHistory(
  context: context,
  onRetry: () => loadData(), // Retry function
);

// Without error handling (for background operations)
final history = await historyService.getPlayHistory();
```

### Error Types Handled

The system handles various network error types:

1. **Timeout Errors** - Connection, send, or receive timeouts
2. **Connection Errors** - No internet connection
3. **Server Errors** - 5xx HTTP status codes
4. **Client Errors** - 4xx HTTP status codes
5. **Unknown Errors** - Unexpected errors

## Implementation Examples

### Basic Usage

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final HistoryService _historyService = HistoryService();
  List<PlayHistory> _history = [];
  bool _isLoading = false;

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final history = await _historyService.getPlayHistory(
        context: context,
        onRetry: _loadHistory, // Retry function
      );

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Error is automatically handled with snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_history[index].title),
                );
              },
            ),
    );
  }
}
```

### Advanced Usage with Custom Error Handling

```dart
Future<void> _performOperation() async {
  try {
    await _historyService.updatePlayHistory(
      episodeId: 'episode_123',
      status: 'played',
      position: 100,
      context: context,
      onRetry: _performOperation,
    );

    // Show success message
    NotificationService.showSuccess(
      context,
      message: 'Operation completed successfully',
    );
  } catch (e) {
    // Error is already handled by the service
    // You can add additional error handling here if needed
  }
}
```

### Background Operations

For operations that shouldn't show snackbars (like progress updates):

```dart
// Progress updates - no snackbar shown
await _historyService.updateProgress(
  episodeId: 'episode_123',
  progressSeconds: 60,
  totalListeningTime: 120,
  context: context, // Optional, won't show snackbar for progress updates
);
```

## Best Practices

### 1. Always Provide Context

```dart
// Good - provides context for error handling
await service.getData(context: context, onRetry: retryFunction);

// Avoid - no error feedback to user
await service.getData();
```

### 2. Provide Retry Functions

```dart
// Good - provides retry functionality
await service.getData(
  context: context,
  onRetry: () => service.getData(context: context, onRetry: retryFunction),
);
```

### 3. Handle Loading States

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final data = await service.getData(context: context, onRetry: _loadData);
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
  }
}
```

### 4. Use Appropriate Notification Types

```dart
// Success operations
NotificationService.showSuccess(context, message: 'Saved successfully');

// Warnings
NotificationService.showWarning(context, message: 'Please check your input');

// Information
NotificationService.showInfo(context, message: 'Syncing data...');

// Errors with retry
NotificationService.showError(
  context, 
  message: 'Failed to save',
  onRetry: () => saveData(),
);
```

## Error Messages

The system provides user-friendly error messages for different scenarios:

- **Timeout**: "Request timed out. Please check your connection and try again."
- **No Connection**: "No internet connection. Please check your network settings."
- **Server Error**: "Server is temporarily unavailable. Please try again later."
- **Unauthorized**: "Please log in to continue."
- **Forbidden**: "You don't have permission to perform this action."

## Debugging

All network errors are logged for debugging:

```dart
// Check debug console for detailed error information
debugPrint('Network Error: timeout - Request timeout after 30 seconds');
debugPrint('Original error: DioException: Request timeout');
```

## Migration Guide

### From Old Error Handling

**Before:**
```dart
try {
  final data = await service.getData();
} catch (e) {
  if (e is DioException) {
    // Manual error handling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: ${e.message}')),
    );
  }
}
```

**After:**
```dart
try {
  final data = await service.getData(context: context, onRetry: retryFunction);
} catch (e) {
  // Error is automatically handled with snackbar
}
```

## Testing

To test network error handling:

1. **Timeout**: Use slow network or increase timeout values
2. **No Connection**: Disable network connection
3. **Server Errors**: Use invalid API endpoints
4. **Client Errors**: Use invalid authentication tokens

## Troubleshooting

### Common Issues

1. **Snackbar not showing**: Ensure `context` is provided and valid
2. **Retry not working**: Check that retry function is properly defined
3. **Multiple snackbars**: Use `NotificationService.hideSnackBar(context)` to clear existing snackbars

### Debug Mode

Enable debug logging to see detailed error information:

```dart
// Check debug console for network error logs
debugPrint('Network Error: ${error.type} - ${error.message}');
``` 