import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Service for monitoring and optimizing app performance
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  // Performance metrics
  final Map<String, List<Duration>> _operationTimings = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, List<double>> _memoryUsage = {};

  // Performance thresholds
  static const Duration _slowOperationThreshold = Duration(milliseconds: 500);
  static const Duration _verySlowOperationThreshold = Duration(seconds: 2);
  static const int _maxMemoryUsageMB = 100;

  // Monitoring state
  bool _isMonitoring = false;
  Timer? _memoryCheckTimer;
  final List<String> _performanceWarnings = [];

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _startMemoryMonitoring();

    if (kDebugMode) {
      developer.log('🚀 Performance monitoring started',
          name: 'PerformanceMonitor');
    }
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _memoryCheckTimer?.cancel();

    if (kDebugMode) {
      developer.log('⏹️ Performance monitoring stopped',
          name: 'PerformanceMonitor');
    }
  }

  /// Monitor operation performance
  Future<T> monitorOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
    String? category,
  }) async {
    if (!_isMonitoring) {
      return await operation();
    }

    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();

    try {
      final result = await operation();
      stopwatch.stop();

      _recordOperationTiming(operationName, stopwatch.elapsed, category);
      _checkPerformanceThresholds(operationName, stopwatch.elapsed);

      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperationError(operationName, stopwatch.elapsed, e.toString());
      rethrow;
    }
  }

  /// Monitor widget build performance
  Widget monitorWidgetBuild({
    required String widgetName,
    required Widget Function() builder,
    String? category,
  }) {
    if (!_isMonitoring) {
      return builder();
    }

    final stopwatch = Stopwatch()..start();
    final widget = builder();
    stopwatch.stop();

    _recordOperationTiming(
        'Widget Build: $widgetName', stopwatch.elapsed, category);
    _checkPerformanceThresholds('Widget Build: $widgetName', stopwatch.elapsed);

    return widget;
  }

  /// Record operation timing
  void _recordOperationTiming(
      String operationName, Duration duration, String? category) {
    final key = category != null ? '$category:$operationName' : operationName;

    if (!_operationTimings.containsKey(key)) {
      _operationTimings[key] = [];
      _operationCounts[key] = 0;
    }

    _operationTimings[key]!.add(duration);
    _operationCounts[key] = _operationCounts[key]! + 1;

    // Keep only last 100 timings to prevent memory bloat
    if (_operationTimings[key]!.length > 100) {
      _operationTimings[key] = _operationTimings[key]!.skip(100).toList();
    }
  }

  /// Record operation error
  void _recordOperationError(
      String operationName, Duration duration, String error) {
    if (kDebugMode) {
      developer.log(
        '❌ Operation failed: $operationName after ${duration.inMilliseconds}ms - $error',
        name: 'PerformanceMonitor',
        error: error,
      );
    }
  }

  /// Check performance thresholds
  void _checkPerformanceThresholds(String operationName, Duration duration) {
    if (duration > _verySlowOperationThreshold) {
      _addPerformanceWarning(
        'Very Slow Operation: $operationName took ${duration.inMilliseconds}ms',
        'critical',
      );
    } else if (duration > _slowOperationThreshold) {
      _addPerformanceWarning(
        'Slow Operation: $operationName took ${duration.inMilliseconds}ms',
        'warning',
      );
    }
  }

  /// Add performance warning
  void _addPerformanceWarning(String message, String level) {
    final warning = '[$level.toUpperCase()] $message';
    _performanceWarnings.add(warning);

    if (kDebugMode) {
      developer.log(warning, name: 'PerformanceMonitor');
    }

    // Keep only last 50 warnings
    if (_performanceWarnings.length > 50) {
      _performanceWarnings.removeRange(0, _performanceWarnings.length - 50);
    }
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkMemoryUsage();
    });
  }

  /// Check memory usage
  void _checkMemoryUsage() {
    // This is a simplified memory check
    // In a real app, you might use platform channels to get actual memory usage
    final estimatedMemory = _estimateMemoryUsage();

    if (estimatedMemory > _maxMemoryUsageMB) {
      _addPerformanceWarning(
        'High memory usage: ${estimatedMemory.toStringAsFixed(1)}MB',
        'warning',
      );
    }

    _memoryUsage['current'] = [estimatedMemory];
  }

  /// Estimate memory usage based on stored data
  double _estimateMemoryUsage() {
    double totalMemory = 0;

    // Estimate memory from operation timings
    for (final timings in _operationTimings.values) {
      totalMemory += timings.length * 8; // 8 bytes per Duration
    }

    // Estimate memory from operation counts
    totalMemory += _operationCounts.length * 16; // 16 bytes per count entry

    // Convert to MB
    return totalMemory / (1024 * 1024);
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};

    for (final entry in _operationTimings.entries) {
      final timings = entry.value;
      if (timings.isEmpty) continue;

      final sortedTimings = List<Duration>.from(timings)..sort();
      final count = timings.length;
      final total = timings.fold<Duration>(
        Duration.zero,
        (sum, timing) => sum + timing,
      );

      stats[entry.key] = {
        'count': count,
        'total_time_ms': total.inMilliseconds,
        'average_time_ms': (total.inMilliseconds / count).round(),
        'min_time_ms': sortedTimings.first.inMilliseconds,
        'max_time_ms': sortedTimings.last.inMilliseconds,
        'median_time_ms': sortedTimings[count ~/ 2].inMilliseconds,
        'p95_time_ms': sortedTimings[(count * 0.95).round()].inMilliseconds,
      };
    }

    return stats;
  }

  /// Get performance warnings
  List<String> getPerformanceWarnings() {
    return List.unmodifiable(_performanceWarnings);
  }

  /// Clear performance data
  void clearPerformanceData() {
    _operationTimings.clear();
    _operationCounts.clear();
    _performanceWarnings.clear();

    if (kDebugMode) {
      developer.log('🧹 Performance data cleared', name: 'PerformanceMonitor');
    }
  }

  /// Get memory usage
  Map<String, dynamic> getMemoryUsage() {
    return {
      'current_mb': _estimateMemoryUsage(),
      'max_threshold_mb': _maxMemoryUsageMB,
      'is_healthy': _estimateMemoryUsage() <= _maxMemoryUsageMB,
    };
  }

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get operation count for a specific operation
  int getOperationCount(String operationName) {
    return _operationCounts[operationName] ?? 0;
  }

  /// Get average time for a specific operation
  Duration getAverageOperationTime(String operationName) {
    final timings = _operationTimings[operationName];
    if (timings == null || timings.isEmpty) return Duration.zero;

    final total = timings.fold<Duration>(
      Duration.zero,
      (sum, timing) => sum + timing,
    );

    return Duration(milliseconds: total.inMilliseconds ~/ timings.length);
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    clearPerformanceData();
  }
}

