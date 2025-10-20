import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../core/app_export.dart';
import '../services/performance_monitor_service.dart';
import '../services/memory_management_service.dart';
import '../services/enhanced_error_handler.dart';

/// Performance dashboard widget showing system health and metrics
class PerformanceDashboard extends StatefulWidget {
  final bool showDetailedMetrics;
  final VoidCallback? onRefresh;

  const PerformanceDashboard({
    super.key,
    this.showDetailedMetrics = false,
    this.onRefresh,
  });

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  late ScrollController _scrollController;

  final PerformanceMonitorService _performanceMonitor =
      PerformanceMonitorService();
  final MemoryManagementService _memoryManager = MemoryManagementService();
  final EnhancedErrorHandler _errorHandler = EnhancedErrorHandler();

  Map<String, dynamic> _performanceStats = {};
  Map<String, dynamic> _memoryStats = {};
  Map<String, dynamic> _errorStats = {};
  List<String> _performanceWarnings = [];

  bool _isLoading = true;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeAnimations();
    _loadPerformanceData();
    _startPeriodicUpdates();
  }

  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadPerformanceData();
      }
    });
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final performanceStats = _performanceMonitor.getPerformanceStats();
      final memoryStats = _memoryManager.getMemoryUsage();
      final errorStats = _errorHandler.getErrorStats();
      final performanceWarnings = _performanceMonitor.getPerformanceWarnings();

      setState(() {
        _performanceStats = performanceStats;
        _memoryStats = memoryStats;
        _errorStats = errorStats;
        _performanceWarnings = performanceWarnings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading performance data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    _refreshController.forward().then((_) {
      _refreshController.reverse();
    });

    // Scroll to top when refreshing
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    await _loadPerformanceData();
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Scroll hint
            if (!_isLoading) ...[
              SizedBox(height: 1.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Scroll to see more',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 3.h),

            if (_isLoading)
              _buildLoadingIndicator()
            else
              _buildDashboardContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 24,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            'Performance Dashboard',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: _refreshData,
          icon: RotationTransition(
            turns: _refreshAnimation,
            child: Icon(
              Icons.refresh,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading performance data...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        // System Health Overview
        _buildSystemHealthOverview(),

        SizedBox(height: 3.h),

        // Performance Metrics
        _buildPerformanceMetrics(),

        SizedBox(height: 3.h),

        // Memory Usage
        _buildMemoryUsage(),

        SizedBox(height: 3.h),

        // Error Statistics
        _buildErrorStatistics(),

        if (widget.showDetailedMetrics) ...[
          SizedBox(height: 3.h),
          _buildDetailedMetrics(),
        ],

        if (_performanceWarnings.isNotEmpty) ...[
          SizedBox(height: 3.h),
          _buildPerformanceWarnings(),
        ],

        // Bottom padding for better scrolling experience
        SizedBox(height: 4.h),
      ],
    );
  }

  Widget _buildSystemHealthOverview() {
    final memoryHealthy = _memoryStats['is_healthy'] ?? true;
    final errorCount = _errorStats['total_errors'] ?? 0;
    final warningsCount = _performanceWarnings.length;

    Color overallColor;
    IconData overallIcon;
    String overallStatus;

    if (errorCount > 10 || warningsCount > 5 || !memoryHealthy) {
      overallColor = Colors.red;
      overallIcon = Icons.warning;
      overallStatus = 'Needs Attention';
    } else if (errorCount > 5 || warningsCount > 2) {
      overallColor = Colors.orange;
      overallIcon = Icons.info;
      overallStatus = 'Good';
    } else {
      overallColor = Colors.green;
      overallIcon = Icons.check_circle;
      overallStatus = 'Excellent';
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: overallColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: overallColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            overallIcon,
            color: overallColor,
            size: 32,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Health',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  overallStatus,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: overallColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: overallColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${((_calculateHealthScore() * 100).round())}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateHealthScore() {
    final memoryScore = _memoryStats['is_healthy'] == true ? 1.0 : 0.3;
    final errorScore =
        1.0 - ((_errorStats['total_errors'] ?? 0) / 20.0).clamp(0.0, 1.0);
    final warningScore =
        1.0 - ((_performanceWarnings.length) / 10.0).clamp(0.0, 1.0);

    return (memoryScore + errorScore + warningScore) / 3.0;
  }

  Widget _buildPerformanceMetrics() {
    final stats = _performanceStats;
    if (stats.isEmpty) {
      return _buildEmptySection(
          'Performance Metrics', 'No performance data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...stats.entries
            .where((entry) => entry.value is Map<String, dynamic>)
            .take(5)
            .map((entry) => _buildMetricRow(
                  entry.key.toString(),
                  '${entry.value['average_time_ms'] ?? 'N/A'}ms avg',
                  entry.value['count'] ?? 0,
                  _getPerformanceColor(entry.value['average_time_ms'] ?? 0),
                )),
      ],
    );
  }

  Widget _buildMemoryUsage() {
    final memoryUsage = _memoryStats;
    if (memoryUsage.isEmpty) {
      return _buildEmptySection('Memory Usage', 'No memory data available');
    }

    final usagePercent =
        double.tryParse(memoryUsage['memory_usage_percent'] ?? '0') ?? 0.0;
    final isHealthy = memoryUsage['is_healthy'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Memory Usage',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cache Usage',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${memoryUsage['cache_size_mb'] ?? 'N/A'} MB / ${memoryUsage['max_memory_mb'] ?? 'N/A'} MB',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              LinearProgressIndicator(
                value: usagePercent / 100,
                backgroundColor: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isHealthy ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cache Items',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  Text(
                    '${memoryUsage['cache_items'] ?? 'N/A'} items',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStatistics() {
    final errors = _errorStats;
    if (errors.isEmpty) {
      return _buildEmptySection('Error Statistics', 'No errors recorded');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Error Statistics',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildStatRow('Total Errors', '${errors['total_errors'] ?? 0}'),
              if (errors['error_counts_by_category'] != null) ...[
                SizedBox(height: 1.h),
                ...(_safeCastToMap(errors['error_counts_by_category']))
                    .entries
                    .map(
                      (entry) => _buildStatRow(
                        '${entry.key.toString().replaceAll('_', ' ').toUpperCase()}',
                        '${entry.value ?? 0}',
                        color: _getErrorCategoryColor(entry.key.toString()),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics() {
    final stats = _performanceStats;
    if (stats.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Metrics',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...stats.entries
            .where((entry) => entry.value is Map<String, dynamic>)
            .map((entry) => _buildDetailedMetricCard(
                entry.key.toString(), _safeCastToMap(entry.value))),
      ],
    );
  }

  Widget _buildPerformanceWarnings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: 20,
            ),
            SizedBox(width: 1.w),
            Text(
              'Performance Warnings',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: _performanceWarnings
                .take(5)
                .map((warning) => Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              warning,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              message,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, int count, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '($count)',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricCard(
      String operation, Map<String, dynamic> metrics) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            operation,
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child:
                    _buildMetricItem('Count', '${metrics['count'] ?? 'N/A'}'),
              ),
              Expanded(
                child: _buildMetricItem(
                    'Avg Time', '${metrics['average_time_ms'] ?? 'N/A'}ms'),
              ),
              Expanded(
                child: _buildMetricItem(
                    'P95 Time', '${metrics['p95_time_ms'] ?? 'N/A'}ms'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getPerformanceColor(dynamic averageTime) {
    final time = averageTime is int
        ? averageTime
        : averageTime is double
            ? averageTime.toInt()
            : int.tryParse(averageTime.toString()) ?? 0;

    if (time < 100) return Colors.green;
    if (time < 500) return Colors.orange;
    return Colors.red;
  }

  Color _getErrorCategoryColor(String category) {
    switch (category) {
      case 'network':
        return Colors.orange;
      case 'database':
        return Colors.red;
      case 'validation':
        return Colors.amber;
      case 'permission':
        return Colors.purple;
      case 'system':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> _safeCastToMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return {};
  }
}
