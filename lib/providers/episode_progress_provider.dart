import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/episode_progress_service.dart';
import '../models/episode_progress.dart';

class EpisodeProgressProvider extends ChangeNotifier {
  final EpisodeProgressService _progressService = EpisodeProgressService();

  // Progress state storage
  final Map<String, EpisodeProgress> _episodeProgress = {};
  final Map<String, DateTime> _lastUpdateTimes = {};

  // Stream subscription for real-time updates
  StreamSubscription<ProgressChangeEvent>? _progressSubscription;

  // Loading states
  final Map<String, bool> _loadingStates = {};
  bool _isInitialized = false;

  // Debug verbosity control
  bool _verboseDebug = false;
  bool get verboseDebug => _verboseDebug;

  // Update batching for performance optimization
  Timer? _batchUpdateTimer;
  final Set<String> _pendingUpdates = {};
  static const Duration _batchUpdateDelay = Duration(milliseconds: 100);

  /// Enable/disable verbose debug logging during playback
  void setVerboseDebug(bool enabled) {
    _verboseDebug = enabled;
    debugPrint(
        '🔊 EpisodeProgressProvider: Verbose debug ${enabled ? 'enabled' : 'disabled'}');
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Map<String, EpisodeProgress> get episodeProgress {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called episodeProgress getter before initialization');
      return <String, EpisodeProgress>{};
    }
    return Map.unmodifiable(_episodeProgress);
  }

  /// Safe way to notify listeners - prevents build phase issues
  void _safeNotifyListeners() {
    // Use microtask to defer notification until after build phase
    Future.microtask(() => notifyListeners());
  }

  /// Get progress for a specific episode
  EpisodeProgress? getProgress(String episodeId) {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called getProgress before initialization');
      return null;
    }
    return _episodeProgress[episodeId];
  }

  /// Check if episode is completed
  bool isEpisodeCompleted(String episodeId) {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called isEpisodeCompleted before initialization');
      return false;
    }
    final progress = _episodeProgress[episodeId];
    return progress?.isCompleted ?? false;
  }

  /// Get progress percentage for an episode
  double getProgressPercentage(String episodeId) {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called getProgressPercentage before initialization');
      return 0.0;
    }
    final progress = _episodeProgress[episodeId];
    if (progress == null) return 0.0;
    return progress.progressPercentage;
  }

  /// Get current position for an episode
  int getCurrentPosition(String episodeId) {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called getCurrentPosition before initialization');
      return 0;
    }
    final progress = _episodeProgress[episodeId];
    return progress?.currentPosition ?? 0;
  }

  /// Mark episode as played (completed)
  Future<bool> markEpisodeAsPlayed({
    required String episodeId,
    String? podcastId,
  }) async {
    try {
      debugPrint(
          '✅ EpisodeProgressProvider: Marking episode as played: $episodeId');

      // Get current progress or create new
      final currentProgress = _episodeProgress[episodeId];
      if (currentProgress != null) {
        // Update existing progress to mark as completed
        final updatedProgress = currentProgress.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          lastPlayedAt: DateTime.now(),
        );

        _episodeProgress[episodeId] = updatedProgress;
        _lastUpdateTimes[episodeId] = DateTime.now();

        // Save to service
        final success = await _progressService.saveProgress(
          episodeId: episodeId,
          podcastId: podcastId ?? 'episode_${episodeId}_podcast',
          currentPosition: updatedProgress.totalDuration,
          totalDuration: updatedProgress.totalDuration,
          playbackData: {
            'is_completed': true,
            'completed_at': updatedProgress.completedAt?.toIso8601String(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (success) {
          _safeNotifyListeners();
          debugPrint('✅ Episode marked as played successfully');
          return true;
        } else {
          debugPrint('⚠️ Failed to save completed status to service');
          return false;
        }
      } else {
        // Create new progress entry for completed episode
        final newProgress = EpisodeProgress(
          episodeId: episodeId,
          podcastId: podcastId ?? 'episode_${episodeId}_podcast',
          currentPosition: 0,
          totalDuration: 0,
          progressPercentage: 1.0, // Completed episode = 100% progress
          isCompleted: true,
          completedAt: DateTime.now(),
          lastPlayedAt: DateTime.now(),
        );

        _episodeProgress[episodeId] = newProgress;
        _lastUpdateTimes[episodeId] = DateTime.now();

        // Save to service
        final success = await _progressService.saveProgress(
          episodeId: episodeId,
          podcastId: podcastId ?? 'episode_${episodeId}_podcast',
          currentPosition: 0,
          totalDuration: 0,
          playbackData: {
            'is_completed': true,
            'completed_at': newProgress.completedAt?.toIso8601String(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (success) {
          _safeNotifyListeners();
          debugPrint('✅ New episode progress created and marked as played');
          return true;
        } else {
          debugPrint('⚠️ Failed to save new completed progress to service');
          return false;
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking episode as played: $e');
      return false;
    }
  }

  /// Update episode progress with real-time status (THROTTLED & BATCHED)
  void updateEpisodeProgressRealTime(
    String episodeId,
    double progress,
    Duration position,
    Duration duration,
  ) {
    if (!_isInitialized) return;

    try {
      // Throttling: Only update if significant change or enough time has passed
      final now = DateTime.now();
      final lastUpdate = _lastUpdateTimes[episodeId];

      // Update if:
      // 1. First time updating this episode, OR
      // 2. Progress changed by more than 1%, OR
      // 3. At least 500ms have passed since last update
      final shouldUpdate = lastUpdate == null ||
          (progress - (_episodeProgress[episodeId]?.progressPercentage ?? 0.0))
                  .abs() >
              0.01 ||
          now.difference(lastUpdate).inMilliseconds >= 500;

      if (!shouldUpdate) {
        // Skip update to prevent excessive notifications
        return;
      }

      // Update progress data
      final currentProgress = _episodeProgress[episodeId];
      if (currentProgress != null) {
        final updatedProgress = currentProgress.copyWith(
          currentPosition: position.inMilliseconds,
          totalDuration: duration.inMilliseconds,
          lastPlayedAt: DateTime.now(),
          isCompleted: progress >= 1.0,
        );
        _episodeProgress[episodeId] = updatedProgress;
      }

      // Update last update time
      _lastUpdateTimes[episodeId] = now;

      // Add to pending updates for batching
      _pendingUpdates.add(episodeId);
      _scheduleBatchUpdate();

      if (_verboseDebug) {
        debugPrint(
            '📊 Episode $episodeId progress updated: ${(progress * 100).toStringAsFixed(1)}% (throttled & batched)');
      }
    } catch (e) {
      debugPrint('❌ Error updating episode progress real-time: $e');
    }
  }

  /// Schedule a batched update to reduce notification frequency
  void _scheduleBatchUpdate() {
    if (_batchUpdateTimer?.isActive == true) return;

    _batchUpdateTimer = Timer(_batchUpdateDelay, () {
      if (_pendingUpdates.isNotEmpty) {
        _pendingUpdates.clear();
        _safeNotifyListeners();
        debugPrint(
            '📦 Batch update completed for ${_pendingUpdates.length} episodes');
      }
    });
  }

  /// Get comprehensive episode status for display
  Map<String, dynamic> getEpisodeDisplayStatus(String episodeId) {
    if (!_isInitialized) {
      return {
        'status': 'Not Started',
        'progress': 0.0,
        'isPlaying': false,
        'isBuffering': false,
        'isPaused': false,
        'isCompleted': false,
        'progressText': '0%',
        'statusColor': null,
      };
    }

    final progress = _episodeProgress[episodeId];
    final progressValue = progress?.progressPercentage ?? 0.0;
    final isCompleted = progress?.isCompleted ?? false;

    String status;
    bool isPlaying = false;
    bool isBuffering = false;
    bool isPaused = false;

    // For now, use basic status based on progress
    if (isCompleted) {
      status = 'Completed';
    } else if (progressValue > 0) {
      status = 'Resume Available';
    } else {
      status = 'Not Started';
    }

    return {
      'status': status,
      'progress': progressValue,
      'isPlaying': isPlaying,
      'isBuffering': isBuffering,
      'isPaused': isPaused,
      'isCompleted': isCompleted,
      'progressText': '${(progressValue * 100).toInt()}%',
      'statusColor': _getStatusColor(status, progressValue),
    };
  }

  /// Get status color for different states
  Color? _getStatusColor(String status, double progress) {
    switch (status) {
      case 'Playing Now':
        return Colors.green;
      case 'Buffering...':
        return Colors.orange;
      case 'Paused':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Resume Available':
        return Colors.blue;
      case 'Error':
        return Colors.red;
      default:
        return null;
    }
  }

  /// Handle episode switching - update status immediately
  void onEpisodeSwitched(String newEpisodeId, String? previousEpisodeId) {
    if (!_isInitialized) return;

    try {
      // Clear previous episode's playback state if needed
      if (previousEpisodeId != null) {
        debugPrint('🔄 Previous episode $previousEpisodeId state cleared');
      }

      // Set new episode to initial state
      debugPrint('🔄 New episode $newEpisodeId set to initial state');

      // Notify listeners immediately
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Error handling episode switch: $e');
    }
  }

  /// Set episode to playing state
  void setEpisodePlaying(
    String episodeId, {
    double? progress,
    Duration? position,
    Duration? duration,
  }) {
    if (!_isInitialized) return;

    try {
      // Update progress data
      if (progress != null && position != null && duration != null) {
        final currentProgress = _episodeProgress[episodeId];
        if (currentProgress != null) {
          final updatedProgress = currentProgress.copyWith(
            currentPosition: position.inMilliseconds,
            totalDuration: duration.inMilliseconds,
            lastPlayedAt: DateTime.now(),
            isCompleted: progress >= 1.0,
          );
          _episodeProgress[episodeId] = updatedProgress;
        }
      }

      // Update last update time
      _lastUpdateTimes[episodeId] = DateTime.now();

      if (_verboseDebug) {
        debugPrint('▶️ Episode $episodeId set to playing');
      }

      // Notify listeners
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting episode to playing: $e');
    }
  }

  /// Set episode to paused state
  void setEpisodePaused(
    String episodeId, {
    double? progress,
    Duration? position,
    Duration? duration,
  }) {
    if (!_isInitialized) return;

    try {
      // Update progress data
      if (progress != null && position != null && duration != null) {
        final currentProgress = _episodeProgress[episodeId];
        if (currentProgress != null) {
          final updatedProgress = currentProgress.copyWith(
            currentPosition: position.inMilliseconds,
            totalDuration: duration.inMilliseconds,
            lastPlayedAt: DateTime.now(),
            isCompleted: progress >= 1.0,
          );
          _episodeProgress[episodeId] = updatedProgress;
        }
      }

      // Update last update time
      _lastUpdateTimes[episodeId] = DateTime.now();

      if (_verboseDebug) {
        debugPrint('⏸️ Episode $episodeId set to paused');
      }

      // Notify listeners
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting episode to paused: $e');
    }
  }

  /// Check if episode is loading
  bool isLoading(String episodeId) {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called isLoading before initialization');
      return false;
    }
    return _loadingStates[episodeId] ?? false;
  }

  /// Get last update time for an episode
  DateTime? getLastUpdateTime(String episodeId) {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called getLastUpdateTime before initialization');
      return null;
    }
    return _lastUpdateTimes[episodeId];
  }

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 EpisodeProgressProvider: Initializing...');

      // Initialize the progress service
      await _progressService.initialize();

      // Set up real-time progress listening
      _setupProgressListening();

      _isInitialized = true;
      debugPrint('✅ EpisodeProgressProvider: Initialized successfully');
      // Use safe method to avoid calling notifyListeners during build
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ EpisodeProgressProvider: Initialization failed: $e');
      rethrow;
    }
  }

  /// Set up real-time progress listening
  void _setupProgressListening() {
    _progressSubscription?.cancel();

    _progressSubscription = _progressService.progressStream.listen(
      (event) {
        // Use microtask to ensure this runs after the current build phase
        Future.microtask(() {
          // Reduce debug noise during playback - only log non-position events or when verbose
          if (_verboseDebug ||
              event.changeType != ProgressChangeType.positionChanged) {
            debugPrint(
                '📡 EpisodeProgressProvider: Received progress event: ${event.changeType.name} for episode ${event.episodeId}');
          }
          _handleProgressEvent(event);
        });
      },
      onError: (error) {
        debugPrint('❌ EpisodeProgressProvider: Progress stream error: $error');
      },
    );

    debugPrint('📡 EpisodeProgressProvider: Progress listening set up');
  }

  /// Handle incoming progress events
  void _handleProgressEvent(ProgressChangeEvent event) {
    try {
      // Safety check - ensure we're initialized before handling events
      if (!_isInitialized) {
        debugPrint(
            '⚠️ EpisodeProgressProvider: Received progress event before initialization, ignoring');
        return;
      }

      // Create or update progress object
      final progress = EpisodeProgress(
        episodeId: event.episodeId,
        podcastId: event.podcastId,
        currentPosition: event.currentPosition,
        totalDuration: event.totalDuration,
        progressPercentage: event.progressPercentage,
        isCompleted: event.isCompleted,
        lastPlayedAt: event.timestamp,
        playbackData: event.playbackData,
      );

      // Update progress state
      _episodeProgress[event.episodeId] = progress;
      _lastUpdateTimes[event.episodeId] = event.timestamp;

      debugPrint(
          '🔄 EpisodeProgressProvider: Updated progress for episode ${event.episodeId} - ${event.changeType.name}');

      // Notify listeners of the change - use safe method to avoid build phase issues
      _safeNotifyListeners();
    } catch (e) {
      debugPrint(
          '❌ EpisodeProgressProvider: Error handling progress event: $e');
    }
  }

  /// Load progress for a specific episode
  Future<EpisodeProgress?> loadProgress(String episodeId) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during loadProgress: $e');
        return null;
      }
    }

    try {
      _setLoading(episodeId, true);

      debugPrint(
          '🔄 EpisodeProgressProvider: Loading progress for episode $episodeId');

      final progress = await _progressService.getProgress(episodeId);

      if (progress != null) {
        _episodeProgress[episodeId] = progress;
        _lastUpdateTimes[episodeId] = DateTime.now();
        debugPrint(
            '✅ EpisodeProgressProvider: Progress loaded for episode $episodeId');
      } else {
        debugPrint(
            'ℹ️ EpisodeProgressProvider: No progress found for episode $episodeId');
      }

      return progress;
    } catch (e) {
      debugPrint(
          '❌ EpisodeProgressProvider: Error loading progress for episode $episodeId: $e');
      return null;
    } finally {
      _setLoading(episodeId, false);
    }
  }

  /// Load progress for multiple episodes
  Future<void> loadProgressForEpisodes(List<String> episodeIds) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during loadProgressForEpisodes: $e');
        return;
      }
    }

    debugPrint(
        '🔄 EpisodeProgressProvider: Loading progress for ${episodeIds.length} episodes');

    final futures = episodeIds.map((id) => loadProgress(id));
    await Future.wait(futures);

    debugPrint(
        '✅ EpisodeProgressProvider: Progress loaded for ${episodeIds.length} episodes');
  }

  /// Save progress for an episode
  Future<bool> saveProgress({
    required String episodeId,
    required String podcastId,
    required int currentPosition,
    required int totalDuration,
    Map<String, dynamic>? playbackData,
  }) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during saveProgress: $e');
        return false;
      }
    }

    try {
      debugPrint(
          '🔄 EpisodeProgressProvider: Saving progress for episode $episodeId');

      final success = await _progressService.saveProgress(
        episodeId: episodeId,
        podcastId: podcastId,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        playbackData: playbackData,
      );

      if (success) {
        debugPrint(
            '✅ EpisodeProgressProvider: Progress saved successfully for episode $episodeId');
      } else {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to save progress for episode $episodeId');
      }

      return success;
    } catch (e) {
      debugPrint(
          '❌ EpisodeProgressProvider: Error saving progress for episode $episodeId: $e');
      return false;
    }
  }

  /// Update existing progress
  Future<bool> updateProgress({
    required String episodeId,
    required int currentPosition,
    int? totalDuration,
    Map<String, dynamic>? playbackData,
  }) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during updateProgress: $e');
        return false;
      }
    }

    try {
      debugPrint(
          '🔄 EpisodeProgressProvider: Updating progress for episode $episodeId');

      final success = await _progressService.updateProgress(
        episodeId: episodeId,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        playbackData: playbackData,
      );

      if (success) {
        debugPrint(
            '✅ EpisodeProgressProvider: Progress updated successfully for episode $episodeId');
      } else {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to update progress for episode $episodeId');
      }

      return success;
    } catch (e) {
      debugPrint(
          '❌ EpisodeProgressProvider: Error updating progress for episode $episodeId: $e');
      return false;
    }
  }

  /// Mark episode as completed
  Future<bool> markCompleted(String episodeId) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during markCompleted: $e');
        return false;
      }
    }

    try {
      debugPrint(
          '🔄 EpisodeProgressProvider: Marking episode $episodeId as completed');

      final success = await _progressService.markCompleted(episodeId);

      if (success) {
        debugPrint(
            '✅ EpisodeProgressProvider: Episode $episodeId marked as completed');
      } else {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to mark episode $episodeId as completed');
      }

      return success;
    } catch (e) {
      debugPrint(
          '❌ EpisodeProgressProvider: Error marking episode $episodeId as completed: $e');
      return false;
    }
  }

  /// Get all progress for a podcast
  Future<List<EpisodeProgress>> getProgressForPodcast(String podcastId) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during getProgressForPodcast: $e');
        return [];
      }
    }

    try {
      debugPrint(
          '🔄 EpisodeProgressProvider: Loading progress for podcast $podcastId');

      final progressList =
          await _progressService.getAllProgress(podcastId: podcastId);

      // Update local state
      for (final progress in progressList) {
        _episodeProgress[progress.episodeId] = progress;
        _lastUpdateTimes[progress.episodeId] = DateTime.now();
      }

      debugPrint(
          '✅ EpisodeProgressProvider: Loaded ${progressList.length} progress items for podcast $podcastId');
      return progressList;
    } catch (e) {
      debugPrint(
          '❌ EpisodeProgressProvider: Error loading progress for podcast $podcastId: $e');
      return [];
    }
  }

  /// Clear progress for an episode
  void clearProgress(String episodeId) {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called clearProgress before initialization, ignoring');
      return;
    }

    _episodeProgress.remove(episodeId);
    _lastUpdateTimes.remove(episodeId);
    _loadingStates.remove(episodeId);
    // Use safe method to avoid build phase issues
    _safeNotifyListeners();
    debugPrint(
        '🗑️ EpisodeProgressProvider: Progress cleared for episode $episodeId');
  }

  /// Clear all progress
  void clearAllProgress() {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called clearAllProgress before initialization, ignoring');
      return;
    }

    _episodeProgress.clear();
    _lastUpdateTimes.clear();
    _loadingStates.clear();
    // Use safe method to avoid build phase issues
    _safeNotifyListeners();
    debugPrint('🗑️ EpisodeProgressProvider: All progress cleared');
  }

  /// Set loading state for an episode
  void _setLoading(String episodeId, bool loading) {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called _setLoading before initialization, ignoring');
      return;
    }

    _loadingStates[episodeId] = loading;
    // Use safe method to avoid build phase issues
    _safeNotifyListeners();
  }

  /// Refresh progress for an episode
  Future<void> refreshProgress(String episodeId) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during refreshProgress: $e');
        return;
      }
    }
    await loadProgress(episodeId);
  }

  /// Refresh progress for multiple episodes
  Future<void> refreshProgressForEpisodes(List<String> episodeIds) async {
    // Safety check - ensure we're initialized
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            '❌ EpisodeProgressProvider: Failed to initialize during refreshProgressForEpisodes: $e');
        return;
      }
    }
    await loadProgressForEpisodes(episodeIds);
  }

  /// Get progress statistics
  Map<String, dynamic> getProgressStatistics() {
    // Safety check - don't call this during build phase
    if (!_isInitialized) {
      debugPrint(
          '⚠️ EpisodeProgressProvider: Called getProgressStatistics before initialization');
      return {
        'totalEpisodes': 0,
        'completedEpisodes': 0,
        'inProgressEpisodes': 0,
        'notStartedEpisodes': 0,
        'completionRate': 0.0,
      };
    }

    final totalEpisodes = _episodeProgress.length;
    final completedEpisodes =
        _episodeProgress.values.where((p) => p.isCompleted).length;
    final inProgressEpisodes = _episodeProgress.values
        .where((p) => !p.isCompleted && p.progressPercentage > 0)
        .length;
    final notStartedEpisodes =
        _episodeProgress.values.where((p) => p.progressPercentage == 0).length;

    return {
      'totalEpisodes': totalEpisodes,
      'completedEpisodes': completedEpisodes,
      'inProgressEpisodes': inProgressEpisodes,
      'notStartedEpisodes': notStartedEpisodes,
      'completionRate':
          totalEpisodes > 0 ? (completedEpisodes / totalEpisodes) * 100 : 0.0,
    };
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _batchUpdateTimer?.cancel();
    super.dispose();
    debugPrint('🗑️ EpisodeProgressProvider: Disposed');
  }
}
