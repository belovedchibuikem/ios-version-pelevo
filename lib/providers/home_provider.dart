import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import '../data/models/home_screen_data.dart';
import '../data/models/podcast.dart';
import '../data/models/category.dart';
import '../core/services/enhanced_api_service.dart';
import '../core/services/comprehensive_cache_service.dart';
import '../core/services/session_persistence_service.dart';
import 'package:flutter/scheduler.dart';

/// Provider for managing home screen state with cache integration
class HomeProvider extends ChangeNotifier {
  final EnhancedApiService _apiService = EnhancedApiService();
  final ComprehensiveCacheService _cacheService = ComprehensiveCacheService();
  final SessionPersistenceService _sessionPersistence =
      SessionPersistenceService();

  // State variables
  HomeScreenData? _homeData;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastFetchTime;
  bool _mounted = true;

  // Cache keys
  static const String _homeDataCacheKey = 'home_screen_data';
  static const String _featuredCacheKey = 'home_featured_podcasts';
  static const String _healthCacheKey = 'home_health_podcasts';
  static const String _categoriesCacheKey = 'home_categories';
  static const String _crimeCacheKey = 'home_crime_archives';
  static const String _recommendedCacheKey = 'home_recommended_podcasts';

  // Getters
  HomeScreenData? get homeData => _homeData;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get hasData => _homeData != null && _homeData!.hasContent;
  bool get isOffline => _cacheService.isOffline;

  // Individual section getters
  List<Podcast> get featuredPodcasts => _homeData?.featuredPodcasts ?? [];
  List<Podcast> get healthPodcasts => _homeData?.healthPodcasts ?? [];
  List<Category> get categories => _homeData?.categories ?? [];
  List<Podcast> get crimeArchives => _homeData?.crimeArchives ?? [];
  List<Podcast> get recommendedPodcasts => _homeData?.recommendedPodcasts ?? [];
  List<Podcast> get trendingPodcasts => _homeData?.trendingPodcasts ?? [];

  /// Safe notifier that defers notification to avoid build phase conflicts
  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // We're in the build phase, defer the notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mounted) {
          notifyListeners();
        }
      });
    } else {
      // Safe to notify immediately
      notifyListeners();
    }
  }

  /// Initialize the provider
  Future<void> initialize() async {
    try {
      // Set loading state immediately when initializing
      _isLoading = true;
      // Defer notifyListeners to avoid build phase issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      await _apiService.initialize();
      await _cacheService.initialize();
      await _sessionPersistence.initialize();

      // Try to load cached data first
      await loadCachedData();

      // Then fetch fresh data if needed
      if (_shouldFetchFreshData()) {
        await fetchHomeData();
      } else {
        // If we have cached data and don't need to fetch fresh, we're done loading
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error initializing HomeProvider: $e');
      _error = 'Failed to initialize: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load data from cache with enhanced fallback
  Future<void> loadCachedData() async {
    try {
      // Try enhanced cache method first
      final cachedData =
          await _cacheService.getHomeScreenData<Map<String, dynamic>>(
        _homeDataCacheKey,
      );

      if (cachedData != null) {
        _homeData = HomeScreenData.fromJson(cachedData);
        _lastFetchTime = _homeData!.lastUpdated;
        debugPrint('📱 Loaded cached home data (enhanced method)');
        // Defer notifyListeners to avoid build phase issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }

      // Fallback to original method
      final fallbackData = await _cacheService.get<Map<String, dynamic>>(
        _homeDataCacheKey,
        preferredTier: CacheTier.persistent,
      );

      if (fallbackData != null) {
        _homeData = HomeScreenData.fromJson(fallbackData);
        _lastFetchTime = _homeData!.lastUpdated;
        debugPrint('📱 Loaded cached home data (fallback method)');
        // Defer notifyListeners to avoid build phase issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading cached data: $e');
    }
  }

  /// Check if we should fetch fresh data
  bool _shouldFetchFreshData() {
    if (_homeData == null) return true;
    if (_cacheService.isOffline) return false;

    // Check if data is stale (older than 2 hours for better persistence)
    return _homeData!.isStale(const Duration(hours: 2));
  }

  /// Fetch home screen data
  Future<void> fetchHomeData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      if (forceRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _error = null;
      _safeNotifyListeners();

      debugPrint('🚀 HomeProvider: Starting to fetch home data...');
      debugPrint('🚀 HomeProvider: Force refresh: $forceRefresh');

      debugPrint('🚀 HomeProvider: Starting to fetch home data...');
      debugPrint('🚀 HomeProvider: Force refresh: $forceRefresh');

      // Fetch data using enhanced API service - fetch individual sections
      debugPrint('📡 HomeProvider: Fetching featured podcasts...');
      final featuredPodcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/featured',
        cacheKey: _featuredCacheKey,
        fromJson: (json) {
          debugPrint('🔍 Featured podcasts raw response: $json');
          debugPrint('🔍 Featured podcasts response type: ${json.runtimeType}');

          // Handle different response formats
          if (json is List) {
            debugPrint(
                '✅ Featured podcasts: Direct List response with ${json.length} items');
            return json
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (json is Map<String, dynamic> && json['data'] is List) {
            debugPrint(
                '✅ Featured podcasts: Map with data field, ${json['data'].length} items');
            return (json['data'] as List)
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            debugPrint(
                '⚠️ Featured podcasts: Unexpected format - ${json.runtimeType}');
            debugPrint(
                '⚠️ Featured podcasts: Available keys: ${json is Map ? json.keys.toList() : 'Not a map'}');
            return <Podcast>[];
          }
        },
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      debugPrint(
          '📊 Featured podcasts result: ${featuredPodcasts.length} podcasts loaded');

      debugPrint('📡 HomeProvider: Fetching health podcasts...');
      final healthPodcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/health',
        cacheKey: _healthCacheKey,
        fromJson: (json) {
          debugPrint('🔍 Health podcasts raw response: $json');
          debugPrint('🔍 Health podcasts response type: ${json.runtimeType}');

          // Handle different response formats
          if (json is List) {
            debugPrint(
                '✅ Health podcasts: Direct List response with ${json.length} items');
            return json
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (json is Map<String, dynamic> && json['data'] is List) {
            debugPrint(
                '✅ Health podcasts: Map with data field, ${json['data'].length} items');
            return (json['data'] as List)
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            debugPrint(
                '⚠️ Health podcasts: Unexpected format - ${json.runtimeType}');
            debugPrint(
                '⚠️ Health podcasts: Available keys: ${json is Map ? json.keys.toList() : 'Not a map'}');
            return <Podcast>[];
          }
        },
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      debugPrint(
          '📊 Health podcasts result: ${healthPodcasts.length} podcasts loaded');

      debugPrint('📡 HomeProvider: Fetching categories...');
      final categories = await _apiService.smartGet<List<Category>>(
        endpoint: '/podcasts/categories',
        cacheKey: _categoriesCacheKey,
        fromJson: (json) {
          debugPrint('🔍 Categories raw response: $json');
          debugPrint('🔍 Categories response type: ${json.runtimeType}');

          // Handle different response formats
          if (json is List) {
            debugPrint(
                '✅ Categories: Direct List response with ${json.length} items');
            final result = json
                .map((e) => Category.fromJson(e as Map<String, dynamic>))
                .toList();
            debugPrint(
                '✅ Categories: Parsed ${result.length} categories from List');
            return result;
          } else if (json is Map<String, dynamic>) {
            // Check for "feeds" field (actual API response format)
            if (json['feeds'] is List) {
              debugPrint(
                  '✅ Categories: Map with feeds field, ${json['feeds'].length} items');
              final result = (json['feeds'] as List)
                  .map((e) => Category.fromJson(e as Map<String, dynamic>))
                  .toList();
              debugPrint(
                  '✅ Categories: Parsed ${result.length} categories from feeds field');
              return result;
            }
            // Check for "data" field (alternative format)
            else if (json['data'] is List) {
              debugPrint(
                  '✅ Categories: Map with data field, ${json['data'].length} items');
              final result = (json['data'] as List)
                  .map((e) => Category.fromJson(e as Map<String, dynamic>))
                  .toList();
              debugPrint(
                  '✅ Categories: Parsed ${result.length} categories from data field');
              return result;
            } else {
              debugPrint(
                  '⚠️ Categories: Map response has neither feeds nor data field');
              debugPrint(
                  '⚠️ Categories: Available keys: ${json.keys.toList()}');
              return <Category>[];
            }
          } else {
            debugPrint(
                '⚠️ Categories: Unexpected response format - ${json.runtimeType}');
            debugPrint('⚠️ Categories: Response content: $json');
            return <Category>[];
          }
        },
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      debugPrint(
          '📊 Categories result: ${categories.length} categories loaded');

      debugPrint('📡 HomeProvider: Fetching crime archives...');
      final crimeArchives = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/true-crime',
        cacheKey: _crimeCacheKey,
        fromJson: (json) {
          debugPrint('🔍 Crime archives raw response: $json');
          debugPrint('🔍 Crime archives response type: ${json.runtimeType}');

          // Handle different response formats
          if (json is List) {
            debugPrint(
                '✅ Crime archives: Direct List response with ${json.length} items');
            return json
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (json is Map<String, dynamic> && json['data'] is List) {
            debugPrint(
                '✅ Crime archives: Map with data field, ${json['data'].length} items');
            return (json['data'] as List)
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            debugPrint(
                '⚠️ Crime archives: Unexpected format - ${json.runtimeType}');
            debugPrint(
                '⚠️ Crime archives: Available keys: ${json is Map ? json.keys.toList() : 'Not a map'}');
            return <Podcast>[];
          }
        },
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      debugPrint(
          '📊 Crime archives result: ${crimeArchives.length} podcasts loaded');

      debugPrint('📡 HomeProvider: Fetching recommended podcasts...');
      final recommendedPodcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/recommended',
        cacheKey: _recommendedCacheKey,
        fromJson: (json) {
          debugPrint('🔍 Recommended podcasts raw response: $json');
          debugPrint(
              '🔍 Recommended podcasts response type: ${json.runtimeType}');

          // Handle different response formats
          if (json is List) {
            debugPrint(
                '✅ Recommended podcasts: Direct List response with ${json.length} items');
            return json
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (json is Map<String, dynamic> && json['data'] is List) {
            debugPrint(
                '✅ Recommended podcasts: Map with data field, ${json['data'].length} items');
            return (json['data'] as List)
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            debugPrint(
                '⚠️ Recommended podcasts: Unexpected format - ${json.runtimeType}');
            debugPrint(
                '⚠️ Recommended podcasts: Available keys: ${json is Map ? json.keys.toList() : 'Not a map'}');
            return <Podcast>[];
          }
        },
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      debugPrint(
          '📊 Recommended podcasts result: ${recommendedPodcasts.length} podcasts loaded');

      debugPrint('📡 HomeProvider: Fetching trending podcasts...');
      final trendingPodcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/trending',
        cacheKey: 'home_trending_podcasts',
        fromJson: (json) {
          debugPrint('🔍 Trending podcasts raw response: $json');
          debugPrint('🔍 Trending podcasts response type: ${json.runtimeType}');

          // Handle different response formats
          if (json is List) {
            debugPrint(
                '✅ Trending podcasts: Direct List response with ${json.length} items');
            return json
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (json is Map<String, dynamic> && json['data'] is List) {
            debugPrint(
                '✅ Trending podcasts: Map with data field, ${json['data'].length} items');
            return (json['data'] as List)
                .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            debugPrint(
                '⚠️ Trending podcasts: Unexpected format - ${json.runtimeType}');
            debugPrint(
                '⚠️ Trending podcasts: Available keys: ${json is Map ? json.keys.toList() : 'Not a map'}');
            return <Podcast>[];
          }
        },
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      debugPrint(
          '📊 Trending podcasts result: ${trendingPodcasts.length} podcasts loaded');

      debugPrint(
          '🏗️ HomeProvider: Creating HomeScreenData from individual sections...');

      // Create HomeScreenData from individual sections
      final data = HomeScreenData(
        featuredPodcasts: featuredPodcasts,
        healthPodcasts: healthPodcasts,
        categories: categories,
        crimeArchives: crimeArchives,
        recommendedPodcasts: recommendedPodcasts,
        trendingPodcasts: trendingPodcasts,
        lastUpdated: DateTime.now(),
        hasNewContent: false,
      );

      _homeData = data;
      _lastFetchTime = DateTime.now();
      _error = null;

      // Store data using enhanced cache method
      try {
        await _cacheService.setHomeScreenData<Map<String, dynamic>>(
          key: _homeDataCacheKey,
          data: data.toJson(),
          expiry: const Duration(hours: 2), // Longer expiry for home data
          priority: 5, // High priority to prevent eviction
        );
        debugPrint('💾 Home data stored with enhanced caching');
      } catch (e) {
        debugPrint('⚠️ Error storing home data with enhanced cache: $e');
        // Fallback to original cache method
        await _cacheService.set(
          key: _homeDataCacheKey,
          data: data.toJson(),
          expiry: const Duration(minutes: 30),
          tier: CacheTier.both,
        );
      }

      // Debug logging to help troubleshoot
      debugPrint('🔍 Home data summary:');
      debugPrint('  - Featured: ${featuredPodcasts.length}');
      debugPrint('  - Health: ${healthPodcasts.length}');
      debugPrint('  - Categories: ${categories.length}');
      debugPrint('  - Crime Archives: ${crimeArchives.length}');
      debugPrint('  - Recommended: ${recommendedPodcasts.length}');
      debugPrint('  - Trending: ${trendingPodcasts.length}');
      debugPrint('  - Has Content: ${data.hasContent}');
      debugPrint('✅ Home data fetched successfully');
    } catch (e) {
      debugPrint('❌ Error fetching home data: $e');
      _error = 'Failed to load home data: $e';

      // If we have cached data, keep it
      if (_homeData == null) {
        await loadCachedData();
      }
    } finally {
      // Always reset loading states
      _isLoading = false;
      _isRefreshing = false;

      // Only notify if we're still mounted
      if (_mounted) {
        _safeNotifyListeners();
      }
    }
  }

  /// Refresh specific sections
  Future<void> refreshSection(String section) async {
    try {
      _isRefreshing = true;
      // Defer notifyListeners to avoid build phase issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      switch (section) {
        case 'featured':
          await _refreshFeaturedPodcasts();
          break;
        case 'health':
          await _refreshHealthPodcasts();
          break;
        case 'categories':
          await _refreshCategories();
          break;
        case 'crime':
          await _refreshCrimeArchives();
          break;
        case 'recommended':
          await _refreshRecommendedPodcasts();
          break;
        case 'trending':
          await _refreshTrendingPodcasts();
          break;
        default:
          debugPrint('⚠️ Unknown section: $section');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing section $section: $e');
      _error = 'Failed to refresh $section: $e';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Refresh featured podcasts
  Future<void> _refreshFeaturedPodcasts() async {
    try {
      final podcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/featured',
        cacheKey: _featuredCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: true,
      );

      if (_homeData != null) {
        _homeData = _homeData!.copyWith(
          featuredPodcasts: podcasts,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing featured podcasts: $e');
      rethrow;
    }
  }

  /// Refresh health podcasts
  Future<void> _refreshHealthPodcasts() async {
    try {
      final podcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/health',
        cacheKey: _healthCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: true,
      );

      if (_homeData != null) {
        _homeData = _homeData!.copyWith(
          healthPodcasts: podcasts,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing health podcasts: $e');
      rethrow;
    }
  }

  /// Refresh categories
  Future<void> _refreshCategories() async {
    try {
      final categories = await _apiService.smartGet<List<Category>>(
        endpoint: '/podcasts/categories',
        cacheKey: _categoriesCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(hours: 2),
        forceRefresh: true,
      );

      if (_homeData != null) {
        _homeData = _homeData!.copyWith(
          categories: categories,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing categories: $e');
      rethrow;
    }
  }

  /// Refresh crime archives
  Future<void> _refreshCrimeArchives() async {
    try {
      final podcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/true-crime',
        cacheKey: _crimeCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: true,
      );

      if (_homeData != null) {
        _homeData = _homeData!.copyWith(
          crimeArchives: podcasts,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing crime archives: $e');
      rethrow;
    }
  }

  /// Refresh recommended podcasts
  Future<void> _refreshRecommendedPodcasts() async {
    try {
      final podcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/recommended',
        cacheKey: _recommendedCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: true,
      );

      if (_homeData != null) {
        _homeData = _homeData!.copyWith(
          recommendedPodcasts: podcasts,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing recommended podcasts: $e');
      rethrow;
    }
  }

  /// Refresh trending podcasts
  Future<void> _refreshTrendingPodcasts() async {
    try {
      final podcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/podcasts/trending',
        cacheKey: 'home_trending_podcasts',
        fromJson: (json) => (json['data'] as List)
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(minutes: 30),
        forceRefresh: true,
      );

      if (_homeData != null) {
        _homeData = _homeData!.copyWith(
          trendingPodcasts: podcasts,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing trending podcasts: $e');
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    // Defer notifyListeners to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }

  /// Force refresh all data
  Future<void> forceRefresh() async {
    await fetchHomeData(forceRefresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      await _cacheService.remove(_homeDataCacheKey);
      await _cacheService.remove(_featuredCacheKey);
      await _cacheService.remove(_healthCacheKey);
      await _cacheService.remove(_categoriesCacheKey);
      await _cacheService.remove(_crimeCacheKey);
      await _cacheService.remove(_recommendedCacheKey);

      debugPrint('🧹 Home cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Check if data is stale
  bool get isDataStale {
    if (_homeData == null) return true;
    return _homeData!.isStale(const Duration(minutes: 30));
  }

  /// Get data freshness indicator
  String get dataFreshness {
    if (_lastFetchTime == null) return 'Never loaded';

    final difference = DateTime.now().difference(_lastFetchTime!);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  /// Background refresh - updates data without showing loading state
  Future<void> backgroundRefresh() async {
    if (_isLoading || _isRefreshing) return;

    try {
      // Only refresh if data is stale
      if (_shouldFetchFreshData()) {
        await fetchHomeData(forceRefresh: false);
      }
    } catch (e) {
      debugPrint('⚠️ Background refresh failed: $e');
      // Don't throw error in background refresh to prevent infinite loops
    }
  }

  /// Background refresh when returning to home screen after idle time
  Future<void> backgroundRefreshOnReturn() async {
    try {
      debugPrint('🔄 HomeProvider: Background refresh on return triggered');

      // Check session persistence first
      final sessionActive = await _sessionPersistence.isSessionActive();
      final shouldRetainData = await _sessionPersistence.shouldRetainData();

      if (!sessionActive && !shouldRetainData) {
        debugPrint(
            '🔄 HomeProvider: Session expired and data retention period passed, clearing cache');
        await _cacheService.clear();
        return;
      }

      // Try to restore session if needed
      if (!sessionActive) {
        debugPrint(
            '🔄 HomeProvider: Session not active, attempting restoration...');
        final sessionRestored =
            await _sessionPersistence.restoreSessionAfterIdle();
        if (!sessionRestored) {
          debugPrint(
              '🔄 HomeProvider: Session restoration failed, using cached data only');
        }
      }

      // Check if we have cached data first
      if (_homeData == null) {
        debugPrint('🔄 HomeProvider: No cached data, loading from cache...');
        await loadCachedData();
      }

      // Only fetch fresh data if we're online and data is stale
      if (!_cacheService.isOffline && _shouldFetchFreshData()) {
        debugPrint('🔄 HomeProvider: Data is stale, fetching fresh data...');
        await fetchHomeData(forceRefresh: false);
      } else {
        debugPrint('🔄 HomeProvider: Data is fresh or offline, skipping fetch');
      }
    } catch (e) {
      debugPrint('⚠️ Background refresh on return failed: $e');
      // Don't throw error to prevent infinite loops
    }
  }

  /// Smart refresh - only refresh sections that are stale
  Future<void> smartRefresh() async {
    if (_isLoading || _isRefreshing) return;

    try {
      _isRefreshing = true;
      _safeNotifyListeners();

      // Refresh only stale sections
      if (_homeData != null) {
        final now = DateTime.now();
        final staleThreshold = const Duration(hours: 2); // Extended threshold

        if (now.difference(_homeData!.lastUpdated) > staleThreshold) {
          // Refresh all data if main data is stale
          await fetchHomeData(forceRefresh: false);
        } else {
          // Refresh individual sections if needed
          await _refreshStaleSections();
        }
      }
    } catch (e) {
      debugPrint('❌ Smart refresh failed: $e');
    } finally {
      _isRefreshing = false;
      _safeNotifyListeners();
    }
  }

  /// Refresh only stale sections
  Future<void> _refreshStaleSections() async {
    // This could be implemented to check individual section freshness
    // For now, just refresh the main data
    await fetchHomeData(forceRefresh: false);
  }

  /// Clear cache and force refresh
  Future<void> clearCacheAndRefresh() async {
    try {
      await _cacheService.remove(_homeDataCacheKey);
      await _cacheService.remove(_featuredCacheKey);
      await _cacheService.remove(_healthCacheKey);
      await _cacheService.remove(_categoriesCacheKey);
      await _cacheService.remove(_crimeCacheKey);
      await _cacheService.remove(_recommendedCacheKey);

      debugPrint('🧹 Cache cleared, forcing refresh...');
      await fetchHomeData(forceRefresh: true);
    } catch (e) {
      debugPrint('❌ Error clearing cache and refreshing: $e');
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
}
