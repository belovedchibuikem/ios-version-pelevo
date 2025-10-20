import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:collection';

/// Service for efficient memory management and caching
class MemoryManagementService {
  static final MemoryManagementService _instance =
      MemoryManagementService._internal();
  factory MemoryManagementService() => _instance;
  MemoryManagementService._internal();

  // Cache management
  final Map<String, _CacheEntry> _cache = LinkedHashMap();
  final Map<String, Timer> _cacheTimers = {};

  // Memory limits
  static const int _maxCacheSize = 100;
  static const int _maxCacheAgeMinutes = 30;
  static const int _maxMemoryUsageMB = 50;

  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;

  // Memory monitoring
  Timer? _cleanupTimer;
  bool _isMonitoring = false;

  /// Initialize memory management
  void initialize() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _startCleanupTimer();

    if (kDebugMode) {
      debugPrint('🧠 Memory management service initialized');
    }
  }

  /// Cache data with automatic expiration
  void cacheData<T>({
    required String key,
    required T data,
    Duration? expiration,
    int? priority,
  }) {
    final entry = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiration: expiration ?? const Duration(minutes: _maxCacheAgeMinutes),
      priority: priority ?? 1,
      size: _estimateDataSize(data),
    );

    // Check if we need to evict items
    _ensureCacheCapacity(entry.size);

    // Add to cache
    _cache[key] = entry;

    // Set expiration timer
    _setCacheExpiration(key, entry.expiration);

    if (kDebugMode) {
      debugPrint('💾 Cached data: $key (${entry.size} bytes)');
    }
  }

  /// Retrieve cached data
  T? getCachedData<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      _cacheMisses++;
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _removeFromCache(key);
      _cacheMisses++;
      return null;
    }

    // Update access time and priority
    entry.lastAccessed = DateTime.now();
    entry.accessCount++;

    // Move to end (LRU behavior)
    _cache.remove(key);
    _cache[key] = entry;

    _cacheHits++;
    return entry.data as T;
  }

  /// Check if data is cached
  bool hasCachedData(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      if (entry?.isExpired == true) {
        _removeFromCache(key);
      }
      return false;
    }
    return true;
  }

  /// Remove specific item from cache
  void removeFromCache(String key) {
    _removeFromCache(key);
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _cacheTimers.values.forEach((timer) => timer.cancel());
    _cacheTimers.clear();

    if (kDebugMode) {
      debugPrint('🧹 Cache cleared');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalSize =
        _cache.values.fold<int>(0, (sum, entry) => sum + entry.size);
    final totalItems = _cache.length;

    return {
      'total_items': totalItems,
      'total_size_bytes': totalSize,
      'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_rate': totalItems > 0
          ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(1)
          : '0.0',
      'cache_evictions': _cacheEvictions,
      'max_cache_size': _maxCacheSize,
      'max_memory_mb': _maxMemoryUsageMB,
    };
  }

  /// Get memory usage information
  Map<String, dynamic> getMemoryUsage() {
    final totalSize =
        _cache.values.fold<int>(0, (sum, entry) => sum + entry.size);
    final totalMB = totalSize / (1024 * 1024);

    return {
      'cache_size_mb': totalMB.toStringAsFixed(2),
      'cache_items': _cache.length,
      'max_cache_size': _maxCacheSize,
      'max_memory_mb': _maxMemoryUsageMB,
      'memory_usage_percent':
          (totalMB / _maxMemoryUsageMB * 100).toStringAsFixed(1),
      'is_healthy': totalMB <= _maxMemoryUsageMB,
    };
  }

  /// Optimize cache based on usage patterns
  void optimizeCache() {
    if (_cache.isEmpty) return;

    // Sort entries by priority and access frequency
    final entries = _cache.entries.toList();
    entries.sort((a, b) {
      final aScore = _calculateEntryScore(a.value);
      final bScore = _calculateEntryScore(b.value);
      return bScore.compareTo(aScore); // Higher score first
    });

    // Keep only top entries
    final keepCount = (_maxCacheSize * 0.8).round(); // Keep 80% of max
    if (entries.length > keepCount) {
      final toRemove = entries.skip(keepCount);
      for (final entry in toRemove) {
        _removeFromCache(entry.key);
      }

      if (kDebugMode) {
        debugPrint('🔧 Cache optimized: removed ${toRemove.length} items');
      }
    }
  }

  /// Calculate entry score for optimization
  double _calculateEntryScore(_CacheEntry entry) {
    final age = DateTime.now().difference(entry.timestamp).inMinutes;
    final accessScore = entry.accessCount * 0.3;
    final priorityScore = entry.priority * 0.4;
    final ageScore = (1.0 / (age + 1)) * 0.3; // Newer items get higher score

    return accessScore + priorityScore + ageScore;
  }

  /// Ensure cache capacity
  void _ensureCacheCapacity(int newEntrySize) {
    if (_cache.length < _maxCacheSize) return;

    // Remove oldest/lowest priority items
    final entries = _cache.entries.toList();
    entries.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    int removedSize = 0;
    for (final entry in entries) {
      if (_cache.length <= _maxCacheSize * 0.8) break; // Keep 80% of max

      removedSize += entry.value.size;
      _removeFromCache(entry.key);
    }

    if (kDebugMode && removedSize > 0) {
      debugPrint('🗑️ Evicted ${removedSize} bytes from cache');
    }
  }

  /// Remove item from cache
  void _removeFromCache(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _cacheEvictions++;

      // Cancel expiration timer
      _cacheTimers[key]?.cancel();
      _cacheTimers.remove(key);
    }
  }

  /// Set cache expiration timer
  void _setCacheExpiration(String key, Duration expiration) {
    _cacheTimers[key]?.cancel();

    _cacheTimers[key] = Timer(expiration, () {
      if (_cache.containsKey(key)) {
        _removeFromCache(key);

        if (kDebugMode) {
          debugPrint('⏰ Cache entry expired: $key');
        }
      }
    });
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredEntries();
    });
  }

  /// Cleanup expired entries
  void _cleanupExpiredEntries() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _removeFromCache(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Estimate data size
  int _estimateDataSize(dynamic data) {
    if (data == null) return 0;

    if (data is String) {
      return data.length * 2; // UTF-16 characters
    } else if (data is List) {
      return data.fold<int>(0, (sum, item) => sum + _estimateDataSize(item));
    } else if (data is Map) {
      return data.entries.fold<int>(
          0,
          (sum, entry) =>
              sum +
              _estimateDataSize(entry.key) +
              _estimateDataSize(entry.value));
    } else if (data is num) {
      return 8; // 8 bytes for numbers
    } else if (data is bool) {
      return 1; // 1 byte for booleans
    }

    return 16; // Default size for unknown types
  }

  /// Dispose resources
  void dispose() {
    _isMonitoring = false;
    _cleanupTimer?.cancel();
    _cacheTimers.values.forEach((timer) => timer.cancel());
    clearCache();

    if (kDebugMode) {
      debugPrint('🧠 Memory management service disposed');
    }
  }
}

/// Cache entry class
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiration;
  final int priority;
  final int size;

  DateTime lastAccessed;
  int accessCount;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiration,
    required this.priority,
    required this.size,
  })  : lastAccessed = timestamp,
        accessCount = 0;

  bool get isExpired {
    return DateTime.now().difference(timestamp) > expiration;
  }
}
