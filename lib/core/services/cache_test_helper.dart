import 'package:flutter/foundation.dart';
import 'comprehensive_cache_service.dart';

/// Helper class to test cache functionality and simulate memory pressure
class CacheTestHelper {
  static final ComprehensiveCacheService _cacheService =
      ComprehensiveCacheService();

  /// Simulate memory pressure by filling up the cache
  static Future<void> simulateMemoryPressure() async {
    await _cacheService.initialize();

    debugPrint('🧪 Simulating memory pressure...');

    // Fill up the cache with dummy data to trigger eviction
    for (int i = 0; i < 150; i++) {
      await _cacheService.set(
        key: 'test_data_$i',
        data: {'id': i, 'content': 'Test data $i'},
        expiry: const Duration(minutes: 30),
        tier: CacheTier.memory,
        priority: 1,
      );
    }

    debugPrint('🧪 Memory pressure simulation complete');
  }

  /// Test home screen data persistence
  static Future<void> testHomeScreenDataPersistence() async {
    await _cacheService.initialize();

    debugPrint('🧪 Testing home screen data persistence...');

    // Store test home data using enhanced method
    final testData = {
      'featuredPodcasts': [
        {'id': 1, 'title': 'Test Podcast 1'},
        {'id': 2, 'title': 'Test Podcast 2'},
      ],
      'categories': [
        {'id': 1, 'name': 'Test Category 1'},
      ],
      'trendingPodcasts': [
        {'id': 3, 'title': 'Test Trending 1'},
      ],
      'recommendedPodcasts': [
        {'id': 4, 'title': 'Test Recommended 1'},
      ],
      'lastUpdated': DateTime.now().toIso8601String(),
      'hasNewContent': false,
    };

    await _cacheService.setHomeScreenData(
      key: 'test_home_data',
      data: testData,
      priority: 5,
    );

    // Simulate memory pressure
    await simulateMemoryPressure();

    // Try to retrieve home data
    final retrievedData =
        await _cacheService.getHomeScreenData('test_home_data');

    if (retrievedData != null) {
      debugPrint('✅ Home screen data persistence test PASSED');
    } else {
      debugPrint('❌ Home screen data persistence test FAILED');
    }

    // Clean up test data
    await _cacheService.remove('test_home_data');
    await _cacheService.remove('test_home_data_backup');
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }
}
