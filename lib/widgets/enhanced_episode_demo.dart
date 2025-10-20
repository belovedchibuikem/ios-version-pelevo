import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import 'episode_list_item.dart';
import 'episode_seek_bar.dart';
import '../models/episode_progress.dart';
import '../models/episode_bookmark.dart';
import '../services/episode_progress_service.dart';

class EnhancedEpisodeDemo extends StatefulWidget {
  const EnhancedEpisodeDemo({super.key});

  @override
  State<EnhancedEpisodeDemo> createState() => _EnhancedEpisodeDemoState();
}

class _EnhancedEpisodeDemoState extends State<EnhancedEpisodeDemo> {
  // Episode progress service instance
  final EpisodeProgressService _progressService = EpisodeProgressService();

  // Demo data
  final List<Map<String, dynamic>> _demoEpisodes = [
    {
      'id': '1',
      'title': 'How to keep close friendships',
      'duration': '45:30',
      'hasTranscript': true,
      'playProgress': null, // Unplayed
      'isCurrentlyPlaying': false,
    },
    {
      'id': '2',
      'title': 'How to be more joyful',
      'duration': '32:15',
      'hasTranscript': false,
      'playProgress': 0.3, // Partially played
      'isCurrentlyPlaying': false,
    },
    {
      'id': '3',
      'title': 'The science of happiness',
      'duration': '58:42',
      'hasTranscript': true,
      'playProgress': 0.0, // Started but not progressed
      'isCurrentlyPlaying': true,
    },
    {
      'id': '4',
      'title': 'Building resilience in tough times',
      'duration': '41:18',
      'hasTranscript': true,
      'playProgress': 1.0, // Completed
      'isCurrentlyPlaying': false,
    },
    {
      'id': '5',
      'title': 'Mindfulness meditation guide',
      'duration': '25:33',
      'hasTranscript': false,
      'playProgress': 0.7, // Almost completed
      'isCurrentlyPlaying': false,
    },
  ];

  // Demo bookmarks
  final List<EpisodeBookmark> _demoBookmarks = [
    EpisodeBookmark(
      episodeId: '2',
      podcastId: 'demo_podcast',
      position: 300, // 5 minutes
      title: 'Key Point: Joy vs Happiness',
      notes:
          'Important distinction between temporary joy and lasting happiness',
      color: '#FF5722',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    EpisodeBookmark(
      episodeId: '2',
      podcastId: 'demo_podcast',
      position: 1200, // 20 minutes
      title: 'Practical Exercise',
      notes: 'Daily gratitude practice',
      color: '#4CAF50',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    EpisodeBookmark(
      episodeId: '5',
      podcastId: 'demo_podcast',
      position: 600, // 10 minutes
      title: 'Breathing Technique',
      notes: '4-7-8 breathing pattern',
      color: '#9C27B0',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // Current seek bar state
  double _currentProgress = 0.3;
  int _currentPosition = 600; // 10 minutes
  int _totalDuration = 1935; // 32:15 in seconds

  @override
  void initState() {
    super.initState();
    _initializeDemo();
  }

  Future<void> _initializeDemo() async {
    // Initialize the progress service
    await _progressService.initialize();

    // Add demo bookmarks to the service
    for (final bookmark in _demoBookmarks) {
      await _progressService.addBookmark(
        episodeId: bookmark.episodeId,
        podcastId: bookmark.podcastId,
        position: bookmark.position,
        title: bookmark.title,
        notes: bookmark.notes,
        color: bookmark.color,
      );
    }
  }

  void _onSeek(double progress) {
    setState(() {
      _currentProgress = progress;
      _currentPosition = (progress * _totalDuration).round();
    });

    // Update progress in the service
    _progressService.updateProgress(
      episodeId: '2',
      currentPosition: _currentPosition,
      totalDuration: _totalDuration,
    );
  }

  void _onBookmarkTap(int position, String title) {
    setState(() {
      _currentProgress = position / _totalDuration;
      _currentPosition = position;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jumped to bookmark: $title'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBookmarkAdd(int position, String title, String notes) {
    _progressService.addBookmark(
      episodeId: '2',
      podcastId: 'demo_podcast',
      position: position,
      title: title,
      notes: notes,
    );

    setState(() {
      // Refresh bookmarks
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark added: $title'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Episode Features Demo'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              await _progressService.syncProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synced to cloud')),
              );
            },
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Sync to Cloud',
          ),
          IconButton(
            onPressed: () async {
              await _progressService.getAllProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synced from cloud')),
              );
            },
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Sync from Cloud',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seek Bar Demo
            _buildSectionHeader('Seek Bar with Bookmarks'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: EpisodeSeekBar(
                progress: _currentProgress,
                currentPosition: _currentPosition,
                totalDuration: _totalDuration,
                bookmarks: _demoBookmarks
                    .where((b) => b.episodeId == '2')
                    .map((b) => b.toJson())
                    .toList(),
                onSeek: _onSeek,
                onBookmarkTap: _onBookmarkTap,
                onBookmarkAdd: _onBookmarkAdd,
                isPlaying: false,
                showBookmarks: true,
              ),
            ),

            SizedBox(height: 4.h),

            // Episode List Demo
            _buildSectionHeader('Episode List with Progress States'),
            ..._demoEpisodes.map((episode) => EpisodeListItem(
                  episode: episode,
                  onPlay: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing: ${episode['title']}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onLongPress: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Long pressed: ${episode['title']}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onShowDetails: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Show details: ${episode['title']}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  showTranscriptIcon: episode['hasTranscript'] ?? false,
                  showArchived: false,
                  playProgress: episode['playProgress'],
                  isCurrentlyPlaying: episode['isCurrentlyPlaying'] ?? false,
                )),

            SizedBox(height: 4.h),

            // Progress Statistics
            _buildSectionHeader('Progress Statistics'),
            FutureBuilder<List<EpisodeProgress>>(
              future: _progressService.getAllProgress(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final progressList = snapshot.data ?? [];
                final completedCount =
                    progressList.where((p) => p.isCompleted).length;
                final inProgressCount =
                    progressList.where((p) => !p.isCompleted).length;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(
                          'Total Episodes', progressList.length.toString()),
                      _buildStatRow('Completed', completedCount.toString()),
                      _buildStatRow('In Progress', inProgressCount.toString()),
                      _buildStatRow(
                          'Completion Rate',
                          progressList.isEmpty
                              ? '0%'
                              : '${((completedCount / progressList.length) * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 4.h),

            // Bookmarks List
            _buildSectionHeader('Episode Bookmarks'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: _demoBookmarks
                    .map((bookmark) => ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(int.parse(
                                  bookmark.color.replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(bookmark.title),
                          subtitle: Text(
                              '${bookmark.formattedPosition} - ${bookmark.episodeId}'),
                          trailing: Text(
                            bookmark.createdAt.toString().substring(0, 10),
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                          onTap: () =>
                              _onBookmarkTap(bookmark.position, bookmark.title),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h, top: 2.h),
      child: Text(
        title,
        style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
