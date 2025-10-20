# Network Error Handling System

This document explains how to implement professional network error handling in your Flutter app using Dio.

## Overview

The network error handling system provides:
- **Professional error categorization** with user-friendly messages
- **Automatic retry mechanism** with exponential backoff
- **Visual error widgets** for different error types
- **Comprehensive logging** for debugging
- **Graceful error handling** that doesn't crash the app

## Components

### 1. NetworkErrorHandler (`network_error_handler.dart`)

Handles Dio exceptions and converts them to user-friendly `NetworkError` objects.

```dart
// Handle DioException
try {
  final response = await dio.get('/api/data');
  return response.data;
} catch (e) {
  if (e is DioException) {
    final networkError = NetworkErrorHandler.handleDioException(e);
    throw networkError; // Now throws NetworkError instead of DioException
  }
  rethrow;
}
```

### 2. RetryInterceptor (`retry_interceptor.dart`)

Automatically retries failed requests with exponential backoff.

```dart
// Add to Dio instance
dio.interceptors.add(RetryInterceptor(
  maxRetries: 3,
  baseDelay: const Duration(seconds: 1),
  retryOnTimeout: true,
  retryOnConnectionError: true,
  retryOnServerError: true,
));
```

### 3. NetworkErrorWidget (`network_error_widget.dart`)

Displays user-friendly error messages with retry functionality.

```dart
NetworkErrorWidget(
  error: networkError,
  onRetry: () => _loadData(),
  title: 'Failed to Load Data',
  subtitle: 'We encountered an issue while loading your data.',
)
```

## Error Types

| Error Type | Description | User Message | Retryable |
|------------|-------------|--------------|-----------|
| `timeout` | Request timed out | "Request timed out. Please check your connection and try again." | ✅ |
| `noConnection` | No internet connection | "No internet connection. Please check your network settings." | ✅ |
| `serverError` | Server error (5xx) | "Server is temporarily unavailable. Please try again later." | ✅ |
| `unauthorized` | Authentication required (401) | "Please log in to continue." | ❌ |
| `forbidden` | Access denied (403) | "You don't have permission to perform this action." | ❌ |
| `notFound` | Resource not found (404) | "The requested resource was not found." | ❌ |
| `badRequest` | Invalid request (400) | "Invalid request. Please check your input and try again." | ❌ |
| `unknown` | Unknown error | "An unexpected error occurred. Please try again." | ❌ |

## Implementation Guide

### Step 1: Update Dio Configuration

```dart
class ApiService {
  late Dio _dio;

  Future<void> _initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60), // Increased for large responses
      sendTimeout: const Duration(seconds: 30),
    ));

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor(
      maxRetries: 3,
      baseDelay: const Duration(seconds: 1),
      retryOnTimeout: true,
      retryOnConnectionError: true,
      retryOnServerError: true,
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
}
```

### Step 2: Update Error Handling in Services

```dart
class HistoryService {
  Future<List<PlayHistory>> getPlayHistory() async {
    await _initialize();

    try {
      final response = await _dio.get('/library/play-history');
      
      if (response.data['data'] != null) {
        final data = response.data['data'] as List;
        return data.map((json) => PlayHistory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getPlayHistory');
        throw networkError;
      }
      debugPrint('Error fetching play history: $e');
      rethrow;
    }
  }
}
```

### Step 3: Update Providers/State Management

```dart
class HistoryProvider extends ChangeNotifier {
  Future<void> loadPlayHistory() async {
    _setLoading(true);
    _error = null;

    try {
      final newHistory = await _historyService.getPlayHistory();
      _playHistory = newHistory;
      notifyListeners();
    } catch (e) {
      if (e is NetworkError) {
        _error = e.userMessage; // Use user-friendly message
      } else {
        _error = e.toString();
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
```

### Step 4: Update UI Widgets

```dart
class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          // Create NetworkError from string error
          final networkError = NetworkError(
            type: NetworkErrorType.unknown,
            message: provider.error!,
            userMessage: provider.error!,
          );

          return NetworkErrorWidget(
            error: networkError,
            onRetry: () => provider.loadPlayHistory(),
            title: 'Failed to Load History',
            subtitle: 'We encountered an issue while loading your history.',
          );
        }

        return ListView.builder(
          itemCount: provider.playHistory.length,
          itemBuilder: (context, index) {
            return HistoryItem(history: provider.playHistory[index]);
          },
        );
      },
    );
  }
}
```

## Best Practices

### 1. Timeout Configuration

```dart
// For different types of requests, use appropriate timeouts
BaseOptions(
  connectTimeout: const Duration(seconds: 30),    // Connection timeout
  receiveTimeout: const Duration(seconds: 60),    // Response timeout (longer for large data)
  sendTimeout: const Duration(seconds: 30),       // Upload timeout
)
```

### 2. Retry Strategy

```dart
RetryInterceptor(
  maxRetries: 3,                    // Don't retry too many times
  baseDelay: const Duration(seconds: 1),
  retryOnTimeout: true,             // Retry timeouts
  retryOnConnectionError: true,     // Retry connection errors
  retryOnServerError: true,         // Retry server errors (5xx)
  // Don't retry client errors (4xx) - they won't succeed
)
```

### 3. Error Logging

```dart
// Always log errors for debugging
NetworkErrorHandler.logError(networkError, context: 'getPlayHistory');
```

### 4. User Experience

```dart
// Show appropriate error messages
NetworkErrorWidget(
  error: networkError,
  onRetry: () => _loadData(),
  showRetryButton: networkError.isRetryable, // Only show retry for retryable errors
)
```

### 5. Progress Updates

```dart
// Don't block playback for progress updates
try {
  await _historyService.updateProgress(...);
} catch (e) {
  // Log but don't rethrow for progress updates
  if (e is DioException) {
    final networkError = NetworkErrorHandler.handleDioException(e);
    NetworkErrorHandler.logError(networkError, context: 'updateProgress');
  }
}
```

## Error Handling Patterns

### Pattern 1: Service Layer

```dart
class ApiService {
  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError);
        throw networkError;
      }
      rethrow;
    }
  }

  Future<List<Data>> getData() async {
    return _handleRequest(() async {
      final response = await _dio.get('/api/data');
      return (response.data as List).map((json) => Data.fromJson(json)).toList();
    });
  }
}
```

### Pattern 2: Provider Layer

```dart
class DataProvider extends ChangeNotifier {
  Future<void> loadData() async {
    _setLoading(true);
    _error = null;

    try {
      _data = await _apiService.getData();
      notifyListeners();
    } catch (e) {
      _error = e is NetworkError ? e.userMessage : e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
```

### Pattern 3: UI Layer

```dart
class DataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return NetworkErrorWidget(
            error: _createNetworkError(provider.error!),
            onRetry: () => provider.loadData(),
          );
        }

        return DataList(data: provider.data);
      },
    );
  }

  NetworkError _createNetworkError(String error) {
    return NetworkError(
      type: NetworkErrorType.unknown,
      message: error,
      userMessage: error,
    );
  }
}
```

## Testing

### Test Network Errors

```dart
test('should handle timeout error', () async {
  // Mock Dio to throw timeout error
  when(dio.get(any)).thenThrow(
    DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.receiveTimeout,
    ),
  );

  expect(
    () => service.getData(),
    throwsA(isA<NetworkError>()),
  );
});
```

### Test Retry Logic

```dart
test('should retry on timeout', () async {
  var callCount = 0;
  when(dio.get(any)).thenAnswer((_) async {
    callCount++;
    if (callCount < 3) {
      throw DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );
    }
    return Response(data: {'success': true});
  });

  final result = await service.getData();
  expect(callCount, 3); // Should retry 3 times
  expect(result, isNotNull);
});
```

## Monitoring and Analytics

### Log Error Metrics

```dart
class NetworkErrorHandler {
  static void logError(NetworkError error, {String? context}) {
    // Log for debugging
    debugPrint('${context ?? 'Network Error'}: ${error.type} - ${error.message}');
    
    // Send to analytics
    Analytics.track('network_error', {
      'type': error.type.toString(),
      'status_code': error.statusCode,
      'context': context,
    });
  }
}
```

This comprehensive network error handling system ensures your app provides a professional user experience even when network issues occur. 