import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../error_handling/global_error_handler.dart';

/// Safe API service wrapper that handles errors gracefully
class SafeApiService {
  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Safe GET request with error handling and retry logic
  static Future<http.Response> safeGet(
    String url, {
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint('🔄 API GET attempt $attempts/$maxRetries: $url');

        final response =
            await http.get(Uri.parse(url), headers: headers).timeout(timeout);

        // Check for HTTP error status codes
        if (response.statusCode >= 400) {
          throw HttpException(
              'HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }

        debugPrint('✅ API GET successful: ${response.statusCode}');
        return response;
      } on TimeoutException {
        debugPrint('⏰ API GET timeout on attempt $attempts');
        if (attempts >= maxRetries) {
          throw TimeoutException(
              'Request timed out after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on SocketException {
        debugPrint('🌐 API GET network error on attempt $attempts');
        if (attempts >= maxRetries) {
          throw SocketException(
              'Network connection failed after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on HttpException catch (e) {
        debugPrint('🚫 API GET HTTP error on attempt $attempts: ${e.message}');
        // Don't retry on HTTP errors (4xx, 5xx)
        rethrow;
      } catch (e) {
        debugPrint('❌ API GET unexpected error on attempt $attempts: $e');
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Failed after $maxRetries attempts');
  }

  /// Safe POST request with error handling and retry logic
  static Future<http.Response> safePost(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _defaultTimeout,
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint('🔄 API POST attempt $attempts/$maxRetries: $url');

        final response = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(timeout);

        // Check for HTTP error status codes
        if (response.statusCode >= 400) {
          throw HttpException(
              'HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }

        debugPrint('✅ API POST successful: ${response.statusCode}');
        return response;
      } on TimeoutException {
        debugPrint('⏰ API POST timeout on attempt $attempts');
        if (attempts >= maxRetries) {
          throw TimeoutException(
              'Request timed out after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on SocketException {
        debugPrint('🌐 API POST network error on attempt $attempts');
        if (attempts >= maxRetries) {
          throw SocketException(
              'Network connection failed after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on HttpException catch (e) {
        debugPrint('🚫 API POST HTTP error on attempt $attempts: ${e.message}');
        // Don't retry on HTTP errors (4xx, 5xx)
        rethrow;
      } catch (e) {
        debugPrint('❌ API POST unexpected error on attempt $attempts: $e');
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Failed after $maxRetries attempts');
  }

  /// Safe PUT request with error handling and retry logic
  static Future<http.Response> safePut(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _defaultTimeout,
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint('🔄 API PUT attempt $attempts/$maxRetries: $url');

        final response = await http
            .put(Uri.parse(url), headers: headers, body: body)
            .timeout(timeout);

        // Check for HTTP error status codes
        if (response.statusCode >= 400) {
          throw HttpException(
              'HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }

        debugPrint('✅ API PUT successful: ${response.statusCode}');
        return response;
      } on TimeoutException {
        debugPrint('⏰ API PUT timeout on attempt $attempts');
        if (attempts >= maxRetries) {
          throw TimeoutException(
              'Request timed out after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on SocketException {
        debugPrint('🌐 API PUT network error on attempt $attempts');
        if (attempts >= maxRetries) {
          throw SocketException(
              'Network connection failed after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on HttpException catch (e) {
        debugPrint('🚫 API PUT HTTP error on attempt $attempts: ${e.message}');
        // Don't retry on HTTP errors (4xx, 5xx)
        rethrow;
      } catch (e) {
        debugPrint('❌ API PUT unexpected error on attempt $attempts: $e');
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Failed after $maxRetries attempts');
  }

  /// Safe DELETE request with error handling and retry logic
  static Future<http.Response> safeDelete(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = _defaultTimeout,
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint('🔄 API DELETE attempt $attempts/$maxRetries: $url');

        final response = await http
            .delete(Uri.parse(url), headers: headers, body: body)
            .timeout(timeout);

        // Check for HTTP error status codes
        if (response.statusCode >= 400) {
          throw HttpException(
              'HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }

        debugPrint('✅ API DELETE successful: ${response.statusCode}');
        return response;
      } on TimeoutException {
        debugPrint('⏰ API DELETE timeout on attempt $attempts');
        if (attempts >= maxRetries) {
          throw TimeoutException(
              'Request timed out after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on SocketException {
        debugPrint('🌐 API DELETE network error on attempt $attempts');
        if (attempts >= maxRetries) {
          throw SocketException(
              'Network connection failed after $maxRetries attempts');
        }
        await Future.delayed(retryDelay);
      } on HttpException catch (e) {
        debugPrint(
            '🚫 API DELETE HTTP error on attempt $attempts: ${e.message}');
        // Don't retry on HTTP errors (4xx, 5xx)
        rethrow;
      } catch (e) {
        debugPrint('❌ API DELETE unexpected error on attempt $attempts: $e');
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Failed after $maxRetries attempts');
  }

  /// Parse JSON response safely with error handling
  static Map<String, dynamic>? safeParseJson(http.Response response) {
    try {
      if (response.body.isEmpty) {
        debugPrint('⚠️ Empty response body');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('✅ JSON parsed successfully');
      return json;
    } on FormatException catch (e) {
      debugPrint('❌ JSON parse error: $e');
      debugPrint('Response body: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error parsing JSON: $e');
      return null;
    }
  }

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    return error is TimeoutException ||
        error is SocketException ||
        (error is HttpException && error.message.contains('500'));
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    return GlobalErrorHandler.getUserFriendlyMessage(error);
  }
}
