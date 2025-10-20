import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';
import '../core/services/unified_auth_service.dart';

class PodcastIndexService {
  static final PodcastIndexService _instance = PodcastIndexService._internal();
  factory PodcastIndexService() => _instance;
  PodcastIndexService._internal();
  final Dio _dio = Dio();
  final UnifiedAuthService _authService = UnifiedAuthService();
  String? _baseUrl;
  bool _isInitialized = false;

  /// @deprecated This method is no longer needed. Authentication is now automatic.
  /// The service will automatically retrieve and use the current authentication token.
  void setAuthToken(String token) {
    debugPrint(
        '⚠️ PodcastIndexService.setAuthToken is deprecated. Authentication is now automatic.');
    // Token is no longer stored - authentication is handled automatically
  }

  /// Setup automatic authentication interceptor
  void _setupAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint(
                '🔐 PodcastIndexService: Auto-added auth token: ${token.substring(0, 10)}...');
          } else {
            debugPrint(
                '⚠️ PodcastIndexService: No auth token available for request to ${options.path}');
          }
          handler.next(options);
        } catch (e) {
          debugPrint('❌ PodcastIndexService: Error in auth interceptor: $e');
          // Continue without auth token if there's an error
          handler.next(options);
        }
      },
    ));
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _baseUrl = '${ApiConfig.baseUrl}/api';
    debugPrint('PodcastIndexService baseUrl: $_baseUrl');

    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
    };

    debugPrint('🔐 PodcastIndexService: Setting up automatic authentication');

    _dio.options = BaseOptions(
      baseUrl: _baseUrl!,
      headers: headers,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    );

    // Setup automatic authentication interceptor
    _setupAuthInterceptor();

    // Add retry interceptor with better settings
    _dio.interceptors.add(RetryInterceptor(
      maxRetries: 2,
      baseDelay: const Duration(seconds: 2),
      retryOnTimeout: true,
      retryOnConnectionError: true,
      retryOnServerError: false,
      maxDelay: const Duration(seconds: 8),
    ));

    if (kDebugMode) {
      _dio.interceptors
          .add(LogInterceptor(requestBody: true, responseBody: true));
    }
    _isInitialized = true;
    debugPrint(
        '✅ PodcastIndexService initialized with automatic authentication');
  }

  Future<List<dynamic>> getCategories({
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    // Debug request details
    debugPrint('🔐 getCategories: Making request to /podcasts/categories');
    debugPrint('🔐 getCategories: Base URL: ${_dio.options.baseUrl}');
    debugPrint('🔐 getCategories: Headers: ${_dio.options.headers}');
    debugPrint(
        '🔐 getCategories: Authentication will be handled automatically');

    try {
      final response = await _dio.get('/podcasts/categories');
      debugPrint('Raw API response for categories: ${response.data}');
      if (response.data is List) {
        return response.data;
      } else if (response.data is Map && response.data['feeds'] != null) {
        return response.data['feeds'] as List;
      } else if (response.data is Map) {
        return (response.data as Map).values.toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getCategories',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError, context: 'getCategories');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPodcastDetails(
    String feedId, {
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/$feedId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPodcastDetails',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getPodcastDetails');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error fetching podcast details: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPodcastDetailsWithEpisodes(String feedId,
      {BuildContext? context, int page = 1, int perPage = 50}) async {
    await initialize();
    try {
      debugPrint('Service: Making API call to /podcasts/by/$feedId');
      debugPrint('Service: Page: $page, PerPage: $perPage');
      debugPrint(
          'Service: Full URL: ${_dio.options.baseUrl}/podcasts/by/$feedId');
      final response = await _dio.get('/podcasts/by/$feedId', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      debugPrint('Service: API response status: ${response.statusCode}');
      debugPrint('Service: API response data keys: ${response.data.keys}');
      debugPrint(
          'Service: API response success: ${response.data['success'] ?? 'N/A'}');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getPodcastDetailsWithEpisodes');

        // Show SnackBar if context is provided
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPodcastDetailsWithEpisodes',
            onRetry: () =>
                getPodcastDetailsWithEpisodes(feedId, context: context),
          );
        }

        // Return empty data instead of throwing
        return {
          'podcast': null,
          'episodes': <dynamic>[],
        };
      }
      debugPrint('Error fetching podcast details with episodes: $e');

      // Show generic error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load podcast details. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () =>
                  getPodcastDetailsWithEpisodes(feedId, context: context),
            ),
          ),
        );
      }

      return {
        'podcast': null,
        'episodes': <dynamic>[],
      };
    }
  }

  Future<List<dynamic>> getFeaturedPodcasts({BuildContext? context}) async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/featured');

      // Debug: Print the API response
      debugPrint('=== FEATURED PODCASTS API DEBUG ===');
      debugPrint('API response: ${response.data}');
      if (response.data is List && response.data.isNotEmpty) {
        debugPrint('First podcast in response: ${response.data.first}');
        debugPrint('First podcast author: ${response.data.first['author']}');
        debugPrint('First podcast creator: ${response.data.first['creator']}');
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getFeaturedPodcasts');

        // Show SnackBar if context is provided
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getFeaturedPodcasts',
            onRetry: () => getFeaturedPodcasts(context: context),
          );
        }

        return [];
      }
      debugPrint('Error fetching featured podcasts: $e');

      // Show generic error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load featured podcasts. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => getFeaturedPodcasts(context: context),
            ),
          ),
        );
      }

      return [];
    }
  }

  Future<List<dynamic>> getTrendingPodcasts({BuildContext? context}) async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/trending');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getTrendingPodcasts');

        // Show SnackBar if context is provided
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getTrendingPodcasts',
            onRetry: () => getTrendingPodcasts(context: context),
          );
        }

        return [];
      }
      debugPrint('Error fetching trending podcasts: $e');

      // Show generic error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load trending podcasts. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => getTrendingPodcasts(context: context),
            ),
          ),
        );
      }

      return [];
    }
  }

  Future<List<dynamic>> getRecommendedPodcasts({BuildContext? context}) async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/recommended');
      return response.data['data'] ?? [];
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getRecommendedPodcasts');

        // Show SnackBar if context is provided
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getRecommendedPodcasts',
            onRetry: () => getRecommendedPodcasts(context: context),
          );
        }

        return [];
      }
      debugPrint('Error fetching recommended podcasts: $e');

      // Show generic error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load recommended podcasts. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => getRecommendedPodcasts(context: context),
            ),
          ),
        );
      }

      return [];
    }
  }

  Future<List<dynamic>> getNewPodcasts({BuildContext? context}) async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/new-podcasts');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getNewPodcasts');

        // Show SnackBar if context is provided
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getNewPodcasts',
            onRetry: () => getNewPodcasts(context: context),
          );
        }

        return [];
      }
      debugPrint('Error fetching new podcasts: $e');

      // Show generic error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load new podcasts. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => getNewPodcasts(context: context),
            ),
          ),
        );
      }

      return [];
    }
  }

  Future<Map<String, dynamic>> subscribe(String feedId) async {
    await initialize();
    try {
      final response = await _dio.post('/podcasts/subscribe/$feedId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'subscribe');
        throw networkError;
      }
      debugPrint('Error subscribing to podcast: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> unsubscribe(String feedId) async {
    await initialize();
    try {
      final response = await _dio.post('/podcasts/unsubscribe/$feedId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'unsubscribe');
        throw networkError;
      }
      debugPrint('Error unsubscribing from podcast: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getNotifications() async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/notifications');
      return response.data['notifications'] ?? [];
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getNotifications');
        throw networkError;
      }
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPodcastsByCategory(String categoryId) async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/category/$categoryId');
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

  Future<List<dynamic>> getPodcastEpisodes(String podcastId) async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/$podcastId/episodes');
      return response.data['episodes'] ?? [];
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

  /// Fetch paginated episodes for a podcast (authenticated, with meta)
  Future<Map<String, dynamic>> getPaginatedEpisodes(
      String feedId, int page, int perPage,
      {BuildContext? context}) async {
    await initialize();
    try {
      final response = await _dio.get(
        '/podcasts/by/$feedId',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getPaginatedEpisodes');

        // Show SnackBar if context is provided
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getPaginatedEpisodes',
            onRetry: () =>
                getPaginatedEpisodes(feedId, page, perPage, context: context),
          );
        }

        // Return empty data instead of throwing
        return {
          'episodes': <dynamic>[],
          'meta': {
            'page': page,
            'per_page': perPage,
            'total': 0,
            'has_more': false,
          },
        };
      }
      debugPrint('Error fetching paginated episodes: $e');

      // Show generic error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load episodes. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () =>
                  getPaginatedEpisodes(feedId, page, perPage, context: context),
            ),
          ),
        );
      }

      // Return empty data instead of rethrowing
      return {
        'episodes': <dynamic>[],
        'meta': {
          'page': page,
          'per_page': perPage,
          'total': 0,
          'has_more': false,
        },
      };
    }
  }

  Future<List<dynamic>> getTrueCrimePodcasts() async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/true-crime');
      final data = response.data;
      if (data is List) {
        return data;
      } else if (data is Map) {
        // If the API returns a Map, return its values as a List
        return data.values.toList();
      } else {
        debugPrint(
            'Unexpected response from /podcasts/true-crime: Type: ${data.runtimeType}\nData: $data');
        return [];
      }
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getTrueCrimePodcasts');
        // Don't rethrow for this method to avoid breaking UI
        debugPrint(
            'Error fetching true crime podcasts: ${networkError.userMessage}');
        return [];
      }
      debugPrint('Error fetching true crime podcasts: $e');
      return [];
    }
  }

  Future<List<dynamic>> getHealthPodcasts() async {
    await initialize();
    try {
      final response = await _dio.get('/podcasts/health');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getHealthPodcasts');
        throw networkError;
      }
      debugPrint('Error fetching health podcasts: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> searchPodcasts(String query,
      {BuildContext? context}) async {
    await initialize();
    try {
      final response = await _dio
          .get('/podcast-index/search', queryParameters: {'q': query});
      final data = response.data;
      // Handle the actual API response structure
      if (data is Map &&
          data['data'] != null &&
          data['data']['feeds'] != null) {
        return data['data']['feeds'] as List;
      }
      // fallback to previous logic for other endpoints
      if (data is List) {
        return data;
      } else if (data is Map && data['podcasts'] != null) {
        return data['podcasts'] as List;
      } else if (data is Map) {
        return (data as Map).values.toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'searchPodcasts');

        // Show SnackBar if context is provided
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'searchPodcasts',
            onRetry: () => searchPodcasts(query, context: context),
          );
        }

        return [];
      }
      debugPrint('Error searching podcasts: $e');

      // Show generic error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search podcasts. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => searchPodcasts(query, context: context),
            ),
          ),
        );
      }

      return [];
    }
  }

  /// Advanced search with filters
  Future<Map<String, dynamic>> advancedSearchPodcasts({
    required String query,
    String? category,
    String? language,
    bool? explicit,
    int? minEpisodes,
    int? maxEpisodes,
    String sortBy = 'relevance',
    String sortOrder = 'desc',
    int page = 1,
    int perPage = 50,
    BuildContext? context,
  }) async {
    await initialize();
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'max': 1000,
        'page': page,
        'per_page': perPage,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      // Add optional filters
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (language != null && language.isNotEmpty) {
        queryParams['language'] = language;
      }
      if (explicit != null) {
        queryParams['explicit'] = explicit;
      }
      if (minEpisodes != null) {
        queryParams['min_episodes'] = minEpisodes;
      }
      if (maxEpisodes != null) {
        queryParams['max_episodes'] = maxEpisodes;
      }

      final response =
          await _dio.get('/podcast-index/search', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'advancedSearchPodcasts');

        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'advancedSearchPodcasts',
            onRetry: () => advancedSearchPodcasts(
              query: query,
              category: category,
              language: language,
              explicit: explicit,
              minEpisodes: minEpisodes,
              maxEpisodes: maxEpisodes,
              sortBy: sortBy,
              sortOrder: sortOrder,
              page: page,
              perPage: perPage,
              context: context,
            ),
          );
        }

        return {
          'success': false,
          'data': {
            'feeds': <dynamic>[],
            'meta': {
              'total': 0,
              'page': page,
              'per_page': perPage,
              'total_pages': 0,
              'has_more': false,
            }
          }
        };
      }
      debugPrint('Error in advanced search: $e');
      return {
        'success': false,
        'data': {
          'feeds': <dynamic>[],
          'meta': {
            'total': 0,
            'page': page,
            'per_page': perPage,
            'total_pages': 0,
            'has_more': false,
          }
        }
      };
    }
  }

  Future<List<dynamic>> getPodcastsByCategorySearch(
      {required String catId, required String catName}) async {
    await initialize();
    try {
      final response =
          await _dio.get('/podcasts/category/search', queryParameters: {
        'catId': catId,
        'catName': catName,
      });
      final data = response.data;
      // New structure: { success, data: { feeds: [...] } }
      if (data is Map &&
          data['data'] != null &&
          data['data']['feeds'] != null) {
        return data['data']['feeds'] as List;
      }
      if (data is List) {
        return data;
      } else if (data is Map && data['podcasts'] != null) {
        return data['podcasts'] as List;
      } else if (data is Map) {
        return (data as Map).values.toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getPodcastsByCategorySearch');
        throw networkError;
      }
      debugPrint('Error fetching podcasts by category search: $e');
      rethrow;
    }
  }
}
