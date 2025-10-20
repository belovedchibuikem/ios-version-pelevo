import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/episode_progress.dart';
import '../services/episode_progress_service.dart';

/// Enhanced Analytics Service that provides comprehensive insights
/// based on episode progress data (not play history)
class EnhancedAnalyticsService {
  final EpisodeProgressService _progressService = EpisodeProgressService();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Cache for analytics data
  Map<String, dynamic> _analyticsCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidity = Duration(minutes: 15);

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  /// Get comprehensive analytics data
  Future<Map<String, dynamic>> getComprehensiveAnalytics({
    String period = 'week',
    bool forceRefresh = false,
  }) async {
    await initialize();

    // Check cache validity
    if (!forceRefresh && _isCacheValid()) {
      return _analyticsCache;
    }

    try {
      final allProgress = await _progressService.getAllProgress();
      final analytics = await _generateAnalytics(allProgress, period);

      // Update cache
      _analyticsCache = analytics;
      _lastCacheUpdate = DateTime.now();

      // Save to local storage
      await _saveAnalyticsToCache(analytics);

      return analytics;
    } catch (e) {
      debugPrint('Error generating analytics: $e');
      // Return cached data if available
      return _isCacheValid() ? _analyticsCache : _getDefaultAnalytics();
    }
  }

  /// Generate analytics from episode progress data
  Future<Map<String, dynamic>> _generateAnalytics(
    List<EpisodeProgress> allProgress,
    String period,
  ) async {
    final now = DateTime.now();
    final periodStart = _getPeriodStart(now, period);

    // Filter progress by period
    final periodProgress = allProgress.where((progress) {
      final lastPlayed = progress.lastPlayedAt;
      return lastPlayed != null && lastPlayed.isAfter(periodStart);
    }).toList();

    // Calculate core metrics
    final coreMetrics = _calculateCoreMetrics(periodProgress);

    // Calculate detailed insights
    final insights = await _calculateDetailedInsights(periodProgress, period);

    // Calculate trends and patterns
    final trends = _calculateTrends(periodProgress, period);

    // Calculate achievements and milestones
    final achievements = _calculateAchievements(allProgress);

    // Calculate performance metrics
    final performance = _calculatePerformanceMetrics(periodProgress);

    return {
      'overview': coreMetrics,
      'insights': insights,
      'trends': trends,
      'achievements': achievements,
      'performance': performance,
      'period': period,
      'generated_at': now.toIso8601String(),
    };
  }

  /// Calculate core listening metrics
  Map<String, dynamic> _calculateCoreMetrics(List<EpisodeProgress> progress) {
    if (progress.isEmpty) {
      return {
        'total_listening_time': 0.0,
        'episodes_completed': 0,
        'total_episodes': 0,
        'episodes_in_progress': 0,
        'avg_session_length': 0.0,
        'streak_days': 0,
        'completion_rate': 0.0,
        'total_duration': 0,
        'listened_duration': 0,
      };
    }

    // Calculate total listening time (in minutes)
    double totalListeningTime = 0.0;
    int totalDuration = 0;
    int listenedDuration = 0;
    int completedEpisodes = 0;
    int inProgressEpisodes = 0;

    for (final p in progress) {
      final duration = p.totalDuration;
      final position = p.currentPosition;

      if (duration > 0) {
        totalDuration += duration;
        listenedDuration += position;

        if (p.isCompleted) {
          completedEpisodes++;
          totalListeningTime += duration / 60.0; // Convert to minutes
        } else if (position > 0) {
          inProgressEpisodes++;
          totalListeningTime += position / 60.0; // Convert to minutes
        }
      }
    }

    // Calculate completion rate
    final completionRate =
        totalDuration > 0 ? (listenedDuration / totalDuration) * 100 : 0.0;

    // Calculate average session length
    final avgSessionLength =
        progress.isNotEmpty ? totalListeningTime / progress.length : 0.0;

    // Calculate streak days
    final streakDays = _calculateStreakDays(progress);

    return {
      'total_listening_time': totalListeningTime,
      'episodes_completed': completedEpisodes,
      'total_episodes': progress.length,
      'episodes_in_progress': inProgressEpisodes,
      'avg_session_length': avgSessionLength,
      'streak_days': streakDays,
      'completion_rate': completionRate,
      'total_duration': totalDuration,
      'listened_duration': listenedDuration,
    };
  }

  // Helper methods
  DateTime _getPeriodStart(DateTime now, String period) {
    switch (period) {
      case 'week':
        return now.subtract(Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'year':
        return DateTime(now.year - 1, now.month, now.day);
      case 'all_time':
        return DateTime(1900);
      default:
        return now.subtract(Duration(days: 7));
    }
  }

  int _calculateStreakDays(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0;

    final sortedProgress = progress
        .where((p) => p.lastPlayedAt != null)
        .toList()
      ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));

    if (sortedProgress.isEmpty) return 0;

    int streak = 0;
    DateTime? currentDate;

    for (int i = 0; i < sortedProgress.length; i++) {
      final progressDate = DateTime(
        sortedProgress[i].lastPlayedAt!.year,
        sortedProgress[i].lastPlayedAt!.month,
        sortedProgress[i].lastPlayedAt!.day,
      );

      if (currentDate == null) {
        currentDate = progressDate;
        streak = 1;
      } else {
        final difference = currentDate.difference(progressDate).inDays;
        if (difference == 1) {
          streak++;
          currentDate = progressDate;
        } else if (difference > 1) {
          break;
        }
      }
    }

    return streak;
  }

  // Placeholder methods for other calculations
  Future<Map<String, dynamic>> _calculateDetailedInsights(
    List<EpisodeProgress> progress,
    String period,
  ) async {
    return {
      'genre_distribution': [],
      'listening_patterns': {
        'completion_rate': _calculateCompletionRate(progress),
        'avg_session_length': _calculateAverageSessionLength(progress),
        'favorite_genre': 'Unknown',
        'most_active_day': 'Unknown',
        'most_active_time': 'Unknown',
      },
    };
  }

  Map<String, dynamic> _calculateTrends(
    List<EpisodeProgress> progress,
    String period,
  ) {
    return {
      'weekly_activity': _groupByWeek(progress),
      'daily_activity': _groupByDay(progress),
      'hourly_activity': _groupByHour(progress),
      'growth_rate': 0.0,
      'consistency_score': 0.0,
    };
  }

  Map<String, dynamic> _calculateAchievements(
      List<EpisodeProgress> allProgress) {
    final achievements = <Map<String, dynamic>>[];

    final totalMinutes = allProgress.fold<double>(0.0, (sum, p) {
      return sum + (p.currentPosition / 60.0);
    });

    if (totalMinutes >= 1000) {
      achievements.add({
        'title': 'Dedicated Listener',
        'description': 'Listened to 1000+ minutes of content',
        'icon': '🎧',
        'unlocked_at': DateTime.now().toIso8601String(),
      });
    }

    return {
      'achievements': achievements,
      'total_achievements': achievements.length,
    };
  }

  Map<String, dynamic> _calculatePerformanceMetrics(
      List<EpisodeProgress> progress) {
    return {
      'efficiency_score': _calculateEfficiencyScore(progress),
      'retention_rate': _calculateRetentionRate(progress),
      'engagement_level': 'Medium',
    };
  }

  double _calculateCompletionRate(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;
    final completed = progress.where((p) => p.isCompleted).length;
    return (completed / progress.length) * 100;
  }

  double _calculateAverageSessionLength(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;
    final totalMinutes = progress.fold<double>(0.0, (sum, p) {
      return sum + (p.currentPosition / 60.0);
    });
    return totalMinutes / progress.length;
  }

  List<Map<String, dynamic>> _groupByWeek(List<EpisodeProgress> progress) {
    final weekData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date);

      final dayProgress = progress.where((p) {
        if (p.lastPlayedAt == null) return false;
        return _isSameDay(p.lastPlayedAt!, date);
      }).toList();

      final totalMinutes = dayProgress.fold<double>(0.0, (sum, p) {
        return sum + (p.currentPosition / 60.0);
      });

      weekData.add({
        'day': dayName,
        'minutes': totalMinutes,
        'episodes': dayProgress.length,
      });
    }

    return weekData;
  }

  List<Map<String, dynamic>> _groupByDay(List<EpisodeProgress> progress) {
    final dayData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.month}/${date.day}';

      final dayProgress = progress.where((p) {
        if (p.lastPlayedAt == null) return false;
        return _isSameDay(p.lastPlayedAt!, date);
      }).toList();

      final totalMinutes = dayProgress.fold<double>(0.0, (sum, p) {
        return sum + (p.currentPosition / 60.0);
      });

      dayData.add({
        'date': dateStr,
        'minutes': totalMinutes,
        'episodes': dayProgress.length,
      });
    }

    return dayData;
  }

  List<Map<String, dynamic>> _groupByHour(List<EpisodeProgress> progress) {
    final hourData = <Map<String, dynamic>>[];

    for (int hour = 0; hour < 24; hour++) {
      final hourProgress = progress.where((p) {
        if (p.lastPlayedAt == null) return false;
        return p.lastPlayedAt!.hour == hour;
      }).toList();

      final totalMinutes = hourProgress.fold<double>(0.0, (sum, p) {
        return sum + (p.currentPosition / 60.0);
      });

      hourData.add({
        'hour': hour,
        'minutes': totalMinutes,
        'episodes': hourProgress.length,
        'label': '${hour}:00',
      });
    }

    return hourData;
  }

  double _calculateEfficiencyScore(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;
    final completionRate = _calculateCompletionRate(progress);
    return completionRate;
  }

  double _calculateRetentionRate(List<EpisodeProgress> progress) {
    if (progress.isEmpty) return 0.0;
    final completed = progress.where((p) => p.isCompleted).length;
    final started = progress.where((p) => p.currentPosition > 0).length;
    return started > 0 ? (completed / started) * 100 : 0.0;
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidity;
  }

  Future<void> _saveAnalyticsToCache(Map<String, dynamic> analytics) async {
    try {
      await _prefs.setString('analytics_cache', jsonEncode(analytics));
      await _prefs.setString(
          'analytics_cache_timestamp', _lastCacheUpdate!.toIso8601String());
    } catch (e) {
      debugPrint('Error saving analytics cache: $e');
    }
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'overview': {
        'total_listening_time': 0.0,
        'episodes_completed': 0,
        'total_episodes': 0,
        'episodes_in_progress': 0,
        'avg_session_length': 0.0,
        'streak_days': 0,
        'completion_rate': 0.0,
      },
      'insights': {
        'listening_patterns': {
          'completion_rate': 0.0,
          'avg_session_length': 0.0,
          'favorite_genre': 'Unknown',
          'most_active_day': 'Unknown',
          'most_active_time': 'Unknown',
        },
      },
      'trends': {
        'weekly_activity': [],
        'daily_activity': [],
        'hourly_activity': [],
      },
      'achievements': {
        'achievements': [],
        'total_achievements': 0,
      },
      'performance': {
        'efficiency_score': 0.0,
        'retention_rate': 0.0,
        'engagement_level': 'Low',
      },
    };
  }

  /// Clear analytics cache
  Future<void> clearCache() async {
    _analyticsCache.clear();
    _lastCacheUpdate = null;
    await _prefs.remove('analytics_cache');
    await _prefs.remove('analytics_cache_timestamp');
  }
}
