import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/app_export.dart';
import '../core/config/api_config.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';
import '../core/services/auth_service.dart';
import 'library_api_service.dart';

class SubscriberCountService extends ChangeNotifier {
  static final SubscriberCountService _instance =
      SubscriberCountService._internal();
  factory SubscriberCountService() => _instance;

  final Map<String, int> _subscriberCounts = {};
  final Map<String, Timer> _refreshTimers = {};
  final LibraryApiService _apiService = LibraryApiService();
  final AuthService _authService = AuthService();
  late final Dio _dio;

  SubscriberCountService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
      },
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

  // Get subscriber count for a specific podcast
  int getSubscriberCount(String podcastId) {
    return _subscriberCounts[podcastId] ?? 0;
  }

  // Get all subscriber counts
  Map<String, int> getAllSubscriberCounts() {
    return Map.from(_subscriberCounts);
  }

  // Fetch subscriber count for a single podcast
  Future<void> fetchSubscriberCount(String podcastId) async {
    try {
      final response = await _dio.get(
        '/library/subscriptions/podcast/$podcastId/subscriber-count',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final count = data['subscriber_count'] as int;

        _subscriberCounts[podcastId] = count;
        notifyListeners();

        debugPrint(
            'SubscriberCountService: Updated count for $podcastId: $count');
      }
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'fetchSubscriberCount');
        // Don't rethrow for subscriber count updates to avoid breaking UI
        debugPrint(
            'SubscriberCountService: Network error fetching count for $podcastId: ${networkError.userMessage}');
      } else {
        debugPrint(
            'SubscriberCountService: Error fetching subscriber count for $podcastId: $e');
      }
    }
  }

  // Fetch subscriber counts for multiple podcasts
  Future<void> fetchMultipleSubscriberCounts(List<String> podcastIds) async {
    if (podcastIds.isEmpty) return;

    try {
      final response = await _dio.post(
        '/library/subscriptions/podcast/subscriber-counts',
        data: {
          'podcast_ids': podcastIds,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;

        for (final entry in data.entries) {
          final podcastId = entry.key;
          final count = entry.value as int;
          _subscriberCounts[podcastId] = count;
        }

        notifyListeners();
        debugPrint(
            'SubscriberCountService: Updated counts for ${podcastIds.length} podcasts');
      }
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'fetchMultipleSubscriberCounts');
        // Don't rethrow for subscriber count updates to avoid breaking UI
        debugPrint(
            'SubscriberCountService: Network error fetching multiple counts: ${networkError.userMessage}');
      } else {
        debugPrint(
            'SubscriberCountService: Error fetching multiple subscriber counts: $e');
      }
    }
  }

  // Start real-time updates for a podcast
  void startRealTimeUpdates(String podcastId) {
    // Cancel existing timer if any
    _refreshTimers[podcastId]?.cancel();

    // Fetch initial count
    fetchSubscriberCount(podcastId);

    // Set up periodic refresh (every 30 seconds)
    _refreshTimers[podcastId] = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchSubscriberCount(podcastId),
    );

    debugPrint(
        'SubscriberCountService: Started real-time updates for $podcastId');
  }

  // Stop real-time updates for a podcast
  void stopRealTimeUpdates(String podcastId) {
    _refreshTimers[podcastId]?.cancel();
    _refreshTimers.remove(podcastId);
    debugPrint(
        'SubscriberCountService: Stopped real-time updates for $podcastId');
  }

  // Start real-time updates for multiple podcasts
  void startMultipleRealTimeUpdates(List<String> podcastIds) {
    // Cancel existing timers
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();

    // Fetch initial counts
    fetchMultipleSubscriberCounts(podcastIds);

    // Set up periodic refresh for all podcasts
    _refreshTimers['multiple'] = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchMultipleSubscriberCounts(podcastIds),
    );

    debugPrint(
        'SubscriberCountService: Started real-time updates for ${podcastIds.length} podcasts');
  }

  // Stop all real-time updates
  void stopAllRealTimeUpdates() {
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();
    debugPrint('SubscriberCountService: Stopped all real-time updates');
  }

  // Update subscriber count locally (for immediate UI updates)
  void updateSubscriberCount(String podcastId, int count) {
    _subscriberCounts[podcastId] = count;
    notifyListeners();
    debugPrint(
        'SubscriberCountService: Locally updated count for $podcastId: $count');
  }

  // Clear all data
  void clear() {
    stopAllRealTimeUpdates();
    _subscriberCounts.clear();
    notifyListeners();
    debugPrint('SubscriberCountService: Cleared all data');
  }

  @override
  void dispose() {
    stopAllRealTimeUpdates();
    super.dispose();
  }
}
