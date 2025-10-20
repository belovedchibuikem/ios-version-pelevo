import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../core/services/enhanced_api_service.dart';
import '../core/services/comprehensive_cache_service.dart';

/// Provider for managing user profile state with cache integration
class ProfileProvider extends ChangeNotifier {
  final EnhancedApiService _apiService = EnhancedApiService();
  final ComprehensiveCacheService _cacheService = ComprehensiveCacheService();

  // State variables
  User? _userProfile;
  Map<String, dynamic> _userStats = {};
  List<Map<String, dynamic>> _userPreferences = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastFetchTime;

  // Cache keys
  static const String _userProfileCacheKey = 'profile_user_data';
  static const String _userStatsCacheKey = 'profile_user_stats';
  static const String _userPreferencesCacheKey = 'profile_user_preferences';

  // Getters
  User? get userProfile => _userProfile;
  Map<String, dynamic> get userStats => _userStats;
  List<Map<String, dynamic>> get userPreferences => _userPreferences;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get hasData => _userProfile != null || _userStats.isNotEmpty;
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
        await fetchProfileData();
      }
    } catch (e) {
      debugPrint('❌ Error initializing ProfileProvider: $e');
      _error = 'Failed to initialize: $e';
      notifyListeners();
    }
  }

  /// Load data from cache
  Future<void> _loadCachedData() async {
    try {
      // Load user profile
      final profileCached = await _cacheService.get<Map<String, dynamic>>(
        _userProfileCacheKey,
        preferredTier: CacheTier.persistent,
      );
      if (profileCached != null) {
        _userProfile = User.fromJson(profileCached);
      }

      // Load user stats
      final statsCached = await _cacheService.get<Map<String, dynamic>>(
        _userStatsCacheKey,
        preferredTier: CacheTier.persistent,
      );
      if (statsCached != null) {
        _userStats = Map<String, dynamic>.from(statsCached);
      }

      // Load user preferences
      final preferencesCached = await _cacheService.get<List<dynamic>>(
        _userPreferencesCacheKey,
        preferredTier: CacheTier.persistent,
      );
      if (preferencesCached != null) {
        _userPreferences = preferencesCached
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (_userProfile != null || _userStats.isNotEmpty) {
        debugPrint('📱 Loaded cached profile data');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Error loading cached data: $e');
    }
  }

  /// Check if we should fetch fresh data
  bool _shouldFetchFreshData() {
    if (_userProfile == null && _userStats.isEmpty) return true;
    if (_cacheService.isOffline) return false;

    // Check if data is stale (older than 4 hours for profile data)
    if (_lastFetchTime != null) {
      return DateTime.now().difference(_lastFetchTime!) >
          const Duration(hours: 4);
    }
    return true;
  }

  /// Fetch profile data
  Future<void> fetchProfileData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      if (forceRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _error = null;
      notifyListeners();

      // Fetch user profile
      final userProfile = await _apiService.smartGet<User>(
        endpoint: '/profile',
        cacheKey: _userProfileCacheKey,
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
        cacheExpiry: const Duration(hours: 4),
        forceRefresh: forceRefresh,
      );

      // Fetch user stats
      final userStats = await _apiService.smartGet<Map<String, dynamic>>(
        endpoint: '/profile/stats',
        cacheKey: _userStatsCacheKey,
        fromJson: (json) => Map<String, dynamic>.from(json),
        cacheExpiry: const Duration(hours: 4),
        forceRefresh: forceRefresh,
      );

      // Fetch user preferences
      final userPreferences =
          await _apiService.smartGet<List<Map<String, dynamic>>>(
        endpoint: '/profile',
        cacheKey: _userPreferencesCacheKey,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        cacheExpiry: const Duration(hours: 4),
        forceRefresh: forceRefresh,
      );

      _userProfile = userProfile;
      _userStats = userStats;
      _userPreferences = userPreferences;
      _lastFetchTime = DateTime.now();
      _error = null;

      debugPrint('✅ Profile data fetched successfully');
    } catch (e) {
      debugPrint('❌ Error fetching profile data: $e');
      _error = 'Failed to load profile data: $e';

      // If we have cached data, keep it
      if (_userProfile == null && _userStats.isEmpty) {
        await _loadCachedData();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final updatedProfile = await _apiService.smartPut<User>(
        endpoint: '/profile/update',
        data: profileData,
        fromJson: User.fromJson,
        invalidateCacheKeys: [_userProfileCacheKey],
      );

      _userProfile = updatedProfile;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final updatedPreferences =
          await _apiService.smartPut<List<Map<String, dynamic>>>(
        endpoint: '/profile/preferences/update',
        data: preferences,
        fromJson: (json) => (json['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        invalidateCacheKeys: [_userPreferencesCacheKey],
      );

      _userPreferences = updatedPreferences;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating preferences: $e');
      rethrow;
    }
  }

  /// Get user stat by key
  dynamic getUserStat(String key) {
    return _userStats[key];
  }

  /// Check if user has specific preference
  bool hasPreference(String key, dynamic value) {
    return _userPreferences.any((pref) => pref[key] == value);
  }

  /// Get user preference by key
  dynamic getUserPreference(String key) {
    try {
      return _userPreferences.firstWhere((pref) => pref.containsKey(key))[key];
    } catch (e) {
      return null;
    }
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
    await fetchProfileData(forceRefresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      await _cacheService.remove(_userProfileCacheKey);
      await _cacheService.remove(_userStatsCacheKey);
      await _cacheService.remove(_userPreferencesCacheKey);

      debugPrint('🧹 Profile cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Check if data is stale
  bool get isDataStale {
    if (_lastFetchTime == null) return true;
    return _lastFetchTime!.difference(DateTime.now()) >
        const Duration(hours: 4);
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
