import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'image_cache_service.dart';
import 'performance_monitor_service.dart';
import 'cache_size_manager.dart';

/// Service that integrates all caching and performance services
class CacheIntegrationService {
  static final CacheIntegrationService _instance =
      CacheIntegrationService._internal();
  factory CacheIntegrationService() => _instance;
  CacheIntegrationService._internal();

  final ImageCacheService _imageCache = ImageCacheService();
  final PerformanceMonitorService _performanceMonitor =
      PerformanceMonitorService();
  final CacheSizeManager _cacheSizeManager = CacheSizeManager();

  bool _isInitialized = false;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize all cache and performance services
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🚀 Initializing cache integration service...');

    try {
      // Initialize image cache service
      await _imageCache.initialize();
      debugPrint('✅ Image cache service initialized');

      // Initialize cache size manager
      await _cacheSizeManager.initialize();
      debugPrint('✅ Cache size manager initialized');

      // Start performance monitoring
      _performanceMonitor.startMonitoring();
      debugPrint('✅ Performance monitoring started');

      _isInitialized = true;
      debugPrint('🎉 Cache integration service fully initialized');
    } catch (e) {
      debugPrint('❌ Error initializing cache integration service: $e');
      rethrow;
    }
  }

  /// Get integrated cache statistics
  Future<Map<String, dynamic>> getIntegratedCacheStats() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final imageStats = await _imageCache.getCacheStats();
      final cacheSizeStats = await _cacheSizeManager.getCacheStats();
      final performanceStatus = _performanceMonitor.getMonitoringStatus();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'services': {
          'image_cache': imageStats,
          'cache_size_manager': cacheSizeStats,
          'performance_monitor': performanceStatus,
        },
        'overall_status':
            _getOverallStatus(imageStats, cacheSizeStats, performanceStatus),
      };
    } catch (e) {
      debugPrint('Error getting integrated cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get overall cache health status
  Map<String, dynamic> _getOverallStatus(
    Map<String, dynamic> imageStats,
    Map<String, dynamic> cacheSizeStats,
    Map<String, dynamic> performanceStatus,
  ) {
    final imageUsage =
        double.tryParse(imageStats['usage_percentage'] ?? '0') ?? 0;
    final cacheUsage =
        double.tryParse(cacheSizeStats['usage_percentage'] ?? '0') ?? 0;
    final isMonitoringActive = performanceStatus['is_active'] ?? false;

    String status = 'Good';
    String recommendation = 'All systems operating normally';

    if (imageUsage > 80 || cacheUsage > 80) {
      status = 'Warning';
      recommendation = 'Cache usage is high. Consider clearing old data.';
    }

    if (imageUsage > 95 || cacheUsage > 95) {
      status = 'Critical';
      recommendation = 'Cache is nearly full. Immediate cleanup recommended.';
    }

    if (!isMonitoringActive) {
      status = 'Warning';
      recommendation = 'Performance monitoring is inactive.';
    }

    return {
      'status': status,
      'recommendation': recommendation,
      'image_cache_usage': imageUsage,
      'total_cache_usage': cacheUsage,
      'monitoring_active': isMonitoringActive,
    };
  }

  /// Perform comprehensive cache cleanup
  Future<void> performComprehensiveCleanup() async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('🧹 Starting comprehensive cache cleanup...');

    try {
      // Start performance timer
      _performanceMonitor.startApiTimer('cache_cleanup');

      // Clean up image cache
      await _imageCache.cleanupCache();

      // Clean up general cache
      await _cacheSizeManager.performCleanup();

      // Stop performance timer
      _performanceMonitor.stopApiTimer('cache_cleanup');

      debugPrint('✅ Comprehensive cache cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during comprehensive cache cleanup: $e');
      rethrow;
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('🗑️ Clearing all caches...');

    try {
      // Start performance timer
      _performanceMonitor.startApiTimer('clear_all_caches');

      // Clear image cache
      await _imageCache.clearCache();

      // Clear all caches
      await _cacheSizeManager.clearAllCaches();

      // Stop performance timer
      _performanceMonitor.stopApiTimer('clear_all_caches');

      debugPrint('✅ All caches cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all caches: $e');
      rethrow;
    }
  }

  /// Get performance report
  Future<Map<String, dynamic>> getPerformanceReport() async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _performanceMonitor.getPerformanceReport();
  }

  /// Track cache hit
  void trackCacheHit(bool isHit) {
    if (_isInitialized) {
      _performanceMonitor.trackCacheHit(isHit);
    }
  }

  /// Track list rendering performance
  void trackListRendering(String listName, int itemCount, Duration renderTime) {
    if (_isInitialized) {
      _performanceMonitor.trackListRendering(listName, itemCount, renderTime);
    }
  }

  /// Track navigation performance
  void trackNavigation(String routeName, Duration navigationTime) {
    if (_isInitialized) {
      _performanceMonitor.trackNavigation(routeName, navigationTime);
    }
  }

  /// Get network image with caching
  Widget getCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (!_isInitialized) {
      // Return basic Image.network if not initialized
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildDefaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    }

    return _imageCache.getNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  /// Build default placeholder widget
  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Build default error widget
  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  /// Check if emergency cleanup is needed
  Future<bool> isEmergencyCleanupNeeded() async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _cacheSizeManager.isEmergencyCleanupNeeded();
  }

  /// Force immediate cleanup
  Future<void> forceCleanup() async {
    if (!_isInitialized) {
      await initialize();
    }

    await _cacheSizeManager.forceCleanup();
  }

  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'is_initialized': _isInitialized,
      'image_cache_active': _imageCache.isInitialized,
      'cache_size_manager_active': _cacheSizeManager.isInitialized,
      'performance_monitor_active': _performanceMonitor.isMonitoring,
    };
  }

  /// Dispose all services
  void dispose() {
    _performanceMonitor.stopMonitoring();
    _cacheSizeManager.dispose();
    _isInitialized = false;
    debugPrint('🔄 Cache integration service disposed');
  }
}
