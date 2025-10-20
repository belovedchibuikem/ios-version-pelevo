import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';
import '../core/interceptors/retry_interceptor.dart';
import '../models/episode_progress.dart';
import '../models/episode_bookmark.dart';

// Progress change event model
class ProgressChangeEvent {
  final String episodeId;
  final String podcastId;
  final int currentPosition;
  final int totalDuration;
  final double progressPercentage;
  final bool isCompleted;
  final DateTime timestamp;
  final ProgressChangeType changeType;
  final Map<String, dynamic>? playbackData;

  ProgressChangeEvent({
    required this.episodeId,
    required this.podcastId,
    required this.currentPosition,
    required this.totalDuration,
    required this.progressPercentage,
    required this.isCompleted,
    required this.timestamp,
    required this.changeType,
    this.playbackData,
  });

  Map<String, dynamic> toJson() => {
        'episodeId': episodeId,
        'podcastId': podcastId,
        'currentPosition': currentPosition,
        'totalDuration': totalDuration,
        'progressPercentage': progressPercentage,
        'isCompleted': isCompleted,
        'timestamp': timestamp.toIso8601String(),
        'changeType': changeType.name,
        'playbackData': playbackData,
      };
}

enum ProgressChangeType {
  started,
  paused,
  resumed,
  positionChanged,
  completed,
  reset,
}

class EpisodeProgressService extends ChangeNotifier {
  static final EpisodeProgressService _instance =
      EpisodeProgressService._internal();
  factory EpisodeProgressService() => _instance;
  EpisodeProgressService._internal();

  // Local storage
  static SharedPreferences? _prefs;

  // Dio instance
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();
  bool _isInitialized = false;

  // Real-time progress broadcasting
  final StreamController<ProgressChangeEvent> _progressController =
      StreamController<ProgressChangeEvent>.broadcast();
  Stream<ProgressChangeEvent> get progressStream => _progressController.stream;

  // Sync management
  bool _isOnline = true;
  bool _isSyncing = false;
  final List<Map<String, dynamic>> _syncQueue = [];
  final Map<String, DateTime> _lastSyncTimes = {};

  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _conflictThreshold = Duration(minutes: 2);
  static const int _maxRetryAttempts = 3;

  // Debug verbosity control
  bool _verboseDebug = false;
  bool get verboseDebug => _verboseDebug;

  /// Enable/disable verbose debug logging during playback
  void setVerboseDebug(bool enabled) {
    _verboseDebug = enabled;
    debugPrint(
        '🔊 EpisodeProgressService: Verbose debug ${enabled ? 'enabled' : 'disabled'}');
  }

  // API endpoints
  static const String _progressEndpoint = '/episodes/progress';
  static const String _bookmarksEndpoint = '/episodes/bookmarks';

  // Getters for sync status
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => _syncQueue.isNotEmpty;
  int get pendingSyncCount => _syncQueue.length;
  DateTime? get lastSyncTime => _lastSyncTimes.isNotEmpty
      ? _lastSyncTimes.values.reduce((a, b) => a.isAfter(b) ? a : b)
      : null;

  /// Broadcast progress change to all listeners
  void _broadcastProgressChange(ProgressChangeEvent event) {
    if (!_progressController.isClosed) {
      _progressController.add(event);

      // Reduce debug noise during playback - only log non-position events or when verbose
      if (_verboseDebug ||
          event.changeType != ProgressChangeType.positionChanged) {
        debugPrint(
            '📡 Broadcasting progress change: ${event.changeType.name} for episode ${event.episodeId}');
      }
    }
  }

  /// Broadcast episode started playing
  void broadcastEpisodeStarted({
    required String episodeId,
    required String podcastId,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) {
    final event = ProgressChangeEvent(
      episodeId: episodeId,
      podcastId: podcastId,
      currentPosition: 0,
      totalDuration: totalDuration,
      progressPercentage: 0.0,
      isCompleted: false,
      timestamp: DateTime.now(),
      changeType: ProgressChangeType.started,
      playbackData: playbackData,
    );
    _broadcastProgressChange(event);
  }

  /// Broadcast episode paused
  void broadcastEpisodePaused({
    required String episodeId,
    required String podcastId,
    required int currentPosition,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) {
    final event = ProgressChangeEvent(
      episodeId: episodeId,
      podcastId: podcastId,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      progressPercentage: (currentPosition / totalDuration) * 100,
      isCompleted: false,
      timestamp: DateTime.now(),
      changeType: ProgressChangeType.paused,
      playbackData: playbackData,
    );
    _broadcastProgressChange(event);
  }

  /// Broadcast episode resumed
  void broadcastEpisodeResumed({
    required String episodeId,
    required String podcastId,
    required int currentPosition,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) {
    final event = ProgressChangeEvent(
      episodeId: episodeId,
      podcastId: podcastId,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      progressPercentage: (currentPosition / totalDuration) * 100,
      isCompleted: false,
      timestamp: DateTime.now(),
      changeType: ProgressChangeType.resumed,
      playbackData: playbackData,
    );
    _broadcastProgressChange(event);
  }

  /// Broadcast position changed
  void broadcastPositionChanged({
    required String episodeId,
    required String podcastId,
    required int currentPosition,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) {
    final event = ProgressChangeEvent(
      episodeId: episodeId,
      podcastId: podcastId,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      progressPercentage: (currentPosition / totalDuration) * 100,
      isCompleted: (currentPosition / totalDuration) >= 0.9,
      timestamp: DateTime.now(),
      changeType: ProgressChangeType.positionChanged,
      playbackData: playbackData,
    );
    _broadcastProgressChange(event);
  }

  /// Broadcast episode completed
  void broadcastEpisodeCompleted({
    required String episodeId,
    required String podcastId,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) {
    final event = ProgressChangeEvent(
      episodeId: episodeId,
      podcastId: podcastId,
      currentPosition: totalDuration,
      totalDuration: totalDuration,
      progressPercentage: 100.0,
      isCompleted: true,
      timestamp: DateTime.now(),
      changeType: ProgressChangeType.completed,
      playbackData: playbackData,
    );
    _broadcastProgressChange(event);
  }

  /// Broadcast episode reset
  void broadcastEpisodeReset({
    required String episodeId,
    required String podcastId,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) {
    final event = ProgressChangeEvent(
      episodeId: episodeId,
      podcastId: podcastId,
      currentPosition: 0,
      totalDuration: totalDuration,
      progressPercentage: 0.0,
      isCompleted: false,
      timestamp: DateTime.now(),
      changeType: ProgressChangeType.reset,
      playbackData: playbackData,
    );
    _broadcastProgressChange(event);
  }

  /// Dispose the service and close streams
  @override
  void dispose() {
    _progressController.close();
    super.dispose();
  }

  /// Check network connectivity and update online status
  Future<void> _checkNetworkStatus() async {
    try {
      // Simple network check - try to reach our API
      final response = await _dio.get('${ApiConfig.baseUrl}/api/health',
          options: Options(sendTimeout: const Duration(seconds: 5)));
      _isOnline = response.statusCode == 200;
    } catch (e) {
      _isOnline = false;
    }

    // Notify listeners of status change
    notifyListeners();

    // If we're back online and have pending sync, trigger it
    if (_isOnline && _syncQueue.isNotEmpty) {
      _processSyncQueue();
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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
        maxRetries: 3,
        baseDelay: const Duration(seconds: 1),
        retryOnTimeout: true,
        retryOnConnectionError: true,
        retryOnServerError: true,
      ));

      // Add auth interceptor
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint(
              'EpisodeProgressService: Making request to: ${options.uri}');
          debugPrint(
              'EpisodeProgressService: Base URL: ${_dio.options.baseUrl}');
          debugPrint(
              'EpisodeProgressService: Full URL: ${options.uri.toString()}');

          final token = await _authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('EpisodeProgressService: Auth token set in interceptor');
          } else {
            debugPrint('EpisodeProgressService: No auth token in interceptor');
          }

          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('EpisodeProgressService: Request error: ${error.message}');
          debugPrint(
              'EpisodeProgressService: Request URL: ${error.requestOptions.uri}');
          debugPrint(
              'EpisodeProgressService: Response status: ${error.response?.statusCode}');
          handler.next(error);
        },
      ));

      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
        ));
      }

      _isInitialized = true;
      debugPrint('EpisodeProgressService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing EpisodeProgressService: $e');
      rethrow;
    }
  }

  /// Helper to ensure the latest token is set before every request
  Future<void> _ensureAuthToken() async {
    try {
      final token = await _authService.getToken();
      debugPrint(
          'EpisodeProgressService: Auth token check - Token present: ${token != null && token.isNotEmpty}');

      if (token != null && token.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        debugPrint(
            'EpisodeProgressService: Authorization header set successfully');
      } else {
        _dio.options.headers.remove('Authorization');
        debugPrint(
            'EpisodeProgressService: No auth token available, removed Authorization header');
      }
    } catch (e) {
      debugPrint('EpisodeProgressService: Error ensuring auth token: $e');
      // Remove auth header on error
      _dio.options.headers.remove('Authorization');
    }
  }

  // MARK: - Local Storage Methods

  /// Initialize SharedPreferences
  Future<void> _initializePrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Save progress locally (for offline support)
  Future<void> _saveProgressLocally(EpisodeProgress progress) async {
    if (_prefs == null) await _initializePrefs();

    final progressData = progress.toJson();
    await _prefs!.setString(
        'episode_progress_${progress.episodeId}', jsonEncode(progressData));

    // Also save to a list for batch sync
    final allProgress = _prefs!.getStringList('episode_progress_list') ?? [];
    if (!allProgress.contains(progress.episodeId)) {
      allProgress.add(progress.episodeId);
      await _prefs!.setStringList('episode_progress_list', allProgress);
    }
  }

  /// Get all local progress IDs for batch sync
  Future<List<String>> _getLocalProgressIds() async {
    if (_prefs == null) await _initializePrefs();
    return _prefs!.getStringList('episode_progress_list') ?? [];
  }

  /// Get a single local progress by episode ID
  Future<EpisodeProgress?> _getLocalProgress(String episodeId) async {
    if (_prefs == null) await _initializePrefs();

    try {
      final progressData = _prefs!.getString('episode_progress_$episodeId');
      if (progressData != null) {
        final progress = EpisodeProgress.fromJson(jsonDecode(progressData));
        debugPrint(
            'EpisodeProgressService: Progress retrieved from local storage for episode $episodeId');
        return progress;
      } else {
        debugPrint(
            'EpisodeProgressService: No local progress data found for episode $episodeId');
      }
    } catch (parseError) {
      debugPrint(
          'EpisodeProgressService: Error parsing local progress data for episode $episodeId: $parseError');
      // Remove corrupted local data
      try {
        await _prefs!.remove('episode_progress_$episodeId');
        debugPrint(
            'EpisodeProgressService: Removed corrupted local progress data for episode $episodeId');
      } catch (removeError) {
        debugPrint(
            'EpisodeProgressService: Failed to remove corrupted local progress data: $removeError');
      }
    }

    debugPrint(
        'EpisodeProgressService: No progress found for episode $episodeId');
    return null;
  }

  // MARK: - Episode Progress Methods

  /// Verify service is properly initialized
  Future<bool> _verifyInitialization() async {
    if (!_isInitialized) {
      debugPrint(
          'EpisodeProgressService: Service not initialized, initializing now...');
      try {
        await initialize();
        return true;
      } catch (e) {
        debugPrint('EpisodeProgressService: Failed to initialize service: $e');
        return false;
      }
    }
    return true;
  }

  /// Get progress for a specific episode (local + cloud)
  Future<EpisodeProgress?> getProgress(String episodeId) async {
    if (_prefs == null) await _initializePrefs();

    try {
      // First try to get from cloud
      await _ensureAuthToken();

      // Ensure service is initialized
      if (!await _verifyInitialization()) {
        debugPrint(
            'EpisodeProgressService: Service initialization failed, falling back to local storage');
        return _getLocalProgress(episodeId);
      }

      debugPrint(
          'EpisodeProgressService: Fetching progress for episode $episodeId from cloud');
      debugPrint(
          'EpisodeProgressService: Using endpoint: $_progressEndpoint/$episodeId');
      debugPrint(
          'EpisodeProgressService: Dio base URL: ${_dio.options.baseUrl}');

      final response = await _dio.get('$_progressEndpoint/$episodeId');

      if (response.statusCode == 200 && response.data['success']) {
        final progress = EpisodeProgress.fromJson(response.data['data']);
        // Update local storage
        await _saveProgressLocally(progress);
        debugPrint(
            'EpisodeProgressService: Progress retrieved from cloud for episode $episodeId');
        return progress;
      } else {
        debugPrint(
            'EpisodeProgressService: Cloud response not successful for episode $episodeId: ${response.statusCode}');
        debugPrint('EpisodeProgressService: Response data: ${response.data}');
      }
    } catch (e) {
      debugPrint(
          'EpisodeProgressService: Failed to get progress from cloud for episode $episodeId: $e');

      // Log specific error details for debugging
      if (e is DioException) {
        debugPrint('EpisodeProgressService: Dio error details: ${e.message}');
        debugPrint('EpisodeProgressService: Dio error type: ${e.type}');
        debugPrint(
            'EpisodeProgressService: Dio error response: ${e.response?.statusCode}');
        debugPrint(
            'EpisodeProgressService: Dio error request URL: ${e.requestOptions.uri}');
      }
    }

    // Fallback to local storage
    debugPrint(
        'EpisodeProgressService: Falling back to local storage for episode $episodeId');
    return _getLocalProgress(episodeId);
  }

  /// Save/update episode progress (local + cloud)
  Future<bool> saveProgress({
    required String episodeId,
    required String podcastId,
    required int currentPosition,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final progressData = {
        'episode_id': episodeId,
        'podcast_id': podcastId,
        'current_position': currentPosition,
        'total_duration': totalDuration,
        'progress_percentage': (currentPosition / totalDuration) * 100,
        'playback_data': playbackData,
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': await _getDeviceId(),
      };

      // Always save locally first for immediate access
      final localProgress = EpisodeProgress(
        episodeId: episodeId,
        podcastId: podcastId,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        progressPercentage: (currentPosition / totalDuration) * 100,
        isCompleted: (currentPosition / totalDuration) >= 0.9,
        lastPlayedAt: DateTime.now(),
        playbackData: playbackData,
      );
      await _saveProgressLocally(localProgress);

      // Broadcast progress change for real-time updates
      final isCompleted = (currentPosition / totalDuration) >= 0.9;
      if (isCompleted) {
        broadcastEpisodeCompleted(
          episodeId: episodeId,
          podcastId: podcastId,
          totalDuration: totalDuration,
          playbackData: playbackData,
        );
      } else {
        broadcastPositionChanged(
          episodeId: episodeId,
          podcastId: podcastId,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          playbackData: playbackData,
        );
      }

      // Check if we should sync immediately or queue for later
      if (_isOnline && _shouldSyncImmediately(episodeId)) {
        return await _syncProgressToCloud(progressData);
      } else {
        // Queue for later sync
        _addToSyncQueue(progressData);
        return true; // Successfully saved locally
      }
    } catch (e) {
      debugPrint('Error in saveProgress: $e');
      return false;
    }
  }

  /// Determine if progress should sync immediately
  bool _shouldSyncImmediately(String episodeId) {
    final lastSync = _lastSyncTimes[episodeId];
    if (lastSync == null) return true;

    // Sync immediately if it's been more than sync interval
    return DateTime.now().difference(lastSync) > _syncInterval;
  }

  /// Add progress data to sync queue
  void _addToSyncQueue(Map<String, dynamic> progressData) {
    // Remove any existing entry for this episode to avoid duplicates
    _syncQueue.removeWhere(
        (item) => item['episode_id'] == progressData['episode_id']);

    // Add to queue with timestamp
    _syncQueue.add({
      ...progressData,
      'queued_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });

    debugPrint(
        'Progress queued for sync: ${progressData['episode_id']} (${_syncQueue.length} pending)');

    // Try to process queue if we're online
    if (_isOnline) {
      _processSyncQueue();
    }
  }

  /// Sync progress data to cloud
  Future<bool> _syncProgressToCloud(Map<String, dynamic> progressData) async {
    try {
      final response = await _dio.post(_progressEndpoint, data: progressData);

      if (response.statusCode == 200 && response.data['success']) {
        // Update last sync time
        _lastSyncTimes[progressData['episode_id']] = DateTime.now();
        debugPrint('Progress synced to cloud: ${progressData['episode_id']}');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to sync progress to cloud: $e');

      // Check if it's a conflict error
      if (e.toString().contains('409') || e.toString().contains('conflict')) {
        return await _handleSyncConflict(progressData);
      }
    }

    return false;
  }

  /// Handle sync conflicts by merging progress intelligently
  Future<bool> _handleSyncConflict(Map<String, dynamic> progressData) async {
    try {
      debugPrint(
          'Handling sync conflict for episode: ${progressData['episode_id']}');

      // Get current progress from cloud
      final cloudProgress = await getProgress(progressData['episode_id']);
      if (cloudProgress == null) return false;

      // Compare timestamps to determine which is more recent
      final localTimestamp = DateTime.parse(progressData['timestamp']);
      final cloudTimestamp = cloudProgress.lastPlayedAt;

      if (cloudTimestamp == null) {
        // No cloud timestamp, use local
        final response = await _dio.put(
          '$_progressEndpoint/${progressData['episode_id']}',
          data: progressData,
        );

        if (response.statusCode == 200) {
          _lastSyncTimes[progressData['episode_id']] = DateTime.now();
          debugPrint('Conflict resolved: no cloud timestamp, using local');
          return true;
        }
        return false;
      }

      if (localTimestamp.isAfter(cloudTimestamp)) {
        // Local is more recent, force update
        final response = await _dio.put(
          '$_progressEndpoint/${progressData['episode_id']}',
          data: progressData,
        );

        if (response.statusCode == 200) {
          _lastSyncTimes[progressData['episode_id']] = DateTime.now();
          debugPrint('Conflict resolved: local progress updated cloud');
          return true;
        }
      } else {
        // Cloud is more recent, update local
        await _saveProgressLocally(cloudProgress);
        _lastSyncTimes[progressData['episode_id']] = DateTime.now();
        debugPrint('Conflict resolved: cloud progress updated local');
        return true;
      }
    } catch (e) {
      debugPrint('Error handling sync conflict: $e');
    }

    return false;
  }

  /// Process the sync queue
  Future<void> _processSyncQueue() async {
    if (_isSyncing || _syncQueue.isEmpty || !_isOnline) return;

    _isSyncing = true;
    debugPrint('Processing sync queue: ${_syncQueue.length} items');

    try {
      final itemsToProcess = List<Map<String, dynamic>>.from(_syncQueue);

      for (final item in itemsToProcess) {
        try {
          final success = await _syncProgressToCloud(item);

          if (success) {
            // Remove from queue on success
            _syncQueue.removeWhere(
                (queuedItem) => queuedItem['episode_id'] == item['episode_id']);
          } else {
            // Increment retry count
            final index = _syncQueue.indexWhere(
                (queuedItem) => queuedItem['episode_id'] == item['episode_id']);
            if (index != -1) {
              _syncQueue[index]['retry_count'] =
                  (_syncQueue[index]['retry_count'] ?? 0) + 1;

              // Remove if max retries exceeded
              if (_syncQueue[index]['retry_count'] >= _maxRetryAttempts) {
                debugPrint(
                    'Max retries exceeded for episode: ${item['episode_id']}');
                _syncQueue.removeAt(index);
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing sync item: $e');
        }
      }
    } finally {
      _isSyncing = false;
      debugPrint(
          'Sync queue processing completed. Remaining: ${_syncQueue.length}');
    }
  }

  /// Get unique device identifier
  Future<String> _getDeviceId() async {
    if (_prefs == null) await _initializePrefs();

    String? deviceId = _prefs!.getString('device_id');
    if (deviceId == null) {
      // Generate a unique device ID
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
      await _prefs!.setString('device_id', deviceId);
    }

    return deviceId;
  }

  // MARK: - Public Sync Methods

  /// Manual sync - force sync all pending progress
  Future<bool> syncAllProgress() async {
    try {
      await initialize();
      await _checkNetworkStatus();

      if (!_isOnline) {
        debugPrint('Cannot sync: device is offline');
        return false;
      }

      // Process sync queue
      await _processSyncQueue();

      // Also sync any local progress that might not be in queue
      await _syncLocalProgressToCloud();

      return _syncQueue.isEmpty;
    } catch (e) {
      debugPrint('Error in syncAllProgress: $e');
      return false;
    }
  }

  /// Sync local progress to cloud
  Future<void> _syncLocalProgressToCloud() async {
    try {
      final localIds = await _getLocalProgressIds();

      for (final episodeId in localIds) {
        final localProgress = await _getLocalProgress(episodeId);
        if (localProgress != null) {
          // Check if this progress is already synced
          final lastSync = _lastSyncTimes[episodeId];
          if (lastSync == null ||
              DateTime.now().difference(lastSync) > _syncInterval) {
            final progressData = {
              'episode_id': episodeId,
              'podcast_id': localProgress.podcastId,
              'current_position': localProgress.currentPosition,
              'total_duration': localProgress.totalDuration,
              'playback_data': localProgress.playbackData,
              'timestamp': localProgress.lastPlayedAt?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
              'device_id': await _getDeviceId(),
            };

            await _syncProgressToCloud(progressData);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing local progress: $e');
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingSyncCount': _syncQueue.length,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'syncQueue': _syncQueue
          .map((item) => {
                'episode_id': item['episode_id'],
                'queued_at': item['queued_at'],
                'retry_count': item['retry_count'],
              })
          .toList(),
    };
  }

  /// Force network status check and sync if needed
  Future<void> checkNetworkAndSync() async {
    await _checkNetworkStatus();
  }

  /// Clear sync queue (useful for debugging or reset)
  void clearSyncQueue() {
    _syncQueue.clear();
    debugPrint('Sync queue cleared');
  }

  /// Update existing progress
  Future<bool> updateProgress({
    required String episodeId,
    required int currentPosition,
    int? totalDuration,
    Map<String, dynamic>? playbackData,
  }) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final updateData = {
        'current_position': currentPosition,
        'total_duration': totalDuration,
        'progress_percentage': totalDuration != null
            ? (currentPosition / totalDuration) * 100
            : null,
        'playback_data': playbackData,
      };

      // Update in cloud
      final response =
          await _dio.put('$_progressEndpoint/$episodeId', data: updateData);

      if (response.statusCode == 200 && response.data['success']) {
        final progress = EpisodeProgress.fromJson(response.data['data']);

        // Update local storage
        await _saveProgressLocally(progress);

        // Broadcast progress change for real-time updates
        if (totalDuration != null) {
          final isCompleted = (currentPosition / totalDuration) >= 0.9;
          if (isCompleted) {
            broadcastEpisodeCompleted(
              episodeId: episodeId,
              podcastId: progress.podcastId,
              totalDuration: totalDuration,
              playbackData: playbackData,
            );
          } else {
            broadcastPositionChanged(
              episodeId: episodeId,
              podcastId: progress.podcastId,
              currentPosition: currentPosition,
              totalDuration: totalDuration,
              playbackData: playbackData,
            );
          }
        }

        debugPrint(
            'Progress updated successfully: ${progress.episodeId} at ${progress.formattedCurrentPosition}');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to update progress in cloud: $e');

      // Update locally as fallback
      try {
        final existingProgress = await getProgress(episodeId);
        if (existingProgress != null) {
          final updatedProgress = existingProgress.copyWith(
            currentPosition: currentPosition,
            totalDuration: totalDuration ?? existingProgress.totalDuration,
            progressPercentage: (currentPosition /
                    (totalDuration ?? existingProgress.totalDuration)) *
                100,
            isCompleted: (currentPosition /
                    (totalDuration ?? existingProgress.totalDuration)) >=
                0.9,
            lastPlayedAt: DateTime.now(),
            playbackData: playbackData ?? existingProgress.playbackData,
          );

          await _saveProgressLocally(updatedProgress);

          // Broadcast progress change for real-time updates
          final isCompleted = (currentPosition /
                  (totalDuration ?? existingProgress.totalDuration)) >=
              0.9;
          if (isCompleted) {
            broadcastEpisodeCompleted(
              episodeId: episodeId,
              podcastId: existingProgress.podcastId,
              totalDuration: totalDuration ?? existingProgress.totalDuration,
              playbackData: playbackData,
            );
          } else {
            broadcastPositionChanged(
              episodeId: episodeId,
              podcastId: existingProgress.podcastId,
              currentPosition: currentPosition,
              totalDuration: totalDuration ?? existingProgress.totalDuration,
              playbackData: playbackData,
            );
          }

          debugPrint(
              'Progress updated locally as fallback: ${updatedProgress.episodeId}');
          return true;
        }
      } catch (localError) {
        debugPrint('Failed to update progress locally: $localError');
      }
    }

    return false;
  }

  /// Mark episode as completed
  Future<bool> markCompleted(String episodeId) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final updateData = {
        'current_position': 0, // Reset position
        'progress_percentage': 100.0, // 100% when completed
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      };

      // Update in cloud
      final response =
          await _dio.put('$_progressEndpoint/$episodeId', data: updateData);

      if (response.statusCode == 200 && response.data['success']) {
        final progress = EpisodeProgress.fromJson(response.data['data']);

        // Update local storage
        await _saveProgressLocally(progress);

        // Broadcast completion for real-time updates
        broadcastEpisodeCompleted(
          episodeId: episodeId,
          podcastId: progress.podcastId,
          totalDuration: progress.totalDuration,
          playbackData: progress.playbackData,
        );

        debugPrint('Episode marked as completed: ${progress.episodeId}');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to mark episode as completed in cloud: $e');

      // Update locally as fallback
      try {
        final existingProgress = await getProgress(episodeId);
        if (existingProgress != null) {
          final updatedProgress = existingProgress.copyWith(
            currentPosition: 0,
            progressPercentage: 100.0,
            isCompleted: true,
            completedAt: DateTime.now(),
          );

          await _saveProgressLocally(updatedProgress);

          // Broadcast completion for real-time updates
          broadcastEpisodeCompleted(
            episodeId: episodeId,
            podcastId: existingProgress.podcastId,
            totalDuration: existingProgress.totalDuration,
            playbackData: existingProgress.playbackData,
          );

          debugPrint(
              'Episode marked as completed locally: ${updatedProgress.episodeId}');
          return true;
        }
      } catch (localError) {
        debugPrint('Failed to mark episode as completed locally: $localError');
      }
    }

    return false;
  }

  /// Get all progress for a user
  Future<List<EpisodeProgress>> getAllProgress({
    String? podcastId,
    bool? completed,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (podcastId != null) queryParams['podcast_id'] = podcastId;
      if (completed != null) queryParams['completed'] = completed;

      final response =
          await _dio.get(_progressEndpoint, queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> progressList = response.data['data']['data'];
        final progress =
            progressList.map((json) => EpisodeProgress.fromJson(json)).toList();

        // Update local storage with all progress
        for (final prog in progress) {
          await _saveProgressLocally(prog);
        }

        return progress;
      }
    } catch (e) {
      debugPrint('Failed to get progress from cloud: $e');
    }

    // Fallback to local storage
    try {
      if (_prefs == null) await _initializePrefs();

      final progressIds = await _getLocalProgressIds();
      final progress = <EpisodeProgress>[];

      for (final id in progressIds) {
        final progressData = _prefs!.getString('episode_progress_$id');
        if (progressData != null) {
          final prog = EpisodeProgress.fromJson(jsonDecode(progressData));

          // Apply filters
          if (podcastId != null && prog.podcastId != podcastId) continue;
          if (completed != null && prog.isCompleted != completed) continue;

          progress.add(prog);
        }
      }

      // Sort by last played
      progress.sort((a, b) => (b.lastPlayedAt ?? DateTime(1900))
          .compareTo(a.lastPlayedAt ?? DateTime(1900)));

      return progress;
    } catch (e) {
      debugPrint('Failed to get progress from local storage: $e');
      return [];
    }
  }

  /// Sync local progress with cloud
  Future<bool> syncProgress() async {
    try {
      await initialize();
      await _ensureAuthToken();

      final localProgressIds = await _getLocalProgressIds();
      final progressData = <Map<String, dynamic>>[];

      for (final id in localProgressIds) {
        final progressDataString = _prefs!.getString('episode_progress_$id');
        if (progressDataString != null) {
          final progress =
              EpisodeProgress.fromJson(jsonDecode(progressDataString));
          progressData.add(progress.toJson());
        }
      }

      if (progressData.isEmpty) {
        debugPrint('No local progress to sync');
        return true;
      }

      final response = await _dio.post('$_progressEndpoint/sync', data: {
        'progress_data': progressData,
      });

      if (response.statusCode == 200 && response.data['success']) {
        debugPrint(
            'Progress synced successfully: ${response.data['data']['total_synced']} items');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to sync progress: $e');
    }

    return false;
  }

  /// Get progress statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      await initialize();
      await _ensureAuthToken();

      final response = await _dio.get('$_progressEndpoint/statistics');

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('Failed to get progress statistics: $e');
    }

    return null;
  }

  /// Delete progress for an episode
  Future<bool> deleteProgress(String episodeId) async {
    try {
      await initialize();
      await _ensureAuthToken();

      // Delete from cloud
      final response = await _dio.delete('$_progressEndpoint/$episodeId');

      if (response.statusCode == 200 && response.data['success']) {
        // Remove from local storage
        if (_prefs != null) {
          await _prefs!.remove('episode_progress_$episodeId');

          // Remove from progress list
          final progressIds = await _getLocalProgressIds();
          progressIds.remove(episodeId);
          await _prefs!.setStringList('episode_progress_list', progressIds);
        }

        debugPrint('Progress deleted successfully: $episodeId');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to delete progress from cloud: $e');

      // Remove from local storage as fallback
      try {
        if (_prefs != null) {
          await _prefs!.remove('episode_progress_$episodeId');

          final progressIds = await _getLocalProgressIds();
          progressIds.remove(episodeId);
          await _prefs!.setStringList('episode_progress_list', progressIds);
        }

        debugPrint('Progress deleted locally: $episodeId');
        return true;
      } catch (localError) {
        debugPrint('Failed to delete progress locally: $localError');
      }
    }

    return false;
  }

  /// Clear all progress (for testing or user request)
  Future<bool> clearAllProgress() async {
    try {
      await initialize();
      await _ensureAuthToken();

      // Clear from cloud (if endpoint exists)
      try {
        await _dio.delete('$_progressEndpoint/clear-all');
      } catch (e) {
        debugPrint('Cloud clear endpoint not available, clearing locally only');
      }

      // Clear local storage
      if (_prefs != null) {
        final progressIds = await _getLocalProgressIds();
        for (final id in progressIds) {
          await _prefs!.remove('episode_progress_$id');
        }
        await _prefs!.remove('episode_progress_list');
      }

      debugPrint('All progress cleared successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to clear progress: $e');
      return false;
    }
  }

  // MARK: - Bookmark Methods

  /// Get bookmarks for a specific episode
  Future<List<EpisodeBookmark>> getBookmarks(String episodeId) async {
    try {
      await initialize();
      await _ensureAuthToken();

      // Try to get from cloud first
      try {
        final response =
            await _dio.get('$_bookmarksEndpoint', queryParameters: {
          'episode_id': episodeId,
        });

        if (response.statusCode == 200 && response.data['success']) {
          final List<dynamic> bookmarksList =
              response.data['data']['data'] ?? [];
          final bookmarks = bookmarksList
              .map((json) => EpisodeBookmark.fromJson(json))
              .toList();

          // Save locally for offline support
          await _saveBookmarksLocally(episodeId, bookmarks);

          return bookmarks;
        }
      } catch (e) {
        debugPrint('Failed to get bookmarks from cloud: $e');
      }

      // Fallback to local storage
      return await _getBookmarksLocally(episodeId);
    } catch (e) {
      debugPrint('Error getting bookmarks: $e');
      return [];
    }
  }

  /// Add a bookmark
  Future<bool> addBookmark({
    required String episodeId,
    required String podcastId,
    required int position,
    required String title,
    String? notes,
    String color = '#2196F3',
    bool isPublic = false,
    String? category,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final bookmarkData = {
        'episode_id': episodeId,
        'podcast_id': podcastId,
        'position': position,
        'title': title,
        'notes': notes,
        'color': color,
        'is_public': isPublic,
        'category': category,
        'tags': tags,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
        'device_id': await _getDeviceId(),
      };

      // Save to cloud
      final response = await _dio.post(_bookmarksEndpoint, data: bookmarkData);

      if (response.statusCode == 200 && response.data['success']) {
        final bookmark = EpisodeBookmark.fromJson(response.data['data']);

        // Save locally for offline support
        await _addBookmarkLocally(episodeId, bookmark);

        debugPrint('Bookmark added successfully: ${bookmark.title}');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to add bookmark to cloud: $e');

      // Save locally as fallback
      try {
        final bookmark = EpisodeBookmark(
          episodeId: episodeId,
          podcastId: podcastId,
          position: position,
          title: title,
          notes: notes,
          color: color,
          isPublic: isPublic,
          createdAt: DateTime.now(),
        );

        await _addBookmarkLocally(episodeId, bookmark);
        debugPrint('Bookmark added locally as fallback: ${bookmark.title}');
        return true;
      } catch (localError) {
        debugPrint('Failed to add bookmark locally: $localError');
      }
    }

    return false;
  }

  /// Update an existing bookmark
  Future<bool> updateBookmark({
    required String episodeId,
    required int position,
    String? title,
    String? notes,
    String? color,
    bool? isPublic,
    String? category,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    final updateData = <String, dynamic>{
      'position': position,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updateData['title'] = title;
    if (notes != null) updateData['notes'] = notes;
    if (color != null) updateData['color'] = color;
    if (isPublic != null) updateData['is_public'] = isPublic;
    if (category != null) updateData['category'] = category;
    if (tags != null) updateData['tags'] = tags;
    if (metadata != null) updateData['metadata'] = metadata;

    try {
      await initialize();
      await _ensureAuthToken();

      // Update in cloud
      final response = await _dio.put(
        '$_bookmarksEndpoint/$episodeId',
        queryParameters: {'position': position},
        data: updateData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        // Update local bookmark
        await _updateBookmarkLocally(episodeId, position, updateData);
        debugPrint('Bookmark updated successfully: $episodeId at $position');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to update bookmark in cloud: $e');

      // Update locally as fallback
      try {
        await _updateBookmarkLocally(episodeId, position, updateData);
        debugPrint('Bookmark updated locally as fallback: $episodeId');
        return true;
      } catch (localError) {
        debugPrint('Failed to update bookmark locally: $localError');
      }
    }

    return false;
  }

  /// Remove a bookmark
  Future<bool> removeBookmark(String episodeId, int position) async {
    try {
      await initialize();
      await _ensureAuthToken();

      // Remove from cloud
      try {
        final response = await _dio
            .delete('$_bookmarksEndpoint/$episodeId', queryParameters: {
          'position': position,
        });

        if (response.statusCode == 200 && response.data['success']) {
          // Remove from local storage
          await _removeBookmarkLocally(episodeId, position);

          debugPrint('Bookmark removed from cloud successfully');
          return true;
        }
      } catch (e) {
        debugPrint('Failed to remove bookmark from cloud: $e');
      }

      // Remove from local storage as fallback
      await _removeBookmarkLocally(episodeId, position);
      debugPrint('Bookmark removed locally: $episodeId at position $position');
      return true;
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
      return false;
    }
  }

  /// Sync bookmarks with cloud
  Future<bool> syncBookmarks() async {
    try {
      await initialize();
      await _ensureAuthToken();

      // Get all local bookmarks
      final localBookmarks = <Map<String, dynamic>>[];

      if (_prefs != null) {
        final keys = _prefs!
            .getKeys()
            .where((key) => key.startsWith('episode_bookmarks_'));
        for (final key in keys) {
          final episodeId = key.replaceFirst('episode_bookmarks_', '');
          final bookmarks = await _getBookmarksLocally(episodeId);

          for (final bookmark in bookmarks) {
            localBookmarks.add(bookmark.toJson());
          }
        }
      }

      if (localBookmarks.isEmpty) {
        debugPrint('No local bookmarks to sync');
        return true;
      }

      // Sync to cloud
      final response = await _dio.post('$_bookmarksEndpoint/sync', data: {
        'bookmarks_data': localBookmarks,
      });

      if (response.statusCode == 200 && response.data['success']) {
        debugPrint(
            'Bookmarks synced successfully: ${response.data['data']['total_synced']} items');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to sync bookmarks: $e');
    }

    return false;
  }

  /// Get bookmarks by category
  Future<List<EpisodeBookmark>> getBookmarksByCategory(String category) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final response = await _dio.get('$_bookmarksEndpoint/category/$category');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> bookmarksList = response.data['data']['data'] ?? [];
        return bookmarksList
            .map((json) => EpisodeBookmark.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to get bookmarks by category: $e');
    }

    return [];
  }

  /// Get bookmarks by tags
  Future<List<EpisodeBookmark>> getBookmarksByTags(List<String> tags) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final response =
          await _dio.get('$_bookmarksEndpoint/tags', queryParameters: {
        'tags': tags.join(','),
      });

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> bookmarksList = response.data['data']['data'] ?? [];
        return bookmarksList
            .map((json) => EpisodeBookmark.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to get bookmarks by tags: $e');
    }

    return [];
  }

  /// Search bookmarks
  Future<List<EpisodeBookmark>> searchBookmarks(String query) async {
    try {
      await initialize();
      await _ensureAuthToken();

      final response =
          await _dio.get('$_bookmarksEndpoint/search', queryParameters: {
        'q': query,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> bookmarksList = response.data['data']['data'] ?? [];
        return bookmarksList
            .map((json) => EpisodeBookmark.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to search bookmarks: $e');
    }

    return [];
  }

  // MARK: - Local Bookmark Storage

  /// Save bookmarks locally
  Future<void> _saveBookmarksLocally(
      String episodeId, List<EpisodeBookmark> bookmarks) async {
    if (_prefs == null) await _initializePrefs();

    final bookmarksData = bookmarks.map((b) => b.toJson()).toList();
    await _prefs!
        .setString('episode_bookmarks_$episodeId', jsonEncode(bookmarksData));
  }

  /// Get bookmarks from local storage
  Future<List<EpisodeBookmark>> _getBookmarksLocally(String episodeId) async {
    if (_prefs == null) await _initializePrefs();

    final bookmarksData = _prefs!.getString('episode_bookmarks_$episodeId');
    if (bookmarksData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(bookmarksData);
        return jsonList.map((json) => EpisodeBookmark.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error parsing local bookmarks data: $e');
      }
    }
    return [];
  }

  /// Add bookmark to local storage
  Future<void> _addBookmarkLocally(
      String episodeId, EpisodeBookmark bookmark) async {
    if (_prefs == null) await _initializePrefs();

    final existingBookmarks = await _getBookmarksLocally(episodeId);
    existingBookmarks.add(bookmark);
    await _saveBookmarksLocally(episodeId, existingBookmarks);
  }

  /// Update bookmark in local storage
  Future<void> _updateBookmarkLocally(
      String episodeId, int position, Map<String, dynamic> updateData) async {
    if (_prefs == null) await _initializePrefs();

    final existingBookmarks = await _getBookmarksLocally(episodeId);
    final index = existingBookmarks
        .indexWhere((bookmark) => bookmark.position == position);
    if (index != -1) {
      final updatedBookmark = existingBookmarks[index].copyWith(
        title: updateData['title'],
        notes: updateData['notes'],
        color: updateData['color'],
        isPublic: updateData['is_public'],
        category: updateData['category'],
        tags: updateData['tags'] != null
            ? List<String>.from(updateData['tags'])
            : null,
        metadata: updateData['metadata'],
        updatedAt: DateTime.now(),
      );
      existingBookmarks[index] = updatedBookmark;
      await _saveBookmarksLocally(episodeId, existingBookmarks);
    }
  }

  /// Remove bookmark from local storage
  Future<void> _removeBookmarkLocally(String episodeId, int position) async {
    if (_prefs == null) await _initializePrefs();

    final existingBookmarks = await _getBookmarksLocally(episodeId);
    existingBookmarks.removeWhere((bookmark) => bookmark.position == position);
    await _saveBookmarksLocally(episodeId, existingBookmarks);
  }

  /// Get bookmark statistics
  Future<Map<String, dynamic>> getBookmarkStatistics() async {
    try {
      await initialize();
      await _ensureAuthToken();

      final response = await _dio.get('$_bookmarksEndpoint/statistics');

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint('Failed to get bookmark statistics: $e');
    }

    // Fallback to local statistics
    return await _getLocalBookmarkStatistics();
  }

  /// Get local bookmark statistics
  Future<Map<String, dynamic>> _getLocalBookmarkStatistics() async {
    if (_prefs == null) await _initializePrefs();

    try {
      final allBookmarks = <EpisodeBookmark>[];
      final progressIds = await _getLocalProgressIds();

      for (final episodeId in progressIds) {
        final bookmarks = await _getBookmarksLocally(episodeId);
        allBookmarks.addAll(bookmarks);
      }

      final categories = <String, int>{};
      final tags = <String, int>{};
      final totalBookmarks = allBookmarks.length;
      final publicBookmarks = allBookmarks.where((b) => b.isPublic).length;

      for (final bookmark in allBookmarks) {
        if (bookmark.category != null) {
          categories[bookmark.category!] =
              (categories[bookmark.category!] ?? 0) + 1;
        }
        if (bookmark.tags != null) {
          for (final tag in bookmark.tags!) {
            tags[tag] = (tags[tag] ?? 0) + 1;
          }
        }
      }

      return {
        'total_bookmarks': totalBookmarks,
        'public_bookmarks': publicBookmarks,
        'categories': categories,
        'tags': tags,
        'source': 'local',
      };
    } catch (e) {
      debugPrint('Error getting local bookmark statistics: $e');
      return {'error': e.toString()};
    }
  }
}
