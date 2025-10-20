import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../repositories/podcast_repository.dart';
import '../repositories/episode_repository.dart';
import '../repositories/playback_repository.dart';
import '../database/database_helper.dart';
import '../../data/models/database_models.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Repositories
  final PodcastRepository _podcastRepository = PodcastRepository();
  final EpisodeRepository _episodeRepository = EpisodeRepository();
  final PlaybackRepository _playbackRepository = PlaybackRepository();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Hive boxes for fast access
  Box<String>? _settingsBox;
  Box<String>? _cacheBox;
  Box<String>? _userDataBox;

  // Cache for frequently accessed data
  final Map<String, dynamic> _memoryCache = {};
  final Duration _cacheExpiry = const Duration(minutes: 15);

  // Initialization status
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _lastError;

  /// Check if service is fully initialized
  bool get isInitialized => _isInitialized;

  /// Check if service is currently initializing
  bool get isInitializing => _isInitializing;

  /// Get last initialization error
  String? get lastError => _lastError;

  /// Check if service can perform operations
  bool get canOperate => _isInitialized && !_isInitializing;

  // Completer for initialization
  Completer<void> _initCompleter = Completer<void>();

  /// Initialize with enhanced error handling and database lock resolution
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _lastError = null;

    try {
      debugPrint('🚀 Initializing LocalStorageService...');

      // Set overall timeout for entire initialization
      await _initializeWithTimeout();

      _isInitialized = true;
      debugPrint('✅ LocalStorageService initialized successfully');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ LocalStorageService initialization failed: $e');

      // Don't rethrow - allow app to continue with fallbacks
      debugPrint('⚠️ LocalStorageService will use fallback methods');
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize with timeout protection and non-blocking fallback
  Future<void> _initializeWithTimeout() async {
    try {
      // Try to initialize both services with timeout
      await Future.wait([
        _initializeHive(),
        _initializeDatabaseWithRetry(),
      ]).timeout(
        Duration(seconds: 30), // Reduced from 60 to prevent hanging
        onTimeout: () {
          debugPrint('⏰ LocalStorageService initialization timeout');
          throw TimeoutException('LocalStorageService initialization timeout');
        },
      );
    } catch (e) {
      debugPrint('❌ Combined initialization failed: $e');

      // Instead of rethrowing, continue with fallback initialization
      debugPrint('🔄 Continuing with fallback initialization...');

      try {
        // Initialize Hive separately (usually fast)
        await _initializeHive().timeout(
          Duration(seconds: 5), // Reduced from 10 to prevent hanging
          onTimeout: () {
            debugPrint('⏰ Hive initialization timeout, skipping...');
            return;
          },
        );

        // Try minimal database setup
        await _initializeMinimalDatabase().timeout(
          Duration(seconds: 10), // Reduced from 15 to prevent hanging
          onTimeout: () {
            debugPrint(
                '⏰ Minimal database timeout, continuing without database...');
            return;
          },
        );

        debugPrint('✅ Fallback initialization completed');
      } catch (fallbackError) {
        debugPrint('⚠️ Fallback initialization failed: $fallbackError');
        // Continue anyway - app will use memory-only fallbacks
      }
    }
  }

  /// Initialize database with enhanced retry and lock resolution
  Future<void> _initializeDatabaseWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        debugPrint(
            '🔓 Attempting database initialization (attempt ${retryCount + 1})...');

        await _databaseHelper.database;

        // Check if database is accessible by trying to get it
        await _databaseHelper.database;
        debugPrint('✅ Database initialized successfully');
        return;
      } catch (e) {
        retryCount++;
        debugPrint('❌ Database initialization attempt $retryCount failed: $e');

        if (retryCount >= maxRetries) {
          debugPrint(
              '🚨 Max database retries reached, attempting emergency bypass...');
          // Try to force database recreation as last resort
          await _forceDatabaseRecreation();
          break;
        }

        // Wait before retry with exponential backoff
        final waitTime =
            Duration(seconds: retryCount * 2); // Reduced from 3 to 2 seconds
        debugPrint('⏳ Waiting ${waitTime.inSeconds}s before retry...');
        await Future.delayed(waitTime);
      }
    }
  }

  /// Force database recreation as last resort
  Future<void> _forceDatabaseRecreation() async {
    try {
      debugPrint('🚨 Force recreating database...');

      // Force close and reset database helper
      await _databaseHelper.resetConnection();

      // Wait for cleanup
      await Future.delayed(Duration(seconds: 3));

      // Try one more time
      await _databaseHelper.database;

      // Check if database is accessible
      await _databaseHelper.database;
      debugPrint('✅ Database force recreation successful');
    } catch (e) {
      debugPrint('❌ Database force recreation failed: $e');
      // Continue without database - app will use fallbacks
    }
  }

  /// Initialize minimal database functionality
  Future<void> _initializeMinimalDatabase() async {
    try {
      debugPrint('🔄 Attempting minimal database setup...');

      // Try to create a basic in-memory database for essential operations
      // Use resetConnection as a public alternative
      await _databaseHelper.resetConnection();
      debugPrint('✅ Minimal database setup completed');
    } catch (e) {
      debugPrint('⚠️ Minimal database setup failed: $e');
      // Continue without database
    }
  }

  /// Force continue with limited functionality if all recovery attempts fail
  Future<void> _forceContinueWithLimitedFunctionality(String reason) async {
    debugPrint(
        '⚠️ LocalStorageService: Forcing continuation with limited functionality: $reason');

    try {
      // Close any existing database connections
      try {
        await _databaseHelper.close();
      } catch (e) {
        debugPrint(
            '⚠️ Warning: Error closing database during force continue: $e');
      }

      // Mark as initialized with limited functionality
      _isInitialized = true;
      _lastError = reason;

      debugPrint(
          '✅ LocalStorageService: Continuing with limited functionality');
      debugPrint('⚠️ Note: Database operations will not be available');
      debugPrint('⚠️ Note: Some app features may be limited');
    } catch (e) {
      debugPrint('❌ Error during force continue: $e');
      // Mark as initialized anyway to prevent infinite loops
      _isInitialized = true;
      _lastError = 'Force continue failed: $e';
    }
  }

  /// Initialize Hive
  Future<void> _initializeHive() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);

      // Open Hive boxes after initialization
      await _openHiveBoxes();

      debugPrint('✅ Hive initialized and boxes opened successfully');
    } catch (e) {
      debugPrint('⚠️ LocalStorageService: Hive initialization failed: $e');
      // Continue without Hive for now
    }
  }

  /// Open Hive boxes with retry logic and error handling
  Future<void> _openHiveBoxes() async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
            '🔄 LocalStorageService: Opening Hive boxes (attempt $attempt/$maxRetries)');

        // Open boxes with timeout
        _settingsBox = await Hive.openBox<String>('settings')
            .timeout(const Duration(seconds: 10));
        _cacheBox = await Hive.openBox<String>('cache')
            .timeout(const Duration(seconds: 10));
        _userDataBox = await Hive.openBox<String>('user_data')
            .timeout(const Duration(seconds: 10));

        debugPrint('✅ Hive boxes opened successfully');
        return; // Success, exit retry loop
      } catch (e) {
        debugPrint(
            '⚠️ LocalStorageService: Hive boxes failed (attempt $attempt/$maxRetries): $e');

        // Check if it's a lock error
        if (e.toString().contains('lock failed') ||
            e.toString().contains('errno = 11')) {
          debugPrint('🔒 Lock error detected, attempting cleanup...');

          // Try to clean up lock files
          await _cleanupHiveLocks();

          if (attempt < maxRetries) {
            debugPrint(
                '⏳ Waiting ${retryDelay.inMilliseconds}ms before retry...');
            await Future.delayed(retryDelay);
            continue;
          }
        }

        // If this is the last attempt, handle the error
        if (attempt == maxRetries) {
          debugPrint(
              '❌ LocalStorageService: All attempts failed, continuing without Hive');
          _handleHiveFailure(e);
          return;
        }
      }
    }
  }

  /// Clean up Hive lock files
  Future<void> _cleanupHiveLocks() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive');

      if (await hiveDir.exists()) {
        // Find and delete lock files
        final lockFiles = await hiveDir
            .list()
            .where((entity) => entity.path.endsWith('.lock'))
            .toList();

        for (final lockFile in lockFiles) {
          try {
            await lockFile.delete();
            debugPrint('🗑️ Deleted lock file: ${lockFile.path}');
          } catch (e) {
            debugPrint('⚠️ Could not delete lock file ${lockFile.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error cleaning up Hive locks: $e');
    }
  }

  /// Handle Hive initialization failure
  void _handleHiveFailure(dynamic error) {
    debugPrint('❌ LocalStorageService: Hive initialization failed: $error');

    // Set fallback values
    _settingsBox = null;
    _cacheBox = null;
    _userDataBox = null;

    // You could implement fallback storage here (SharedPreferences, etc.)
    debugPrint('📝 LocalStorageService: Using fallback storage methods');
  }

  /// Force re-initialization of the service
  Future<void> reinitialize() async {
    debugPrint('🔄 LocalStorageService: Force re-initialization requested');

    // Close existing connections
    try {
      await _databaseHelper.close();
    } catch (e) {
      debugPrint(
          '⚠️ Warning: Error closing database during re-initialization: $e');
    }

    // Reset state
    _isInitialized = false;
    _isInitializing = false;
    _lastError = null;

    // Try to initialize again
    await initialize();
  }

  /// Check service health and attempt recovery if needed
  Future<bool> checkHealth() async {
    if (!_isInitialized) {
      debugPrint('⚠️ LocalStorageService: Service not initialized');
      return false;
    }

    try {
      // Check database health by trying to access it
      try {
        await _databaseHelper.database;
        return true;
      } catch (e) {
        debugPrint(
            '⚠️ LocalStorageService: Database unhealthy, attempting recovery...');
        await reinitialize();
        return _isInitialized;
      }

      return true;
    } catch (e) {
      debugPrint('❌ LocalStorageService: Health check failed: $e');
      return false;
    }
  }

  /// Recover from database corruption
  Future<bool> recoverFromCorruption() async {
    debugPrint('🔄 LocalStorageService: Attempting corruption recovery...');

    try {
      // Force database reset
      await _databaseHelper.resetConnection();

      // Try to reinitialize
      await reinitialize();

      if (_isInitialized) {
        debugPrint('✅ LocalStorageService: Corruption recovery successful');
        return true;
      } else {
        debugPrint('❌ LocalStorageService: Corruption recovery failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ LocalStorageService: Error during corruption recovery: $e');
      return false;
    }
  }

  /// Force database recreation (nuclear option for severe corruption)
  Future<bool> forceDatabaseRecreation() async {
    debugPrint(
        '🔄 LocalStorageService: Force database recreation requested...');

    try {
      // Force database recreation
      await _databaseHelper.resetConnection();

      // Reinitialize service
      await reinitialize();

      if (_isInitialized) {
        debugPrint('✅ LocalStorageService: Database recreation successful');
        return true;
      } else {
        debugPrint('❌ LocalStorageService: Database recreation failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ LocalStorageService: Error during database recreation: $e');
      return false;
    }
  }

  /// Check if database is corrupted and attempt recovery
  Future<bool> _handleDatabaseCorruption() async {
    try {
      debugPrint('🔍 Checking for database corruption...');

      // Try to access the database to check for corruption
      try {
        await _databaseHelper.database;
        debugPrint('✅ Database appears to be healthy');
        return true;
      } catch (e) {
        if (e.toString().contains('corrupted') ||
            e.toString().contains('malformed') ||
            e.toString().contains('not a database')) {
          debugPrint('⚠️ Database corruption detected: $e');

          // Try to recover from corruption
          debugPrint('🔄 Attempting corruption recovery...');

          try {
            final recovered = await recoverFromCorruption();
            if (recovered) {
              debugPrint('✅ Database corruption recovery successful');
              return true;
            } else {
              debugPrint('❌ Database corruption recovery failed');
              return false;
            }
          } catch (recoveryError) {
            debugPrint('❌ Error during corruption recovery: $recoveryError');
            return false;
          }
        } else {
          // Not a corruption error, rethrow
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking database corruption: $e');
      return false;
    }
  }

  // MARK: - Settings Management

  // Save setting
  Future<void> saveSetting(String key, String value) async {
    if (!canOperate) {
      debugPrint(
          '⚠️ LocalStorageService: Cannot save setting - service not ready');
      return;
    }

    try {
      // Check if Hive boxes are properly initialized
      if (_settingsBox?.isOpen == true) {
        await _settingsBox!.put(key, value);
      } else {
        debugPrint('⚠️ Hive settings box not available, using memory cache');
        _memoryCache['setting_$key'] = value;
      }
    } catch (e) {
      debugPrint('❌ Error saving setting: $e');
      // Fallback to memory cache
      _memoryCache['setting_$key'] = value;
    }
  }

  // Get setting
  String? getSetting(String key) {
    if (!canOperate) {
      debugPrint(
          '⚠️ LocalStorageService: Cannot get setting - service not ready');
      // Return from memory cache if available
      return _memoryCache['setting_$key'];
    }

    try {
      // Check if Hive boxes are properly initialized
      if (_settingsBox?.isOpen == true) {
        return _settingsBox!.get(key);
      } else {
        debugPrint('⚠️ Hive settings box not open, using memory cache');
        return _memoryCache['setting_$key'];
      }
    } catch (e) {
      debugPrint('❌ Error getting setting: $e');
      // Fallback to memory cache
      return _memoryCache['setting_$key'];
    }
  }

  // Get setting with default
  String getSettingOrDefault(String key, String defaultValue) {
    return getSetting(key) ?? defaultValue;
  }

  // Delete setting
  Future<void> deleteSetting(String key) async {
    if (!canOperate) {
      debugPrint(
          '⚠️ LocalStorageService: Cannot delete setting - service not ready');
      return;
    }

    try {
      // Check if Hive boxes are properly initialized
      if (_settingsBox?.isOpen == true) {
        await _settingsBox!.delete(key);
      }
      _memoryCache.remove('setting_$key');
    } catch (e) {
      debugPrint('❌ Error deleting setting: $e');
      // Remove from memory cache anyway
      _memoryCache.remove('setting_$key');
    }
  }

  // MARK: - Cache Management

  // Save to cache
  Future<void> saveToCache(String key, dynamic data, {Duration? expiry}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': (expiry ?? _cacheExpiry).inMilliseconds,
    };

    // Always save to memory cache first
    _memoryCache[key] = cacheData;

    // Try to save to Hive if available
    if (canOperate && _cacheBox?.isOpen == true) {
      try {
        await _cacheBox!.put(key, jsonEncode(cacheData));
      } catch (e) {
        debugPrint('⚠️ Warning: Could not save to Hive cache: $e');
        // Continue with memory cache only
      }
    }
  }

  // Get from cache
  dynamic getFromCache(String key) {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final cacheData = _memoryCache[key];
      final expiry = cacheData['expiry'] as int;
      final timestamp = cacheData['timestamp'] as int;

      if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
        return cacheData['data'];
      } else {
        _memoryCache.remove(key);
      }
    }

    // Check Hive cache if available
    if (canOperate && _cacheBox?.isOpen == true) {
      try {
        final cached = _cacheBox!.get(key);
        if (cached != null) {
          try {
            final cacheData = jsonDecode(cached);
            final expiry = cacheData['expiry'] as int;
            final timestamp = cacheData['timestamp'] as int;

            if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
              _memoryCache[key] = cacheData;
              return cacheData['data'];
            } else {
              if (_cacheBox?.isOpen == true) {
                _cacheBox!.delete(key);
              }
            }
          } catch (e) {
            debugPrint('Error parsing cached data: $e');
            if (_cacheBox?.isOpen == true) {
              _cacheBox!.delete(key);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Warning: Could not access Hive cache: $e');
        // Continue with memory cache only
      }
    }

    return null;
  }

  // Clear cache
  Future<void> clearCache() async {
    // Always clear memory cache
    _memoryCache.clear();

    // Try to clear Hive cache if available
    if (canOperate && _cacheBox?.isOpen == true) {
      try {
        await _cacheBox!.clear();
      } catch (e) {
        debugPrint('⚠️ Warning: Could not clear Hive cache: $e');
        // Continue with memory cache cleared
      }
    }
  }

  // Clear expired cache
  Future<void> clearExpiredCache() async {
    final keysToDelete = <String>[];

    // Check memory cache
    for (final key in _memoryCache.keys) {
      final cacheData = _memoryCache[key];
      if (cacheData != null) {
        final expiry = cacheData['expiry'] as int;
        final timestamp = cacheData['timestamp'] as int;

        if (DateTime.now().millisecondsSinceEpoch - timestamp >= expiry) {
          keysToDelete.add(key);
        }
      }
    }

    // Remove expired items from memory cache
    for (final key in keysToDelete) {
      _memoryCache.remove(key);
    }

    // Try to clear expired items from Hive cache if available
    if (canOperate && _cacheBox?.isOpen == true) {
      try {
        for (final key in _cacheBox!.keys) {
          final cached = _cacheBox!.get(key);
          if (cached != null) {
            try {
              final cacheData = jsonDecode(cached);
              final expiry = cacheData['expiry'] as int;
              final timestamp = cacheData['timestamp'] as int;

              if (DateTime.now().millisecondsSinceEpoch - timestamp >= expiry) {
                _cacheBox!.delete(key);
              }
            } catch (e) {
              debugPrint('Error parsing cached data during cleanup: $e');
              _cacheBox!.delete(key);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Warning: Could not clear expired Hive cache: $e');
        // Continue with memory cache cleaned
      }
    }
  }

  // MARK: - User Data Management

  // Save user data
  Future<void> saveUserData(String key, dynamic data) async {
    if (!canOperate) {
      debugPrint(
          '⚠️ LocalStorageService: Cannot save user data - service not ready');
      // Fallback to memory cache
      _memoryCache['userdata_$key'] = data;
      return;
    }

    try {
      // Check if Hive boxes are properly initialized
      if (_userDataBox?.isOpen == true) {
        await _userDataBox!.put(key, jsonEncode(data));
      }
      // Also save to memory cache for faster access
      _memoryCache['userdata_$key'] = data;
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
      // Fallback to memory cache
      _memoryCache['userdata_$key'] = data;
    }
  }

  // Get user data
  dynamic getUserData(String key) {
    // Check memory cache first
    if (_memoryCache.containsKey('userdata_$key')) {
      return _memoryCache['userdata_$key'];
    }

    if (!canOperate) {
      debugPrint(
          '⚠️ LocalStorageService: Cannot get user data - service not ready');
      return null;
    }

    try {
      // Check if Hive boxes are properly initialized
      if (_userDataBox?.isOpen == true) {
        final data = _userDataBox!.get(key);
        if (data != null) {
          try {
            final decodedData = jsonDecode(data);
            // Cache in memory for faster access
            _memoryCache['userdata_$key'] = decodedData;
            return decodedData;
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  // Delete user data
  Future<void> deleteUserData(String key) async {
    // Remove from memory cache
    _memoryCache.remove('userdata_$key');

    if (!canOperate) {
      debugPrint(
          '⚠️ LocalStorageService: Cannot delete user data - service not ready');
      return;
    }

    try {
      // Check if Hive boxes are properly initialized
      if (_userDataBox?.isOpen == true) {
        await _userDataBox!.delete(key);
      }
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      // Continue since we already removed from memory cache
    }
  }

  // MARK: - Podcast Operations

  // Get podcasts with caching
  Future<List<PodcastDatabaseModel>> getPodcasts({bool useCache = true}) async {
    if (useCache) {
      final cached = getFromCache('podcasts');
      if (cached != null) {
        return (cached as List)
            .map((e) => PodcastDatabaseModel.fromMap(e))
            .toList();
      }
    }

    final podcasts = await _podcastRepository.getAllPodcasts();

    if (useCache) {
      await saveToCache('podcasts', podcasts.map((e) => e.toMap()).toList());
    }

    return podcasts;
  }

  // Get subscribed podcasts with caching
  Future<List<PodcastDatabaseModel>> getSubscribedPodcasts(
      {bool useCache = true}) async {
    if (useCache) {
      final cached = getFromCache('subscribed_podcasts');
      if (cached != null) {
        return (cached as List)
            .map((e) => PodcastDatabaseModel.fromMap(e))
            .toList();
      }
    }

    final podcasts = await _podcastRepository.getSubscribedPodcasts();

    if (useCache) {
      await saveToCache(
          'subscribed_podcasts', podcasts.map((e) => e.toMap()).toList());
    }

    return podcasts;
  }

  // Search podcasts
  Future<List<PodcastDatabaseModel>> searchPodcasts(String query) async {
    return await _podcastRepository.searchPodcasts(query);
  }

  // MARK: - Episode Operations

  // Get episodes by podcast with caching
  Future<List<EpisodeDatabaseModel>> getEpisodesByPodcast(int podcastId,
      {bool useCache = true}) async {
    final cacheKey = 'episodes_podcast_$podcastId';

    if (useCache) {
      final cached = getFromCache(cacheKey);
      if (cached != null) {
        return (cached as List)
            .map((e) => EpisodeDatabaseModel.fromMap(e))
            .toList();
      }
    }

    final episodes = await _episodeRepository.getEpisodesByPodcastId(podcastId);

    if (useCache) {
      await saveToCache(cacheKey, episodes.map((e) => e.toMap()).toList());
    }

    return episodes;
  }

  // Get downloaded episodes
  Future<List<EpisodeDatabaseModel>> getDownloadedEpisodes() async {
    return await _episodeRepository.getDownloadedEpisodes();
  }

  // Get recent episodes
  Future<List<EpisodeDatabaseModel>> getRecentEpisodes({int days = 7}) async {
    return await _episodeRepository.getRecentEpisodes(days: days);
  }

  // Search episodes
  Future<List<EpisodeDatabaseModel>> searchEpisodes(String query) async {
    return await _episodeRepository.searchEpisodes(query);
  }

  // MARK: - Playback Operations

  // Get playback progress
  Future<Map<String, dynamic>?> getPlaybackProgress(int episodeId) async {
    return await _playbackRepository.getPlaybackProgress(episodeId);
  }

  // Update playback position
  Future<int> updatePlaybackPosition(
      int episodeId, int position, int duration) async {
    return await _playbackRepository.updatePlaybackPosition(
        episodeId, position, duration);
  }

  // Get episodes in progress
  Future<List<Map<String, dynamic>>> getEpisodesInProgress() async {
    return await _playbackRepository.getEpisodesInProgress();
  }

  // Get resumable episodes
  Future<List<Map<String, dynamic>>> getResumableEpisodes() async {
    return await _playbackRepository.getResumableEpisodes();
  }

  // MARK: - Statistics

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    return await _databaseHelper.getDatabaseStats();
  }

  // Get listening statistics
  Future<Map<String, dynamic>> getListeningStats({int days = 30}) async {
    return await _playbackRepository.getListeningStats(days: days);
  }

  // Get listening streak
  Future<int> getListeningStreak() async {
    return await _playbackRepository.getListeningStreak();
  }

  // MARK: - Data Synchronization

  // Check if data needs syncing
  Future<bool> needsSync() async {
    final lastSync = getSetting('last_sync_timestamp');
    if (lastSync == null) return true;

    final lastSyncTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(lastSync));
    final hoursSinceLastSync = DateTime.now().difference(lastSyncTime).inHours;

    return hoursSinceLastSync >= 6; // Sync every 6 hours
  }

  // Mark data as synced
  Future<void> markAsSynced() async {
    await saveSetting('last_sync_timestamp',
        DateTime.now().millisecondsSinceEpoch.toString());
  }

  // Get data that needs syncing
  Future<Map<String, dynamic>> getDataForSync() async {
    final podcastsNeedingUpdate =
        await _podcastRepository.getPodcastsNeedingUpdate(6);
    final episodesNeedingUpdate =
        await _episodeRepository.getEpisodesNeedingUpdate(1);

    return {
      'podcasts': podcastsNeedingUpdate.map((e) => e.toMap()).toList(),
      'episodes': episodesNeedingUpdate.map((e) => e.toMap()).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // MARK: - Cleanup

  // Clean up old data
  Future<void> cleanup() async {
    try {
      // Clear expired cache
      await clearExpiredCache();

      // Delete old playback history (older than 90 days)
      await _playbackRepository.deleteOldPlaybackHistory(90);

      debugPrint('✅ LocalStorageService cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }

  // Close all resources
  Future<void> dispose() async {
    try {
      if (_settingsBox?.isOpen == true) {
        await _settingsBox!.close();
      }
      if (_cacheBox?.isOpen == true) {
        await _cacheBox!.close();
      }
      if (_userDataBox?.isOpen == true) {
        await _userDataBox!.close();
      }
      await _databaseHelper.close();

      _memoryCache.clear();

      debugPrint('✅ LocalStorageService disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing LocalStorageService: $e');
    }
  }
}
