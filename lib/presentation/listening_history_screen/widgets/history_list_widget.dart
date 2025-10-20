import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/navigation_service.dart';
import '../../../providers/history_provider.dart';
import '../../../models/play_history.dart';

class HistoryListWidget extends StatelessWidget {
  final HistoryProvider historyProvider;
  final VoidCallback onRefresh;
  final Function(PlayHistory) onHistoryTap;

  const HistoryListWidget({
    super.key,
    required this.historyProvider,
    required this.onRefresh,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    if (historyProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: currentTheme.colorScheme.primary,
        ),
      );
    }

    if (historyProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: currentTheme.colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Error loading history',
              style: currentTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              historyProvider.error!,
              style: currentTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: onRefresh,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (historyProvider.filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No listening history',
              style: currentTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Your recently played episodes will appear here',
              style: currentTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () {
                NavigationService().navigateToHomeTab();
              },
              child: Text('Start Listening'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: currentTheme.colorScheme.primary,
      child: ListView.separated(
        padding: EdgeInsets.all(4.w),
        itemCount: historyProvider.filteredHistory.length +
            (historyProvider.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          if (index == historyProvider.filteredHistory.length &&
              historyProvider.hasMore) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: historyProvider.isLoadingMore
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => historyProvider.loadMoreHistory(),
                        child: Text('Load More'),
                      ),
              ),
            );
          }

          final history = historyProvider.filteredHistory[index];
          return _buildHistoryItem(context, history);
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, PlayHistory history) {
    final currentTheme = Theme.of(context);
    final episode = history.episode;
    if (episode == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(4.w),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: currentTheme.colorScheme.surfaceContainer,
          ),
          child: Stack(
            children: [
              CustomImageWidget(
                imageUrl: episode.image ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              if (history.progressPercentage > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: history.progressPercentage / 100,
                    backgroundColor: Colors.black26,
                    valueColor: AlwaysStoppedAnimation(
                      currentTheme.colorScheme.primary,
                    ),
                  ),
                ),
              // Status indicator
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(history.status).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(history.status),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          episode.title,
          style: currentTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.podcast?.author ?? 'Unknown',
              style: currentTheme.textTheme.bodySmall?.copyWith(
                color: currentTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: currentTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Text(
                  history.timeAgo,
                  style: currentTheme.textTheme.bodySmall,
                ),
                const Spacer(),
                // Progress text
                Text(
                  '${history.formattedProgressTime} / ${history.formattedTotalTime}',
                  style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            // Progress bar
            LinearProgressIndicator(
              value: history.progressPercentage / 100,
              backgroundColor: currentTheme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                currentTheme.colorScheme.primary,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: currentTheme.colorScheme.onSurfaceVariant,
          ),
          onSelected: (value) => _handleHistoryAction(context, history, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  SizedBox(width: 8),
                  Text('Resume'),
                ],
              ),
            ),
            if (!history.isCompleted)
              PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Mark Complete'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20),
                  SizedBox(width: 8),
                  Text('Remove from History'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => onHistoryTap(history),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'played':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'abandoned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'played':
        return Icons.play_circle;
      case 'paused':
        return Icons.pause_circle;
      case 'abandoned':
        return Icons.stop_circle;
      default:
        return Icons.circle;
    }
  }

  void _handleHistoryAction(
      BuildContext context, PlayHistory history, String action) {
    switch (action) {
      case 'play':
        onHistoryTap(history);
        break;
      case 'complete':
        historyProvider.markEpisodeCompleted(history.id);
        break;
      case 'remove':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Remove from History'),
            content: Text(
                'Are you sure you want to remove this episode from your history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  historyProvider.deletePlayHistory(history.id);
                  Navigator.pop(context);
                },
                child: Text('Remove'),
              ),
            ],
          ),
        );
        break;
    }
  }
}
