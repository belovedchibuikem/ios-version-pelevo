import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/services/unified_auth_service.dart';
import '../core/utils/network_error_handler.dart';

class ProfileStatsService {
  static final ProfileStatsService _instance = ProfileStatsService._internal();
  factory ProfileStatsService() => _instance;
  ProfileStatsService._internal();

  late final Dio _dio;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      // Add auth interceptor
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final authService = UnifiedAuthService();
            final token = await authService.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              debugPrint(
                  '🔐 ProfileStatsService: Authorization header set with token: ${token.substring(0, 10)}...');
            } else {
              debugPrint(
                  '⚠️ ProfileStatsService: No token available for request to ${options.path}');
            }
            handler.next(options);
          } catch (e) {
            debugPrint('❌ ProfileStatsService: Error in auth interceptor: $e');
            // Continue without auth token if there's an error
            handler.next(options);
          }
        },
      ));

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing ProfileStatsService: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Get user profile statistics including subscriptions, downloads and listening hours
  Future<Map<String, dynamic>> getProfileStats({
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    try {
      await initialize();
    } catch (e) {
      debugPrint('Failed to initialize ProfileStatsService: $e');
      return {
        'subscriptionsCount': 0,
        'downloadsCount': 0,
        'listeningHours': 0,
        'success': false,
        'error': 'Service initialization failed',
        'errorCode': 'INIT_ERROR',
      };
    }

    try {
      // Get total subscription count without pagination
      final subscriptionsResponse =
          await _dio.get('/api/library/subscriptions/all');

      // Get total download count without pagination
      final downloadsResponse = await _dio.get('/api/library/downloads/total');

      if (subscriptionsResponse.statusCode == 200 &&
          downloadsResponse.statusCode == 200) {
        try {
          final subscriptionsData =
              subscriptionsResponse.data['data'] as Map<String, dynamic>?;
          final subscriptionsCount =
              subscriptionsData?['total_subscriptions'] as int? ?? 0;

          final downloadsData =
              downloadsResponse.data['data'] as Map<String, dynamic>?;
          final downloadsCount = downloadsData?['total_downloads'] as int? ?? 0;

          // Calculate total listening hours from play history
          final listeningHours =
              await _getListeningHours(context: context, onRetry: onRetry);

          return {
            'subscriptionsCount': subscriptionsCount,
            'downloadsCount': downloadsCount,
            'listeningHours': listeningHours,
            'success': true,
          };
        } catch (e) {
          debugPrint('Error parsing profile stats data: $e');
          return {
            'subscriptionsCount': 0,
            'downloadsCount': 0,
            'listeningHours': 0,
            'success': false,
            'error': 'Failed to parse profile stats data',
            'errorCode': 'PARSE_ERROR',
          };
        }
      } else {
        throw Exception('Failed to fetch profile stats');
      }
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getProfileStats',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getProfileStats');
        }

        // Return error response instead of throwing
        return {
          'subscriptionsCount': 0,
          'downloadsCount': 0,
          'listeningHours': 0,
          'success': false,
          'error': 'Network error occurred while fetching profile stats',
          'errorCode': 'NETWORK_ERROR',
        };
      }

      debugPrint('Error fetching profile stats: $e');

      // Return error response for other exceptions
      return {
        'subscriptionsCount': 0,
        'downloadsCount': 0,
        'listeningHours': 0,
        'success': false,
        'error': 'Failed to fetch profile stats: ${e.toString()}',
        'errorCode': 'GENERAL_ERROR',
      };
    }
  }

  /// Get listening hours from play history
  Future<int> _getListeningHours({
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    try {
      final response = await _dio.get('/api/library/play-history');

      if (response.statusCode == 200) {
        final playHistory = response.data['data'] as List<dynamic>;

        // Calculate total listening hours from progress_seconds
        int totalSeconds = 0;
        for (final history in playHistory) {
          final progressSeconds = history['progress_seconds'] as int? ?? 0;
          totalSeconds += progressSeconds;
        }

        // Convert to hours (rounded down)
        return totalSeconds ~/ 3600;
      } else {
        return 0;
      }
    } catch (e) {
      debugPrint('Error fetching listening hours: $e');
      // Return 0 hours on error, but don't crash the entire operation
      return 0;
    }
  }

  /// Get detailed subscription information
  Future<List<Map<String, dynamic>>> getSubscriptions({
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    try {
      await initialize();
    } catch (e) {
      debugPrint('Failed to initialize ProfileStatsService: $e');
      return [];
    }

    try {
      final response = await _dio.get('/api/library/subscriptions');

      if (response.statusCode == 200) {
        final subscriptions = response.data['data'] as List<dynamic>;
        return subscriptions.map((sub) => sub as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch subscriptions');
      }
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getSubscriptions',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getSubscriptions');
        }

        // Return error response instead of throwing
        return [];
      }

      debugPrint('Error fetching subscriptions: $e');

      // Return empty list for other exceptions
      return [];
    }
  }
}
