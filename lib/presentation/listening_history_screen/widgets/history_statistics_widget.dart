import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class HistoryStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final bool isLoading;
  final VoidCallback onRefresh;

  const HistoryStatisticsWidget({
    super.key,
    required this.statistics,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: currentTheme.colorScheme.primary,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: currentTheme.colorScheme.primary,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewCards(currentTheme),
            SizedBox(height: 4.h),

            // Listening Time Chart
            _buildListeningTimeCard(currentTheme),
            SizedBox(height: 4.h),

            // Top Podcasts
            _buildTopPodcastsCard(currentTheme),
            SizedBox(height: 4.h),

            // Recent Activity
            _buildRecentActivityCard(currentTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(ThemeData currentTheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 3.w,
      mainAxisSpacing: 3.h,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          currentTheme,
          'Total Episodes',
          '${statistics['total_episodes_played'] ?? 0}',
          Icons.play_circle,
          Colors.blue,
        ),
        _buildStatCard(
          currentTheme,
          'Completed',
          '${statistics['completed_episodes'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          currentTheme,
          'In Progress',
          '${statistics['in_progress_episodes'] ?? 0}',
          Icons.pause_circle,
          Colors.orange,
        ),
        _buildStatCard(
          currentTheme,
          'Total Time',
          _formatListeningTime(
              _parseInt(statistics['total_listening_time'] ?? 0)),
          Icons.timer,
          Colors.purple,
        ),
      ],
    );
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildStatCard(
    ThemeData currentTheme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: currentTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: currentTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              title,
              style: currentTheme.textTheme.bodySmall?.copyWith(
                color: currentTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningTimeCard(ThemeData currentTheme) {
    final totalTime = _parseInt(statistics['total_listening_time'] ?? 0);
    final hours = (totalTime / 3600).floor();
    final minutes = ((totalTime % 3600) / 60).floor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: currentTheme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Listening Time',
                  style: currentTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$hours',
                        style: currentTheme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTheme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Hours',
                        style: currentTheme.textTheme.bodySmall?.copyWith(
                          color: currentTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$minutes',
                        style: currentTheme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTheme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Minutes',
                        style: currentTheme.textTheme.bodySmall?.copyWith(
                          color: currentTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPodcastsCard(ThemeData currentTheme) {
    final topPodcasts = statistics['top_podcasts'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: currentTheme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Top Podcasts',
                  style: currentTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (topPodcasts.isEmpty)
              Center(
                child: Text(
                  'No listening data yet',
                  style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...topPodcasts.take(5).map((podcast) {
                final podcastData = podcast as Map<String, dynamic>;
                final podcastInfo =
                    podcastData['podcast'] as Map<String, dynamic>?;
                final totalTime = _parseInt(podcastData['total_time'] ?? 0);

                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: currentTheme.colorScheme.surfaceContainer,
                        ),
                        child: CustomImageWidget(
                          imageUrl: podcastInfo?['image'] ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              podcastInfo?['title'] ?? 'Unknown Podcast',
                              style:
                                  currentTheme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatListeningTime(totalTime),
                              style: currentTheme.textTheme.bodySmall?.copyWith(
                                color:
                                    currentTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(ThemeData currentTheme) {
    final recentEpisodes = _parseInt(statistics['recent_episodes'] ?? 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: currentTheme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Recent Activity',
                  style: currentTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$recentEpisodes',
                        style: currentTheme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTheme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Episodes (7 days)',
                        style: currentTheme.textTheme.bodySmall?.copyWith(
                          color: currentTheme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatListeningTime(int seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
