import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/utils/network_error_handler.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';

class ListeningStatisticsService {
  late Dio _dio;

  ListeningStatisticsService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final authService = AuthService();
        final token = await authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// Get comprehensive listening statistics
  Future<Map<String, dynamic>> getListeningStatistics({
    String period = 'week',
    BuildContext? context,
  }) async {
    try {
      final response = await _dio.get(
        '/library/listening-statistics',
        queryParameters: {'period': period},
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      } else {
        throw Exception('Failed to load listening statistics');
      }
    } on DioException catch (e) {
      final networkError = NetworkErrorHandler.handleDioException(e);
      NetworkErrorHandler.logError(networkError,
          context: 'getListeningStatistics');

      if (context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'getListeningStatistics',
          onRetry: () =>
              getListeningStatistics(period: period, context: context),
        );
      }

      // Return empty data structure instead of throwing
      return {
        'overview': {
          'total_listening_time': 0.0,
          'episodes_completed': 0,
          'total_episodes': 0,
          'avg_session_length': 0.0,
          'streak_days': 0,
          'top_podcasts': [],
          'weekly_activity': [],
        },
        'activity': {
          'recent_activity': [],
          'daily_activity': [],
          'hourly_activity': [],
        },
        'insights': {
          'genre_distribution': [],
          'listening_patterns': {
            'completion_rate': 0.0,
            'avg_session_length': 0.0,
            'favorite_genre': 'Unknown',
            'most_active_day': 'Unknown',
            'most_active_time': 'Unknown',
          },
          'achievements': [],
        },
      };
    } catch (e) {
      debugPrint('Error fetching listening statistics: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load listening statistics. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () =>
                  getListeningStatistics(period: period, context: context),
            ),
          ),
        );
      }

      // Return empty data structure
      return {
        'overview': {
          'total_listening_time': 0.0,
          'episodes_completed': 0,
          'total_episodes': 0,
          'avg_session_length': 0.0,
          'streak_days': 0,
          'top_podcasts': [],
          'weekly_activity': [],
        },
        'activity': {
          'recent_activity': [],
          'daily_activity': [],
          'hourly_activity': [],
        },
        'insights': {
          'genre_distribution': [],
          'listening_patterns': {
            'completion_rate': 0.0,
            'avg_session_length': 0.0,
            'favorite_genre': 'Unknown',
            'most_active_day': 'Unknown',
            'most_active_time': 'Unknown',
          },
          'achievements': [],
        },
      };
    }
  }

  /// Get statistics for a specific period
  Future<Map<String, dynamic>> getStatisticsForPeriod(String period,
      {BuildContext? context}) async {
    return getListeningStatistics(period: period, context: context);
  }
}
