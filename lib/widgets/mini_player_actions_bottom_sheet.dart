import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_player_provider.dart';
import '../providers/episode_progress_provider.dart';
import '../data/models/episode.dart';
import '../core/app_export.dart';

/// Bottom sheet that appears when swiping right on the mini-player
/// Contains actions for marking episodes as played and clearing the queue
class MiniPlayerActionsBottomSheet extends StatelessWidget {
  final Episode currentEpisode;

  const MiniPlayerActionsBottomSheet({
    super.key,
    required this.currentEpisode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
        child: SafeAreaUtils.wrapWithSafeArea(
      Material(
        elevation:
            64, // Increased from 32 to ensure it appears above mini-player overlay
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Episode info header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Episode thumbnail
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: currentEpisode.coverImage != null &&
                                currentEpisode.coverImage!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(currentEpisode.coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: currentEpisode.coverImage == null ||
                                currentEpisode.coverImage!.isEmpty
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : null,
                      ),
                      child: currentEpisode.coverImage == null ||
                              currentEpisode.coverImage!.isEmpty
                          ? Icon(
                              Icons.music_note,
                              color: theme.colorScheme.primary,
                              size: 24,
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
                            currentEpisode.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentEpisode.podcastName ?? 'Unknown Podcast',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Actions
              _buildActionItem(
                context: context,
                icon: Icons.check_circle_outline,
                title: 'Mark played',
                subtitle: 'Mark this episode as completed',
                onTap: () => _onMarkPlayed(context),
                iconColor: theme.colorScheme.primary,
                textColor: theme.colorScheme.onSurface,
              ),

              const Divider(height: 1),

              _buildActionItem(
                context: context,
                icon: Icons.close,
                title: 'Close and clear Up Next',
                subtitle: 'Stop playback and clear the queue',
                onTap: () => _onCloseAndClear(context),
                iconColor: theme.colorScheme.error,
                textColor: theme.colorScheme.error,
              ),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle "Mark played" action
  void _onMarkPlayed(BuildContext context) async {
    try {
      final progressProvider = context.read<EpisodeProgressProvider>();
      final playerProvider = context.read<PodcastPlayerProvider>();

      // Mark episode as played
      final success = await progressProvider.markEpisodeAsPlayed(
        episodeId: currentEpisode.id.toString(),
        podcastId: currentEpisode.podcastId?.toString(),
      );

      if (success) {
        // Update the episode in the player provider
        final updatedEpisode = currentEpisode.copyWith(
          isCompleted: true,
          lastPlayedAt: DateTime.now(),
        );

        // Update current episode if it's the same one
        if (playerProvider.currentEpisode?.id == currentEpisode.id) {
          // This will trigger UI updates
          // Note: notifyListeners() is called automatically by the provider when state changes
        }

        // Show success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Episode marked as played'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Failed to mark episode as played'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking episode as played: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Close the bottom sheet
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Handle "Close and clear Up Next" action
  void _onCloseAndClear(BuildContext context) async {
    try {
      final playerProvider = context.read<PodcastPlayerProvider>();

      // Clear the episode queue
      playerProvider.clearQueue();

      // Stop playback
      await playerProvider.pause();

      // Hide the mini-player (force hide for explicit user action)
      playerProvider.forceHideFloatingMiniPlayer();

      // Show feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.queue_music,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Queue cleared and player closed'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error closing and clearing queue: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Close the bottom sheet
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
