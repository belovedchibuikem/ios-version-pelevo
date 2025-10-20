import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../core/routes/app_routes.dart';
import '../../models/episode_progress.dart';
import '../../services/episode_progress_tracker.dart';
import '../../services/episode_progress_service.dart';
import '../../services/social_sharing_service.dart';
import '../../widgets/episode_progress_display.dart';
import '../../widgets/sync_status_widget.dart';
import '../../core/utils/mini_player_positioning.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with TickerProviderStateMixin {
  final EpisodeProgressTracker _progressTracker = EpisodeProgressTracker();
  final EpisodeProgressService _progressService = EpisodeProgressService();

  late TabController _tabController;
  List<EpisodeProgress> _allProgress = [];
  List<EpisodeProgress> _inProgressEpisodes = [];
  List<EpisodeProgress> _completedEpisodes = [];

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _progressService.initialize();
      await _loadProgressData();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      await _loadProgressData(); // Still try to load data
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load all progress
      final allProgress = await _progressTracker.getAllProgress();

      // Load statistics
      final stats = await _progressTracker.getProgressStatistics();

      // Categorize progress
      final inProgress = <EpisodeProgress>[];
      final completed = <EpisodeProgress>[];

      for (final progress in allProgress) {
        if (progress.isCompleted) {
          completed.add(progress);
        } else if (progress.currentPosition > 0) {
          inProgress.add(progress);
        }
      }

      // Sort by last played date
      inProgress.sort((a, b) => (b.lastPlayedAt ?? DateTime(1900))
          .compareTo(a.lastPlayedAt ?? DateTime(1900)));
      completed.sort((a, b) => (b.completedAt ?? DateTime(1900))
          .compareTo(a.completedAt ?? DateTime(1900)));

      setState(() {
        _allProgress = allProgress;
        _inProgressEpisodes = inProgress;
        _completedEpisodes = completed;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _syncProgress() async {
    try {
      final success = await _progressTracker.syncProgress();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress synced successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload data after sync
        await _loadProgressData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress sync failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Clear all progress data
  Future<void> _clearAllProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Progress'),
        content: const Text(
            'Are you sure you want to clear all episode progress? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _progressTracker.clearAllProgress();
        await _loadProgressData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All progress cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing progress: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show sync details dialog
  void _showSyncDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: SyncStatusWidget(
            showDetails: true,
            onSyncComplete: () {
              Navigator.of(context).pop();
              _loadProgressData();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Progress'),
        actions: [
          // Share button
          IconButton(
            onPressed: _shareProgress,
            icon: const Icon(Icons.share),
            tooltip: 'Share Progress',
          ),
          // Sync status indicator
          CompactSyncIndicator(
            progressService: _progressService,
            onTap: () => _showSyncDetails(context),
          ),
          SizedBox(width: 2.w),
          // Manual sync button
          IconButton(
            onPressed: _syncProgress,
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Progress',
          ),
          // Clear all progress button
          IconButton(
            onPressed: _clearAllProgress,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All Progress',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_allProgress.length})'),
            Tab(text: 'In Progress (${_inProgressEpisodes.length})'),
            Tab(text: 'Completed (${_completedEpisodes.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllProgressTab(),
                    _buildInProgressTab(),
                    _buildCompletedTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.lightTheme.colorScheme.error,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading progress',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProgressData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProgressTab() {
    return _buildProgressList(_allProgress);
  }

  Widget _buildInProgressTab() {
    return _buildProgressList(_inProgressEpisodes);
  }

  Widget _buildCompletedTab() {
    return _buildProgressList(_completedEpisodes);
  }

  Widget _buildProgressList(List<EpisodeProgress> progressList) {
    if (progressList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              size: 64,
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
            SizedBox(height: 16),
            Text(
              'No progress to show',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Start listening to episodes to see your progress here',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProgressData,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 4.w,
          right: 4.w,
          top: 4.w,
          bottom: MiniPlayerPositioning.bottomPaddingForScrollables(),
        ),
        itemCount: progressList.length,
        itemBuilder: (context, index) {
          final progress = progressList[index];
          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            child: ListTile(
              contentPadding: EdgeInsets.all(4.w),
              title: Text(
                'Episode ${progress.episodeId}',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 1.h),
                  EpisodeProgressDisplay(
                    progress: progress,
                    onTap: () {
                      // Navigate to episode detail or player
                      Navigator.pushNamed(
                        context,
                        AppRoutes.podcastPlayer,
                        arguments: {
                          'episodeId': progress.episodeId,
                          'startPosition': progress.currentPosition,
                        },
                      );
                    },
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _deleteProgress(progress);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Progress'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteProgress(EpisodeProgress progress) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Progress'),
        content: Text(
          'Are you sure you want to delete progress for Episode ${progress.episodeId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success =
            await _progressTracker.deleteEpisodeProgress(progress.episodeId);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Progress deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          await _loadProgressData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting progress: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareProgress() async {
    try {
      final totalEpisodes = _allProgress.length;
      final inProgressCount = _inProgressEpisodes.length;
      final completedCount = _completedEpisodes.length;

      if (totalEpisodes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No progress to share'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('📊 My Podcast Progress Summary');
      buffer.writeln();
      buffer.writeln('📈 Total Episodes: $totalEpisodes');
      buffer.writeln('⏳ In Progress: $inProgressCount');
      buffer.writeln('✅ Completed: $completedCount');

      if (_statistics != null) {
        final totalListeningTime = _statistics!['totalListeningTime'] ?? 0;
        final hours = (totalListeningTime / 3600).floor();
        final minutes = ((totalListeningTime % 3600) / 60).floor();

        if (hours > 0) {
          buffer.writeln('⏱️ Total Listening Time: ${hours}h ${minutes}m');
        } else {
          buffer.writeln('⏱️ Total Listening Time: ${minutes}m');
        }
      }

      buffer.writeln();
      buffer.writeln('Shared via Pelevo Podcast App');

      await SocialSharingService().shareStatistics(
        totalEpisodes: totalEpisodes,
        completedEpisodes: completedCount,
        totalListeningTime: (_statistics?['totalListeningTime'] ?? 0).round(),
        customMessage: buffer.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing progress: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
