import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_export.dart';
import '../providers/podcast_player_provider.dart';

class PlayingIndicator extends StatelessWidget {
  final String episodeId;
  final double size;

  const PlayingIndicator({
    super.key,
    required this.episodeId,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        final isCurrentEpisode = playerProvider.currentEpisode?.id == episodeId;
        final isPlaying = playerProvider.isPlaying && isCurrentEpisode;

        if (!isCurrentEpisode) {
          return const SizedBox.shrink();
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: size * 0.6,
          ),
        );
      },
    );
  }
}
