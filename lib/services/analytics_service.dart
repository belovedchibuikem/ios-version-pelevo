import 'package:flutter/material.dart';
import '../models/episode_progress.dart';
import '../services/episode_progress_service.dart';

/// Analytics service for data analysis and insights
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final EpisodeProgressService _progressService = EpisodeProgressService();

  /// Get listening behavior analytics
  Future<Map<String, dynamic>> getListeningBehaviorAnalytics() async {
    try {
      await _progressService.initialize();
      final allProgress = await _progressService.getAllProgress();

      if (allProgress.isEmpty) return _getDefaultListeningBehavior();

      final totalEpisodes = allProgress.length;
      final completedEpisodes = allProgress.where((p) => p.isCompleted).length;
      final inProgressEpisodes = allProgress
          .where((p) => !p.isCompleted && p.currentPosition > 0)
          .length;

      return {
        'overview': {
          'total_episodes': totalEpisodes,
          'completed_episodes': completedEpisodes,
          'in_progress_episodes': inProgressEpisodes,
          'completion_rate': totalEpisodes > 0
              ? (completedEpisodes / totalEpisodes * 100).toStringAsFixed(1)
              : '0.0',
          'engagement_rate': totalEpisodes > 0
              ? ((completedEpisodes + inProgressEpisodes) / totalEpisodes * 100)
                  .toStringAsFixed(1)
              : '0.0',
        },
        'listening_patterns': _analyzeListeningPatterns(allProgress),
        'time_analysis': _analyzeTimePatterns(allProgress),
      };
    } catch (e) {
      debugPrint('Error getting listening behavior analytics: $e');
      return _getDefaultListeningBehavior();
    }
  }

  /// Get content analytics
  Future<Map<String, dynamic>> getContentAnalytics() async {
    try {
      await _progressService.initialize();
      final allProgress = await _progressService.getAllProgress();

      if (allProgress.isEmpty) return _getDefaultContentAnalytics();

      return {
        'podcast_performance': _analyzePodcastPerformance(allProgress),
        'episode_performance': _analyzeEpisodePerformance(allProgress),
        'content_insights': _generateContentInsights(allProgress),
      };
    } catch (e) {
      debugPrint('Error getting content analytics: $e');
      return _getDefaultContentAnalytics();
    }
  }

  /// Get user engagement analytics
  Future<Map<String, dynamic>> getUserEngagementAnalytics() async {
    try {
      await _progressService.initialize();
      final allProgress = await _progressService.getAllProgress();

      if (allProgress.isEmpty) return _getDefaultUserEngagement();

      return {
        'engagement_metrics': _calculateEngagementMetrics(allProgress),
        'retention_analysis': _analyzeRetention(allProgress),
        'engagement_score': _calculateEngagementScore(allProgress),
      };
    } catch (e) {
      debugPrint('Error getting user engagement analytics: $e');
      return _getDefaultUserEngagement();
    }
  }

  /// Analyze listening patterns
  Map<String, dynamic> _analyzeListeningPatterns(
      List<EpisodeProgress> progress) {
    final sessions = <Map<String, dynamic>>[];

    for (final episode in progress) {
      if (episode.lastPlayedAt != null) {
        final sessionDuration = episode.currentPosition;
        final isCompleted = episode.isCompleted;

        sessions.add({
          'episode_id': episode.episodeId,
          'duration': sessionDuration,
          'is_completed': isCompleted,
          'session_type': isCompleted
              ? 'full'
              : sessionDuration > 300
                  ? 'substantial'
                  : 'brief',
        });
      }
    }

    final sessionDurations = sessions.map((s) => s['duration'] as int).toList();
    final averageSessionDuration = sessionDurations.isNotEmpty
        ? sessionDurations.reduce((a, b) => a + b) / sessionDurations.length
        : 0;

    return {
      'total_sessions': sessions.length,
      'average_session_duration': averageSessionDuration.round(),
      'session_types': {
        'full': sessions.where((s) => s['session_type'] == 'full').length,
        'substantial':
            sessions.where((s) => s['session_type'] == 'substantial').length,
        'brief': sessions.where((s) => s['session_type'] == 'brief').length,
      },
    };
  }

  /// Analyze time patterns
  Map<String, dynamic> _analyzeTimePatterns(List<EpisodeProgress> progress) {
    final timeSlots = <String, int>{
      'morning': 0, // 6 AM - 12 PM
      'afternoon': 0, // 12 PM - 6 PM
      'evening': 0, // 6 PM - 12 AM
      'night': 0, // 12 AM - 6 AM
    };

    for (final episode in progress) {
      if (episode.lastPlayedAt != null) {
        final hour = episode.lastPlayedAt!.hour;
        if (hour >= 6 && hour < 12) {
          timeSlots['morning'] = (timeSlots['morning'] ?? 0) + 1;
        } else if (hour >= 12 && hour < 18) {
          timeSlots['afternoon'] = (timeSlots['afternoon'] ?? 0) + 1;
        } else if (hour >= 18 && hour < 24) {
          timeSlots['evening'] = (timeSlots['evening'] ?? 0) + 1;
        } else {
          timeSlots['night'] = (timeSlots['night'] ?? 0) + 1;
        }
      }
    }

    final totalSessions = timeSlots.values.reduce((a, b) => a + b);
    final preferredTimeSlot =
        timeSlots.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return {
      'time_distribution': timeSlots,
      'total_sessions': totalSessions,
      'preferred_time_slot': preferredTimeSlot,
    };
  }

  /// Analyze podcast performance
  Map<String, dynamic> _analyzePodcastPerformance(
      List<EpisodeProgress> progress) {
    final podcastGroups = <String, List<EpisodeProgress>>{};

    for (final episode in progress) {
      final podcastId = episode.podcastId ?? 'unknown';
      podcastGroups.putIfAbsent(podcastId, () => []).add(episode);
    }

    final podcastAnalytics = <String, Map<String, dynamic>>{};

    for (final entry in podcastGroups.entries) {
      final episodes = entry.value;
      final totalEpisodes = episodes.length;
      final completedEpisodes = episodes.where((e) => e.isCompleted).length;
      final totalListeningTime =
          episodes.fold<int>(0, (sum, e) => sum + e.currentPosition);

      podcastAnalytics[entry.key] = {
        'total_episodes': totalEpisodes,
        'completed_episodes': completedEpisodes,
        'completion_rate': totalEpisodes > 0
            ? (completedEpisodes / totalEpisodes * 100).toStringAsFixed(1)
            : '0.0',
        'total_listening_time': totalListeningTime,
        'average_episode_duration': totalEpisodes > 0
            ? (totalListeningTime / totalEpisodes).round()
            : 0,
      };
    }

    return podcastAnalytics;
  }

  /// Analyze episode performance
  Map<String, dynamic> _analyzeEpisodePerformance(
      List<EpisodeProgress> progress) {
    final episodeAnalytics = <String, Map<String, dynamic>>{};

    for (final episode in progress) {
      final episodeId = episode.episodeId;
      final isCompleted = episode.isCompleted;
      final listeningTime = episode.currentPosition;
      final totalDuration = episode.totalDuration ?? 1;
      final completionPercentage =
          (listeningTime / totalDuration * 100).round();

      episodeAnalytics[episodeId] = {
        'is_completed': isCompleted,
        'listening_time': listeningTime,
        'total_duration': totalDuration,
        'completion_percentage': completionPercentage,
        'engagement_level': _getEngagementLevel(completionPercentage),
        'last_played': episode.lastPlayedAt?.toIso8601String(),
      };
    }

    return episodeAnalytics;
  }

  /// Generate content insights
  Map<String, dynamic> _generateContentInsights(
      List<EpisodeProgress> progress) {
    final totalListeningTime =
        progress.fold<int>(0, (sum, p) => sum + p.currentPosition);
    final totalEpisodes = progress.length;
    final completedEpisodes = progress.where((p) => p.isCompleted).length;

    return {
      'total_listening_time': totalListeningTime,
      'average_listening_time_per_episode':
          totalEpisodes > 0 ? (totalListeningTime / totalEpisodes).round() : 0,
      'episode_completion_rate': totalEpisodes > 0
          ? (completedEpisodes / totalEpisodes * 100).toStringAsFixed(1)
          : '0.0',
      'content_quality_score': _calculateContentQualityScore(progress),
    };
  }

  /// Calculate engagement metrics
  Map<String, dynamic> _calculateEngagementMetrics(
      List<EpisodeProgress> progress) {
    if (progress.isEmpty) return {};

    final totalListeningTime =
        progress.fold<int>(0, (sum, p) => sum + p.currentPosition);
    final totalEpisodes = progress.length;
    final completedEpisodes = progress.where((p) => p.isCompleted).length;
    final activeEpisodes = progress.where((p) => p.currentPosition > 0).length;

    return {
      'total_listening_time': totalListeningTime,
      'average_listening_time_per_episode':
          totalEpisodes > 0 ? (totalListeningTime / totalEpisodes).round() : 0,
      'episode_completion_rate': totalEpisodes > 0
          ? (completedEpisodes / totalEpisodes * 100).toStringAsFixed(1)
          : '0.0',
      'active_episode_rate': totalEpisodes > 0
          ? (activeEpisodes / totalEpisodes * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Analyze retention
  Map<String, dynamic> _analyzeRetention(List<EpisodeProgress> progress) {
    if (progress.length < 2) return {'retention_rate': '100.0'};

    final timestamps = progress
        .where((p) => p.lastPlayedAt != null)
        .map((p) => p.lastPlayedAt!)
        .toList()
      ..sort();

    if (timestamps.length < 2) return {'retention_rate': '100.0'};

    double totalGap = 0.0;
    for (int i = 1; i < timestamps.length; i++) {
      final gap =
          timestamps[i].difference(timestamps[i - 1]).inHours.toDouble();
      totalGap += gap;
    }

    final averageGap = totalGap / (timestamps.length - 1);
    final retentionRate =
        (1.0 / (1.0 + averageGap / 24.0) * 100).clamp(0.0, 100.0);

    return {
      'retention_rate': retentionRate.toStringAsFixed(1),
      'average_gap_hours': averageGap.round(),
      'consistency_score': retentionRate,
    };
  }

  /// Calculate engagement score
  double _calculateEngagementScore(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;

    final completionScore =
        progress.where((p) => p.isCompleted).length / progress.length * 40;
    final listeningScore = _calculateListeningDepthScore(progress) * 30;
    final consistencyScore = _calculateConsistencyScore(progress) * 30;

    return (completionScore + listeningScore + consistencyScore)
        .clamp(0.0, 100.0);
  }

  /// Calculate listening depth score
  double _calculateListeningDepthScore(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;

    double totalDepth = 0.0;
    for (final episode in progress) {
      final duration = episode.totalDuration ?? 1;
      final position = episode.currentPosition;
      final depth = (position / duration).clamp(0.0, 1.0);
      totalDepth += depth;
    }

    return totalDepth / progress.length;
  }

  /// Calculate consistency score
  double _calculateConsistencyScore(List<EpisodeProgress> progress) {
    if (progress.length < 2) return 1.0;

    final timestamps = progress
        .where((p) => p.lastPlayedAt != null)
        .map((p) => p.lastPlayedAt!)
        .toList()
      ..sort();

    if (timestamps.length < 2) return 1.0;

    double totalGap = 0.0;
    for (int i = 1; i < timestamps.length; i++) {
      final gap =
          timestamps[i].difference(timestamps[i - 1]).inHours.toDouble();
      totalGap += gap;
    }

    final averageGap = totalGap / (timestamps.length - 1);
    return (1.0 / (1.0 + averageGap / 24.0)).clamp(0.0, 1.0);
  }

  /// Calculate content quality score
  double _calculateContentQualityScore(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (final episode in progress) {
      final duration = episode.totalDuration ?? 1;
      final position = episode.currentPosition;
      final completionRate = position / duration;

      // Higher completion rate = higher quality content
      totalScore += completionRate;
    }

    return (totalScore / progress.length * 100).clamp(0.0, 100.0);
  }

  /// Get engagement level
  String _getEngagementLevel(int completionPercentage) {
    if (completionPercentage >= 80) return 'high';
    if (completionPercentage >= 50) return 'medium';
    if (completionPercentage >= 20) return 'low';
    return 'minimal';
  }

  /// Get default analytics
  Map<String, dynamic> _getDefaultListeningBehavior() {
    return {
      'overview': {
        'total_episodes': 0,
        'completed_episodes': 0,
        'in_progress_episodes': 0,
        'completion_rate': '0.0',
        'engagement_rate': '0.0',
      },
      'listening_patterns': {
        'total_sessions': 0,
        'average_session_duration': 0
      },
      'time_analysis': {'total_sessions': 0, 'preferred_time_slot': 'none'},
    };
  }

  Map<String, dynamic> _getDefaultContentAnalytics() {
    return {
      'podcast_performance': {},
      'episode_performance': {},
      'content_insights': {
        'total_listening_time': 0,
        'episode_completion_rate': '0.0'
      },
    };
  }

  Map<String, dynamic> _getDefaultUserEngagement() {
    return {
      'engagement_metrics': {
        'total_listening_time': 0,
        'episode_completion_rate': '0.0'
      },
      'retention_analysis': {'retention_rate': '0.0'},
      'engagement_score': 0.0,
    };
  }
}
