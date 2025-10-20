import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/episode_progress_provider.dart';
import '../data/models/episode.dart';

/// Sample widget demonstrating real-time episode progress updates
/// This shows how to integrate the EpisodeProgressProvider with episode lists
class RealTimeEpisodeList extends StatefulWidget {
  final List<Episode> episodes;
  final String podcastId;

  const RealTimeEpisodeList({
    super.key,
    required this.episodes,
    required this.podcastId,
  });

  @override
  State<RealTimeEpisodeList> createState() => _RealTimeEpisodeListState();
}

class _RealTimeEpisodeListState extends State<RealTimeEpisodeList> {
  @override
  void initState() {
    super.initState();
    // Load progress for all episodes when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEpisodeProgress();
    });
  }

  Future<void> _loadEpisodeProgress() async {
    final progressProvider = context.read<EpisodeProgressProvider>();
    final episodeIds = widget.episodes.map((e) => e.id.toString()).toList();
    await progressProvider.loadProgressForEpisodes(episodeIds);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EpisodeProgressProvider>(
      builder: (context, progressProvider, child) {
        return ListView.builder(
          itemCount: widget.episodes.length,
          itemBuilder: (context, index) {
            final episode = widget.episodes[index];
            final episodeId = episode.id.toString();

            // Get real-time progress data
            final progress = progressProvider.getProgress(episodeId);
            final isCompleted = progressProvider.isEpisodeCompleted(episodeId);
            final progressPercentage =
                progressProvider.getProgressPercentage(episodeId);
            final isLoading = progressProvider.isLoading(episodeId);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading:
                    _buildEpisodeStatusIcon(isCompleted, progressPercentage),
                title: Text(
                  episode.title,
                  style: TextStyle(
                    fontWeight:
                        isCompleted ? FontWeight.normal : FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(episode.description ?? 'No description'),
                    const SizedBox(height: 8),
                    _buildProgressIndicator(progressPercentage, progress),
                    if (isLoading)
                      const LinearProgressIndicator(
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                  ],
                ),
                trailing: _buildProgressActions(episode, progressProvider),
                onTap: () => _onEpisodeTap(episode, progressProvider),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEpisodeStatusIcon(bool isCompleted, double progressPercentage) {
    if (isCompleted) {
      return const CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(Icons.check, color: Colors.white),
      );
    } else if (progressPercentage > 0) {
      return CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          '${progressPercentage.toInt()}%',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.play_arrow, color: Colors.white),
      );
    }
  }

  Widget _buildProgressIndicator(double progressPercentage, dynamic progress) {
    if (progress == null) {
      return const Text('Not started');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progressPercentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progressPercentage >= 90 ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${progressPercentage.toStringAsFixed(1)}% complete',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProgressActions(
      Episode episode, EpisodeProgressProvider progressProvider) {
    final episodeId = episode.id.toString();
    final isCompleted = progressProvider.isEpisodeCompleted(episodeId);

    return PopupMenuButton<String>(
      onSelected: (value) =>
          _handleProgressAction(value, episode, progressProvider),
      itemBuilder: (context) => [
        if (!isCompleted)
          const PopupMenuItem(
            value: 'mark_completed',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Mark as Completed'),
              ],
            ),
          ),
        if (isCompleted)
          const PopupMenuItem(
            value: 'reset_progress',
            child: Row(
              children: [
                Icon(Icons.refresh, color: Colors.blue),
                SizedBox(width: 8),
                Text('Reset Progress'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, color: Colors.orange),
              SizedBox(width: 8),
              Text('Refresh Progress'),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  void _handleProgressAction(String action, Episode episode,
      EpisodeProgressProvider progressProvider) async {
    final episodeId = episode.id.toString();

    switch (action) {
      case 'mark_completed':
        await progressProvider.markCompleted(episodeId);
        break;
      case 'reset_progress':
        await progressProvider.updateProgress(
          episodeId: episodeId,
          currentPosition: 0,
          totalDuration:
              episode.duration is int ? episode.duration as int : null,
        );
        break;
      case 'refresh':
        await progressProvider.refreshProgress(episodeId);
        break;
    }
  }

  void _onEpisodeTap(
      Episode episode, EpisodeProgressProvider progressProvider) {
    // Handle episode tap - could start playback, show details, etc.
    debugPrint('Episode tapped: ${episode.title}');

    // Example: Load fresh progress data
    progressProvider.refreshProgress(episode.id.toString());
  }
}

/// Example usage in a screen:
///
/// ```dart
/// class PodcastDetailScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Podcast Episodes')),
///       body: RealTimeEpisodeList(
///         episodes: podcastEpisodes,
///         podcastId: podcastId,
///       ),
///     );
///   }
/// }
/// ```
