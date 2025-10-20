import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Simplified performance monitoring service for tracking app performance metrics
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  static const String _performanceDataKey = 'performance_data';
  static const String _apiResponseTimeKey = 'api_response_time';
  static const String _cacheHitRateKey = 'cache_hit_rate';
  static const String _listRenderingKey = 'list_rendering';

  final Map<String, List<double>> _metrics = {};
  final Map<String, Stopwatch> _stopwatches = {};

  bool _isMonitoring = false;
  Timer? _monitoringTimer;

  // Performance thresholds
  static const int _apiResponseThresholdMs = 5000; // 5 seconds
  static const int _listRenderingThresholdMs = 100; // 100ms
  static const double _cacheHitRateThreshold = 0.7; // 70%

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Periodic metrics collection
    _monitoringTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _collectMetrics();
    });

    debugPrint('🚀 Performance monitoring started');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;

    _monitoringTimer?.cancel();
    _stopwatches.clear();

    debugPrint('🛑 Performance monitoring stopped');
  }

  /// Start API response time measurement
  void startApiTimer(String endpoint) {
    if (!_isMonitoring) return;

    _stopwatches[endpoint] = Stopwatch()..start();
  }

  /// Stop API response time measurement
  void stopApiTimer(String endpoint) {
    if (!_isMonitoring) return;

    final stopwatch = _stopwatches[endpoint];
    if (stopwatch != null) {
      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds.toDouble();
      _addMetric('apiResponseTime', responseTime);

      if (responseTime > _apiResponseThresholdMs) {
        _logPerformanceIssue(
            'Slow API response: $endpoint took ${responseTime}ms');
      }

      _stopwatches.remove(endpoint);
    }
  }

  /// Track cache hit rate
  void trackCacheHit(bool isHit) {
    if (!_isMonitoring) return;

    _addMetric('cacheHitRate', isHit ? 1.0 : 0.0);
  }

  /// Track list rendering performance
  void trackListRendering(String listName, int itemCount, Duration renderTime) {
    if (!_isMonitoring) return;

    final itemsPerSecond = itemCount / (renderTime.inMilliseconds / 1000);
    _addMetric('listRendering_$listName', itemsPerSecond);

    if (renderTime.inMilliseconds > _listRenderingThresholdMs) {
      _logPerformanceIssue(
          'Slow list rendering: $listName took ${renderTime.inMilliseconds}ms for $itemCount items');
    }
  }

  /// Track navigation performance
  void trackNavigation(String routeName, Duration navigationTime) {
    if (!_isMonitoring) return;

    _addMetric('navigation', navigationTime.inMilliseconds.toDouble());

    if (navigationTime.inMilliseconds > 500) {
      _logPerformanceIssue(
          'Slow navigation: $routeName took ${navigationTime.inMilliseconds}ms');
    }
  }

  /// Track widget build performance
  void trackWidgetBuild(String widgetName, Duration buildTime) {
    if (!_isMonitoring) return;

    _addMetric('widgetBuild_$widgetName', buildTime.inMilliseconds.toDouble());

    if (buildTime.inMilliseconds > 50) {
      _logPerformanceIssue(
          'Slow widget build: $widgetName took ${buildTime.inMilliseconds}ms');
    }
  }

  /// Track memory usage (simplified estimation)
  void trackMemoryUsage() {
    if (!_isMonitoring) return;

    // This is a simplified memory tracking
    // In production, you might want to use platform-specific methods
    final estimatedMemory = _estimateMemoryUsage();
    _addMetric('memoryUsage', estimatedMemory);

    if (estimatedMemory > 100) {
      // 100MB threshold
      _logPerformanceIssue(
          'High memory usage: ${estimatedMemory.toStringAsFixed(1)} MB');
    }
  }

  /// Estimate memory usage (simplified)
  double _estimateMemoryUsage() {
    // This is a placeholder - in real implementation you'd use
    // platform-specific memory APIs or Flutter's memory tracking
    return 50.0 + (DateTime.now().second % 30); // Simulate 50-80 MB
  }

  /// Add metric to tracking
  void _addMetric(String metricName, double value) {
    if (!_metrics.containsKey(metricName)) {
      _metrics[metricName] = [];
    }

    _metrics[metricName]!.add(value);

    // Keep only last 500 values to prevent memory bloat
    if (_metrics[metricName]!.length > 500) {
      _metrics[metricName]!.removeRange(0, _metrics[metricName]!.length - 500);
    }
  }

  /// Log performance issues
  void _logPerformanceIssue(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ Performance: $message');
    }
  }

  /// Collect periodic metrics
  void _collectMetrics() {
    _saveMetrics();
    _analyzePerformance();
  }

  /// Save metrics to persistent storage
  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = <String, dynamic>{};

      _metrics.forEach((key, values) {
        if (values.isNotEmpty) {
          metricsJson[key] = {
            'count': values.length,
            'average': values.reduce((a, b) => a + b) / values.length,
            'min': values.reduce((a, b) => a < b ? a : b),
            'max': values.reduce((a, b) => a > b ? a : b),
            'last_value': values.last,
            'last_updated': DateTime.now().toIso8601String(),
          };
        }
      });

      await prefs.setString(_performanceDataKey, metricsJson.toString());
    } catch (e) {
      debugPrint('Error saving performance metrics: $e');
    }
  }

  /// Analyze performance and generate insights
  void _analyzePerformance() {
    final insights = <String, dynamic>{};

    // API response time analysis
    if (_metrics.containsKey('apiResponseTime')) {
      final responseTimes = _metrics['apiResponseTime']!;
      final avgResponseTime =
          responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      insights['apiResponseTime'] = {
        'average': avgResponseTime,
        'status': avgResponseTime <= _apiResponseThresholdMs ? 'Good' : 'Slow',
        'recommendation': avgResponseTime > _apiResponseThresholdMs
            ? 'Consider implementing request caching and optimizing API calls'
            : 'API response times are within acceptable range',
      };
    }

    // Cache hit rate analysis
    if (_metrics.containsKey('cacheHitRate')) {
      final hitRates = _metrics['cacheHitRate']!;
      final avgHitRate = hitRates.reduce((a, b) => a + b) / hitRates.length;
      insights['cacheHitRate'] = {
        'average': avgHitRate,
        'status': avgHitRate >= _cacheHitRateThreshold ? 'Good' : 'Low',
        'recommendation': avgHitRate < _cacheHitRateThreshold
            ? 'Consider improving cache strategies and preloading frequently accessed data'
            : 'Cache hit rate is good',
      };
    }

    // Memory usage analysis
    if (_metrics.containsKey('memoryUsage')) {
      final memoryUsage = _metrics['memoryUsage']!;
      final avgMemory =
          memoryUsage.reduce((a, b) => a + b) / memoryUsage.length;
      insights['memoryUsage'] = {
        'average': avgMemory,
        'status': avgMemory <= 100 ? 'Good' : 'High',
        'recommendation': avgMemory > 100
            ? 'Consider implementing memory cleanup and reducing cache sizes'
            : 'Memory usage is within acceptable range',
      };
    }

    _saveInsights(insights);
  }

  /// Save performance insights
  Future<void> _saveInsights(Map<String, dynamic> insights) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('performance_insights', insights.toString());
    } catch (e) {
      debugPrint('Error saving performance insights: $e');
    }
  }

  /// Get performance insights
  Future<Map<String, dynamic>> getPerformanceInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final insightsString = prefs.getString('performance_insights');
      if (insightsString != null) {
        return {'status': 'Available', 'data': insightsString};
      }
    } catch (e) {
      debugPrint('Error loading performance insights: $e');
    }
    return {'status': 'Not available'};
  }

  /// Get current metrics
  Map<String, List<double>> getCurrentMetrics() {
    return Map.unmodifiable(_metrics);
  }

  /// Get metric summary
  Map<String, dynamic> getMetricSummary(String metricName) {
    if (!_metrics.containsKey(metricName) || _metrics[metricName]!.isEmpty) {
      return {'error': 'Metric not found or empty'};
    }

    final values = _metrics[metricName]!;
    return {
      'name': metricName,
      'count': values.length,
      'average': values.reduce((a, b) => a + b) / values.length,
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
      'last_value': values.last,
      'trend': _calculateTrend(values),
    };
  }

  /// Calculate trend (simplified)
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'Insufficient data';

    final recent = values.take(10).toList();
    final older = values.take(values.length - 10).toList();

    if (recent.isEmpty || older.isEmpty) return 'Insufficient data';

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    if (recentAvg > olderAvg * 1.1) return 'Improving';
    if (recentAvg < olderAvg * 0.9) return 'Declining';
    return 'Stable';
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _saveMetrics();
  }

  /// Get performance report
  Future<Map<String, dynamic>> getPerformanceReport() async {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'monitoring_active': _isMonitoring,
      'metrics_count': _metrics.length,
      'insights': await getPerformanceInsights(),
    };

    // Add metric summaries
    final summaries = <String, dynamic>{};
    _metrics.keys.forEach((key) {
      summaries[key] = getMetricSummary(key);
    });
    report['metric_summaries'] = summaries;

    return report;
  }

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'is_active': _isMonitoring,
      'metrics_tracked': _metrics.keys.toList(),
      'active_timers': _stopwatches.keys.toList(),
      'last_collection': _monitoringTimer != null ? 'Active' : 'Inactive',
    };
  }
}
