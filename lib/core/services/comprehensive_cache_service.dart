import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprehensive cache service with multi-tier caching strategy
class ComprehensiveCacheService {
  static final ComprehensiveCacheService _instance =
      ComprehensiveCacheService._internal();
  factory ComprehensiveCacheService() => _instance;
  ComprehensiveCacheService._internal();

  // Cache tiers
  final Map<String, _CacheEntry> _memoryCache = {};
  late Box<String> _persistentCache;

  // Cache configuration
  static const int _maxMemoryCacheSize = 100;
  static const Duration _defaultExpiry = Duration(minutes: 30);

  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;

  // Connectivity
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isOnline = true;

  // Initialization
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize persistent storage
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
      _persistentCache = await Hive.openBox<String>('comprehensive_cache');

      // Initialize connectivity monitoring
      await _initializeConnectivity();

      // Start cleanup timer
      _startCleanupTimer();

      _isInitialized = true;
      debugPrint('✅ ComprehensiveCacheService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing ComprehensiveCacheService: $e');
      rethrow;
    }
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      final connectivity = Connectivity();
      _isOnline =
          await connectivity.checkConnectivity() != ConnectivityResult.none;

      _connectivitySubscription =
          connectivity.onConnectivityChanged.listen((result) {
        _isOnline = result != ConnectivityResult.none;
        debugPrint(
            '🌐 Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      });
    } catch (e) {
      debugPrint(
          '⚠️ Warning: Could not initialize connectivity monitoring: $e');
      _isOnline = true; // Assume online by default
    }
  }

  /// Store data in cache with TTL
  Future<void> set<T>({
    required String key,
    required T data,
    Duration? expiry,
    CacheTier tier = CacheTier.both,
    int priority = 1,
  }) async {
    await initialize();

    final entry = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiry: expiry ?? _getDefaultExpiry(key),
      priority: priority,
      size: _estimateDataSize(data),
    );

    // Store in memory cache if specified
    if (tier == CacheTier.memory || tier == CacheTier.both) {
      _setInMemoryCache(key, entry);
    }

    // Store in persistent cache if specified
    if (tier == CacheTier.persistent || tier == CacheTier.both) {
      await _setInPersistentCache(key, entry);
    }

    debugPrint('💾 Cached data: $key (${tier.name})');
  }

  /// Retrieve data from cache
  Future<T?> get<T>(String key,
      {CacheTier preferredTier = CacheTier.memory}) async {
    await initialize();

    T? data;

    // Try memory cache first if preferred
    if (preferredTier == CacheTier.memory || preferredTier == CacheTier.both) {
      data = _getFromMemoryCache<T>(key);
      if (data != null) {
        _cacheHits++;
        return data;
      }
    }

    // Try persistent cache
    if (preferredTier == CacheTier.persistent ||
        preferredTier == CacheTier.both) {
      data = await _getFromPersistentCache<T>(key);
      if (data != null) {
        // Also store in memory cache for faster access
        final entry = _CacheEntry(
          data: data,
          timestamp: DateTime.now(),
          expiry: _getDefaultExpiry(key),
          priority: 1,
          size: _estimateDataSize(data),
        );
        _setInMemoryCache(key, entry);

        _cacheHits++;
        return data;
      }
    }

    // Try memory cache if not already tried
    if (preferredTier == CacheTier.persistent) {
      data = _getFromMemoryCache<T>(key);
      if (data != null) {
        _cacheHits++;
        return data;
      }
    }

    _cacheMisses++;
    return null;
  }

  /// Check if data exists in cache
  Future<bool> has(String key, {CacheTier tier = CacheTier.both}) async {
    await initialize();

    if (tier == CacheTier.memory || tier == CacheTier.both) {
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        if (!entry.isExpired) return true;
        _memoryCache.remove(key); // Clean up expired entry
      }
    }

    if (tier == CacheTier.persistent || tier == CacheTier.both) {
      try {
        final cached = _persistentCache.get(key);
        if (cached != null) {
          final cacheData = jsonDecode(cached);
          final expiry = cacheData['expiry'] as int;
          final timestamp = cacheData['timestamp'] as int;

          if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
            return true;
          } else {
            // Clean up expired entry
            _persistentCache.delete(key);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error checking persistent cache: $e');
      }
    }

    return false;
  }

  /// Remove specific item from cache
  Future<void> remove(String key, {CacheTier tier = CacheTier.both}) async {
    await initialize();

    if (tier == CacheTier.memory || tier == CacheTier.both) {
      _memoryCache.remove(key);
    }

    if (tier == CacheTier.persistent || tier == CacheTier.both) {
      await _persistentCache.delete(key);
    }

    debugPrint('🗑️ Removed from cache: $key');
  }

  /// Clear all cache
  Future<void> clear({CacheTier tier = CacheTier.both}) async {
    await initialize();

    if (tier == CacheTier.memory || tier == CacheTier.both) {
      _memoryCache.clear();
    }

    if (tier == CacheTier.persistent || tier == CacheTier.both) {
      await _persistentCache.clear();
    }

    debugPrint('🧹 Cache cleared (${tier.name})');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalMemorySize =
        _memoryCache.values.fold<int>(0, (sum, entry) => sum + entry.size);
    final totalMemoryItems = _memoryCache.length;

    return {
      'memory_cache': {
        'items': totalMemoryItems,
        'size_bytes': totalMemorySize,
        'size_mb': (totalMemorySize / (1024 * 1024)).toStringAsFixed(2),
      },
      'persistent_cache': {
        'items': _persistentCache.length,
      },
      'performance': {
        'hits': _cacheHits,
        'misses': _cacheMisses,
        'hit_rate': totalMemoryItems > 0
            ? (_cacheHits / (_cacheHits + _cacheMisses) * 100)
                .toStringAsFixed(1)
            : '0.0',
        'evictions': _cacheEvictions,
      },
      'connectivity': {
        'is_online': _isOnline,
      },
    };
  }

  /// Get offline status
  bool get isOffline => !_isOnline;

  /// Get online status
  bool get isOnline => _isOnline;

  /// Enhanced method for home screen data with better persistence
  Future<void> setHomeScreenData<T>({
    required String key,
    required T data,
    Duration? expiry,
    int priority = 5, // Higher priority for home screen data
  }) async {
    await set<T>(
      key: key,
      data: data,
      expiry: expiry ?? const Duration(hours: 2), // Longer expiry for home data
      tier: CacheTier.both, // Always store in both memory and persistent
      priority: priority,
    );

    // Also store a backup copy with a different key for fallback
    await set<T>(
      key: '${key}_backup',
      data: data,
      expiry: expiry ?? const Duration(hours: 6), // Even longer for backup
      tier: CacheTier.persistent, // Backup only in persistent storage
      priority: priority + 1, // Higher priority for backup
    );
  }

  /// Enhanced method to get home screen data with fallback
  Future<T?> getHomeScreenData<T>(String key) async {
    // Try primary cache first
    T? data = await get<T>(key, preferredTier: CacheTier.memory);

    if (data != null) {
      return data;
    }

    // Try backup cache if primary is not available
    data = await get<T>('${key}_backup', preferredTier: CacheTier.persistent);

    if (data != null) {
      // Restore to primary cache if backup exists
      await setHomeScreenData(key: key, data: data);
      debugPrint('🔄 Restored home screen data from backup: $key');
      return data;
    }

    return null;
  }

  /// Check if home screen data exists in any cache tier
  Future<bool> hasHomeScreenData(String key) async {
    return await has(key) || await has('${key}_backup');
  }

  // Private methods

  void _setInMemoryCache(String key, _CacheEntry entry) {
    // Check capacity and evict if necessary
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _evictFromMemoryCache();
    }

    _memoryCache[key] = entry;
  }

  Future<void> _setInPersistentCache(String key, _CacheEntry entry) async {
    try {
      final cacheData = {
        'data': entry.data,
        'timestamp': entry.timestamp.millisecondsSinceEpoch,
        'expiry': entry.expiry.inMilliseconds,
        'priority': entry.priority,
      };

      await _persistentCache.put(key, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('❌ Error saving to persistent cache: $e');
    }
  }

  T? _getFromMemoryCache<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null || entry.isExpired) {
      if (entry?.isExpired == true) {
        _memoryCache.remove(key);
      }
      return null;
    }

    // Update access time
    entry.lastAccessed = DateTime.now();
    entry.accessCount++;

    return entry.data as T;
  }

  Future<T?> _getFromPersistentCache<T>(String key) async {
    try {
      final cached = _persistentCache.get(key);
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final expiry = cacheData['expiry'] as int;
        final timestamp = cacheData['timestamp'] as int;

        if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
          return cacheData['data'] as T;
        } else {
          // Clean up expired entry
          await _persistentCache.delete(key);
        }
      }
    } catch (e) {
      debugPrint('❌ Error reading from persistent cache: $e');
    }

    return null;
  }

  void _evictFromMemoryCache() {
    if (_memoryCache.isEmpty) return;

    // Find least recently used and lowest priority item
    String? keyToEvict;
    int lowestScore = double.maxFinite.toInt();

    for (final entry in _memoryCache.entries) {
      final score = _calculateEvictionScore(entry.value);
      if (score < lowestScore) {
        lowestScore = score;
        keyToEvict = entry.key;
      }
    }

    if (keyToEvict != null) {
      _memoryCache.remove(keyToEvict);
      _cacheEvictions++;
      debugPrint('🗑️ Evicted from memory cache: $keyToEvict');
    }
  }

  int _calculateEvictionScore(_CacheEntry entry) {
    final age = DateTime.now().difference(entry.timestamp).inMinutes;
    final accessScore = entry.accessCount * 10;
    final priorityScore = entry.priority * 100;
    final ageScore = age * 5;

    return ageScore - accessScore - priorityScore;
  }

  Duration _getDefaultExpiry(String key) {
    // Different TTL for different data types - extended for better persistence
    if (key.startsWith('home_'))
      return const Duration(hours: 4); // Extended from 30 minutes
    if (key.startsWith('library_'))
      return const Duration(hours: 6); // Extended from 2 hours
    if (key.startsWith('profile_'))
      return const Duration(hours: 8); // Extended from 4 hours
    if (key.startsWith('image_')) return const Duration(days: 7);
    if (key.startsWith('crime_'))
      return const Duration(hours: 6); // Specific for crime archives
    if (key.startsWith('health_'))
      return const Duration(hours: 6); // Specific for health podcasts

    return const Duration(hours: 2); // Extended default from 30 minutes
  }

  int _estimateDataSize(dynamic data) {
    try {
      final jsonString = jsonEncode(data);
      return jsonString.length;
    } catch (e) {
      return 1000; // Default size estimate
    }
  }

  void _startCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredEntries();
    });
  }

  void _cleanupExpiredEntries() {
    // Clean memory cache
    final expiredKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint(
          '🧹 Cleaned up ${expiredKeys.length} expired memory cache entries');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription.cancel();
    _persistentCache.close();
  }
}

/// Cache entry with metadata
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiry;
  final int priority;
  final int size;

  DateTime? lastAccessed;
  int accessCount = 0;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiry,
    required this.priority,
    required this.size,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > expiry;
}

/// Cache tier options
enum CacheTier {
  memory,
  persistent,
  both,
}
