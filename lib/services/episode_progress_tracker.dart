import 'package:flutter/foundation.dart';
import '../services/episode_progress_service.dart';
import '../models/episode_progress.dart';

/// Comprehensive Episode Progress Tracker Service
///
/// This service provides a unified interface for tracking episode progress
/// across the entire application, ensuring consistent progress tracking
/// and display.
class EpisodeProgressTracker {
  static final EpisodeProgressTracker _instance =
      EpisodeProgressTracker._internal();
  factory EpisodeProgressTracker() => _instance;
  EpisodeProgressTracker._internal();

  final EpisodeProgressService _progressService = EpisodeProgressService();
  bool _isInitialized = false;

  /// Get the progress service instance
  EpisodeProgressService get progressService => _progressService;

  /// Initialize the progress tracker
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _progressService.initialize();
      _isInitialized = true;
      debugPrint('EpisodeProgressTracker initialized successfully');
    } catch (e) {
      debugPrint('Error initializing EpisodeProgressTracker: $e');
      rethrow;
    }
  }

  /// Track episode playback start
  Future<bool> trackEpisodeStart({
    required String episodeId,
    required String podcastId,
    int? initialPosition,
    int? totalDuration,
  }) async {
    try {
      await initialize();

      // If initial position is provided, use it; otherwise start from 0
      final position = initialPosition ?? 0;
      final duration = totalDuration ?? 0;

      final success = await _progressService.saveProgress(
        episodeId: episodeId,
        podcastId: podcastId,
        currentPosition: position,
        totalDuration: duration,
        playbackData: {
          'action': 'started',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        debugPrint('✅ Episode start tracked: $episodeId at position $position');
      } else {
        debugPrint('⚠️ Episode start tracked locally only: $episodeId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error tracking episode start: $e');
      return false;
    }
  }

  /// Track episode playback progress
  Future<bool> trackEpisodeProgress({
    required String episodeId,
    required int currentPosition,
    int? totalDuration,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await initialize();

      final success = await _progressService.updateProgress(
        episodeId: episodeId,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        playbackData: {
          'action': 'progress_update',
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );

      if (success) {
        debugPrint(
            '✅ Episode progress tracked: $episodeId at $currentPosition');
      } else {
        debugPrint('⚠️ Episode progress tracked locally only: $episodeId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error tracking episode progress: $e');
      return false;
    }
  }

  /// Track episode completion
  Future<bool> trackEpisodeCompletion({
    required String episodeId,
    int? totalDuration,
  }) async {
    try {
      await initialize();

      final success = await _progressService.markCompleted(episodeId);

      if (success) {
        debugPrint('✅ Episode completion tracked: $episodeId');
      } else {
        debugPrint('⚠️ Episode completion tracked locally only: $episodeId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error tracking episode completion: $e');
      return false;
    }
  }

  /// Track episode pause
  Future<bool> trackEpisodePause({
    required String episodeId,
    required int currentPosition,
    int? totalDuration,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await initialize();

      final success = await _progressService.updateProgress(
        episodeId: episodeId,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        playbackData: {
          'action': 'paused',
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );

      if (success) {
        debugPrint('✅ Episode pause tracked: $episodeId at $currentPosition');
      } else {
        debugPrint('⚠️ Episode pause tracked locally only: $episodeId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error tracking episode pause: $e');
      return false;
    }
  }

  /// Track episode seek
  Future<bool> trackEpisodeSeek({
    required String episodeId,
    required int newPosition,
    int? totalDuration,
    int? previousPosition,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await initialize();

      final success = await _progressService.updateProgress(
        episodeId: episodeId,
        currentPosition: newPosition,
        totalDuration: totalDuration,
        playbackData: {
          'action': 'seek',
          'previous_position': previousPosition,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );

      if (success) {
        debugPrint(
            '✅ Episode seek tracked: $episodeId from ${previousPosition ?? 'unknown'} to $newPosition');
      } else {
        debugPrint('⚠️ Episode seek tracked locally only: $episodeId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error tracking episode seek: $e');
      return false;
    }
  }

  /// Get progress for an episode
  Future<EpisodeProgress?> getEpisodeProgress(String episodeId) async {
    try {
      await initialize();
      return await _progressService.getProgress(episodeId);
    } catch (e) {
      debugPrint('❌ Error getting episode progress: $e');
      return null;
    }
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
      return await _progressService.getAllProgress(
        podcastId: podcastId,
        completed: completed,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      debugPrint('❌ Error getting all progress: $e');
      return [];
    }
  }

  /// Get progress statistics
  Future<Map<String, dynamic>?> getProgressStatistics() async {
    try {
      await initialize();
      return await _progressService.getStatistics();
    } catch (e) {
      debugPrint('❌ Error getting progress statistics: $e');
      return null;
    }
  }

  /// Sync progress with cloud
  Future<bool> syncProgress() async {
    try {
      await initialize();
      return await _progressService.syncProgress();
    } catch (e) {
      debugPrint('❌ Error syncing progress: $e');
      return false;
    }
  }

  /// Delete progress for an episode
  Future<bool> deleteEpisodeProgress(String episodeId) async {
    try {
      await initialize();
      return await _progressService.deleteProgress(episodeId);
    } catch (e) {
      debugPrint('❌ Error deleting episode progress: $e');
      return false;
    }
  }

  /// Clear all progress
  Future<bool> clearAllProgress() async {
    try {
      await initialize();
      return await _progressService.clearAllProgress();
    } catch (e) {
      debugPrint('❌ Error clearing all progress: $e');
      return false;
    }
  }

  /// Check if episode has progress
  Future<bool> hasEpisodeProgress(String episodeId) async {
    try {
      final progress = await getEpisodeProgress(episodeId);
      return progress != null;
    } catch (e) {
      debugPrint('❌ Error checking episode progress: $e');
      return false;
    }
  }

  /// Check if episode is completed
  Future<bool> isEpisodeCompleted(String episodeId) async {
    try {
      final progress = await getEpisodeProgress(episodeId);
      return progress?.isCompleted ?? false;
    } catch (e) {
      debugPrint('❌ Error checking episode completion: $e');
      return false;
    }
  }

  /// Get episode progress percentage
  Future<double> getEpisodeProgressPercentage(String episodeId) async {
    try {
      final progress = await getEpisodeProgress(episodeId);
      return progress?.progressPercentage ?? 0.0;
    } catch (e) {
      debugPrint('❌ Error getting episode progress percentage: $e');
      return 0.0;
    }
  }

  /// Get episode remaining time
  Future<String> getEpisodeRemainingTime(String episodeId) async {
    try {
      final progress = await getEpisodeProgress(episodeId);
      return progress?.formattedRemainingTime ?? '';
    } catch (e) {
      debugPrint('❌ Error getting episode remaining time: $e');
      return '';
    }
  }

  /// Get episode last played position
  Future<int> getEpisodeLastPosition(String episodeId) async {
    try {
      final progress = await getEpisodeProgress(episodeId);
      return progress?.currentPosition ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting episode last position: $e');
      return 0;
    }
  }

  /// Get episode last played time
  Future<DateTime?> getEpisodeLastPlayedTime(String episodeId) async {
    try {
      final progress = await getEpisodeProgress(episodeId);
      return progress?.lastPlayedAt;
    } catch (e) {
      debugPrint('❌ Error getting episode last played time: $e');
      return null;
    }
  }

  /// Batch track multiple episodes
  Future<Map<String, bool>> batchTrackEpisodes({
    required List<Map<String, dynamic>> episodes,
    required String action,
  }) async {
    try {
      await initialize();

      final results = <String, bool>{};

      for (final episodeData in episodes) {
        final episodeId = episodeData['episode_id'] as String;
        final currentPosition = episodeData['current_position'] as int? ?? 0;
        final totalDuration = episodeData['total_duration'] as int?;

        bool success = false;

        switch (action) {
          case 'start':
            success = await trackEpisodeStart(
              episodeId: episodeId,
              podcastId: episodeData['podcast_id'] as String,
              initialPosition: currentPosition,
              totalDuration: totalDuration,
            );
            break;
          case 'progress':
            success = await trackEpisodeProgress(
              episodeId: episodeId,
              currentPosition: currentPosition,
              totalDuration: totalDuration,
              additionalData: episodeData['additional_data'],
            );
            break;
          case 'pause':
            success = await trackEpisodePause(
              episodeId: episodeId,
              currentPosition: currentPosition,
              totalDuration: totalDuration,
              additionalData: episodeData['additional_data'],
            );
            break;
          case 'seek':
            success = await trackEpisodeSeek(
              episodeId: episodeId,
              newPosition: currentPosition,
              totalDuration: totalDuration,
              previousPosition: episodeData['previous_position'] as int?,
              additionalData: episodeData['additional_data'],
            );
            break;
          case 'complete':
            success = await trackEpisodeCompletion(
              episodeId: episodeId,
              totalDuration: totalDuration,
            );
            break;
          default:
            debugPrint('⚠️ Unknown action: $action');
            success = false;
        }

        results[episodeId] = success;
      }

      return results;
    } catch (e) {
      debugPrint('❌ Error batch tracking episodes: $e');
      return {};
    }
  }
}
