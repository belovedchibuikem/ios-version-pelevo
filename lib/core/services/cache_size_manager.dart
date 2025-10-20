import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

/// Cache size management service for automatic cleanup and optimization
class CacheSizeManager {
  static final CacheSizeManager _instance = CacheSizeManager._internal();
  factory CacheSizeManager() => _instance;
  CacheSizeManager._internal();

  static const String _cacheSizeKey = 'total_cache_size_bytes';
  static const String _lastCleanupKey = 'last_cache_cleanup';
  static const String _cleanupCountKey = 'cache_cleanup_count';
  static const String _cacheStatsKey = 'cache_statistics';

  // Cache size limits
  static const int _maxTotalCacheSize = 200 * 1024 * 1024; // 200MB
  static const int _maxImageCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxDataCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxTempCacheSize = 50 * 1024 * 1024; // 50MB

  // Cleanup intervals
  static const Duration _cleanupInterval = Duration(hours: 6);
  static const Duration _emergencyCleanupThreshold = Duration(hours: 1);

  Timer? _cleanupTimer;
  bool _isInitialized = false;
  bool _isCleaningUp = false;

  /// Initialize the cache size manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Schedule periodic cleanup
    _scheduleCleanup();

    // Perform initial cleanup if needed
    if (await _isCleanupNeeded()) {
      await performCleanup();
    }

    _isInitialized = true;
    debugPrint('🗂️ Cache size manager initialized');
  }

  /// Schedule periodic cleanup
  void _scheduleCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) async {
      if (await _isCleanupNeeded()) {
        await performCleanup();
      }
    });
  }

  /// Check if cleanup is needed
  Future<bool> _isCleanupNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt(_lastCleanupKey);

      if (lastCleanup == null) return true;

      final timeSinceLastCleanup = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastCleanup));

      return timeSinceLastCleanup >= _cleanupInterval;
    } catch (e) {
      debugPrint('Error checking cleanup status: $e');
      return true;
    }
  }

  /// Perform comprehensive cache cleanup
  Future<void> performCleanup() async {
    if (_isCleaningUp) return;

    _isCleaningUp = true;
    debugPrint('🧹 Starting cache cleanup...');

    try {
      final startTime = DateTime.now();

      // Get current cache sizes
      final currentSizes = await _getCurrentCacheSizes();
      final totalSize = currentSizes.values.reduce((a, b) => a + b);

      debugPrint('📊 Current cache sizes: ${_formatBytes(totalSize)}');

      if (totalSize <= _maxTotalCacheSize) {
        debugPrint('✅ Cache size is within limits, no cleanup needed');
        await _updateLastCleanup();
        return;
      }

      // Perform cleanup based on priority
      await _cleanupImageCache(currentSizes['images'] ?? 0);
      await _cleanupDataCache(currentSizes['data'] ?? 0);
      await _cleanupTempCache(currentSizes['temp'] ?? 0);

      // Verify cleanup results
      final newSizes = await _getCurrentCacheSizes();
      final newTotalSize = newSizes.values.reduce((a, b) => a + b);

      final cleanupTime = DateTime.now().difference(startTime);
      final freedSpace = totalSize - newTotalSize;

      debugPrint(
          '✅ Cache cleanup completed in ${cleanupTime.inMilliseconds}ms');
      debugPrint('💾 Freed ${_formatBytes(freedSpace)} of space');
      debugPrint('📊 New total size: ${_formatBytes(newTotalSize)}');

      await _updateLastCleanup();
      await _incrementCleanupCount();
      await _updateCacheStats(totalSize, newTotalSize, freedSpace, cleanupTime);
    } catch (e) {
      debugPrint('❌ Error during cache cleanup: $e');
    } finally {
      _isCleaningUp = false;
    }
  }

  /// Cleanup image cache
  Future<void> _cleanupImageCache(int currentSize) async {
    if (currentSize <= _maxImageCacheSize) return;

    debugPrint('🖼️ Cleaning up image cache...');

    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');

      if (!await imageCacheDir.exists()) return;

      final files = await _getCacheFiles(imageCacheDir);
      final sortedFiles = _sortFilesByAccessTime(files);

      int sizeToFree = currentSize - _maxImageCacheSize;
      int freedSize = 0;

      for (final file in sortedFiles) {
        if (freedSize >= sizeToFree) break;

        final fileSize = await file.length();
        await file.delete();
        freedSize += fileSize;
      }

      debugPrint('🖼️ Image cache cleanup: freed ${_formatBytes(freedSize)}');
    } catch (e) {
      debugPrint('❌ Error cleaning up image cache: $e');
    }
  }

  /// Cleanup data cache
  Future<void> _cleanupDataCache(int currentSize) async {
    if (currentSize <= _maxDataCacheSize) return;

    debugPrint('📁 Cleaning up data cache...');

    try {
      final cacheDir = await getTemporaryDirectory();
      final dataCacheDir = Directory('${cacheDir.path}/cache');

      if (!await dataCacheDir.exists()) return;

      final files = await _getCacheFiles(dataCacheDir);
      final sortedFiles = _sortFilesByAccessTime(files);

      int sizeToFree = currentSize - _maxDataCacheSize;
      int freedSize = 0;

      for (final file in sortedFiles) {
        if (freedSize >= sizeToFree) break;

        final fileSize = await file.length();
        await file.delete();
        freedSize += fileSize;
      }

      debugPrint('📁 Data cache cleanup: freed ${_formatBytes(freedSize)}');
    } catch (e) {
      debugPrint('❌ Error cleaning up data cache: $e');
    }
  }

  /// Cleanup temporary cache
  Future<void> _cleanupTempCache(int currentSize) async {
    if (currentSize <= _maxTempCacheSize) return;

    debugPrint('🗑️ Cleaning up temp cache...');

    try {
      final cacheDir = await getTemporaryDirectory();
      final tempCacheDir = Directory('${cacheDir.path}/temp');

      if (!await tempCacheDir.exists()) return;

      final files = await _getCacheFiles(tempCacheDir);
      final sortedFiles = _sortFilesByAccessTime(files);

      int sizeToFree = currentSize - _maxTempCacheSize;
      int freedSize = 0;

      for (final file in sortedFiles) {
        if (freedSize >= sizeToFree) break;

        final fileSize = await file.length();
        await file.delete();
        freedSize += fileSize;
      }

      debugPrint('🗑️ Temp cache cleanup: freed ${_formatBytes(freedSize)}');
    } catch (e) {
      debugPrint('❌ Error cleaning up temp cache: $e');
    }
  }

  /// Get cache files from directory
  Future<List<File>> _getCacheFiles(Directory dir) async {
    final files = <File>[];

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (e) {
      debugPrint('Error listing cache files: $e');
    }

    return files;
  }

  /// Sort files by last access time (oldest first)
  List<File> _sortFilesByAccessTime(List<File> files) {
    files.sort((a, b) {
      try {
        return a.lastAccessedSync().compareTo(b.lastAccessedSync());
      } catch (e) {
        return 0;
      }
    });
    return files;
  }

  /// Get current cache sizes
  Future<Map<String, int>> _getCurrentCacheSizes() async {
    final sizes = <String, int>{};

    try {
      final cacheDir = await getTemporaryDirectory();

      // Image cache
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      sizes['images'] = await _getDirectorySize(imageCacheDir);

      // Data cache
      final dataCacheDir = Directory('${cacheDir.path}/cache');
      sizes['data'] = await _getDirectorySize(dataCacheDir);

      // Temp cache
      final tempCacheDir = Directory('${cacheDir.path}/temp');
      sizes['temp'] = await _getDirectorySize(tempCacheDir);
    } catch (e) {
      debugPrint('Error getting cache sizes: $e');
      sizes['images'] = 0;
      sizes['data'] = 0;
      sizes['temp'] = 0;
    }

    return sizes;
  }

  /// Get directory size
  Future<int> _getDirectorySize(Directory dir) async {
    if (!await dir.exists()) return 0;

    int totalSize = 0;

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
    }

    return totalSize;
  }

  /// Update last cleanup time
  Future<void> _updateLastCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastCleanupKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last cleanup time: $e');
    }
  }

  /// Increment cleanup count
  Future<void> _incrementCleanupCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_cleanupCountKey) ?? 0;
      await prefs.setInt(_cleanupCountKey, currentCount + 1);
    } catch (e) {
      debugPrint('Error incrementing cleanup count: $e');
    }
  }

  /// Update cache statistics
  Future<void> _updateCacheStats(
      int oldSize, int newSize, int freedSpace, Duration cleanupTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = {
        'last_cleanup': DateTime.now().toIso8601String(),
        'old_size_bytes': oldSize,
        'new_size_bytes': newSize,
        'freed_space_bytes': freedSpace,
        'cleanup_time_ms': cleanupTime.inMilliseconds,
        'efficiency': freedSpace > 0
            ? (freedSpace / oldSize * 100).toStringAsFixed(1)
            : '0.0',
      };

      await prefs.setString(_cacheStatsKey, stats.toString());
    } catch (e) {
      debugPrint('Error updating cache stats: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSizes = await _getCurrentCacheSizes();
      final totalSize = currentSizes.values.reduce((a, b) => a + b);
      final lastCleanup = prefs.getInt(_lastCleanupKey);
      final cleanupCount = prefs.getInt(_cleanupCountKey) ?? 0;
      final statsString = prefs.getString(_cacheStatsKey);

      return {
        'current_sizes': {
          'images': _formatBytes(currentSizes['images'] ?? 0),
          'data': _formatBytes(currentSizes['data'] ?? 0),
          'temp': _formatBytes(currentSizes['temp'] ?? 0),
          'total': _formatBytes(totalSize),
        },
        'limits': {
          'max_total': _formatBytes(_maxTotalCacheSize),
          'max_images': _formatBytes(_maxImageCacheSize),
          'max_data': _formatBytes(_maxDataCacheSize),
          'max_temp': _formatBytes(_maxTempCacheSize),
        },
        'usage_percentage':
            (totalSize / _maxTotalCacheSize * 100).toStringAsFixed(1),
        'last_cleanup': lastCleanup != null
            ? DateTime.fromMillisecondsSinceEpoch(lastCleanup).toIso8601String()
            : 'Never',
        'cleanup_count': cleanupCount,
        'cleanup_interval_hours': _cleanupInterval.inHours,
        'is_cleaning_up': _isCleaningUp,
        'detailed_stats': statsString,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Force immediate cleanup
  Future<void> forceCleanup() async {
    debugPrint('🚨 Force cleanup requested');
    await performCleanup();
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    debugPrint('🗑️ Clearing all caches...');

    try {
      final cacheDir = await getTemporaryDirectory();

      // Clear image cache
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
      }

      // Clear data cache
      final dataCacheDir = Directory('${cacheDir.path}/cache');
      if (await dataCacheDir.exists()) {
        await dataCacheDir.delete(recursive: true);
      }

      // Clear temp cache
      final tempCacheDir = Directory('${cacheDir.path}/temp');
      if (await tempCacheDir.exists()) {
        await tempCacheDir.delete(recursive: true);
      }

      await _updateLastCleanup();
      debugPrint('✅ All caches cleared');
    } catch (e) {
      debugPrint('❌ Error clearing caches: $e');
    }
  }

  /// Check if emergency cleanup is needed
  Future<bool> isEmergencyCleanupNeeded() async {
    try {
      final currentSizes = await _getCurrentCacheSizes();
      final totalSize = currentSizes.values.reduce((a, b) => a + b);

      // Emergency cleanup if cache is 90% full
      return totalSize > (_maxTotalCacheSize * 0.9);
    } catch (e) {
      return false;
    }
  }

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _isInitialized = false;
    debugPrint('🗂️ Cache size manager disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
