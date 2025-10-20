import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';

class SubscriberService {
  static final SubscriberService _instance = SubscriberService._internal();
  factory SubscriberService() => _instance;
  SubscriberService._internal();

  late Dio _dio;
  final AuthService _authService = AuthService();

  Future<void> _initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
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
        debugPrint(
            'SubscriberService: Auth token: ${token != null ? 'Present' : 'Missing'}');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint('SubscriberService: Added Authorization header');
        }
        debugPrint('SubscriberService: Request URL: ${options.uri}');
        debugPrint('SubscriberService: Request method: ${options.method}');
        handler.next(options);
      },
    ));
  }

  /// Get subscriber count for a podcast
  Future<Map<String, dynamic>> getPodcastSubscriberCount({
    required String podcastId,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      debugPrint('SubscriberService: Making API call to get subscriber count');
      debugPrint('SubscriberService: podcastId: $podcastId');
      debugPrint('SubscriberService: Base URL: ${ApiConfig.baseUrl}');
      debugPrint(
          'SubscriberService: Full URL: ${ApiConfig.baseUrl}/podcasts/$podcastId/subscribers');

      final response = await _dio.get('/podcasts/$podcastId/subscribers');

      debugPrint('SubscriberService: API response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('SubscriberService: Error getting subscriber count: $e');

      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPodcastSubscriberCount',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getPodcastSubscriberCount');
        }
      }

      // Return default data on error
      return {
        'success': false,
        'data': {
          'subscriber_count': 0,
          'message': 'Failed to load subscriber count'
        }
      };
    }
  }

  /// Get subscriber count for multiple podcasts
  Future<Map<String, dynamic>> getPodcastsSubscriberCounts({
    required List<String> podcastIds,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      debugPrint('SubscriberService: Making API call to get subscriber counts');
      debugPrint('SubscriberService: podcastIds: $podcastIds');

      final response = await _dio.post('/podcasts/subscribers/batch', data: {
        'podcast_ids': podcastIds,
      });

      debugPrint('SubscriberService: API response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('SubscriberService: Error getting subscriber counts: $e');

      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPodcastsSubscriberCounts',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getPodcastsSubscriberCounts');
        }
      }

      // Return default data on error
      return {
        'success': false,
        'data': podcastIds
            .map((id) => {
                  'podcast_id': id,
                  'subscriber_count': 0,
                })
            .toList()
      };
    }
  }
}
