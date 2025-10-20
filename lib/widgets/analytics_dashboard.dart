import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../services/analytics_service.dart';

/// Analytics dashboard widget displaying comprehensive analytics data
class AnalyticsDashboard extends StatefulWidget {
  final bool showDetailedMetrics;
  final VoidCallback? onRefresh;

  const AnalyticsDashboard({
    super.key,
    this.showDetailedMetrics = false,
    this.onRefresh,
  });

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic> _listeningBehavior = {};
  Map<String, dynamic> _contentAnalytics = {};
  Map<String, dynamic> _userEngagement = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalyticsData();
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
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final listeningBehavior =
          await _analyticsService.getListeningBehaviorAnalytics();
      final contentAnalytics = await _analyticsService.getContentAnalytics();
      final userEngagement =
          await _analyticsService.getUserEngagementAnalytics();

      setState(() {
        _listeningBehavior = listeningBehavior;
        _contentAnalytics = contentAnalytics;
        _userEngagement = userEngagement;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    _refreshController.forward().then((_) {
      _refreshController.reverse();
    });

    await _loadAnalyticsData();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          SizedBox(height: 3.h),

          if (_isLoading)
            _buildLoadingIndicator()
          else if (_errorMessage != null)
            _buildErrorDisplay()
          else
            _buildDashboardContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.insights,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 24,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            'Analytics Dashboard',
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
            'Loading analytics data...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.lightTheme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Error loading analytics',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            _errorMessage!,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _loadAnalyticsData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        // Listening Behavior Overview
        _buildListeningBehaviorOverview(),

        SizedBox(height: 3.h),

        // Content Analytics
        _buildContentAnalytics(),

        SizedBox(height: 3.h),

        // User Engagement
        _buildUserEngagement(),

        if (widget.showDetailedMetrics) ...[
          SizedBox(height: 3.h),
          _buildDetailedMetrics(),
        ],
      ],
    );
  }

  Widget _buildListeningBehaviorOverview() {
    final overview = _listeningBehavior['overview'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listening Behavior Overview',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Episodes',
                '${overview['total_episodes'] ?? 0}',
                Icons.library_books,
                Colors.blue,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Completed',
                '${overview['completed_episodes'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'In Progress',
                '${overview['in_progress_episodes'] ?? 0}',
                Icons.pause_circle,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                'Completion Rate',
                '${overview['completion_rate'] ?? '0.0'}%',
                double.tryParse(overview['completion_rate']
                            ?.toString()
                            .replaceAll('%', '') ??
                        '0') ??
                    0.0,
                Colors.green,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildProgressCard(
                'Engagement Rate',
                '${overview['engagement_rate'] ?? '0.0'}%',
                double.tryParse(overview['engagement_rate']
                            ?.toString()
                            .replaceAll('%', '') ??
                        '0') ??
                    0.0,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentAnalytics() {
    final contentInsights = _contentAnalytics['content_insights'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Analytics',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Listening Time',
                _formatDuration(contentInsights['total_listening_time'] ?? 0),
                Icons.access_time,
                Colors.purple,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Avg Episode Duration',
                _formatDuration(
                    contentInsights['average_listening_time_per_episode'] ?? 0),
                Icons.timer,
                Colors.indigo,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildContentQualityCard(contentInsights),
      ],
    );
  }

  Widget _buildUserEngagement() {
    final engagementMetrics = _userEngagement['engagement_metrics'] ?? {};
    final retentionAnalysis = _userEngagement['retention_analysis'] ?? {};
    final engagementScore = _userEngagement['engagement_score'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Engagement',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Episode Rate',
                '${engagementMetrics['active_episode_rate'] ?? '0.0'}%',
                Icons.trending_up,
                Colors.teal,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Retention Rate',
                '${retentionAnalysis['retention_rate'] ?? '0.0'}%',
                Icons.people,
                Colors.amber,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildEngagementScoreCard(engagementScore),
      ],
    );
  }

  Widget _buildDetailedMetrics() {
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
        _buildListeningPatternsCard(),
        SizedBox(height: 2.h),
        _buildTimeAnalysisCard(),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      String title, String value, double percentage, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildContentQualityCard(Map<String, dynamic> contentInsights) {
    final qualityScore = contentInsights['content_quality_score'] ?? 0.0;

    return Container(
      width: double.infinity,
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
            'Content Quality Score',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: qualityScore / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getQualityColor(qualityScore)),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '${qualityScore.toStringAsFixed(1)}%',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getQualityColor(qualityScore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementScoreCard(double engagementScore) {
    return Container(
      width: double.infinity,
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
            'Overall Engagement Score',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: engagementScore / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getEngagementColor(engagementScore)),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '${engagementScore.toStringAsFixed(1)}%',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getEngagementColor(engagementScore),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _getEngagementDescription(engagementScore),
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningPatternsCard() {
    final patterns = _listeningBehavior['listening_patterns'] ?? {};

    return Container(
      width: double.infinity,
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
            'Listening Patterns',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildPatternItem(
                  'Total Sessions',
                  '${patterns['total_sessions'] ?? 0}',
                  Icons.play_circle,
                ),
              ),
              Expanded(
                child: _buildPatternItem(
                  'Avg Duration',
                  _formatDuration(patterns['average_session_duration'] ?? 0),
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAnalysisCard() {
    final timeAnalysis = _listeningBehavior['time_analysis'] ?? {};
    final timeDistribution = timeAnalysis['time_distribution'] ?? {};

    return Container(
      width: double.infinity,
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
            'Time Analysis',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildTimeSlotItem(
                    'Morning', timeDistribution['morning'] ?? 0, Colors.orange),
              ),
              Expanded(
                child: _buildTimeSlotItem('Afternoon',
                    timeDistribution['afternoon'] ?? 0, Colors.blue),
              ),
              Expanded(
                child: _buildTimeSlotItem(
                    'Evening', timeDistribution['evening'] ?? 0, Colors.purple),
              ),
              Expanded(
                child: _buildTimeSlotItem(
                    'Night', timeDistribution['night'] ?? 0, Colors.indigo),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.lightTheme.colorScheme.primary, size: 20),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeSlotItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Helper methods
  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    return '${(seconds / 3600).round()}h';
  }

  Color _getQualityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getEngagementColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getEngagementDescription(double score) {
    if (score >= 80) return 'Excellent engagement!';
    if (score >= 60) return 'Good engagement level';
    if (score >= 40) return 'Moderate engagement';
    return 'Low engagement - consider exploring more content';
  }
}

