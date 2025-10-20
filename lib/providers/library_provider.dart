import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/podcast.dart';
import '../data/models/episode.dart';
import '../core/services/enhanced_api_service.dart';
import '../core/services/comprehensive_cache_service.dart';

/// Provider for managing library state with cache integration
class LibraryProvider extends ChangeNotifier {
  final EnhancedApiService _apiService = EnhancedApiService();
  final ComprehensiveCacheService _cacheService = ComprehensiveCacheService();

  // State variables
  List<Podcast> _savedPodcasts = [];
  List<Episode> _downloadedEpisodes = [];
  List<Podcast> _favoritePodcasts = [];
  List<Episode> _recentlyPlayed = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastFetchTime;

  // Cache keys
  static const String _savedPodcastsCacheKey = 'library_saved_podcasts';
  static const String _downloadedEpisodesCacheKey =
      'library_downloaded_episodes';
  static const String _favoritePodcastsCacheKey = 'library_favorite_podcasts';
  static const String _recentlyPlayedCacheKey = 'library_recently_played';

  // Getters
  List<Podcast> get savedPodcasts => _savedPodcasts;
  List<Episode> get downloadedEpisodes => _downloadedEpisodes;
  List<Podcast> get favoritePodcasts => _favoritePodcasts;
  List<Episode> get recentlyPlayed => _recentlyPlayed;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get hasData =>
      _savedPodcasts.isNotEmpty ||
      _downloadedEpisodes.isNotEmpty ||
      _favoritePodcasts.isNotEmpty;
  bool get isOffline => _cacheService.isOffline;

  /// Initialize the provider
  Future<void> initialize() async {
    try {
      await _apiService.initialize();
      await _cacheService.initialize();

      // Try to load cached data first
      await _loadCachedData();

      // Then fetch fresh data if needed
      if (_shouldFetchFreshData()) {
        await fetchLibraryData();
      }
    } catch (e) {
      debugPrint('❌ Error initializing LibraryProvider: $e');
      _error = 'Failed to initialize: $e';
      notifyListeners();
    }
  }

  /// Load data from cache
  Future<void> _loadCachedData() async {
    try {
      // Load saved podcasts
      final savedCached = await _cacheService.get<List<dynamic>>(
        _savedPodcastsCacheKey,
        preferredTier: CacheTier.persistent,
      );
      if (savedCached != null) {
        _savedPodcasts = savedCached
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load downloaded episodes
      final downloadedCached = await _cacheService.get<List<dynamic>>(
        _downloadedEpisodesCacheKey,
        preferredTier: CacheTier.persistent,
      );
      if (downloadedCached != null) {
        _downloadedEpisodes = downloadedCached
            .map((e) => Episode.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load favorite podcasts
      final favoriteCached = await _cacheService.get<List<dynamic>>(
        _favoritePodcastsCacheKey,
        preferredTier: CacheTier.persistent,
      );
      if (favoriteCached != null) {
        _favoritePodcasts = favoriteCached
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Load recently played
      final recentCached = await _cacheService.get<List<dynamic>>(
        _recentlyPlayedCacheKey,
        preferredTier: CacheTier.persistent,
      );
      if (recentCached != null) {
        _recentlyPlayed = recentCached
            .map((e) => Episode.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (_savedPodcasts.isNotEmpty ||
          _downloadedEpisodes.isNotEmpty ||
          _favoritePodcasts.isNotEmpty) {
        debugPrint('📱 Loaded cached library data');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Error loading cached data: $e');
    }
  }

  /// Check if we should fetch fresh data
  bool _shouldFetchFreshData() {
    if (_savedPodcasts.isEmpty &&
        _downloadedEpisodes.isEmpty &&
        _favoritePodcasts.isEmpty) return true;
    if (_cacheService.isOffline) return false;

    // Check if data is stale (older than 2 hours for library data)
    if (_lastFetchTime != null) {
      return DateTime.now().difference(_lastFetchTime!) >
          const Duration(hours: 2);
    }
    return true;
  }

  /// Fetch library data
  Future<void> fetchLibraryData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      if (forceRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _error = null;
      notifyListeners();

      // Fetch saved podcasts
      final savedPodcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/library/saved-podcasts',
        cacheKey: _savedPodcastsCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(hours: 2),
        forceRefresh: forceRefresh,
      );

      // Fetch downloaded episodes
      final downloadedEpisodes = await _apiService.smartGet<List<Episode>>(
        endpoint: '/library/downloaded-episodes',
        cacheKey: _downloadedEpisodesCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Episode.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(hours: 2),
        forceRefresh: forceRefresh,
      );

      // Fetch favorite podcasts
      final favoritePodcasts = await _apiService.smartGet<List<Podcast>>(
        endpoint: '/library/favorite-podcasts',
        cacheKey: _favoritePodcastsCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Podcast.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(hours: 2),
        forceRefresh: forceRefresh,
      );

      // Fetch recently played
      final recentlyPlayed = await _apiService.smartGet<List<Episode>>(
        endpoint: '/library/recently-played',
        cacheKey: _recentlyPlayedCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Episode.fromJson(e as Map<String, dynamic>))
            .toList(),
        cacheExpiry: const Duration(hours: 2),
        forceRefresh: forceRefresh,
      );

      _savedPodcasts = savedPodcasts;
      _downloadedEpisodes = downloadedEpisodes;
      _favoritePodcasts = favoritePodcasts;
      _recentlyPlayed = recentlyPlayed;
      _lastFetchTime = DateTime.now();
      _error = null;

      debugPrint('✅ Library data fetched successfully');
    } catch (e) {
      debugPrint('❌ Error fetching library data: $e');
      _error = 'Failed to load library data: $e';

      // If we have cached data, keep it
      if (_savedPodcasts.isEmpty &&
          _downloadedEpisodes.isEmpty &&
          _favoritePodcasts.isEmpty) {
        await _loadCachedData();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Add podcast to saved list
  Future<void> addToSaved(Podcast podcast) async {
    try {
      await _apiService.smartPost(
        endpoint: '/library/save-podcast',
        data: {'podcast_id': podcast.id},
        fromJson: (json) => json,
        invalidateCacheKeys: [_savedPodcastsCacheKey],
      );

      if (!_savedPodcasts.any((p) => p.id == podcast.id)) {
        _savedPodcasts.add(podcast);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error adding podcast to saved: $e');
      rethrow;
    }
  }

  /// Remove podcast from saved list
  Future<void> removeFromSaved(String podcastId) async {
    try {
      await _apiService.smartDelete(
        endpoint: '/library/remove-saved-podcast/$podcastId',
        invalidateCacheKeys: [_savedPodcastsCacheKey],
      );

      _savedPodcasts.removeWhere((p) => p.id == podcastId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error removing podcast from saved: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Podcast podcast) async {
    try {
      final isFavorite = _favoritePodcasts.any((p) => p.id == podcast.id);

      if (isFavorite) {
        await _apiService.smartDelete(
          endpoint: '/library/remove-favorite/$podcast.id',
          invalidateCacheKeys: [_favoritePodcastsCacheKey],
        );
        _favoritePodcasts.removeWhere((p) => p.id == podcast.id);
      } else {
        await _apiService.smartPost(
          endpoint: '/library/add-favorite',
          data: {'podcast_id': podcast.id},
          fromJson: (json) => json,
          invalidateCacheKeys: [_favoritePodcastsCacheKey],
        );
        _favoritePodcasts.add(podcast);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Check if podcast is saved
  bool isPodcastSaved(String podcastId) {
    return _savedPodcasts.any((p) => p.id == podcastId);
  }

  /// Check if podcast is favorite
  bool isPodcastFavorite(String podcastId) {
    return _favoritePodcasts.any((p) => p.id == podcastId);
  }

  /// Get podcasts by category
  List<Podcast> getPodcastsByCategory(String categoryId) {
    return _savedPodcasts.where((podcast) {
      if (podcast.categories is List) {
        return (podcast.categories as List)
            .any((cat) => cat.toString() == categoryId);
      } else if (podcast.categories is String) {
        return podcast.categories == categoryId;
      }
      return podcast.category == categoryId;
    }).toList();
  }

  /// Search in library
  List<Podcast> searchInLibrary(String query) {
    if (query.isEmpty) return _savedPodcasts;

    final lowercaseQuery = query.toLowerCase();
    return _savedPodcasts.where((podcast) {
      return podcast.title.toLowerCase().contains(lowercaseQuery) ||
          podcast.creator.toLowerCase().contains(lowercaseQuery) ||
          podcast.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }

  /// Force refresh all data
  Future<void> forceRefresh() async {
    await fetchLibraryData(forceRefresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      await _cacheService.remove(_savedPodcastsCacheKey);
      await _cacheService.remove(_downloadedEpisodesCacheKey);
      await _cacheService.remove(_favoritePodcastsCacheKey);
      await _cacheService.remove(_recentlyPlayedCacheKey);

      debugPrint('🧹 Library cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Check if data is stale
  bool get isDataStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) >
        const Duration(hours: 2);
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

  @override
  void dispose() {
    super.dispose();
  }
}
