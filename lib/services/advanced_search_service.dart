import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';
import '../core/services/unified_auth_service.dart';
import '../data/models/podcast.dart';

class AdvancedSearchService {
  static final AdvancedSearchService _instance =
      AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  final Dio _dio = Dio();
  final UnifiedAuthService _authService = UnifiedAuthService();
  String? _baseUrl;
  bool _isInitialized = false;

  /// Setup automatic authentication interceptor
  void _setupAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint(
                '🔐 AdvancedSearchService: Auto-added auth token: ${token.substring(0, 10)}...');
          } else {
            debugPrint(
                '⚠️ AdvancedSearchService: No auth token available for request to ${options.path}');
          }
          debugPrint(
              '🔍 AdvancedSearchService: Request headers: ${options.headers}');
          handler.next(options);
        } catch (e) {
          debugPrint('❌ AdvancedSearchService: Error in auth interceptor: $e');
          handler.next(options);
        }
      },
    ));
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _baseUrl = '${ApiConfig.baseUrl}/api';
    debugPrint('AdvancedSearchService baseUrl: $_baseUrl');

    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
    };

    _dio.options = BaseOptions(
      baseUrl: _baseUrl!,
      headers: headers,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    );

    _setupAuthInterceptor();

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
    debugPrint('✅ AdvancedSearchService initialized');
  }

  /// Advanced search with filters
  Future<AdvancedSearchResult> searchPodcasts({
    required String query,
    String? category,
    String? language,
    bool? explicit,
    int? minEpisodes,
    int? maxEpisodes,
    SearchSortBy sortBy = SearchSortBy.relevance,
    SearchSortOrder sortOrder = SearchSortOrder.desc,
    int page = 1,
    int perPage = 50,
    BuildContext? context,
  }) async {
    await initialize();

    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'max': 1000, // Get more results for filtering
        'page': page,
        'per_page': perPage,
        'sort_by': sortBy.value,
        'sort_order': sortOrder.value,
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

      debugPrint(
          '🔍 AdvancedSearchService: Searching with params: $queryParams');

      final response =
          await _dio.get('/podcasts/search', queryParameters: queryParams);

      debugPrint(
          '🔍 AdvancedSearchService: Response status: ${response.statusCode}');
      debugPrint('🔍 AdvancedSearchService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final feeds = data['feeds'] as List<dynamic>;
        final meta = data['meta'] as Map<String, dynamic>;

        debugPrint('🔍 AdvancedSearchService: Found ${feeds.length} feeds');

        final podcasts = feeds
            .map((feed) {
              try {
                debugPrint(
                    '🔍 AdvancedSearchService: About to parse feed: ${feed['id']} - ${feed['title']}');
                final podcast = Podcast.fromJson(feed);
                debugPrint(
                    '✅ AdvancedSearchService: Successfully parsed podcast: ${podcast.id} - ${podcast.title}');
                return podcast;
              } catch (e, stackTrace) {
                debugPrint(
                    '❌ AdvancedSearchService: Error parsing podcast: $e');
                debugPrint('❌ AdvancedSearchService: Stack trace: $stackTrace');
                debugPrint('❌ AdvancedSearchService: Feed data: $feed');
                debugPrint(
                    '❌ AdvancedSearchService: Feed keys: ${feed.keys.toList()}');

                // Log each field type to identify the problematic one
                feed.forEach((key, value) {
                  debugPrint(
                      '❌ AdvancedSearchService: Field $key: type=${value.runtimeType}, value=$value');
                });

                return null;
              }
            })
            .where((podcast) => podcast != null)
            .cast<Podcast>()
            .toList();

        debugPrint(
            '🔍 AdvancedSearchService: Successfully parsed ${podcasts.length} podcasts');

        // Debug the meta data to see if there are any type issues
        debugPrint('🔍 AdvancedSearchService: Meta data: $meta');
        debugPrint(
            '🔍 AdvancedSearchService: Meta total type: ${meta['total'].runtimeType}, value: ${meta['total']}');
        debugPrint(
            '🔍 AdvancedSearchService: Meta page type: ${meta['page'].runtimeType}, value: ${meta['page']}');
        debugPrint(
            '🔍 AdvancedSearchService: Meta per_page type: ${meta['per_page'].runtimeType}, value: ${meta['per_page']}');
        debugPrint(
            '🔍 AdvancedSearchService: Meta total_pages type: ${meta['total_pages'].runtimeType}, value: ${meta['total_pages']}');
        debugPrint(
            '🔍 AdvancedSearchService: Meta has_more type: ${meta['has_more'].runtimeType}, value: ${meta['has_more']}');

        try {
          // Safely convert meta data to ensure proper types
          final total =
              AdvancedSearchServiceHelpers.safeParseInt(meta['total']) ?? 0;
          final page =
              AdvancedSearchServiceHelpers.safeParseInt(meta['page']) ?? 1;
          final perPage =
              AdvancedSearchServiceHelpers.safeParseInt(meta['per_page']) ?? 50;
          final totalPages =
              AdvancedSearchServiceHelpers.safeParseInt(meta['total_pages']) ??
                  1;
          final hasMore =
              AdvancedSearchServiceHelpers.safeParseBool(meta['has_more']) ??
                  false;

          debugPrint(
              '🔍 AdvancedSearchService: Converted meta values - total: $total, page: $page, perPage: $perPage, totalPages: $totalPages, hasMore: $hasMore');

          // Safely handle filtersApplied and sort
          final filtersApplied = meta['filters_applied'];
          final sort = meta['sort'];

          debugPrint(
              '🔍 AdvancedSearchService: filtersApplied type: ${filtersApplied.runtimeType}, value: $filtersApplied');
          debugPrint(
              '🔍 AdvancedSearchService: sort type: ${sort.runtimeType}, value: $sort');

          final result = AdvancedSearchResult(
            podcasts: podcasts,
            total: total,
            page: page,
            perPage: perPage,
            totalPages: totalPages,
            hasMore: hasMore,
            filtersApplied:
                filtersApplied is Map<String, dynamic> ? filtersApplied : {},
            sort: sort is Map<String, dynamic> ? sort : {},
          );
          debugPrint(
              '✅ AdvancedSearchService: Successfully created AdvancedSearchResult');
          return result;
        } catch (e, stackTrace) {
          debugPrint(
              '❌ AdvancedSearchService: Error creating AdvancedSearchResult: $e');
          debugPrint('❌ AdvancedSearchService: Stack trace: $stackTrace');
          throw e;
        }
      } else {
        debugPrint('❌ AdvancedSearchService: Search failed - ${response.data}');
        throw Exception(
            'Search request failed: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ AdvancedSearchService: Error in search: $e');

      if (e is DioException) {
        debugPrint('❌ AdvancedSearchService: DioException details:');
        debugPrint('  - Status code: ${e.response?.statusCode}');
        debugPrint('  - Response data: ${e.response?.data}');
        debugPrint('  - Request path: ${e.requestOptions.path}');

        // Check for authentication errors
        if (e.response?.statusCode == 401) {
          debugPrint(
              '❌ AdvancedSearchService: Authentication failed - user needs to login');
          // You might want to trigger a login flow here
        }

        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'advancedSearch');

        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'advancedSearch',
            onRetry: () => searchPodcasts(
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

        return AdvancedSearchResult.empty();
      }
      debugPrint('❌ AdvancedSearchService: Non-DioException error: $e');
      return AdvancedSearchResult.empty();
    }
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query) async {
    await initialize();

    try {
      // For now, we'll return some basic suggestions
      // In the future, this could be enhanced with a dedicated suggestions endpoint
      final suggestions = <String>[];

      if (query.length >= 2) {
        // Add common podcast-related terms
        final commonTerms = [
          'comedy',
          'true crime',
          'news',
          'business',
          'technology',
          'science',
          'health',
          'education',
          'history',
          'politics',
          'music',
          'sports',
          'entertainment',
          'culture',
          'religion'
        ];

        for (final term in commonTerms) {
          if (term.toLowerCase().contains(query.toLowerCase())) {
            suggestions.add(term);
          }
        }
      }

      return suggestions.take(5).toList();
    } catch (e) {
      debugPrint('Error getting search suggestions: $e');
      return [];
    }
  }

  /// Get popular search terms
  Future<List<String>> getPopularSearchTerms() async {
    await initialize();

    try {
      // Return some popular search terms
      return [
        'true crime',
        'comedy',
        'news',
        'business',
        'technology',
        'science',
        'health',
        'education',
        'history',
        'politics',
      ];
    } catch (e) {
      debugPrint('Error getting popular search terms: $e');
      return [];
    }
  }
}

/// Search result model
class AdvancedSearchResult {
  final List<Podcast> podcasts;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;
  final bool hasMore;
  final Map<String, dynamic> filtersApplied;
  final Map<String, dynamic> sort;

  AdvancedSearchResult({
    required this.podcasts,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.hasMore,
    required this.filtersApplied,
    required this.sort,
  });

  factory AdvancedSearchResult.empty() {
    return AdvancedSearchResult(
      podcasts: [],
      total: 0,
      page: 1,
      perPage: 50,
      totalPages: 0,
      hasMore: false,
      filtersApplied: {},
      sort: {},
    );
  }

  bool get isEmpty => podcasts.isEmpty;
  bool get isNotEmpty => podcasts.isNotEmpty;
}

/// Helper methods for safe type conversion
class AdvancedSearchServiceHelpers {
  static int? safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static bool? safeParseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return null;
  }
}

/// Search sort options
enum SearchSortBy {
  relevance('relevance'),
  title('title'),
  episodeCount('episode_count'),
  newest('newest');

  const SearchSortBy(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case SearchSortBy.relevance:
        return 'Relevance';
      case SearchSortBy.title:
        return 'Title';
      case SearchSortBy.episodeCount:
        return 'Episode Count';
      case SearchSortBy.newest:
        return 'Newest';
    }
  }
}

/// Search sort order
enum SearchSortOrder {
  asc('asc'),
  desc('desc');

  const SearchSortOrder(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case SearchSortOrder.asc:
        return 'Ascending';
      case SearchSortOrder.desc:
        return 'Descending';
    }
  }
}

/// Search filters model
class SearchFilters {
  final String? category;
  final String? language;
  final bool? explicit;
  final int? minEpisodes;
  final int? maxEpisodes;

  const SearchFilters({
    this.category,
    this.language,
    this.explicit,
    this.minEpisodes,
    this.maxEpisodes,
  });

  SearchFilters copyWith({
    String? category,
    String? language,
    bool? explicit,
    int? minEpisodes,
    int? maxEpisodes,
  }) {
    return SearchFilters(
      category: category ?? this.category,
      language: language ?? this.language,
      explicit: explicit ?? this.explicit,
      minEpisodes: minEpisodes ?? this.minEpisodes,
      maxEpisodes: maxEpisodes ?? this.maxEpisodes,
    );
  }

  bool get hasActiveFilters {
    return category != null ||
        language != null ||
        explicit != null ||
        minEpisodes != null ||
        maxEpisodes != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'language': language,
      'explicit': explicit,
      'min_episodes': minEpisodes,
      'max_episodes': maxEpisodes,
    };
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      category: json['category'],
      language: json['language'],
      explicit: json['explicit'],
      minEpisodes: json['min_episodes'],
      maxEpisodes: json['max_episodes'],
    );
  }
}
