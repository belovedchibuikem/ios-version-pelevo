import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';
import '../models/play_history.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

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
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// Get user's play history with filtering
  Future<List<PlayHistory>> getPlayHistory({
    int page = 1,
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
    String? podcastId,
    String? sortBy = 'last_played_at',
    String? sortOrder = 'desc',
    int perPage = 20,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final queryParams = {
        'page': page,
        'per_page': perPage,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (podcastId != null) 'podcast_id': podcastId,
      };

      final response =
          await _dio.get('/library/play-history', queryParameters: queryParams);

      if (response.data['data'] != null) {
        final data = response.data['data'] as List;
        return data.map((json) => PlayHistory.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPlayHistory',
            onRetry: onRetry,
          );
        } else {
          debugPrint('Network error in getPlayHistory: ${e.message}');
        }
        throw Exception('Network error: ${e.message}');
      }
      debugPrint('Error fetching play history: $e');
      rethrow;
    }
  }

  /// Get recent play history
  Future<List<PlayHistory>> getRecentPlayHistory({
    int days = 7,
    int limit = 10,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final response =
          await _dio.get('/library/play-history/recent', queryParameters: {
        'days': days,
        'limit': limit,
      });

      if (response.data['data'] != null) {
        final data = response.data['data'] as List;
        return data.map((json) => PlayHistory.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getRecentPlayHistory',
            onRetry: onRetry,
          );
        } else {
          debugPrint('Network error in getRecentPlayHistory: ${e.message}');
        }
        throw Exception('Network error: ${e.message}');
      }
      debugPrint('Error fetching recent play history: $e');
      rethrow;
    }
  }

  /// Get play history by status
  Future<List<PlayHistory>> getPlayHistoryByStatus(
    String status, {
    int page = 1,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final response = await _dio
          .get('/library/play-history/status/$status', queryParameters: {
        'page': page,
      });

      if (response.data['data'] != null) {
        final data = response.data['data'] as List;
        return data.map((json) => PlayHistory.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPlayHistoryByStatus',
            onRetry: onRetry,
          );
        } else {
          debugPrint('Network error in getPlayHistoryByStatus: ${e.message}');
        }
        throw Exception('Network error: ${e.message}');
      }
      debugPrint('Error fetching play history by status: $e');
      rethrow;
    }
  }

  /// Update play history entry
  Future<PlayHistory> updatePlayHistory({
    required String episodeId,
    required String status,
    required int position,
    int? progressSeconds,
    int? totalListeningTime,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final response = await _dio.post('/library/play-history', data: {
        'podcastindex_episode_id': episodeId,
        'status': status,
        'position': position,
        if (progressSeconds != null) 'progress_seconds': progressSeconds,
        if (totalListeningTime != null)
          'total_listening_time': totalListeningTime,
      });

      return PlayHistory.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'updatePlayHistory',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'updatePlayHistory');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error updating play history: $e');
      rethrow;
    }
  }

  /// Mark episode as completed
  Future<PlayHistory> markEpisodeCompleted(
    int playHistoryId, {
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final response = await _dio
          .post('/library/play-history/$playHistoryId/mark-completed');
      return PlayHistory.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'markEpisodeCompleted',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'markEpisodeCompleted');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error marking episode as completed: $e');
      rethrow;
    }
  }

  /// Delete play history entry
  Future<void> deletePlayHistory(
    int playHistoryId, {
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      await _dio.delete('/library/play-history/$playHistoryId');
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'deletePlayHistory',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'deletePlayHistory');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error deleting play history: $e');
      rethrow;
    }
  }

  /// Batch delete play history entries
  Future<void> batchDeletePlayHistory(
    List<int> playHistoryIds, {
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      await _dio.post('/library/play-history/batch-destroy', data: {
        'play_history_ids': playHistoryIds,
      });
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'batchDeletePlayHistory',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'batchDeletePlayHistory');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error batch deleting play history: $e');
      rethrow;
    }
  }

  /// Clear all play history
  Future<void> clearAllPlayHistory({
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      await _dio.delete('/library/play-history/clear-all');
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'clearAllPlayHistory',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'clearAllPlayHistory');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error clearing all play history: $e');
      rethrow;
    }
  }

  /// Get listening statistics
  Future<Map<String, dynamic>> getListeningStatistics({
    int days = 30,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final response =
          await _dio.get('/library/play-history/statistics', queryParameters: {
        'days': days,
      });

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getListeningStatistics',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getListeningStatistics');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error fetching listening statistics: $e');
      rethrow;
    }
  }

  /// Get specific play history entry
  Future<PlayHistory> getPlayHistoryEntry(
    int playHistoryId, {
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final response = await _dio.get('/library/play-history/$playHistoryId');
      return PlayHistory.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPlayHistoryEntry',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getPlayHistoryEntry');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error fetching play history entry: $e');
      rethrow;
    }
  }

  /// Real-time progress update
  Future<void> updateProgress({
    required String episodeId,
    required int progressSeconds,
    required int totalListeningTime,
    BuildContext? context,
  }) async {
    await _initialize();

    try {
      await _dio.put('/library/play-history', data: {
        'podcastindex_episode_id': episodeId,
        'progress_seconds': progressSeconds,
        'total_listening_time': totalListeningTime,
        'status': 'played',
      });
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'updateProgress');
        // Don't show snackbar for progress updates to avoid blocking playback
        // but still log the error for debugging
      } else {
        debugPrint('Error updating progress: $e');
      }
    }
  }

  /// Get completed episodes
  Future<List<PlayHistory>> getCompletedEpisodes({
    int page = 1,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    return getPlayHistoryByStatus('completed',
        page: page, context: context, onRetry: onRetry);
  }

  /// Get in-progress episodes
  Future<List<PlayHistory>> getInProgressEpisodes({
    int page = 1,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    return getPlayHistoryByStatus('in_progress',
        page: page, context: context, onRetry: onRetry);
  }

  /// Search play history
  Future<List<PlayHistory>> searchPlayHistory(
    String query, {
    int page = 1,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    return getPlayHistory(
        search: query, page: page, context: context, onRetry: onRetry);
  }

  /// Get play history by date range
  Future<List<PlayHistory>> getPlayHistoryByDateRange({
    required DateTime fromDate,
    required DateTime toDate,
    int page = 1,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    return getPlayHistory(
      dateFrom: fromDate.toIso8601String(),
      dateTo: toDate.toIso8601String(),
      page: page,
      context: context,
      onRetry: onRetry,
    );
  }

  /// Ensure episodes exist for play history entries
  Future<Map<String, dynamic>> ensureEpisodesExist({
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await _initialize();

    try {
      final response = await _dio.post('/library/play-history/ensure-episodes');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'ensureEpisodesExist',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'ensureEpisodesExist');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error ensuring episodes exist: $e');
      rethrow;
    }
  }
}
