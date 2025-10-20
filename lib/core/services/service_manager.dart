import 'dart:async';
import 'package:flutter/foundation.dart';

import 'local_storage_service.dart';
import 'background_sync_service.dart';
import 'data_sync_manager.dart';
import 'offline_queue_manager.dart';
import 'media_session_service.dart';
import 'notification_service.dart';
import 'unified_auth_service.dart';
import 'playback_persistence_service.dart';
import 'cache_integration_service.dart';
import '../../providers/podcast_player_provider.dart';

class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  // Service instances - make nullable to prevent LateInitializationError
  LocalStorageService? _localStorage;
  BackgroundSyncService? _backgroundSync;
  DataSyncManager? _dataSync;
  OfflineQueueManager? _offlineQueue;
  MediaSessionService? _mediaSession;
  NotificationService? _notifications;
  UnifiedAuthService? _authService;
  PlaybackPersistenceService? _playbackPersistence;
  CacheIntegrationService? _cacheIntegration;

  // State tracking
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;

  // Getters for services with null safety
  LocalStorageService? get localStorage => _localStorage;
  BackgroundSyncService? get backgroundSync => _backgroundSync;
  DataSyncManager? get dataSync => _dataSync;
  OfflineQueueManager? get offlineQueue => _offlineQueue;
  MediaSessionService? get mediaSession => _mediaSession;
  NotificationService? get notifications => _notifications;
  UnifiedAuthService? get authService => _authService;
  PlaybackPersistenceService? get playbackPersistence => _playbackPersistence;
  CacheIntegrationService? get cacheIntegration => _cacheIntegration;

  // Safe getters that initialize services if needed
  Future<LocalStorageService> get localStorageSafe async {
    if (_localStorage == null) {
      await _initializeLocalStorage();
    }
    return _localStorage!;
  }

  Future<BackgroundSyncService> get backgroundSyncSafe async {
    if (_backgroundSync == null) {
      await _initializeBackgroundServices();
    }
    return _backgroundSync!;
  }

  Future<DataSyncManager> get dataSyncSafe async {
    if (_dataSync == null) {
      await _initializeBackgroundServices();
    }
    return _dataSync!;
  }

  Future<OfflineQueueManager> get offlineQueueSafe async {
    if (_offlineQueue == null) {
      await _initializeBackgroundServices();
    }
    return _offlineQueue!;
  }

  Future<MediaSessionService> get mediaSessionSafe async {
    if (_mediaSession == null) {
      await _initializeMediaServices();
    }
    return _mediaSession!;
  }

  Future<NotificationService?> get notificationsSafe async {
    if (_notifications == null) {
      try {
        await _initializeNotificationServices();
      } catch (e) {
        debugPrint('⚠️ Failed to initialize notification services: $e');
        return null;
      }
    }
    return _notifications;
  }

  Future<UnifiedAuthService> get authServiceSafe async {
    if (_authService == null) {
      await _initializeAuthService();
    }
    return _authService!;
  }

  Future<CacheIntegrationService> get cacheIntegrationSafe async {
    if (_cacheIntegration == null) {
      await _initializeCacheIntegration();
    }
    return _cacheIntegration!;
  }

  // Initialize all services
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _initializationError = null;

    try {
      debugPrint('🚀 Initializing ServiceManager...');

      // Initialize services in dependency order
      await _initializeAuthService();
      await _initializeLocalStorage();
      await _initializeBackgroundServices();
      await _initializeMediaServices();
      await _initializeNotificationServices();
      await _initializeCacheIntegration();
      await _setupServiceConnections();

      _isInitialized = true;
      debugPrint('✅ ServiceManager initialized successfully');
    } catch (e) {
      _initializationError = e.toString();
      debugPrint('❌ Error initializing ServiceManager: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize only essential services for state restoration
  Future<void> initializeEssentialServicesOnly() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _initializationError = null;

    try {
      debugPrint('🚀 Initializing essential services only...');

      // Initialize only services needed for basic functionality
      await _initializeAuthService();
      await _initializeLocalStorage();
      await _initializeCacheIntegration();

      // Skip background services, media services, and notifications for now
      // These will be initialized later when needed

      _isInitialized = true;
      debugPrint('✅ Essential services initialized successfully');
    } catch (e) {
      _initializationError = e.toString();
      debugPrint('❌ Error initializing essential services: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  // Initialize auth service first
  Future<void> _initializeAuthService() async {
    debugPrint('🔐 Initializing UnifiedAuthService...');
    try {
      _authService = UnifiedAuthService();
      debugPrint('✅ UnifiedAuthService initialized');
    } catch (e) {
      debugPrint('⚠️ Warning: UnifiedAuthService initialization failed: $e');
      debugPrint('UnifiedAuthService will be initialized later when needed');
      // Don't rethrow - continue without auth service for now
    }
  }

  // Initialize local storage first
  Future<void> _initializeLocalStorage() async {
    debugPrint('📱 Initializing LocalStorageService...');
    try {
      _localStorage = LocalStorageService();
      await _localStorage!.initialize();
      debugPrint('✅ LocalStorageService initialized');

      // Initialize playback persistence service with local storage
      _playbackPersistence =
          PlaybackPersistenceService(localStorage: _localStorage);
      debugPrint('✅ PlaybackPersistenceService initialized');
    } catch (e) {
      debugPrint('⚠️ Warning: LocalStorageService initialization failed: $e');
      debugPrint('LocalStorageService will be initialized later when needed');
      // Don't rethrow - continue without local storage for now
    }
  }

  // Initialize background services
  Future<void> _initializeBackgroundServices() async {
    debugPrint('🔄 Initializing background services...');

    try {
      _backgroundSync = BackgroundSyncService();
      _dataSync = DataSyncManager();
      _offlineQueue = OfflineQueueManager();

      // Initialize in parallel with error handling
      try {
        await Future.wait([
          _backgroundSync!.initialize(),
          _dataSync!.initialize(),
          _offlineQueue!.initialize(),
        ]);
        debugPrint('✅ All background services initialized successfully');
      } catch (e) {
        debugPrint('⚠️ Some background services failed to initialize: $e');
        // Continue without failing services
      }

      debugPrint('✅ Background services initialization completed');
    } catch (e) {
      debugPrint('⚠️ Warning: Background services initialization failed: $e');
      debugPrint('Background services will be initialized later when needed');
      // Don't rethrow - continue without background services for now
    }
  }

  // Initialize media services
  Future<void> _initializeMediaServices() async {
    debugPrint('🎵 Initializing media services...');

    try {
      _mediaSession = MediaSessionService();
      // Note: Media session will be initialized later when player provider is available
      debugPrint(
          '✅ Media session service created (will initialize with player provider)');
    } catch (e) {
      debugPrint('⚠️ Warning: Media services initialization failed: $e');
      debugPrint('Media services will be initialized later when needed');
      // Don't rethrow - continue without media services for now
    }
  }

  // Initialize media session with player provider
  Future<void> initializeMediaSessionWithPlayer(
      PodcastPlayerProvider playerProvider) async {
    if (_mediaSession == null) {
      debugPrint('🎵 Creating media session service...');
      _mediaSession = MediaSessionService();
    }

    try {
      await _mediaSession!.initialize(playerProvider: playerProvider);
      debugPrint('✅ Media session initialized with player provider');
    } catch (e) {
      debugPrint('⚠️ Warning: Media session initialization failed: $e');
      debugPrint('Media session will work without system media controls');
    }
  }

  // Initialize notification services
  Future<void> _initializeNotificationServices() async {
    debugPrint('🔔 Initializing notification services...');

    try {
      _notifications = NotificationService();
      await _notifications!.initialize();
      debugPrint('✅ Notification services initialized (permissions deferred)');
    } catch (e) {
      debugPrint('⚠️ Warning: Notification services initialization failed: $e');
      debugPrint('App will continue without notification services for now');
      // Don't rethrow - continue without notification services
      _notifications = null;
    }
  }

  // Initialize cache integration service
  Future<void> _initializeCacheIntegration() async {
    debugPrint('🗂️ Initializing cache integration service...');

    try {
      _cacheIntegration = CacheIntegrationService();
      await _cacheIntegration!.initialize();
      debugPrint('✅ Cache integration service initialized');
    } catch (e) {
      debugPrint(
          '⚠️ Warning: Cache integration service initialization failed: $e');
      debugPrint(
          'Cache integration service will be initialized later when needed');
      // Don't rethrow - continue without cache integration for now
    }
  }

  // Setup connections between services
  Future<void> _setupServiceConnections() async {
    debugPrint('🔗 Setting up service connections...');

    try {
      // Note: Media session notifications will be handled manually
      // when episodes are set or playback state changes

      // Setup background sync notifications (only if both services are available)
      // Disabled to prevent aggressive background notifications
      // if (_backgroundSync != null && _notifications != null) {
      //   try {
      //     final status = await _backgroundSync!.getSyncStatus();
      //     if (status['isSyncing'] == true) {
      //       _notifications!.showSyncNotification(
      //         title: 'Podcast Sync',
      //         body: 'Synchronizing podcasts and episodes...',
      //         isOngoing: true,
      //       );
      //     }
      //   } catch (e) {
      //     debugPrint('⚠️ Could not setup background sync notifications: $e');
      //   }
      // }

      // Setup offline queue notifications (only if both services are available)
      // Disabled to prevent aggressive background notifications
      // if (_offlineQueue != null && _notifications != null) {
      //   try {
      //     final stats = await _offlineQueue!.getQueueStats();
      //     if (stats['pendingCount'] > 0) {
      //       _notifications!.showSyncNotification(
      //         title: 'Offline Operations',
      //         body: '${stats['pendingCount']} operations pending sync',
      //       );
      //     }
      //   } catch (e) {
      //     debugPrint('⚠️ Could not setup offline queue notifications: $e');
      //   }
      // }

      debugPrint('✅ Service connections established');
    } catch (e) {
      debugPrint('⚠️ Warning: Service connections setup failed: $e');
      debugPrint('Service connections will be established later when needed');
    }
  }

  // Get initialization status
  Map<String, dynamic> getInitializationStatus() {
    return {
      'isInitialized': _isInitialized,
      'isInitializing': _isInitializing,
      'error': _initializationError,
      'services': {
        'localStorage': _localStorage != null,
        'backgroundSync': _backgroundSync != null,
        'dataSync': _dataSync != null,
        'offlineQueue': _offlineQueue != null,
        'authService': _authService != null,
        'mediaSession': _mediaSession != null,
        'notifications': _notifications != null,
        'playbackPersistence': _playbackPersistence != null,
      },
    };
  }

  // Check if all services are ready
  bool get isReady => _isInitialized && !_isInitializing;

  // Check if specific services are available
  bool get hasLocalStorage => _localStorage != null;
  bool get hasBackgroundSync => _backgroundSync != null;
  bool get hasMediaSession => _mediaSession != null;
  bool get hasNotifications => _notifications != null;
  bool get hasAuthService => _authService != null;
  bool get hasPlaybackPersistence => _playbackPersistence != null;
  bool get hasCacheIntegration => _cacheIntegration != null;

  // Get service status for debugging
  Map<String, bool> get serviceStatus => {
        'localStorage': hasLocalStorage,
        'backgroundSync': hasBackgroundSync,
        'authService': hasAuthService,
        'mediaSession': hasMediaSession,
        'notifications': hasNotifications,
        'playbackPersistence': hasPlaybackPersistence,
        'cacheIntegration': _cacheIntegration != null,
        'isInitialized': _isInitialized,
        'isInitializing': _isInitializing,
      };

  // Initialize media services when needed
  Future<void> initializeMediaServices() async {
    if (_mediaSession != null && _mediaSession!.isInitialized) {
      return; // Already initialized
    }

    try {
      debugPrint('🎵 Initializing media services (deferred)...');
      _mediaSession = MediaSessionService();
      await _mediaSession!.initialize();
      debugPrint('✅ Media services initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing media services: $e');
      rethrow;
    }
  }

  // Get service health status
  Future<Map<String, dynamic>> getServiceHealth() async {
    try {
      final syncStatus = await _dataSync!.getSyncStatus();
      final queueStats = await _offlineQueue!.getQueueStats();
      final notificationStatus =
          await _notifications!.areNotificationsEnabled();

      return {
        'overall': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'services': {
          'localStorage': 'healthy',
          'backgroundSync': syncStatus['isSyncing'] ? 'syncing' : 'idle',
          'dataSync': syncStatus['isOnline'] ? 'online' : 'offline',
          'offlineQueue': {
            'pending': queueStats['pendingCount'],
            'failed': queueStats['failedCount'],
            'status': queueStats['isProcessing'] ? 'processing' : 'idle',
          },
          'mediaSession': _mediaSession != null && _mediaSession!.isInitialized
              ? 'ready'
              : 'not_initialized',
          'notifications': notificationStatus ? 'enabled' : 'disabled',
          'cacheIntegration':
              _cacheIntegration != null ? 'ready' : 'not_initialized',
        },
        'sync': syncStatus,
        'queue': queueStats,
      };
    } catch (e) {
      return {
        'overall': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Perform health check and auto-recovery
  Future<void> performHealthCheck() async {
    try {
      debugPrint('🏥 Performing service health check...');

      final health = await getServiceHealth();

      if (health['overall'] == 'error') {
        debugPrint('⚠️ Service health check failed, attempting recovery...');
        await _attemptRecovery();
      } else {
        debugPrint('✅ Service health check passed');
      }
    } catch (e) {
      debugPrint('❌ Error during health check: $e');
    }
  }

  // Attempt to recover failed services
  Future<void> _attemptRecovery() async {
    try {
      debugPrint('🔄 Attempting service recovery...');

      // Check if local storage is accessible
      try {
        await _localStorage!.getDatabaseStats();
      } catch (e) {
        debugPrint('🔄 Reinitializing local storage...');
        await _localStorage!.initialize();
      }

      // Check if background sync is working
      final syncStatus = await _dataSync!.getSyncStatus();
      if (syncStatus['isOnline'] == false) {
        debugPrint('🔄 Rechecking network connectivity...');
        // This will trigger connectivity monitoring
      }

      // Check if notifications are working
      final notificationStatus =
          await _notifications!.areNotificationsEnabled();
      if (notificationStatus == false) {
        debugPrint('🔄 Requesting notification permissions...');
        await _notifications!.requestPermissions();
      }

      debugPrint('✅ Service recovery completed');
    } catch (e) {
      debugPrint('❌ Service recovery failed: $e');
    }
  }

  // Manual sync trigger
  Future<void> triggerManualSync() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Services not initialized, cannot sync');
      return;
    }

    try {
      debugPrint('🔄 Triggering manual sync...');

      // Show sync notification
      await _notifications!.showSyncNotification(
        title: 'Manual Sync',
        body: 'Starting podcast synchronization...',
        isOngoing: true,
      );

      // Perform sync
      await _dataSync!.triggerManualSync();

      // Update notification
      await _notifications!.showSyncNotification(
        title: 'Sync Complete',
        body: 'Podcast synchronization completed successfully',
      );

      debugPrint('✅ Manual sync completed');
    } catch (e) {
      debugPrint('❌ Manual sync failed: $e');

      // Show error notification
      await _notifications!.showSyncNotification(
        title: 'Sync Failed',
        body: 'Error during synchronization: ${e.toString()}',
      );
    }
  }

  // Cleanup and dispose all services
  Future<void> dispose() async {
    try {
      debugPrint('🧹 Disposing ServiceManager...');

      // Dispose services in reverse order
      if (_cacheIntegration != null) {
        _cacheIntegration!.dispose();
      }
      await _mediaSession!.dispose();
      await _notifications!.dispose();
      await _offlineQueue!.dispose();
      await _dataSync!.dispose();
      await _backgroundSync!.dispose();
      await _localStorage!.dispose();
      // Note: UnifiedAuthService doesn't need disposal as it's just a wrapper

      _isInitialized = false;
      debugPrint('✅ ServiceManager disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing ServiceManager: $e');
    }
  }

  // Get service statistics
  Future<Map<String, dynamic>> getServiceStats() async {
    try {
      final syncStatus = await _dataSync!.getSyncStatus();
      final queueStats = await _offlineQueue!.getQueueStats();
      final dbStats = await _localStorage!.getDatabaseStats();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'uptime': DateTime.now().difference(DateTime.now()).inSeconds,
        'database': dbStats,
        'sync': syncStatus,
        'queue': queueStats,
        'notifications': {
          'enabled': await _notifications!.areNotificationsEnabled(),
          'channels': 3, // playback, sync, download
        },
        'cache': {
          'active': _cacheIntegration != null,
          'initialized': _cacheIntegration?.isInitialized ?? false,
        },
        'media': {
          'episode': _mediaSession!.currentEpisode?.title ?? 'None',
          'playing': _mediaSession!.isPlaying,
          'position': _mediaSession!.position.inSeconds,
          'duration': _mediaSession!.duration.inSeconds,
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
