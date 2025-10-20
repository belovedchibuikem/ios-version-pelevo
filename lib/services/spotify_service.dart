// This file is deprecated. Use PodcastIndexService instead. All Spotify API usage has been removed from the project.

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';

class SpotifyService {
  final Dio _dio = Dio();
  bool _isInitialized = false;
  String? _baseUrl;
  String? _apiKey;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _baseUrl = dotenv.env['SPOTIFY_API_URL'];
      _apiKey = dotenv.env['SPOTIFY_API_KEY'];

      if (_baseUrl == null || _apiKey == null) {
        throw Exception('Spotify API configuration missing in .env file');
      }

      _dio.options = BaseOptions(
        baseUrl: _baseUrl!,
        headers: {
          'Authorization': 'Bearer _apiKey',
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

      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
        ));
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing SpotifyService: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFeaturedPodcasts() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('Fetching featured podcasts from API...');
      final response = await _dio.get('/api/podcasts/featured');
      debugPrint('Featured podcasts API response: ${response.data}');

      if (response.data == null) {
        throw Exception('Empty response from API');
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getFeaturedPodcasts');
        // Return a structured error response
        return {
          'success': false,
          'message': 'Failed to fetch featured podcasts',
          'error': networkError.userMessage
        };
      }
      debugPrint('Error fetching featured podcasts: $e');
      // Return a structured error response
      return {
        'success': false,
        'message': 'Failed to fetch featured podcasts',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> getTrendingPodcasts() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('Fetching trending podcasts from API...');
      final response = await _dio.get('/api/podcasts/trending');
      debugPrint('Trending podcasts API response: ${response.data}');

      if (response.data == null) {
        throw Exception('Empty response from API');
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getTrendingPodcasts');
        // Return a structured error response
        return {
          'success': false,
          'message': 'Failed to fetch trending podcasts',
          'error': networkError.userMessage
        };
      }
      debugPrint('Error fetching trending podcasts: $e');
      // Return a structured error response
      return {
        'success': false,
        'message': 'Failed to fetch trending podcasts',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final response = await _dio.get('/podcasts/categories');
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

  Future<Map<String, dynamic>> getPodcastsByCategory(String category) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final response = await _dio.get('/podcasts/category/$category');
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

  Future<Map<String, dynamic>> getPodcastDetails(String podcastId) async {
    if (!_isInitialized) {
      await initialize();
    }

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

  Future<Map<String, dynamic>> getPodcastEpisodes(String podcastId) async {
    if (!_isInitialized) {
      await initialize();
    }

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
}
