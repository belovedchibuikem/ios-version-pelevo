import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../utils/network_error_handler.dart';
import '../interceptors/retry_interceptor.dart';
import 'comprehensive_cache_service.dart';
import 'unified_auth_service.dart';

/// Enhanced API service with cache-first strategy and offline support
class EnhancedApiService {
  static final EnhancedApiService _instance = EnhancedApiService._internal();
  factory EnhancedApiService() => _instance;
  EnhancedApiService._internal();

  final Dio _dio = Dio();
  final ComprehensiveCacheService _cacheService = ComprehensiveCacheService();
  final UnifiedAuthService _authService = UnifiedAuthService();

  bool _isInitialized = false;
  String? _authToken;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize cache service
      await _cacheService.initialize();

      // Initialize Dio
      _dio.options = BaseOptions(
        baseUrl: '${ApiConfig.baseUrl}/api',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      );

      // Add retry interceptor
      _dio.interceptors.add(RetryInterceptor(
        maxRetries: 2,
        baseDelay: const Duration(seconds: 2),
        retryOnTimeout: true,
        retryOnConnectionError: true,
        retryOnServerError: false,
        maxDelay: const Duration(seconds: 8),
      ));

      // Add auth interceptor
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint(
                '🔐 EnhancedApiService: Authorization header set with token: ${token.substring(0, 10)}...');
          } else {
            debugPrint(
                '⚠️ EnhancedApiService: No token available for request to ${options.path}');
          }
          handler.next(options);
        },
      ));

      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
        ));
      }

      _isInitialized = true;
      debugPrint('✅ EnhancedApiService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing EnhancedApiService: $e');
      rethrow;
    }
  }

  /// Smart GET request with cache-first strategy
  Future<T> smartGet<T>({
    required String endpoint,
    required String cacheKey,
    required T Function(dynamic) fromJson,
    Duration? cacheExpiry,
    CacheTier cacheTier = CacheTier.both,
    bool forceRefresh = false,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<dynamic>(
        cacheKey,
        preferredTier: cacheTier,
      );

      if (cachedData != null) {
        debugPrint('📱 Cache hit for: $cacheKey');
        try {
          return fromJson(cachedData);
        } catch (e) {
          debugPrint('⚠️ Error parsing cached data: $e');
          // Continue to API call if cached data is invalid
        }
      }
    }

    // If offline and no cached data, throw exception
    if (_cacheService.isOffline) {
      final cachedData = await _cacheService.get<dynamic>(
        cacheKey,
        preferredTier: CacheTier.persistent,
      );

      if (cachedData != null) {
        debugPrint('📱 Offline mode: Using cached data for $cacheKey');
        try {
          return fromJson(cachedData);
        } catch (e) {
          throw Exception('No valid cached data available and offline');
        }
      } else {
        throw Exception('No cached data available and offline');
      }
    }

    try {
      // Make API request
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;

        // Cache the successful response
        await _cacheService.set(
          key: cacheKey,
          data: data,
          expiry: cacheExpiry,
          tier: cacheTier,
          priority: 1,
        );

        debugPrint('✅ API request successful for: $endpoint');
        return fromJson(data);
      } else {
        throw Exception(
            'API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ API request failed for: $endpoint - $e');

      // Try to return cached data as fallback
      final cachedData = await _cacheService.get<dynamic>(
        cacheKey,
        preferredTier: cacheTier,
      );

      if (cachedData != null) {
        debugPrint('📱 Returning cached data as fallback for: $cacheKey');
        try {
          return fromJson(cachedData);
        } catch (e) {
          debugPrint('⚠️ Error parsing fallback cached data: $e');
        }
      }

      // Handle network errors
      if (e is DioException && context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'smartGet',
          onRetry: onRetry,
        );
      }

      rethrow;
    }
  }

  /// Smart POST request with cache invalidation
  Future<T> smartPost<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? invalidateCacheKeys,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      final response = await _dio.post(endpoint, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        // Invalidate specified cache keys
        if (invalidateCacheKeys != null) {
          for (final key in invalidateCacheKeys) {
            await _cacheService.remove(key);
            debugPrint('🗑️ Invalidated cache key: $key');
          }
        }

        debugPrint('✅ POST request successful for: $endpoint');
        return fromJson(responseData);
      } else {
        throw Exception(
            'POST request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ POST request failed for: $endpoint - $e');

      // Handle network errors
      if (e is DioException && context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'smartPost',
          onRetry: onRetry,
        );
      }

      rethrow;
    }
  }

  /// Smart PUT request with cache invalidation
  Future<T> smartPut<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? invalidateCacheKeys,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      final response = await _dio.put(endpoint, data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Invalidate specified cache keys
        if (invalidateCacheKeys != null) {
          for (final key in invalidateCacheKeys) {
            await _cacheService.remove(key);
            debugPrint('🗑️ Invalidated cache key: $key');
          }
        }

        debugPrint('✅ PUT request successful for: $endpoint');
        return fromJson(responseData);
      } else {
        throw Exception(
            'PUT request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ PUT request failed for: $endpoint - $e');

      // Handle network errors
      if (e is DioException && context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'smartPut',
          onRetry: onRetry,
        );
      }

      rethrow;
    }
  }

  /// Smart DELETE request with cache invalidation
  Future<void> smartDelete({
    required String endpoint,
    List<String>? invalidateCacheKeys,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      final response = await _dio.delete(endpoint);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Invalidate specified cache keys
        if (invalidateCacheKeys != null) {
          for (final key in invalidateCacheKeys) {
            await _cacheService.remove(key);
            debugPrint('🗑️ Invalidated cache key: $key');
          }
        }

        debugPrint('✅ DELETE request successful for: $endpoint');
      } else {
        throw Exception(
            'DELETE request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ DELETE request failed for: $endpoint - $e');

      // Handle network errors
      if (e is DioException && context != null) {
        NetworkErrorHandler.handleNetworkError(
          context,
          e,
          errorContext: 'smartDelete',
          onRetry: onRetry,
        );
      }

      rethrow;
    }
  }

  /// Force refresh specific cache keys
  Future<void> forceRefreshCache(List<String> cacheKeys) async {
    await initialize();

    for (final key in cacheKeys) {
      await _cacheService.remove(key);
      debugPrint('🔄 Force refreshed cache key: $key');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }

  /// Check if service is online
  bool get isOnline => _cacheService.isOnline;

  /// Check if service is offline
  bool get isOffline => _cacheService.isOffline;

  /// Clear all cache
  Future<void> clearCache() async {
    await initialize();
    await _cacheService.clear();
  }

  /// Dispose resources
  void dispose() {
    _cacheService.dispose();
  }
}
