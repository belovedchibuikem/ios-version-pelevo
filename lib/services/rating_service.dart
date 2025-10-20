import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  late Dio _dio;
  final AuthService _authService = AuthService();

  Future<void> _initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60), // Increased timeout
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
            'RatingService: Auth token: ${token != null ? 'Present' : 'Missing'}');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint('RatingService: Added Authorization header');
        }
        debugPrint('RatingService: Request URL: ${options.uri}');
        debugPrint('RatingService: Request method: ${options.method}');
        handler.next(options);
      },
    ));
  }

  /// Rate a podcast
  Future<Map<String, dynamic>> ratePodcast({
    required String podcastId,
    required int rating,
    String? comment,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      debugPrint('RatingService: Making API call to rate podcast');
      debugPrint('RatingService: podcastId: $podcastId, rating: $rating');
      debugPrint('RatingService: Base URL: ${ApiConfig.baseUrl}');
      debugPrint(
          'RatingService: Full URL: ${ApiConfig.baseUrl}/ratings/rate-podcast');

      final requestData = {
        'podcast_id': podcastId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      };

      debugPrint('RatingService: Request data: $requestData');

      final response =
          await _dio.post('/ratings/rate-podcast', data: requestData);

      debugPrint('RatingService: API response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('RatingService: Error rating podcast: $e');

      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'ratePodcast',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError, context: 'ratePodcast');

          // Extract the actual error message from the response for user-friendly display
          if (networkError.type == NetworkErrorType.forbidden &&
              networkError.statusCode == 403) {
            final errorData = e.response?.data;
            if (errorData is Map && errorData.containsKey('message')) {
              String userMessage = errorData['message'];
              debugPrint('RatingService: Extracted message: $userMessage');
              throw Exception(userMessage);
            }
          }
        }
        throw NetworkErrorHandler.handleDioException(e);
      }

      rethrow;
    }
  }

  /// Get user's rating for a podcast
  Future<Map<String, dynamic>> getUserRating(String podcastId) async {
    await _initialize();

    try {
      final response = await _dio.get('/ratings/user-rating/$podcastId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getUserRating');
        throw networkError;
      }
      debugPrint('Error getting user rating: $e');
      rethrow;
    }
  }

  /// Get podcast rating statistics
  Future<Map<String, dynamic>> getPodcastRating(String podcastId) async {
    await _initialize();

    try {
      final response = await _dio.get('/ratings/podcast-rating/$podcastId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getPodcastRating');
        throw networkError;
      }
      debugPrint('Error getting podcast rating: $e');
      rethrow;
    }
  }

  /// Get recent ratings for a podcast
  Future<Map<String, dynamic>> getRecentRatings(String podcastId) async {
    await _initialize();

    try {
      final response = await _dio.get('/ratings/recent-ratings/$podcastId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getRecentRatings');
        throw networkError;
      }
      debugPrint('Error getting recent ratings: $e');
      rethrow;
    }
  }
}
