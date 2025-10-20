import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/download_manager.dart';
import '../core/app_export.dart';
import 'download_progress_widget.dart';
import 'offline_mode_indicator.dart';

/// Example widget showing how to integrate download functionality
class DownloadIntegrationExample extends StatefulWidget {
  const DownloadIntegrationExample({super.key});

  @override
  State<DownloadIntegrationExample> createState() =>
      _DownloadIntegrationExampleState();
}

class _DownloadIntegrationExampleState
    extends State<DownloadIntegrationExample> {
  final DownloadManager _downloadManager = DownloadManager();
  bool _isOffline = false;
  String? _currentEpisodeId;

  @override
  void initState() {
    super.initState();
    _initializeDownloadManager();
  }

  Future<void> _initializeDownloadManager() async {
    await _downloadManager.initialize();
  }

  Future<void> _downloadEpisode() async {
    const episodeId = 'example_episode_123';
    const episodeTitle = 'Example Episode';
    const audioUrl = 'https://example.com/episode.mp3';

    await _downloadManager.downloadEpisodeWithValidation(
      episodeId: episodeId,
      episodeTitle: episodeTitle,
      audioUrl: audioUrl,
      context: context,
      onDownloadComplete: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download completed!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onDownloadError: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed!'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _playEpisode() async {
    const episodeId = 'example_episode_123';
    const episodeTitle = 'Example Episode';
    const audioUrl = 'https://example.com/episode.mp3';

    await _downloadManager.playEpisodeWithOfflineDetection(
      episodeId: episodeId,
      episodeTitle: episodeTitle,
      audioUrl: audioUrl,
      context: context,
    );

    // Check if playing offline
    final playbackInfo =
        await _downloadManager.getEpisodePlaybackInfo(episodeId);
    setState(() {
      _isOffline = playbackInfo['isOffline'] ?? false;
      _currentEpisodeId = episodeId;
    });
  }

  Future<void> _checkDownloadStatus() async {
    const episodeId = 'example_episode_123';
    final playbackInfo =
        await _downloadManager.getEpisodePlaybackInfo(episodeId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status: ${playbackInfo['isOffline'] ? 'Offline' : 'Online'}, '
          'Downloading: ${playbackInfo['isDownloading']}, '
          'Progress: ${(playbackInfo['downloadProgress'] * 100).toInt()}%',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download System Example'),
        backgroundColor: currentTheme.colorScheme.primary,
        foregroundColor: currentTheme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline mode indicator
            OfflineModeIndicator(
              isOffline: _isOffline,
              episodeTitle: _isOffline ? 'Example Episode' : null,
            ),

            SizedBox(height: 4.h),

            // Download progress widget
            DownloadProgressWidget(
              episodeId: 'example_episode_123',
              episodeTitle: 'Example Episode',
              audioUrl: 'https://example.com/episode.mp3',
              onDownloadComplete: () {
                setState(() {
                  // Refresh UI after download
                });
              },
              onDownloadError: () {
                // Handle download error
              },
            ),

            SizedBox(height: 4.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadEpisode,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Episode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.colorScheme.primary,
                      foregroundColor: currentTheme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _playEpisode,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Episode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.colorScheme.secondary,
                      foregroundColor: currentTheme.colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            ElevatedButton.icon(
              onPressed: _checkDownloadStatus,
              icon: const Icon(Icons.info),
              label: const Text('Check Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.colorScheme.tertiary,
                foregroundColor: currentTheme.colorScheme.onTertiary,
              ),
            ),

            SizedBox(height: 4.h),

            // Status information
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download System Status',
                      style: currentTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text('Offline Mode: ${_isOffline ? 'Yes' : 'No'}'),
                    Text('Current Episode: ${_currentEpisodeId ?? 'None'}'),
                    Text(
                        'Active Downloads: ${_downloadManager.activeDownloads.length}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _downloadManager.dispose();
    super.dispose();
  }
}
