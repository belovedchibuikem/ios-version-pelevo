import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/enhanced_analytics_service.dart';
import '../../services/social_sharing_service.dart';
import '../../core/routes/app_routes.dart';

// lib/presentation/listening_statistics_screen/listening_statistics_screen.dart

class ListeningStatisticsScreen extends StatefulWidget {
  const ListeningStatisticsScreen({super.key});

  @override
  State<ListeningStatisticsScreen> createState() =>
      _ListeningStatisticsScreenState();
}

class _ListeningStatisticsScreenState extends State<ListeningStatisticsScreen>
    with TickerProviderStateMixin {
  final NavigationService _navigationService = NavigationService();
  final EnhancedAnalyticsService _analyticsService = EnhancedAnalyticsService();
  int _selectedTabIndex = 4;
  late TabController _tabController;
  String _selectedPeriod = 'This Week';
  bool _isLoading = true;
  Map<String, dynamic> _statisticsData = {};

  final List<String> _periodOptions = [
    'This Week',
    'This Month',
    'This Year',
    'All Time'
  ];

  // Default empty data
  Map<String, dynamic> get overallStats =>
      _statisticsData['overview'] ??
      {
        'total_listening_time': 0.0,
        'episodes_completed': 0,
        'total_episodes': 0,
        'avg_session_length': 0.0,
        'streak_days': 0,
      };

  List<Map<String, dynamic>> get weeklyData {
    final data = _statisticsData['overview']?['weekly_activity'] ?? [];
    if (data.isEmpty) {
      return [
        {'day': 'Mon', 'minutes': 0},
        {'day': 'Tue', 'minutes': 0},
        {'day': 'Wed', 'minutes': 0},
        {'day': 'Thu', 'minutes': 0},
        {'day': 'Fri', 'minutes': 0},
        {'day': 'Sat', 'minutes': 0},
        {'day': 'Sun', 'minutes': 0},
      ];
    }
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> get topPodcasts {
    final data = _statisticsData['overview']?['top_podcasts'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> get genreData {
    final data = _statisticsData['insights']?['genre_distribution'] ?? [];
    if (data.isEmpty) {
      return [
        {'genre': 'No Data', 'percentage': 100.0, 'color': Colors.grey},
      ];
    }
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> get recentActivity {
    final data = _statisticsData['activity']?['recent_activity'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> get dailyActivity {
    final data = _statisticsData['activity']?['daily_activity'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> get hourlyActivity {
    final data = _statisticsData['activity']?['hourly_activity'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Map<String, dynamic> get listeningPatterns {
    return _statisticsData['insights']?['listening_patterns'] ??
        {
          'completion_rate': 0.0,
          'avg_session_length': 0.0,
          'favorite_genre': 'Unknown',
          'most_active_day': 'Unknown',
          'most_active_time': 'Unknown',
        };
  }

  List<Map<String, dynamic>> get achievements {
    final data = _statisticsData['insights']?['achievements'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _navigationService.trackNavigation('/listening-statistics-screen');
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final period = _getPeriodFromDisplay(_selectedPeriod);
      final data = await _analyticsService.getComprehensiveAnalytics(
        period: period,
      );

      setState(() {
        _statisticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPeriodFromDisplay(String displayPeriod) {
    switch (displayPeriod) {
      case 'This Week':
        return 'week';
      case 'This Month':
        return 'month';
      case 'This Year':
        return 'year';
      case 'All Time':
        return 'all_time';
      default:
        return 'week';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    switch (index) {
      case 0:
        _navigationService.navigateTo(AppRoutes.homeScreen);
        break;
      case 1:
        _navigationService.navigateTo(AppRoutes.earnScreen);
        break;
      case 2:
        _navigationService.navigateTo(AppRoutes.libraryScreen);
        break;
      case 3:
        _navigationService.navigateTo(AppRoutes.walletScreen);
        break;
      case 4:
        _navigationService.navigateTo(AppRoutes.profileScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: currentTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Listening Statistics',
          style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: currentTheme.colorScheme.onSurface),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: currentTheme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => _navigationService.goBack(),
        ),
        actions: [
          // Share button
          IconButton(
            onPressed: _shareStatistics,
            icon: const Icon(Icons.share),
            tooltip: 'Share Statistics',
          ),
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: currentTheme.colorScheme.onSurface,
              size: 24,
            ),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadStatistics();
            },
            itemBuilder: (BuildContext context) =>
                _periodOptions.map((String period) {
              return PopupMenuItem<String>(
                value: period,
                child: Row(
                  children: [
                    if (period == _selectedPeriod)
                      CustomIconWidget(
                        iconName: 'check',
                        color: currentTheme.colorScheme.primary,
                        size: 20,
                      ),
                    if (period == _selectedPeriod) SizedBox(width: 2.w),
                    Text(period),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Activity'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading statistics...',
                    style: currentTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(currentTheme),
                _buildActivityTab(currentTheme),
                _buildInsightsTab(currentTheme),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(ThemeData currentTheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Stats Cards
            _buildEnhancedStatsGrid(currentTheme),
            SizedBox(height: 3.h),

            // Weekly Activity Chart
            Text(
              'Weekly Activity',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildWeeklyChart(currentTheme),
            SizedBox(height: 3.h),

            // Performance Metrics
            Text(
              'Performance Metrics',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildPerformanceMetricsSection(currentTheme),
            SizedBox(height: 3.h),

            // Top Podcasts
            Text(
              'Top Podcasts',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            ...topPodcasts
                .map((podcast) => _buildTopPodcastCard(currentTheme, podcast)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab(ThemeData currentTheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Activity
            Text(
              'Recent Activity',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildRecentActivityCard(currentTheme),
            SizedBox(height: 3.h),

            // Daily Activity
            Text(
              'Daily Listening Activity',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildDailyActivityChart(currentTheme),
            SizedBox(height: 3.h),

            // Hourly Activity
            Text(
              'Hourly Activity',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildHourlyActivityCard(currentTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab(ThemeData currentTheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genre Distribution
            Text(
              'Genre Distribution',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildGenreChart(currentTheme),
            SizedBox(height: 3.h),

            // Listening Patterns
            Text(
              'Listening Patterns',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildListeningPatternsCard(currentTheme),
            SizedBox(height: 3.h),

            // Achievements
            Text(
              'Achievements',
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildAchievementsCard(currentTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData currentTheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 3.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          currentTheme,
          'Total Hours',
          '${overallStats['total_listening_time']}h',
          'headphones',
          currentTheme.colorScheme.primary,
        ),
        _buildStatCard(
          currentTheme,
          'Episodes',
          '${overallStats['episodes_completed']}',
          'play_circle',
          currentTheme.colorScheme.secondary,
        ),
        _buildStatCard(
          currentTheme,
          'Avg Session',
          '${overallStats['avg_session_length']}m',
          'schedule',
          currentTheme.colorScheme.tertiary,
        ),
        _buildStatCard(
          currentTheme,
          'Streak Days',
          '${overallStats['streak_days']}',
          'local_fire_department',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData currentTheme, String title, String value,
      String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: currentTheme.textTheme.bodySmall?.copyWith(
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Enhanced stats grid using episode progress data
  Widget _buildEnhancedStatsGrid(ThemeData currentTheme) {
    final overview = _statisticsData['overview'] ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 3.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.5,
      children: [
        _buildEnhancedStatCard(
          currentTheme,
          'Total Listening',
          '${(overview['total_listening_time'] ?? 0.0).toStringAsFixed(1)} min',
          'headphones',
          currentTheme.colorScheme.primary,
        ),
        _buildEnhancedStatCard(
          currentTheme,
          'Episodes Completed',
          '${overview['episodes_completed'] ?? 0}',
          'check_circle',
          Colors.green,
        ),
        _buildEnhancedStatCard(
          currentTheme,
          'Completion Rate',
          '${(overview['completion_rate'] ?? 0.0).toStringAsFixed(1)}%',
          'trending_up',
          Colors.orange,
        ),
        _buildEnhancedStatCard(
          currentTheme,
          'Streak Days',
          '${overview['streak_days'] ?? 0} days',
          'local_fire_department',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(ThemeData currentTheme, String title,
      String value, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: currentTheme.textTheme.bodySmall?.copyWith(
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Performance metrics section using episode progress data
  Widget _buildPerformanceMetricsSection(ThemeData currentTheme) {
    final performance = _statisticsData['performance'] ?? {};

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentTheme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Performance',
            style: currentTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: currentTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  currentTheme,
                  'Efficiency Score',
                  '${(performance['efficiency_score'] ?? 0.0).toStringAsFixed(1)}%',
                  'speed',
                  Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildPerformanceMetric(
                  currentTheme,
                  'Retention Rate',
                  '${(performance['retention_rate'] ?? 0.0).toStringAsFixed(1)}%',
                  'psychology',
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildEngagementLevel(
              currentTheme, performance['engagement_level'] ?? 'Low'),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(ThemeData currentTheme, String label,
      String value, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: currentTheme.textTheme.bodySmall?.copyWith(
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementLevel(ThemeData currentTheme, String level) {
    Color color;
    String iconName;

    switch (level.toLowerCase()) {
      case 'very high':
        color = Colors.green;
        iconName = 'emoji_events';
        break;
      case 'high':
        color = Colors.lightGreen;
        iconName = 'star';
        break;
      case 'medium':
        color = Colors.orange;
        iconName = 'trending_up';
        break;
      case 'low':
        color = Colors.red;
        iconName = 'trending_down';
        break;
      default:
        color = Colors.grey;
        iconName = 'help_outline';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 24,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Engagement Level',
                  style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  level.toUpperCase(),
                  style: currentTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ThemeData currentTheme) {
    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    weeklyData[value.toInt()]['day'],
                    style: currentTheme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: weeklyData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value['minutes'].toDouble(),
                  color: currentTheme.colorScheme.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopPodcastCard(
      ThemeData currentTheme, Map<String, dynamic> podcast) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImageWidget(
                imageUrl: podcast['thumbnail'],
                width: 12.w,
                height: 12.w,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  podcast['title'],
                  style: currentTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${podcast['listening_time']}h • ${podcast['episodes']} episodes',
                  style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'chevron_right',
            color: currentTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(ThemeData currentTheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withAlpha(26),
            Colors.red.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: 'local_fire_department',
              color: Colors.orange,
              size: 32,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overallStats['streak_days']} Day Streak!',
                  style: currentTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Keep it up! Listen to an episode today to continue your streak.',
                  style: currentTheme.textTheme.bodyMedium?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityCard(ThemeData currentTheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Most Active Day',
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                overallStats['most_active_day'],
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                  color: currentTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Preferred Time',
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                overallStats['most_active_time'],
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                  color: currentTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(ThemeData currentTheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Goal: 10 hours',
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '7.2h / 10h',
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                  color: currentTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: 0.72,
            backgroundColor: currentTheme.colorScheme.outline.withAlpha(51),
            valueColor: AlwaysStoppedAnimation<Color>(
              currentTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '2.8 hours to go! You\'re doing great 🎯',
            style: currentTheme.textTheme.bodySmall?.copyWith(
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChart(ThemeData currentTheme) {
    print('Building genre chart with data: $genreData'); // Debug print
    return Container(
      height: 35.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: genreData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No genre data available',
                          style: currentTheme.textTheme.bodyMedium?.copyWith(
                            color: currentTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        // Test pie chart with dummy data
                        SizedBox(
                          height: 20.h,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  color: Colors.blue,
                                  value: 100,
                                  title: '100%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              sectionsSpace: 1,
                              centerSpaceRadius: 20,
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: genreData.map((data) {
                        print('Creating pie section: $data'); // Debug print
                        return PieChartSectionData(
                          color: _parseColor(data['color']),
                          value: (data['percentage'] ?? 0).toDouble(),
                          title: '${data['percentage']}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 1,
                      centerSpaceRadius: 30,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            flex: 1,
            child: Wrap(
              spacing: 3.w,
              runSpacing: 1.h,
              children: genreData
                  .map((data) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _parseColor(data['color']),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            data['genre'],
                            style: currentTheme.textTheme.bodySmall,
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningPatternsCard(ThemeData currentTheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatternRow(currentTheme, 'Favorite Genre',
              listeningPatterns['favorite_genre']),
          SizedBox(height: 2.h),
          _buildPatternRow(currentTheme, 'Average Session',
              '${listeningPatterns['avg_session_length']} minutes'),
          SizedBox(height: 2.h),
          _buildPatternRow(currentTheme, 'Completion Rate',
              '${listeningPatterns['completion_rate']}%'),
          SizedBox(height: 2.h),
          _buildPatternRow(currentTheme, 'Most Active Day',
              listeningPatterns['most_active_day']),
          SizedBox(height: 2.h),
          _buildPatternRow(currentTheme, 'Most Active Time',
              listeningPatterns['most_active_time']),
        ],
      ),
    );
  }

  Widget _buildPatternRow(ThemeData currentTheme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: currentTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: currentTheme.textTheme.bodyMedium?.copyWith(
            color: currentTheme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard(ThemeData currentTheme) {
    final achievements = _statisticsData['achievements']?['achievements'] ?? [];
    final totalAchievements = achievements.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentTheme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: currentTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: currentTheme.colorScheme.primary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: currentTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalAchievements',
                  style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (achievements.isEmpty)
            _buildEmptyAchievements(currentTheme)
          else
            ...achievements.map((achievement) =>
                _buildEnhancedAchievementItem(currentTheme, achievement)),
        ],
      ),
    );
  }

  Widget _buildEmptyAchievements(ThemeData currentTheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: currentTheme.colorScheme.outline,
          ),
          SizedBox(height: 1.h),
          Text(
            'No achievements yet',
            style: currentTheme.textTheme.titleMedium?.copyWith(
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Keep listening to unlock achievements!',
            style: currentTheme.textTheme.bodySmall?.copyWith(
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAchievementItem(
      ThemeData currentTheme, Map<String, dynamic> achievement) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            achievement['icon'] ?? '🏆',
            style: const TextStyle(fontSize: 24),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'] ?? 'Achievement',
                  style: currentTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: currentTheme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  achievement['description'] ?? 'Description',
                  style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(ThemeData currentTheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: recentActivity.isEmpty
            ? [
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Text(
                    'No recent activity',
                    style: currentTheme.textTheme.bodyMedium?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ]
            : recentActivity
                .take(5)
                .map((activity) => Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: currentTheme.colorScheme.outline.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: currentTheme.colorScheme.primary
                                  .withAlpha(26),
                            ),
                            child: CustomIconWidget(
                              iconName: 'play_circle',
                              color: currentTheme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['episode_title'] ??
                                      'Unknown Episode',
                                  style: currentTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  activity['podcast_title'] ??
                                      'Unknown Podcast',
                                  style: currentTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: currentTheme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${activity['listening_time']} minutes • ${activity['status']}',
                                  style: currentTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: currentTheme
                                        .colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
      ),
    );
  }

  Widget _buildDailyActivityChart(ThemeData currentTheme) {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: dailyActivity.isNotEmpty
                    ? dailyActivity
                            .map((d) => d['minutes'] as double)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2
                    : 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dailyActivity.length) {
                          return Text(
                            dailyActivity[value.toInt()]['day'] ?? '',
                            style: currentTheme.textTheme.bodySmall,
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: currentTheme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyActivity.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (data['minutes'] ?? 0).toDouble(),
                        color: currentTheme.colorScheme.primary,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyActivityCard(ThemeData currentTheme) {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < hourlyActivity.length) {
                          final hour =
                              hourlyActivity[value.toInt()]['hour'] ?? 0;
                          return Text(
                            '${hour}h',
                            style: currentTheme.textTheme.bodySmall,
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: currentTheme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: hourlyActivity.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return FlSpot(
                          index.toDouble(), (data['minutes'] ?? 0).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: currentTheme.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: currentTheme.colorScheme.primary.withAlpha(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parse color string to Color object
  Color _parseColor(dynamic colorValue) {
    print('Parsing color: $colorValue'); // Debug print
    if (colorValue == null) return Colors.grey;

    if (colorValue is Color) return colorValue;

    if (colorValue is String) {
      // Handle hex color strings
      if (colorValue.startsWith('#')) {
        try {
          // Add alpha channel (FF) to make colors opaque
          final hexString = colorValue.replaceFirst('#', '');
          final fullHex = 'FF$hexString'; // Add alpha channel
          final color = Color(int.parse(fullHex, radix: 16));
          print('Parsed hex color: $color'); // Debug print
          return color;
        } catch (e) {
          print('Error parsing hex color: $e'); // Debug print
          return Colors.grey;
        }
      }

      // Handle named colors
      switch (colorValue.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'brown':
          return Colors.brown;
        case 'grey':
        case 'gray':
          return Colors.grey;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        default:
          return Colors.grey;
      }
    }

    return Colors.grey;
  }

  Future<void> _shareStatistics() async {
    try {
      final stats = overallStats;
      final totalListeningTime = stats['total_listening_time'] ?? 0.0;
      final episodesCompleted = stats['episodes_completed'] ?? 0;
      final totalEpisodes = stats['total_episodes'] ?? 0;
      final avgSessionLength = stats['avg_session_length'] ?? 0.0;
      final streakDays = stats['streak_days'] ?? 0;

      if (totalEpisodes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No statistics to share'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('📊 My Listening Statistics - $_selectedPeriod');
      buffer.writeln();
      buffer.writeln(
          '⏱️ Total Listening Time: ${_formatDuration(totalListeningTime)}');
      buffer.writeln('✅ Episodes Completed: $episodesCompleted');
      buffer.writeln('📈 Total Episodes: $totalEpisodes');
      buffer.writeln('⏰ Average Session: ${_formatDuration(avgSessionLength)}');
      buffer.writeln('🔥 Streak: $streakDays days');

      // Add completion rate
      if (totalEpisodes > 0) {
        final completionRate =
            (episodesCompleted / totalEpisodes * 100).round();
        buffer.writeln('📊 Completion Rate: $completionRate%');
      }

      buffer.writeln();
      buffer.writeln('Shared via Pelevo Podcast App');

      await SocialSharingService().shareStatistics(
        totalEpisodes: totalEpisodes,
        completedEpisodes: episodesCompleted,
        totalListeningTime: totalListeningTime.round(),
        customMessage: buffer.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statistics shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing statistics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();

    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}
