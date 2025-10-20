import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Simplified image cache service using Flutter's built-in Image.network
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static const String _cacheSizeKey = 'image_cache_size_bytes';
  static const String _lastCleanupKey = 'image_cache_last_cleanup';
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const Duration _cleanupInterval = Duration(days: 1);

  bool _isInitialized = false;
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Initialize the image cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Schedule periodic cleanup
    _scheduleCleanup();

    _isInitialized = true;
    debugPrint('🖼️ Image cache service initialized');
  }

  /// Get network image with basic caching support
  Widget getNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Color? color,
    BlendMode? colorBlendMode,
    Alignment alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    bool matchTextDirection = false,
    FilterQuality filterQuality = FilterQuality.low,
    Map<String, String>? httpHeaders,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _trackImageLoad(imageUrl, true);
          return child;
        }
        return placeholder ?? _buildDefaultPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        _trackImageLoad(imageUrl, false);
        return errorWidget ?? _buildDefaultErrorWidget();
      },
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      filterQuality: filterQuality,
      headers: httpHeaders,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
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

  /// Track image loading success/failure
  void _trackImageLoad(String imageUrl, bool success) {
    if (success) {
      _cacheTimestamps[imageUrl] = DateTime.now();
    }
  }

  /// Get cache size in bytes (simplified estimation)
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/image_cache');

      if (!await imageCacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in imageCacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Get cache size in human readable format
  Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clear image cache
  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/image_cache');

      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
      }

      _cacheTimestamps.clear();
      await _saveCacheSize(0);
      debugPrint('🖼️ Image cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing image cache: $e');
    }
  }

  /// Check if image is cached (simplified check)
  bool isImageCached(String imageUrl) {
    return _cacheTimestamps.containsKey(imageUrl);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final size = await getCacheSize();
    final lastCleanup = await getLastCleanup();
    final isCleanupNeeded = await this.isCleanupNeeded();

    return {
      'size_bytes': size,
      'size_formatted': await getCacheSizeFormatted(),
      'max_size_bytes': _maxCacheSizeBytes,
      'max_size_formatted': _formatBytes(_maxCacheSizeBytes),
      'usage_percentage': (size / _maxCacheSizeBytes * 100).toStringAsFixed(1),
      'last_cleanup': lastCleanup?.toIso8601String(),
      'cleanup_needed': isCleanupNeeded,
      'cleanup_interval_hours': _cleanupInterval.inHours,
      'cached_images_count': _cacheTimestamps.length,
    };
  }

  /// Clean up old cache entries
  Future<void> cleanupCache() async {
    try {
      final currentSize = await getCacheSize();
      if (currentSize <= _maxCacheSizeBytes) return;

      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/image_cache');

      if (!await imageCacheDir.exists()) return;

      // Get all files with their last accessed time
      final files = <File>[];
      await for (final entity in imageCacheDir.list(recursive: true)) {
        if (entity is File) {
          files.add(entity);
        }
      }

      // Sort by last accessed time (oldest first)
      files.sort((a, b) {
        try {
          return a.lastAccessedSync().compareTo(b.lastAccessedSync());
        } catch (e) {
          return 0;
        }
      });

      // Remove oldest files until we're under the limit
      int currentSizeBytes = currentSize;
      for (final file in files) {
        if (currentSizeBytes <= _maxCacheSizeBytes) break;

        final fileSize = await file.length();
        await file.delete();
        currentSizeBytes -= fileSize;
      }

      await _saveCacheSize(currentSizeBytes);
      await _saveLastCleanup(DateTime.now());
      debugPrint('🖼️ Image cache cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during image cache cleanup: $e');
    }
  }

  /// Schedule periodic cleanup
  void _scheduleCleanup() {
    Future.delayed(const Duration(hours: 12), () async {
      await cleanupCache();
      _scheduleCleanup(); // Reschedule
    });
  }

  /// Save cache size to preferences
  Future<void> _saveCacheSize(int size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheSizeKey, size);
    } catch (e) {
      debugPrint('Error saving cache size: $e');
    }
  }

  /// Save last cleanup time
  Future<void> _saveLastCleanup(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastCleanupKey);
      await prefs.setInt(_lastCleanupKey, time.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving last cleanup time: $e');
    }
  }

  /// Get last cleanup time
  Future<DateTime?> getLastCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastCleanupKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      return null;
    }
  }

  /// Check if cleanup is needed
  Future<bool> isCleanupNeeded() async {
    try {
      final lastCleanup = await getLastCleanup();
      if (lastCleanup == null) return true;

      final timeSinceLastCleanup = DateTime.now().difference(lastCleanup);
      return timeSinceLastCleanup >= _cleanupInterval;
    } catch (e) {
      return true;
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

  /// Get cached images count
  int get cachedImagesCount => _cacheTimestamps.length;

  /// Get cache timestamps
  Map<String, DateTime> get cacheTimestamps =>
      Map.unmodifiable(_cacheTimestamps);

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
