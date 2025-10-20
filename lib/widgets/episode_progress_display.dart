import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../models/episode_progress.dart';

/// Widget for displaying episode progress consistently across the app
class EpisodeProgressDisplay extends StatelessWidget {
  final EpisodeProgress? progress;
  final bool isCurrentlyPlaying;
  final bool isPlaying;
  final VoidCallback? onTap;

  const EpisodeProgressDisplay({
    super.key,
    this.progress,
    this.isCurrentlyPlaying = false,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return const SizedBox.shrink();
    }

    final isCompleted = progress!.isCompleted;
    final isPartiallyPlayed = !isCompleted && progress!.currentPosition > 0;
    final hasProgress = isPartiallyPlayed || isCompleted;

    if (!hasProgress) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: _getProgressBackgroundColor(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getProgressBorderColor(),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress status row
            Row(
              children: [
                Icon(
                  _getProgressIcon(),
                  size: 14,
                  color: _getProgressIconColor(),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _getProgressStatusText(),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _getProgressTextColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (progress!.lastPlayedAt != null) ...[
                  Text(
                    _formatLastPlayedDate(progress!.lastPlayedAt!),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),

            // Progress bar
            if (isPartiallyPlayed) ...[
              SizedBox(height: 1.h),
              LinearProgressIndicator(
                value: progress!.progressRatio,
                backgroundColor: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressBarColor(),
                ),
                minHeight: 4,
              ),
              SizedBox(height: 0.5.h),
            ],

            // Progress details
            Row(
              children: [
                if (isPartiallyPlayed) ...[
                  Icon(
                    Icons.timer,
                    size: 12,
                    color: _getProgressTextColor(),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    progress!.formattedRemainingTime,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _getProgressTextColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 3.w),
                ],
                Text(
                  '${progress!.progressPercentage.round()}% complete',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: _getProgressTextColor(),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressBackgroundColor() {
    if (isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1);
    } else if (progress!.isCompleted) {
      return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05);
    } else {
      return AppTheme.lightTheme.colorScheme.surfaceVariant
          .withValues(alpha: 0.3);
    }
  }

  Color _getProgressBorderColor() {
    if (isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (progress!.isCompleted) {
      return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.5);
    } else {
      return AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3);
    }
  }

  IconData _getProgressIcon() {
    if (isCurrentlyPlaying) {
      return isPlaying ? Icons.play_arrow : Icons.pause;
    } else if (progress!.isCompleted) {
      return Icons.check_circle;
    } else {
      return Icons.timer;
    }
  }

  Color _getProgressIconColor() {
    if (isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (progress!.isCompleted) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getProgressStatusText() {
    if (isCurrentlyPlaying) {
      return isPlaying ? 'Now Playing' : 'Paused';
    } else if (progress!.isCompleted) {
      return 'Completed';
    } else {
      return 'Resume available';
    }
  }

  Color _getProgressTextColor() {
    if (isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (progress!.isCompleted) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  Color _getProgressBarColor() {
    if (isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  /// Format last played date for display
  String _formatLastPlayedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Compact version of progress display for list items
class CompactEpisodeProgressDisplay extends StatelessWidget {
  final EpisodeProgress? progress;
  final bool isCurrentlyPlaying;
  final bool isPlaying;

  const CompactEpisodeProgressDisplay({
    super.key,
    this.progress,
    this.isCurrentlyPlaying = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return const SizedBox.shrink();
    }

    final isCompleted = progress!.isCompleted;
    final isPartiallyPlayed = !isCompleted && progress!.currentPosition > 0;
    final hasProgress = isPartiallyPlayed || isCompleted;

    if (!hasProgress) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getProgressIcon(),
          size: 14,
          color: _getProgressIconColor(),
        ),
        SizedBox(width: 1.w),
        Text(
          _getProgressStatusText(),
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: _getProgressTextColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isPartiallyPlayed) ...[
          SizedBox(width: 2.w),
          Text(
            progress!.formattedRemainingTime,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: _getProgressTextColor(),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getProgressIcon() {
    if (isCurrentlyPlaying) {
      return isPlaying ? Icons.play_arrow : Icons.pause;
    } else if (progress!.isCompleted) {
      return Icons.check_circle;
    } else {
      return Icons.timer;
    }
  }

  Color _getProgressIconColor() {
    if (isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (progress!.isCompleted) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getProgressStatusText() {
    if (isCurrentlyPlaying) {
      return isPlaying ? 'Now Playing' : 'Paused';
    } else if (progress!.isCompleted) {
      return 'Completed';
    } else {
      return 'Resume';
    }
  }

  Color _getProgressTextColor() {
    if (isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (progress!.isCompleted) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return AppTheme.lightTheme.colorScheme.primary;
    }
  }
}
