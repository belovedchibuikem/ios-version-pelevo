import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'network_connectivity_service.dart';
import '../utils/network_error_handler.dart';

class SmartApiService {
  static final SmartApiService _instance = SmartApiService._internal();
  factory SmartApiService() => _instance;
  SmartApiService._internal();

  final NetworkConnectivityService _connectivityService =
      NetworkConnectivityService();
  final Map<String, Box<String>> _cacheBoxes = {};
  bool _isInitialized = false;

  // Cache configuration
  static const Duration _defaultCacheExpiry = Duration(hours: 1);
  static const Duration _offlineCacheExpiry = Duration(days: 7);

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _connectivityService.initialize();

      // Initialize cache boxes
      await _initializeCacheBoxes();

      _isInitialized = true;
      debugPrint('✅ SmartApiService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing SmartApiService: $e');
      rethrow;
    }
  }

  // Initialize cache boxes for different data types
  Future<void> _initializeCacheBoxes() async {
    final cacheBoxNames = [
      'api_responses',
      'podcast_data',
      'episode_data',
      'user_data',
    ];

    for (final boxName in cacheBoxNames) {
      _cacheBoxes[boxName] = await Hive.openBox<String>(boxName);
    }
  }

  // Smart GET request with offline support
  Future<T> smartGet<T>(
    String endpoint, {
    String? cacheKey,
    Duration? cacheExpiry,
    T Function(Map<String, dynamic>)? fromJson,
    bool forceRefresh = false,
    String cacheBox = 'api_responses',
  }) async {
    await initialize();

    // Check if we should use cached data
    if (!forceRefresh && !await _connectivityService.checkConnectivity()) {
      debugPrint('📱 Offline mode: Using cached data for $endpoint');
      final cachedData = _getFromCache(cacheKey ?? endpoint, cacheBox);
      if (cachedData != null) {
        if (fromJson != null) {
          return fromJson(cachedData);
        }
        return cachedData as T;
      }
      throw Exception('No cached data available and offline');
    }

    try {
      // Make the actual API request
      final response = await _makeApiRequest(endpoint);

      // Cache the successful response
      if (cacheKey != null || cacheBox != 'api_responses') {
        _saveToCache(
          cacheKey ?? endpoint,
          response,
          cacheExpiry ?? _defaultCacheExpiry,
          cacheBox,
        );
      }

      if (fromJson != null) {
        return fromJson(response);
      }
      return response as T;
    } catch (e) {
      // If API fails, try to return cached data
      debugPrint('⚠️ API request failed, trying cached data: $e');
      final cachedData = _getFromCache(cacheKey ?? endpoint, cacheBox);
      if (cachedData != null) {
        debugPrint('✅ Returning cached data for $endpoint');
        if (fromJson != null) {
          return fromJson(cachedData);
        }
        return cachedData as T;
      }
      rethrow;
    }
  }

  // Make API request with proper error handling
  Future<Map<String, dynamic>> _makeApiRequest(String endpoint) async {
    // This would be implemented by the specific API service
    // For now, throw an exception to indicate it needs to be implemented
    throw UnimplementedError('_makeApiRequest must be implemented by subclass');
  }

  // Save data to cache
  void _saveToCache(
      String key, dynamic data, Duration expiry, String cacheBox) {
    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': expiry.inMilliseconds,
      };

      _cacheBoxes[cacheBox]?.put(key, jsonEncode(cacheData));
      debugPrint('💾 Cached data for key: $key');
    } catch (e) {
      debugPrint('❌ Error saving to cache: $e');
    }
  }

  // Get data from cache
  Map<String, dynamic>? _getFromCache(String key, String cacheBox) {
    try {
      final cached = _cacheBoxes[cacheBox]?.get(key);
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final expiry = cacheData['expiry'] as int;
        final timestamp = cacheData['timestamp'] as int;

        // Check if cache is still valid
        if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
          debugPrint('📱 Cache hit for key: $key');
          return cacheData['data'] as Map<String, dynamic>;
        } else {
          // Cache expired, remove it
          _cacheBoxes[cacheBox]?.delete(key);
          debugPrint('⏰ Cache expired for key: $key');
        }
      }
    } catch (e) {
      debugPrint('❌ Error reading from cache: $e');
    }
    return null;
  }

  // Clear expired cache
  Future<void> clearExpiredCache() async {
    try {
      for (final box in _cacheBoxes.values) {
        final keysToDelete = <String>[];

        for (final key in box.keys) {
          final cached = box.get(key);
          if (cached != null) {
            try {
              final cacheData = jsonDecode(cached);
              final expiry = cacheData['expiry'] as int;
              final timestamp = cacheData['timestamp'] as int;

              if (DateTime.now().millisecondsSinceEpoch - timestamp >= expiry) {
                keysToDelete.add(key);
              }
            } catch (e) {
              keysToDelete.add(key);
            }
          }
        }

        for (final key in keysToDelete) {
          await box.delete(key);
        }
      }

      debugPrint('🧹 Cleared expired cache entries');
    } catch (e) {
      debugPrint('❌ Error clearing expired cache: $e');
    }
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final stats = <String, dynamic>{};

    for (final entry in _cacheBoxes.entries) {
      stats[entry.key] = {
        'size': entry.value.length,
        'keys': entry.value.keys.toList(),
      };
    }

    return stats;
  }

  // Check if data is cached
  bool isCached(String key, String cacheBox) {
    return _getFromCache(key, cacheBox) != null;
  }

  // Force refresh cache for specific key
  void invalidateCache(String key, String cacheBox) {
    _cacheBoxes[cacheBox]?.delete(key);
    debugPrint('🗑️ Invalidated cache for key: $key');
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      for (final box in _cacheBoxes.values) {
        await box.close();
      }
      await _connectivityService.dispose();
      debugPrint('✅ SmartApiService disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing SmartApiService: $e');
    }
  }
}

