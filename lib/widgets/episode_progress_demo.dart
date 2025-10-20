import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import 'episode_list_item.dart';

class EpisodeProgressDemo extends StatelessWidget {
  const EpisodeProgressDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Progress Demo'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildDemoSection('Unplayed Episodes', [
            {
              'title': 'How to keep close friendships',
              'duration': '45:30',
              'hasTranscript': true,
              'playProgress': null,
              'isCurrentlyPlaying': false
            },
            {
              'title': 'How to be more joyful',
              'duration': '32:15',
              'hasTranscript': false,
              'playProgress': null,
              'isCurrentlyPlaying': false
            },
          ]),
          SizedBox(height: 3.h),
          _buildDemoSection('Partially Played Episodes', [
            {
              'title': 'How to find laughter anywhere',
              'duration': '28:45',
              'hasTranscript': true,
              'playProgress': 0.25,
              'isCurrentlyPlaying': false
            },
            {
              'title': 'The science of happiness',
              'duration': '52:10',
              'hasTranscript': true,
              'playProgress': 0.67,
              'isCurrentlyPlaying': false
            },
          ]),
          SizedBox(height: 3.h),
          _buildDemoSection('Currently Playing', [
            {
              'title': 'Mindfulness in daily life',
              'duration': '41:15',
              'hasTranscript': true,
              'playProgress': 0.45,
              'isCurrentlyPlaying': true
            },
          ]),
          SizedBox(height: 3.h),
          _buildDemoSection('Completed Episodes', [
            {
              'title': 'Introduction to meditation',
              'duration': '25:30',
              'hasTranscript': true,
              'playProgress': 1.0,
              'isCurrentlyPlaying': false
            },
            {
              'title': 'Stress management techniques',
              'duration': '35:45',
              'hasTranscript': false,
              'playProgress': 1.0,
              'isCurrentlyPlaying': false
            },
          ]),
        ],
      ),
    );
  }

  Widget _buildDemoSection(String title, List<Map<String, dynamic>> episodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary)),
        SizedBox(height: 2.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2)),
          ),
          child: Column(
            children: episodes
                .map((episode) => EpisodeListItem(
                      episode: episode,
                      onPlay: () => debugPrint('Play: ${episode['title']}'),
                      onLongPress: () =>
                          debugPrint('Long press: ${episode['title']}'),
                      onShowDetails: () =>
                          debugPrint('Show details: ${episode['title']}'),
                      showTranscriptIcon: episode['hasTranscript'] ?? false,
                      showArchived: false,
                      playProgress: episode['playProgress'],
                      isCurrentlyPlaying:
                          episode['isCurrentlyPlaying'] ?? false,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
