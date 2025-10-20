import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Retry interceptor for Dio with exponential backoff
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final bool retryOnTimeout;
  final bool retryOnConnectionError;
  final bool retryOnServerError;
  final Random _random = Random();

  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
    this.retryOnTimeout = true,
    this.retryOnConnectionError = true,
    this.retryOnServerError = false,
  });

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final retryCount = _getRetryCount(requestOptions);

    if (retryCount < maxRetries && _shouldRetry(err)) {
      final delay = _calculateDelay(retryCount);

      debugPrint(
          '🔄 Retrying request (${retryCount + 1}/$maxRetries) after ${delay.inMilliseconds}ms');

      // Wait for the delay
      await Future.delayed(delay);

      // Increment retry count
      _incrementRetryCount(requestOptions);

      try {
        // Retry the request
        final response = await _retryRequest(requestOptions);
        handler.resolve(response);
        return;
      } catch (retryError) {
        // If retry fails, continue with the original error
        debugPrint('❌ Retry attempt failed: $retryError');
      }
    }

    // Don't retry, pass the error to the next handler
    handler.next(err);
  }

  /// Check if the error should trigger a retry
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return retryOnTimeout;

      case DioExceptionType.connectionError:
        return retryOnConnectionError;

      case DioExceptionType.badResponse:
        if (retryOnServerError && error.response?.statusCode != null) {
          final statusCode = error.response!.statusCode!;
          // Retry on 5xx server errors
          return statusCode >= 500 && statusCode < 600;
        }
        return false;

      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return false;
    }
  }

  /// Calculate delay with exponential backoff and jitter
  Duration _calculateDelay(int retryCount) {
    // Exponential backoff: baseDelay * 2^retryCount
    final exponentialDelay = baseDelay.inMilliseconds * (1 << retryCount);

    // Add jitter (±25% random variation)
    final jitter = exponentialDelay * 0.25;
    final jitteredDelay =
        exponentialDelay + (_random.nextDouble() * 2 - 1) * jitter;

    // Cap at maxDelay
    final finalDelay = jitteredDelay.clamp(0, maxDelay.inMilliseconds);

    return Duration(milliseconds: finalDelay.round());
  }

  /// Get current retry count from request options
  int _getRetryCount(RequestOptions options) {
    return options.extra['retry_count'] ?? 0;
  }

  /// Increment retry count in request options
  void _incrementRetryCount(RequestOptions options) {
    final currentCount = _getRetryCount(options);
    options.extra['retry_count'] = currentCount + 1;
  }

  /// Retry the request with the same options
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final dio = Dio();

    // Copy the request options
    final retryOptions = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      validateStatus: requestOptions.validateStatus,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      extra: requestOptions.extra,
      followRedirects: requestOptions.followRedirects,
      maxRedirects: requestOptions.maxRedirects,
      persistentConnection: requestOptions.persistentConnection,
      requestEncoder: requestOptions.requestEncoder,
      responseDecoder: requestOptions.responseDecoder,
      listFormat: requestOptions.listFormat,
    );

    return await dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: retryOptions,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }
}

/// Extension to add retry functionality to Dio
extension RetryExtension on Dio {
  /// Add retry interceptor with custom configuration
  void addRetryInterceptor({
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    bool retryOnTimeout = true,
    bool retryOnConnectionError = true,
    bool retryOnServerError = false,
  }) {
    interceptors.add(RetryInterceptor(
      maxRetries: maxRetries,
      baseDelay: baseDelay,
      maxDelay: maxDelay,
      retryOnTimeout: retryOnTimeout,
      retryOnConnectionError: retryOnConnectionError,
      retryOnServerError: retryOnServerError,
    ));
  }
}
