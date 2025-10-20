import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../models/episode_progress.dart';
import '../models/episode_bookmark.dart';
import '../services/episode_progress_service.dart';

/// Advanced analytics service for comprehensive data analysis and insights
class AdvancedAnalyticsService {
  static final AdvancedAnalyticsService _instance =
      AdvancedAnalyticsService._internal();
  factory AdvancedAnalyticsService() => _instance;
  AdvancedAnalyticsService._internal();

  final EpisodeProgressService _progressService = EpisodeProgressService();

  // Analytics data cache
  Map<String, dynamic> _analyticsCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidity = Duration(minutes: 15);

  // Analytics categories
  static const String _listeningBehavior = 'listening_behavior';
  static const String _contentAnalytics = 'content_analytics';
  static const String _userEngagement = 'user_engagement';
  static const String _trendAnalysis = 'trend_analysis';
  static const String _predictiveInsights = 'predictive_insights';

  /// Get comprehensive analytics data
  Future<Map<String, dynamic>> getComprehensiveAnalytics() async {
    // Check cache validity
    if (_isCacheValid()) {
      return _analyticsCache;
    }

    try {
      final analytics = await _generateComprehensiveAnalytics();
      _analyticsCache = analytics;
      _lastCacheUpdate = DateTime.now();

      return analytics;
    } catch (e) {
      debugPrint('Error generating analytics: $e');
      return _getDefaultAnalytics();
    }
  }

  /// Get listening behavior analytics
  Future<Map<String, dynamic>> getListeningBehaviorAnalytics() async {
    final analytics = await getComprehensiveAnalytics();
    return analytics[_listeningBehavior] ?? {};
  }

  /// Get content analytics
  Future<Map<String, dynamic>> getContentAnalytics() async {
    final analytics = await getComprehensiveAnalytics();
    return analytics[_contentAnalytics] ?? {};
  }

  /// Get user engagement analytics
  Future<Map<String, dynamic>> getUserEngagementAnalytics() async {
    final analytics = await getComprehensiveAnalytics();
    return analytics[_userEngagement] ?? {};
  }

  /// Get trend analysis
  Future<Map<String, dynamic>> getTrendAnalysis() async {
    final analytics = await getComprehensiveAnalytics();
    return analytics[_trendAnalysis] ?? {};
  }

  /// Get predictive insights
  Future<Map<String, dynamic>> getPredictiveInsights() async {
    final analytics = await getComprehensiveAnalytics();
    return analytics[_predictiveInsights] ?? {};
  }

  /// Generate comprehensive analytics
  Future<Map<String, dynamic>> _generateComprehensiveAnalytics() async {
    await _progressService.initialize();

    final allProgress = await _progressService.getAllProgress();
    final allBookmarks = await _getAllBookmarks();

    return {
      _listeningBehavior: await _analyzeListeningBehavior(allProgress),
      _contentAnalytics: await _analyzeContent(allProgress, allBookmarks),
      _userEngagement: await _analyzeUserEngagement(allProgress, allBookmarks),
      _trendAnalysis: await _analyzeTrends(allProgress),
      _predictiveInsights:
          await _generatePredictiveInsights(allProgress, allBookmarks),
    };
  }

  /// Analyze listening behavior patterns
  Future<Map<String, dynamic>> _analyzeListeningBehavior(
      List<EpisodeProgress> progress) async {
    if (progress.isEmpty) return _getDefaultListeningBehavior();

    final totalEpisodes = progress.length;
    final completedEpisodes = progress.where((p) => p.isCompleted).length;
    final inProgressEpisodes =
        progress.where((p) => !p.isCompleted && p.currentPosition > 0).length;
    final abandonedEpisodes =
        progress.where((p) => !p.isCompleted && p.currentPosition == 0).length;

    // Calculate listening patterns
    final listeningSessions = _analyzeListeningSessions(progress);
    final timeOfDayPatterns = _analyzeTimeOfDayPatterns(progress);
    final durationPatterns = _analyzeDurationPatterns(progress);
    final completionPatterns = _analyzeCompletionPatterns(progress);

    return {
      'overview': {
        'total_episodes': totalEpisodes,
        'completed_episodes': completedEpisodes,
        'in_progress_episodes': inProgressEpisodes,
        'abandoned_episodes': abandonedEpisodes,
        'completion_rate': totalEpisodes > 0
            ? (completedEpisodes / totalEpisodes * 100).toStringAsFixed(1)
            : '0.0',
        'engagement_rate': totalEpisodes > 0
            ? ((completedEpisodes + inProgressEpisodes) / totalEpisodes * 100)
                .toStringAsFixed(1)
            : '0.0',
      },
      'listening_sessions': listeningSessions,
      'time_of_day_patterns': timeOfDayPatterns,
      'duration_patterns': durationPatterns,
      'completion_patterns': completionPatterns,
    };
  }

  /// Analyze content performance and popularity
  Future<Map<String, dynamic>> _analyzeContent(
      List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) async {
    if (progress.isEmpty) return _getDefaultContentAnalytics();

    // Group by podcast/series
    final podcastAnalytics = _analyzePodcastPerformance(progress);
    final episodeAnalytics = _analyzeEpisodePerformance(progress);
    final bookmarkAnalytics = _analyzeBookmarkPatterns(bookmarks);
    final contentCategories = _analyzeContentCategories(progress, bookmarks);

    return {
      'podcast_performance': podcastAnalytics,
      'episode_performance': episodeAnalytics,
      'bookmark_patterns': bookmarkAnalytics,
      'content_categories': contentCategories,
      'top_content': _getTopContent(progress, bookmarks),
    };
  }

  /// Analyze user engagement metrics
  Future<Map<String, dynamic>> _analyzeUserEngagement(
      List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) async {
    if (progress.isEmpty) return _getDefaultUserEngagement();

    final engagementMetrics = _calculateEngagementMetrics(progress);
    final interactionPatterns =
        _analyzeInteractionPatterns(progress, bookmarks);
    final retentionMetrics = _calculateRetentionMetrics(progress);
    final satisfactionIndicators =
        _calculateSatisfactionIndicators(progress, bookmarks);

    return {
      'engagement_metrics': engagementMetrics,
      'interaction_patterns': interactionPatterns,
      'retention_metrics': retentionMetrics,
      'satisfaction_indicators': satisfactionIndicators,
      'engagement_score': _calculateOverallEngagementScore(progress, bookmarks),
    };
  }

  /// Analyze trends over time
  Future<Map<String, dynamic>> _analyzeTrends(
      List<EpisodeProgress> progress) async {
    if (progress.isEmpty) return _getDefaultTrendAnalysis();

    final weeklyTrends = _analyzeWeeklyTrends(progress);
    final monthlyTrends = _analyzeMonthlyTrends(progress);
    final seasonalPatterns = _analyzeSeasonalPatterns(progress);
    final growthMetrics = _calculateGrowthMetrics(progress);

    return {
      'weekly_trends': weeklyTrends,
      'monthly_trends': monthlyTrends,
      'seasonal_patterns': seasonalPatterns,
      'growth_metrics': growthMetrics,
      'trend_direction': _determineTrendDirection(progress),
    };
  }

  /// Generate predictive insights
  Future<Map<String, dynamic>> _generatePredictiveInsights(
      List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) async {
    if (progress.isEmpty) return _getDefaultPredictiveInsights();

    final listeningPredictions = _predictListeningBehavior(progress);
    final contentRecommendations =
        _generateContentRecommendations(progress, bookmarks);
    final engagementForecasts = _forecastEngagement(progress);
    final optimizationSuggestions =
        _generateOptimizationSuggestions(progress, bookmarks);

    return {
      'listening_predictions': listeningPredictions,
      'content_recommendations': contentRecommendations,
      'engagement_forecasts': engagementForecasts,
      'optimization_suggestions': optimizationSuggestions,
      'next_best_actions': _suggestNextBestActions(progress, bookmarks),
    };
  }

  /// Analyze listening sessions
  Map<String, dynamic> _analyzeListeningSessions(
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
          'timestamp': episode.lastPlayedAt!.toIso8601String(),
          'session_type': isCompleted
              ? 'full'
              : sessionDuration > 300
                  ? 'substantial'
                  : 'brief',
        });
      }
    }

    // Calculate session statistics
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
      'recent_sessions': sessions.take(10).toList(),
    };
  }

  /// Analyze time of day patterns
  Map<String, dynamic> _analyzeTimeOfDayPatterns(
      List<EpisodeProgress> progress) {
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
      'peak_listening_hour': _findPeakListeningHour(progress),
    };
  }

  /// Analyze duration patterns
  Map<String, dynamic> _analyzeDurationPatterns(
      List<EpisodeProgress> progress) {
    final durations = progress.map((p) => p.currentPosition).toList();
    if (durations.isEmpty) return {};

    durations.sort();
    final totalDuration = durations.reduce((a, b) => a + b);
    final averageDuration = totalDuration / durations.length;
    final medianDuration = durations[durations.length ~/ 2];

    return {
      'total_listening_time': totalDuration,
      'average_episode_duration': averageDuration.round(),
      'median_episode_duration': medianDuration,
      'duration_distribution': {
        'short': durations.where((d) => d < 300).length, // < 5 min
        'medium':
            durations.where((d) => d >= 300 && d < 1800).length, // 5-30 min
        'long': durations.where((d) => d >= 1800).length, // > 30 min
      },
      'longest_session': durations.last,
      'shortest_session': durations.first,
    };
  }

  /// Analyze completion patterns
  Map<String, dynamic> _analyzeCompletionPatterns(
      List<EpisodeProgress> progress) {
    final completed = progress.where((p) => p.isCompleted).length;
    final total = progress.length;
    final completionRate = total > 0 ? (completed / total * 100) : 0;

    // Analyze partial completions
    final partialCompletions =
        progress.where((p) => !p.isCompleted && p.currentPosition > 0).toList();
    final partialRates = <String, int>{};

    for (final episode in partialCompletions) {
      final percentage =
          (episode.currentPosition / (episode.totalDuration ?? 1) * 100)
              .round();
      if (percentage < 25) {
        partialRates['0-25%'] = (partialRates['0-25%'] ?? 0) + 1;
      } else if (percentage < 50) {
        partialRates['25-50%'] = (partialRates['25-50%'] ?? 0) + 1;
      } else if (percentage < 75) {
        partialRates['50-75%'] = (partialRates['50-75%'] ?? 0) + 1;
      } else {
        partialRates['75-99%'] = (partialRates['75-99%'] ?? 0) + 1;
      }
    }

    return {
      'completion_rate': completionRate.toStringAsFixed(1),
      'completed_episodes': completed,
      'total_episodes': total,
      'partial_completion_distribution': partialRates,
      'abandonment_rate': total > 0
          ? ((total - completed) / total * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Analyze podcast performance
  Map<String, dynamic> _analyzePodcastPerformance(
      List<EpisodeProgress> progress) {
    // Group by podcast ID (simplified - in real app you'd have podcast metadata)
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
        'engagement_score': _calculatePodcastEngagementScore(episodes),
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

  /// Analyze bookmark patterns
  Map<String, dynamic> _analyzeBookmarkPatterns(
      List<EpisodeBookmark> bookmarks) {
    if (bookmarks.isEmpty) return {};

    final totalBookmarks = bookmarks.length;
    final bookmarksWithNotes =
        bookmarks.where((b) => b.notes?.isNotEmpty == true).length;
    final bookmarksByCategory = <String, int>{};
    final bookmarksByColor = <String, int>{};

    for (final bookmark in bookmarks) {
      if (bookmark.category != null) {
        bookmarksByCategory[bookmark.category!] =
            (bookmarksByCategory[bookmark.category!] ?? 0) + 1;
      }
      bookmarksByColor[bookmark.color] =
          (bookmarksByColor[bookmark.color] ?? 0) + 1;
    }

    return {
      'total_bookmarks': totalBookmarks,
      'bookmarks_with_notes': bookmarksWithNotes,
      'notes_percentage': totalBookmarks > 0
          ? (bookmarksWithNotes / totalBookmarks * 100).toStringAsFixed(1)
          : '0.0',
      'by_category': bookmarksByCategory,
      'by_color': bookmarksByColor,
      'average_bookmarks_per_episode':
          _calculateAverageBookmarksPerEpisode(bookmarks),
    };
  }

  /// Get all bookmarks
  Future<List<EpisodeBookmark>> _getAllBookmarks() async {
    try {
      // This would need to be implemented in EpisodeProgressService
      // For now, return empty list
      return [];
    } catch (e) {
      debugPrint('Error getting bookmarks: $e');
      return [];
    }
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
      'engagement_intensity': _calculateEngagementIntensity(progress),
    };
  }

  /// Calculate engagement intensity
  double _calculateEngagementIntensity(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;

    double totalIntensity = 0.0;
    for (final episode in progress) {
      final duration = episode.totalDuration ?? 1;
      final position = episode.currentPosition;
      final intensity = position / duration;
      totalIntensity += intensity;
    }

    return totalIntensity / progress.length;
  }

  /// Calculate overall engagement score
  double _calculateOverallEngagementScore(
      List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) {
    if (progress.isEmpty) return 0.0;

    final completionScore =
        progress.where((p) => p.isCompleted).length / progress.length * 40;
    final listeningScore = _calculateListeningDepthScore(progress) * 30;
    final bookmarkScore = bookmarks.isNotEmpty
        ? (bookmarks.length / progress.length * 10).clamp(0.0, 10.0)
        : 0.0;
    final consistencyScore = _calculateConsistencyScore(progress) * 20;

    return (completionScore + listeningScore + bookmarkScore + consistencyScore)
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
    // Lower gap = higher consistency
    return (1.0 / (1.0 + averageGap / 24.0)).clamp(0.0, 1.0);
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidity;
  }

  /// Get default analytics when data is unavailable
  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      _listeningBehavior: _getDefaultListeningBehavior(),
      _contentAnalytics: _getDefaultContentAnalytics(),
      _userEngagement: _getDefaultUserEngagement(),
      _trendAnalysis: _getDefaultTrendAnalysis(),
      _predictiveInsights: _getDefaultPredictiveInsights(),
    };
  }

  /// Get default listening behavior
  Map<String, dynamic> _getDefaultListeningBehavior() {
    return {
      'overview': {
        'total_episodes': 0,
        'completed_episodes': 0,
        'in_progress_episodes': 0,
        'abandoned_episodes': 0,
        'completion_rate': '0.0',
        'engagement_rate': '0.0',
      },
      'listening_sessions': {
        'total_sessions': 0,
        'average_session_duration': 0
      },
      'time_of_day_patterns': {
        'total_sessions': 0,
        'preferred_time_slot': 'none'
      },
      'duration_patterns': {
        'total_listening_time': 0,
        'average_episode_duration': 0
      },
      'completion_patterns': {
        'completion_rate': '0.0',
        'completed_episodes': 0
      },
    };
  }

  /// Get default content analytics
  Map<String, dynamic> _getDefaultContentAnalytics() {
    return {
      'podcast_performance': {},
      'episode_performance': {},
      'bookmark_patterns': {'total_bookmarks': 0, 'notes_percentage': '0.0'},
      'content_categories': {},
      'top_content': [],
    };
  }

  /// Get default user engagement
  Map<String, dynamic> _getDefaultUserEngagement() {
    return {
      'engagement_metrics': {
        'total_listening_time': 0,
        'episode_completion_rate': '0.0'
      },
      'interaction_patterns': {},
      'retention_metrics': {},
      'satisfaction_indicators': {},
      'engagement_score': 0.0,
    };
  }

  /// Get default trend analysis
  Map<String, dynamic> _getDefaultTrendAnalysis() {
    return {
      'weekly_trends': {},
      'monthly_trends': {},
      'seasonal_patterns': {},
      'growth_metrics': {},
      'trend_direction': 'stable',
    };
  }

  /// Get default predictive insights
  Map<String, dynamic> _getDefaultPredictiveInsights() {
    return {
      'listening_predictions': {},
      'content_recommendations': [],
      'engagement_forecasts': {},
      'optimization_suggestions': [],
      'next_best_actions': [],
    };
  }

  /// Helper methods (implemented as placeholders)
  Map<String, dynamic> _analyzeContentCategories(
          List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) =>
      {};
  List<Map<String, dynamic>> _getTopContent(
          List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) =>
      [];
  Map<String, dynamic> _analyzeInteractionPatterns(
          List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) =>
      {};
  Map<String, dynamic> _calculateRetentionMetrics(
          List<EpisodeProgress> progress) =>
      {};
  Map<String, dynamic> _calculateSatisfactionIndicators(
          List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) =>
      {};
  Map<String, dynamic> _analyzeWeeklyTrends(List<EpisodeProgress> progress) =>
      {};
  Map<String, dynamic> _analyzeMonthlyTrends(List<EpisodeProgress> progress) =>
      {};
  Map<String, dynamic> _analyzeSeasonalPatterns(
          List<EpisodeProgress> progress) =>
      {};
  Map<String, dynamic> _calculateGrowthMetrics(
          List<EpisodeProgress> progress) =>
      {};
  String _determineTrendDirection(List<EpisodeProgress> progress) => 'stable';
  Map<String, dynamic> _predictListeningBehavior(
          List<EpisodeProgress> progress) =>
      {};
  List<Map<String, dynamic>> _generateContentRecommendations(
          List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) =>
      [];
  Map<String, dynamic> _forecastEngagement(List<EpisodeProgress> progress) =>
      {};
  List<String> _generateOptimizationSuggestions(
          List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) =>
      [];
  List<String> _suggestNextBestActions(
          List<EpisodeProgress> progress, List<EpisodeBookmark> bookmarks) =>
      [];
  int _findPeakListeningHour(List<EpisodeProgress> progress) => 0;
  double _calculateAverageBookmarksPerEpisode(
          List<EpisodeBookmark> bookmarks) =>
      0.0;
  double _calculatePodcastEngagementScore(List<EpisodeProgress> episodes) =>
      0.0;
  String _getEngagementLevel(int completionPercentage) => 'low';

  /// Clear analytics cache
  void clearCache() {
    _analyticsCache.clear();
    _lastCacheUpdate = null;

    if (kDebugMode) {
      debugPrint('🧹 Analytics cache cleared');
    }
  }

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}

