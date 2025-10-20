import 'package:flutter/material.dart';
import '../core/utils/episode_utils.dart';

/// Test widget to verify audio URL extraction
class AudioUrlTestWidget extends StatefulWidget {
  const AudioUrlTestWidget({super.key});

  @override
  State<AudioUrlTestWidget> createState() => _AudioUrlTestWidgetState();
}

class _AudioUrlTestWidgetState extends State<AudioUrlTestWidget> {
  final List<Map<String, dynamic>> _testEpisodes = [
    {
      'id': '123',
      'title': 'Test Episode 1',
      'audioUrl': 'https://example.com/episode1.mp3',
    },
    {
      'id': '456',
      'title': 'Test Episode 2',
      'enclosureUrl': 'https://example.com/episode2.mp3',
    },
    {
      'id': '789',
      'title': 'Test Episode 3',
      'audio_url': 'https://example.com/episode3.mp3',
    },
    {
      'id': '101',
      'title': 'Test Episode 4',
      'enclosure_url': 'https://example.com/episode4.mp3',
    },
    {
      'id': '102',
      'title': 'Test Episode 5',
      'url': 'https://example.com/episode5.mp3',
    },
    {
      'id': '103',
      'title': 'Test Episode 6',
      'link': 'https://example.com/episode6.mp3',
    },
    {
      'id': '104',
      'title': 'Test Episode 7',
      // No audio URL - should fail
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio URL Extraction Test'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testEpisodes.length,
        itemBuilder: (context, index) {
          final episode = _testEpisodes[index];
          final episodeId = EpisodeUtils.extractEpisodeId(episode);
          final episodeTitle = EpisodeUtils.extractEpisodeTitle(episode);
          final audioUrl = EpisodeUtils.extractAudioUrl(episode);
          final hasValidUrl = EpisodeUtils.hasValidAudioUrl(episode);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Episode ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('ID: $episodeId'),
                  Text('Title: $episodeTitle'),
                  Text('Audio URL: ${audioUrl ?? 'NOT FOUND'}'),
                  Text(
                    'Valid for Download: ${hasValidUrl ? 'YES' : 'NO'}',
                    style: TextStyle(
                      color: hasValidUrl ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available Keys: ${episode.keys.toList()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
