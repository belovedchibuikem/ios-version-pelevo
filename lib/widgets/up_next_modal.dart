import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_player_provider.dart';
import '../data/models/episode.dart';

class UpNextModal extends StatefulWidget {
  const UpNextModal({super.key});

  @override
  State<UpNextModal> createState() => _UpNextModalState();
}

class _UpNextModalState extends State<UpNextModal> {
  @override
  void initState() {
    super.initState();

    // Hide mini-player when Up Next modal is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final playerProvider =
              Provider.of<PodcastPlayerProvider>(context, listen: false);
          playerProvider.hideFloatingMiniPlayer();
        } catch (e) {
          debugPrint('Error hiding mini-player in UpNext modal initState: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    // Show mini-player again when Up Next modal is closed
    // Use a delayed callback to ensure the widget is still mounted
    Future.delayed(Duration.zero, () {
      if (mounted) {
        try {
          final playerProvider =
              Provider.of<PodcastPlayerProvider>(context, listen: false);
          // Use the new persistent mini-player logic
          playerProvider.showMiniPlayerIfAppropriate(context);
        } catch (e) {
          debugPrint('Error showing mini-player in UpNext modal dispose: $e');
        }
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentEpisode = playerProvider.currentEpisode;
        final queue = playerProvider.episodeQueue;

        return Material(
          elevation:
              100, // High elevation to ensure it appears above mini-player
          color: Colors.transparent,
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            appBar: AppBar(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              elevation: 10, // Higher than mini-player to appear above it
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              title: Text(
                'Up Next',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              centerTitle: true,
              actions: [
                // Filter/Sort button
                IconButton(
                  onPressed: () => _showSortOptions(context),
                  icon: Icon(
                    Icons.sort,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),

                // Select button
                IconButton(
                  onPressed: () => _toggleSelectionMode(),
                  icon: Icon(
                    Icons.check_box_outline_blank,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Currently Playing/Next Episode
                if (currentEpisode != null)
                  _buildCurrentEpisode(currentEpisode),

                // Queue Summary
                _buildQueueSummary(queue.length),

                // Upcoming Episodes List
                Expanded(
                  child: _buildEpisodesList(queue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentEpisode(Episode currentEpisode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Episode artwork
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: currentEpisode.coverImage?.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(currentEpisode.coverImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: currentEpisode.coverImage?.isEmpty != false
                  ? Colors.grey[600]
                  : null,
            ),
            child: currentEpisode.coverImage?.isEmpty != false
                ? Icon(
                    Icons.music_note,
                    color: Colors.grey[400],
                    size: 30,
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Episode details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(currentEpisode.releaseDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentEpisode.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDurationString(currentEpisode.duration),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                ),
              ],
            ),
          ),

          // Play next button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _playNext(),
              icon: Icon(
                Icons.play_arrow,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSummary(int episodeCount) {
    final totalDuration = _calculateTotalDuration();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$episodeCount episodes - ${_formatDuration(totalDuration)} left',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
          ),

          // Shuffle button
          IconButton(
            onPressed: () => _shuffleQueue(),
            icon: Icon(
              Icons.shuffle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList(List<Episode> queue) {
    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              'No episodes in queue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add episodes to your queue to see them here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final episode = queue[index];
        return _buildEpisodeItem(episode, index);
      },
    );
  }

  Widget _buildEpisodeItem(Episode episode, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Episode artwork
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: episode.coverImage?.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(episode.coverImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: episode.coverImage?.isEmpty != false
                  ? Colors.grey[600]
                  : null,
            ),
            child: episode.coverImage?.isEmpty != false
                ? Icon(
                    Icons.music_note,
                    color: Colors.grey[400],
                    size: 30,
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Episode details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E${index + 1} • ${_formatDate(episode.releaseDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  episode.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDurationString(episode.duration),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                ),
              ],
            ),
          ),

          // More options button
          IconButton(
            onPressed: () => _showEpisodeOptions(episode, index),
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown Date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'TODAY';
    } else if (difference.inDays == 1) {
      return 'YESTERDAY';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} DAYS AGO';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDurationString(String duration) {
    // Parse duration string (e.g., "01:30:00" or "30:00")
    final parts = duration.split(':');
    if (parts.length == 3) {
      // HH:MM:SS format
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    } else if (parts.length == 2) {
      // MM:SS format
      final minutes = int.tryParse(parts[0]) ?? 0;
      return '${minutes}m';
    } else {
      return duration; // Return as-is if can't parse
    }
  }

  int _calculateTotalDuration() {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    final queue = playerProvider.episodeQueue;

    return queue.fold(0, (total, episode) {
      // Parse duration string to seconds
      final parts = episode.duration.split(':');
      if (parts.length == 3) {
        // HH:MM:SS format
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return total + (hours * 3600 + minutes * 60 + seconds);
      } else if (parts.length == 2) {
        // MM:SS format
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return total + (minutes * 60 + seconds);
      } else {
        return total; // Skip if can't parse
      }
    });
  }

  void _playNext() {
    // This would play the next episode in the queue
    debugPrint('Playing next episode');
  }

  void _shuffleQueue() {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    playerProvider.shuffleQueue();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.shuffle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Queue shuffled'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Sort Queue',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.access_time,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'By Date (Newest First)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sortQueue('date');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.schedule,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'By Duration (Shortest First)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sortQueue('duration');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.sort_by_alpha,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'By Title (A-Z)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sortQueue('title');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _sortQueue(String sortBy) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    playerProvider.sortQueue(sortBy);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.sort, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Queue sorted by ${sortBy}'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSelectionMode() {
    // TODO: Implement selection mode for bulk actions
    debugPrint('Toggle selection mode');
  }

  void _showEpisodeOptions(Episode episode, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                episode.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.play_arrow,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'Play Now',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _playEpisode(episode);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.remove_circle_outline,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'Remove from Queue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeFromQueue(episode, index);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'Share Episode',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareEpisode(episode);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _playEpisode(Episode episode) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    playerProvider.playEpisode(episode);

    Navigator.pop(context); // Close the Up Next modal

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Now playing: ${episode.title}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeFromQueue(Episode episode, int index) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    playerProvider.removeFromQueue(index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.remove_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Removed from queue: ${episode.title}'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareEpisode(Episode episode) {
    // TODO: Implement episode sharing
    debugPrint('Sharing episode: ${episode.title}');
  }
}
