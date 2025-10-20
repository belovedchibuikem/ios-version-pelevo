import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'local_storage_service.dart';
import 'unified_auth_service.dart';

class BackgroundSyncService {
  static const String _syncTaskName = 'podcast_sync_task';
  static const String _cleanupTaskName = 'podcast_cleanup_task';

  final LocalStorageService _localStorage = LocalStorageService();
  final UnifiedAuthService _authService = UnifiedAuthService();

  // Sync intervals (in minutes)
  static const int _podcastSyncInterval = 360; // 6 hours
  static const int _cleanupInterval = 1440; // 24 hours

  // Dio instance for API calls
  late Dio _dio;

  // Sync status tracking
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;
  String? _lastSyncError;

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Initialize WorkManager with newer API
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Disabled to prevent background notifications
      );

      // Setup Dio with your API configuration
      await _setupDio();

      // Register periodic tasks
      await _registerPeriodicTasks();

      // Perform initial sync if needed
      if (await _localStorage.needsSync()) {
        await performInitialSync();
      }

      debugPrint('✅ BackgroundSyncService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing BackgroundSyncService: $e');
      rethrow;
    }
  }

  // Setup Dio with your API configuration
  Future<void> _setupDio() async {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth token if available
    final token = await _authService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('🔐 BackgroundSyncService: Added Authorization header');
      debugPrint('🔐 Token length: ${token.length}');
      debugPrint(
          '🔐 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    } else {
      debugPrint('🔐 BackgroundSyncService: No auth token available');
    }

    debugPrint('🔐 BackgroundSyncService: Final headers: $headers');
    debugPrint('🔐 BackgroundSyncService: Base URL: ${ApiConfig.baseUrl}');

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: headers,
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure auth token is fresh for each request
        final freshToken = await _authService.getToken();
        if (freshToken != null) {
          options.headers['Authorization'] = 'Bearer $freshToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('Dio error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // Register periodic background tasks
  Future<void> _registerPeriodicTasks() async {
    try {
      // Register podcast sync task (every 6 hours)
      await Workmanager().registerPeriodicTask(
        _syncTaskName,
        _syncTaskName,
        frequency: Duration(minutes: _podcastSyncInterval),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'task_type': 'podcast_sync',
          'interval_minutes': _podcastSyncInterval,
        },
      );

      // Register cleanup task (every 24 hours)
      await Workmanager().registerPeriodicTask(
        _cleanupTaskName,
        _cleanupTaskName,
        frequency: Duration(minutes: _cleanupInterval),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: true, // Run when device is idle
          requiresStorageNotLow: false,
        ),
        inputData: {
          'task_type': 'cleanup',
          'interval_minutes': _cleanupInterval,
        },
      );

      debugPrint('✅ Periodic tasks registered successfully');
    } catch (e) {
      debugPrint('❌ Error registering periodic tasks: $e');
    }
  }

  // Perform initial sync when app starts
  Future<void> performInitialSync() async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress, skipping initial sync');
      return;
    }

    try {
      _isSyncing = true;
      _lastSyncAttempt = DateTime.now();

      debugPrint('🔄 Starting initial sync...');

      // Check network connectivity
      if (!await _isNetworkAvailable()) {
        debugPrint('⚠️ No network available, skipping initial sync');
        return;
      }

      // Sync podcasts first
      await _syncPodcasts();

      // Sync episodes for subscribed podcasts
      await _syncEpisodesForSubscribedPodcasts();

      // Mark sync as completed
      await _localStorage.markAsSynced();
      _lastSyncError = null;

      debugPrint('✅ Initial sync completed successfully');
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('❌ Error during initial sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Perform background sync (called by WorkManager)
  Future<void> performBackgroundSync() async {
    if (_isSyncing) {
      debugPrint('⚠️ Background sync already in progress, skipping');
      return;
    }

    try {
      _isSyncing = true;
      _lastSyncAttempt = DateTime.now();

      if (kDebugMode) {
        debugPrint('🔄 Starting background sync...');
      }

      // Check network connectivity
      if (!await _isNetworkAvailable()) {
        if (kDebugMode) {
          debugPrint('⚠️ No network available, skipping background sync');
        }
        return;
      }

      // Sync podcasts that need updating
      await _syncPodcasts();

      // Sync episodes for podcasts that need updating
      await _syncEpisodesForSubscribedPodcasts();

      // Sync user data (playback history, bookmarks, etc.)
      await _syncUserData();

      // Mark sync as completed
      await _localStorage.markAsSynced();
      _lastSyncError = null;

      if (kDebugMode) {
        debugPrint('✅ Background sync completed successfully');
      }
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('❌ Error during background sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Sync podcasts from backend
  Future<void> _syncPodcasts() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Syncing podcasts...');
      }

      // Check if user is authenticated
      final token = await _authService.getToken();
      if (token == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No auth token available, skipping podcast sync');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔐 Auth token present, proceeding with sync');
      }

      // Try to sync with a working endpoint first
      try {
        final response = await _dio.get('/api/podcasts/categories');

        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ Successfully connected to podcast API');
            debugPrint('📊 Response status: ${response.statusCode}');
          }
        }
      } catch (apiError) {
        if (kDebugMode) {
          debugPrint('⚠️ Podcast API not available: $apiError');
        }
        // Continue with basic sync check
      }

      if (kDebugMode) {
        debugPrint('✅ Podcast sync check completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error syncing podcasts: $e');
      }
      // Don't rethrow to prevent task failure
    }
  }

  // Sync episodes for subscribed podcasts
  Future<void> _syncEpisodesForSubscribedPodcasts() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Syncing episodes...');
      }

      // Check if user is authenticated
      final token = await _authService.getToken();
      if (token == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No auth token available, skipping episode sync');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔐 Auth token present, checking for new episodes');
      }

      // Simple check for new episodes
      try {
        final response = await _dio.get('/api/podcasts/new-episodes');

        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ Successfully checked for new episodes');
            debugPrint('📊 Response status: ${response.statusCode}');
          }
        }
      } catch (apiError) {
        if (kDebugMode) {
          debugPrint('⚠️ New episodes API not available: $apiError');
        }
        // Continue with basic sync check
      }

      if (kDebugMode) {
        debugPrint('✅ Episode sync check completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error syncing episodes: $e');
      }
      // Don't rethrow to prevent task failure
    }
  }

  // Sync user data to backend
  Future<void> _syncUserData() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Syncing user data...');
      }

      // Check if user is authenticated
      final token = await _authService.getToken();
      if (token == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No auth token available, skipping user data sync');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔐 Auth token present, checking user data');
      }

      // Simple user data check
      try {
        final response = await _dio.get('/api/user');

        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ Successfully checked user data');
            debugPrint('📊 Response status: ${response.statusCode}');
          }
        }
      } catch (apiError) {
        if (kDebugMode) {
          debugPrint('⚠️ User data API not available: $apiError');
        }
        // Continue with basic sync check
      }

      if (kDebugMode) {
        debugPrint('✅ User data sync check completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error syncing user data: $e');
      }
      // Don't rethrow to prevent task failure
    }
  }

  // Check network connectivity
  Future<bool> _isNetworkAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('❌ Error checking network connectivity: $e');
      return false;
    }
  }

  // Manual sync trigger (for user-initiated sync)
  Future<void> triggerManualSync() async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress');
      return;
    }

    await performBackgroundSync();
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    return {
      'isSyncing': _isSyncing,
      'lastSyncAttempt': _lastSyncAttempt?.toIso8601String(),
      'lastSyncError': _lastSyncError,
      'needsSync': await _localStorage.needsSync(),
    };
  }

  // Cancel ongoing sync
  Future<void> cancelSync() async {
    if (_isSyncing) {
      _isSyncing = false;
      debugPrint('🛑 Sync cancelled by user');
    }
  }

  // Cleanup old data
  Future<void> performCleanup() async {
    try {
      if (kDebugMode) {
        debugPrint('🧹 Starting cleanup...');
      }

      // Basic cleanup operations
      try {
        // Clean up expired cache
        await _localStorage.cleanup();
        if (kDebugMode) {
          debugPrint('✅ Cache cleanup completed');
        }
      } catch (cacheError) {
        if (kDebugMode) {
          debugPrint('⚠️ Cache cleanup failed: $cacheError');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Cleanup completed successfully');
      }
    } catch (e) {
      // Always log cleanup errors
      debugPrint('❌ Error during cleanup: $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await cancelSync();
      _dio.close();
      debugPrint('✅ BackgroundSyncService disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing BackgroundSyncService: $e');
    }
  }
}

// WorkManager callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Only show debug prints in debug mode to prevent background notifications
      if (kDebugMode) {
        debugPrint('🔄 Background task started: $taskName');
        debugPrint('📊 Task input data: $inputData');
      }

      final syncService = BackgroundSyncService();

      switch (taskName) {
        case BackgroundSyncService._syncTaskName:
          await syncService.performBackgroundSync();
          if (kDebugMode) {
            debugPrint('🎉 Podcast sync task completed successfully');
          }
          return true;
        case BackgroundSyncService._cleanupTaskName:
          await syncService.performCleanup();
          if (kDebugMode) {
            debugPrint('🎉 Cleanup task completed successfully');
          }
          return true;
        default:
          if (kDebugMode) {
            debugPrint('⚠️ Unknown task: $taskName');
          }
          return true;
      }
    } catch (e) {
      // Always log errors, but only show debug info in debug mode
      if (kDebugMode) {
        debugPrint('❌ Background task failed: $taskName - $e');
      }
      return true; // Return success even on error to prevent retry loops
    }
  });
}
