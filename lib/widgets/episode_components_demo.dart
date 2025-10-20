import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import 'episode_list_item.dart';
import 'enhanced_search_bar.dart';
import '../core/utils/date_grouping_utils.dart';

/// Demo file showing how to use the new episode components
/// This demonstrates the reusability of the components across different screens
class EpisodeComponentsDemo extends StatelessWidget {
  const EpisodeComponentsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Components Demo'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo 1: Enhanced Search Bar
            Text(
              'Enhanced Search Bar',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            EnhancedSearchBar(
              hintText: 'Search episodes...',
              onChanged: (query) => debugPrint('Search: $query'),
              onMoreOptionsTap: () => _showMoreOptions(context),
            ),

            SizedBox(height: 4.h),

            // Demo 2: Episode List Item
            Text(
              'Episode List Item',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            _buildDemoEpisodeItem(),

            SizedBox(height: 4.h),

            // Demo 3: Date Grouping
            Text(
              'Date Grouping Demo',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            _buildDateGroupingDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoEpisodeItem() {
    final demoEpisode = {
      'title': 'Can Carney move fast enough on affordable housing?',
      'duration': 1620, // 27 minutes in seconds
      'hasTranscript': true,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightTheme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: EpisodeListItem(
        episode: demoEpisode,
        onPlay: () => debugPrint('Play episode'),
        onLongPress: () => debugPrint('Long press episode'),
        onShowDetails: () => debugPrint('Show episode details'),
        showTranscriptIcon: true,
      ),
    );
  }

  Widget _buildDateGroupingDemo() {
    final demoEpisodes = [
      {
        'title': 'Episode 1',
        'duration': 1800,
        'releaseDate': DateTime.now().toIso8601String(),
        'hasTranscript': false,
      },
      {
        'title': 'Episode 2',
        'duration': 2400,
        'releaseDate':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'hasTranscript': true,
      },
      {
        'title': 'Episode 3',
        'duration': 3600,
        'releaseDate':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'hasTranscript': false,
      },
    ];

    final groupedEpisodes = DateGroupingUtils.groupEpisodesByDate(demoEpisodes);
    final sortedHeaders =
        DateGroupingUtils.getSortedDateHeaders(groupedEpisodes);

    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.lightTheme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: sortedHeaders.map((header) {
            final episodesInGroup = groupedEpisodes[header] ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Text(
                    header,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...episodesInGroup.map((episode) => EpisodeListItem(
                      episode: episode,
                      onPlay: () => debugPrint('Play ${episode['title']}'),
                      onLongPress: () =>
                          debugPrint('Long press ${episode['title']}'),
                      onShowDetails: () =>
                          debugPrint('Show details ${episode['title']}'),
                      showTranscriptIcon: episode['hasTranscript'] ?? false,
                    )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('More Options'),
        content: const Text(
            'This shows how the enhanced search bar can be used with custom options.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Example of how to use EpisodeListItem in a library screen
class LibraryEpisodeList extends StatelessWidget {
  final List<Map<String, dynamic>> episodes;
  final Function(Map<String, dynamic>) onPlayEpisode;

  const LibraryEpisodeList({
    super.key,
    required this.episodes,
    required this.onPlayEpisode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        return EpisodeListItem(
          episode: episode,
          onPlay: () => onPlayEpisode(episode),
          onLongPress: () => debugPrint('Long press ${episode['title']}'),
          onShowDetails: () => debugPrint('Show details ${episode['title']}'),
          showTranscriptIcon: episode['hasTranscript'] ?? false,
        );
      },
    );
  }
}

/// Example of how to use EpisodeListItem in search results
class SearchResultsEpisodeList extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final Function(Map<String, dynamic>) onPlayEpisode;

  const SearchResultsEpisodeList({
    super.key,
    required this.searchResults,
    required this.onPlayEpisode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        EnhancedSearchBar(
          hintText: 'Search podcasts and episodes...',
          onChanged: (query) => debugPrint('Search query: $query'),
          onMoreOptionsTap: () => debugPrint('More search options'),
        ),

        // Search results
        Expanded(
          child: ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final episode = searchResults[index];
              return EpisodeListItem(
                episode: episode,
                onPlay: () => onPlayEpisode(episode),
                onLongPress: () => debugPrint('Long press ${episode['title']}'),
                onShowDetails: () =>
                    debugPrint('Show details ${episode['title']}'),
                showTranscriptIcon: episode['hasTranscript'] ?? false,
              );
            },
          ),
        ),
      ],
    );
  }
}
