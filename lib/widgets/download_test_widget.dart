import 'package:flutter/material.dart';
import '../services/download_manager.dart';
import '../core/utils/episode_utils.dart';

/// Test widget to verify download functionality
class DownloadTestWidget extends StatefulWidget {
  const DownloadTestWidget({super.key});

  @override
  State<DownloadTestWidget> createState() => _DownloadTestWidgetState();
}

class _DownloadTestWidgetState extends State<DownloadTestWidget> {
  final DownloadManager _downloadManager = DownloadManager();
  bool _isLoading = false;
  String _status = 'Ready to test';

  final Map<String, dynamic> _testEpisode = {
    'id': '67228779',
    'title': 'Test Episode - Download Test',
    'enclosureUrl':
        'https://api.spreaker.com/download/episode/67228779/draft_175414047876963_audio.mp3',
  };

  @override
  void initState() {
    super.initState();
    _initializeDownloadManager();
  }

  Future<void> _initializeDownloadManager() async {
    try {
      await _downloadManager.initialize();
      setState(() {
        _status = 'Download manager initialized';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing: $e';
      });
    }
  }

  Future<void> _testDownload() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting download test...';
    });

    try {
      final episodeInfo = EpisodeUtils.getEpisodeDownloadInfo(_testEpisode);
      final episodeId = episodeInfo['episodeId'];
      final episodeTitle = episodeInfo['episodeTitle'];
      final audioUrl = episodeInfo['audioUrl'];

      if (episodeId == null || episodeTitle == null || audioUrl == null) {
        setState(() {
          _status = 'Invalid episode data for download';
          _isLoading = false;
        });
        return;
      }

      await _downloadManager.downloadEpisodeWithValidation(
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
        context: context,
        onDownloadComplete: () {
          setState(() {
            _status = 'Download completed successfully!';
            _isLoading = false;
          });
        },
        onDownloadError: () {
          setState(() {
            _status = 'Download failed';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Download error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Episode Info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text('ID: ${_testEpisode['id']}'),
                    Text('Title: ${_testEpisode['title']}'),
                    Text('Audio URL: ${_testEpisode['enclosureUrl']}'),
                    Text(
                        'Has Valid URL: ${EpisodeUtils.hasValidAudioUrl(_testEpisode)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDownload,
              child: const Text('Test Download'),
            ),
          ],
        ),
      ),
    );
  }
}
