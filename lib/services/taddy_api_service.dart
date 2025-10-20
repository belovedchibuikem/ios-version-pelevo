// lib/services/taddy_api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';

class TaddyApiService {
  static final TaddyApiService _instance = TaddyApiService._internal();
  factory TaddyApiService() => _instance;
  TaddyApiService._internal();

  final Dio _dio = Dio();
  String? _baseUrl;
  String? _apiKey;
  String? _userId;
  bool _isInitialized = false;

  /// Initialize the service with API key and user ID
  Future<void> initialize({String? apiKey, String? userId}) async {
    try {
      _apiKey = apiKey ?? dotenv.env['TADDY_API_KEY'];
      _userId = userId ?? dotenv.env['TADDY_USER_ID'];
      _baseUrl = dotenv.env['TADDY_API_URL'] ?? 'https://api.taddy.org';

      if (_apiKey == null || _userId == null) {
        throw Exception('API key or user ID missing');
      }

      _dio.options = BaseOptions(
        baseUrl: _baseUrl!,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'User-ID': _userId,
          'Content-Type': 'application/json',
          'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // Increased timeout
        sendTimeout: const Duration(seconds: 30),
      );

      // Add retry interceptor
      _dio.interceptors.add(RetryInterceptor(
        maxRetries: 3,
        baseDelay: const Duration(seconds: 1),
        retryOnTimeout: true,
        retryOnConnectionError: true,
        retryOnServerError: true,
      ));

      _dio.interceptors.add(LogInterceptor(
        requestBody: kDebugMode,
        responseBody: kDebugMode,
      ));

      // Test API connection
      try {
        final response = await _dio.get('/ping');
        debugPrint('Taddy API connection test: ${response.statusCode}');
      } catch (e) {
        // Just log, don't throw
        debugPrint('Taddy API connection test failed: $e');
      }

      _isInitialized = true;
      debugPrint('TaddyApiService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TaddyApiService: $e');
      rethrow;
    }
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get featured podcasts
  Future<Map<String, dynamic>> getFeaturedPodcasts() async {
    _checkInitialization();
    try {
      debugPrint('Making API request to /podcasts/featured');
      final response = await _dio.get('/podcasts/featured');
      debugPrint(
          'Featured podcasts API response status: ${response.statusCode}');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getFeaturedPodcasts');
        throw networkError;
      }
      debugPrint('Error in getFeaturedPodcasts: $e');
      rethrow;
    }
  }

  /// Get trending podcasts
  Future<Map<String, dynamic>> getTrendingPodcasts() async {
    _checkInitialization();
    try {
      final response = await _dio.get('/podcasts/trending');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getTrendingPodcasts');
        throw networkError;
      }
      debugPrint('Error fetching trending podcasts: $e');
      rethrow;
    }
  }

  /// Get podcast categories
  Future<Map<String, dynamic>> getCategories() async {
    _checkInitialization();
    try {
      final response = await _dio.get('/categories');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getCategories');
        throw networkError;
      }
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Get podcasts by category
  Future<Map<String, dynamic>> getPodcastsByCategory(String categoryId) async {
    _checkInitialization();
    try {
      final response = await _dio.get('/categories/$categoryId/podcasts');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getPodcastsByCategory');
        throw networkError;
      }
      debugPrint('Error fetching podcasts by category: $e');
      rethrow;
    }
  }

  /// Get podcast details
  Future<Map<String, dynamic>> getPodcastDetails(String podcastId) async {
    _checkInitialization();
    try {
      final response = await _dio.get('/podcasts/$podcastId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getPodcastDetails');
        throw networkError;
      }
      debugPrint('Error fetching podcast details: $e');
      rethrow;
    }
  }

  /// Get episodes for a podcast
  Future<Map<String, dynamic>> getPodcastEpisodes(String podcastId) async {
    _checkInitialization();
    try {
      final response = await _dio.get('/podcasts/$podcastId/episodes');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getPodcastEpisodes');
        throw networkError;
      }
      debugPrint('Error fetching podcast episodes: $e');
      rethrow;
    }
  }

  /// Get episode details
  Future<Map<String, dynamic>> getEpisodeDetails(String episodeId) async {
    _checkInitialization();
    try {
      final response = await _dio.get('/episodes/$episodeId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getEpisodeDetails');
        throw networkError;
      }
      debugPrint('Error fetching episode details: $e');
      rethrow;
    }
  }

  /// Search podcasts
  Future<Map<String, dynamic>> searchPodcasts(String query) async {
    _checkInitialization();
    try {
      final response =
          await _dio.get('/search/podcasts', queryParameters: {'q': query});
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'searchPodcasts');
        throw networkError;
      }
      debugPrint('Error searching podcasts: $e');
      rethrow;
    }
  }

  /// Get combined podcast feed including featured podcasts
  Future<Map<String, dynamic>> getCombinedPodcastFeed() async {
    _checkInitialization();
    try {
      final response = await _dio.get('/podcasts/combined-feed');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getCombinedPodcastFeed');
        throw networkError;
      }
      debugPrint('Error fetching combined podcast feed: $e');
      rethrow;
    }
  }

  /// Check if the service is initialized before making requests
  void _checkInitialization() {
    if (!_isInitialized) {
      debugPrint('TaddyApiService not initialized. Initializing now...');
      initialize();
    }
  }
}
