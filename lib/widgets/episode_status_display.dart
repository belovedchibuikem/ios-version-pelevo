import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../core/app_export.dart';
import '../providers/episode_progress_provider.dart';

/// Enhanced episode status display widget with real-time playback states
class EpisodeStatusDisplay extends StatelessWidget {
  final String episodeId;
  final EpisodeProgressProvider? progressProvider;
  final double? progress;
  final bool showProgressBar;
  final bool showStatusText;
  final bool showProgressPercentage;
  final VoidCallback? onTap;

  const EpisodeStatusDisplay({
    super.key,
    required this.episodeId,
    this.progressProvider,
    this.progress,
    this.showProgressBar = true,
    this.showStatusText = true,
    this.showProgressPercentage = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (progressProvider == null) {
      return _buildDefaultStatus();
    }

    return Consumer<EpisodeProgressProvider>(
      builder: (context, provider, child) {
        final displayStatus = provider.getEpisodeDisplayStatus(episodeId);

        return _buildStatusContent(displayStatus);
      },
    );
  }

  Widget _buildStatusContent(Map<String, dynamic> displayStatus) {
    final status = displayStatus['status'] as String;
    final progress = displayStatus['progress'] as double;
    final isPlaying = displayStatus['isPlaying'] as bool;
    final isBuffering = displayStatus['isBuffering'] as bool;
    final isPaused = displayStatus['isPaused'] as bool;
    final isCompleted = displayStatus['isCompleted'] as bool;
    final progressText = displayStatus['progressText'] as String;
    final statusColor = displayStatus['statusColor'] as Color?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: _getStatusBackgroundColor(status, isPlaying, isBuffering),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor ?? Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row with icon and text
            if (showStatusText) ...[
              Row(
                children: [
                  _buildStatusIcon(status, isPlaying, isBuffering, isPaused),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      status,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color:
                            _getStatusTextColor(status, isPlaying, isBuffering),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showProgressPercentage) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.w),
                      decoration: BoxDecoration(
                        color: statusColor?.withValues(alpha: 0.1) ??
                            Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        progressText,
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: statusColor ?? Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 1.h),
            ],

            // Progress bar
            if (showProgressBar && progress > 0) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  statusColor ?? AppTheme.lightTheme.colorScheme.primary,
                ),
                minHeight: 4,
              ),
              SizedBox(height: 0.5.h),
            ],

            // Progress details
            if (progress > 0 && !isCompleted) ...[
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 12,
                    color: _getStatusTextColor(status, isPlaying, isBuffering),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatProgressTime(progress),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color:
                          _getStatusTextColor(status, isPlaying, isBuffering),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(
      String status, bool isPlaying, bool isBuffering, bool isPaused) {
    IconData iconData;
    Color iconColor;

    if (isBuffering) {
      iconData = Icons.hourglass_empty;
      iconColor = Colors.orange;
    } else if (isPlaying) {
      iconData = Icons.play_arrow;
      iconColor = Colors.green;
    } else if (isPaused) {
      iconData = Icons.pause;
      iconColor = Colors.blue;
    } else if (status == 'Completed') {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else if (status == 'Resume Available') {
      iconData = Icons.replay;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.play_arrow;
      iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      size: 16,
      color: iconColor,
    );
  }

  Widget _buildDefaultStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.play_arrow, size: 16, color: Colors.grey),
          SizedBox(width: 2.w),
          Text(
            'Not Started',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBackgroundColor(
      String status, bool isPlaying, bool isBuffering) {
    if (isPlaying) {
      return Colors.green.withValues(alpha: 0.1);
    } else if (isBuffering) {
      return Colors.orange.withValues(alpha: 0.1);
    } else if (status == 'Completed') {
      return Colors.green.withValues(alpha: 0.05);
    } else if (status == 'Resume Available') {
      return Colors.blue.withValues(alpha: 0.1);
    } else {
      return Colors.grey.shade50;
    }
  }

  Color _getStatusTextColor(String status, bool isPlaying, bool isBuffering) {
    if (isPlaying) {
      return Colors.green.shade700;
    } else if (isBuffering) {
      return Colors.orange.shade700;
    } else if (status == 'Completed') {
      return Colors.green.shade700;
    } else if (status == 'Resume Available') {
      return Colors.blue.shade700;
    } else {
      return Colors.grey.shade700;
    }
  }

  String _formatProgressTime(double progress) {
    if (progress >= 1.0) return 'Completed';

    final percentage = (progress * 100).round();
    if (percentage < 10) return 'Just started';
    if (percentage < 25) return 'Getting started';
    if (percentage < 50) return 'Quarter way';
    if (percentage < 75) return 'Halfway through';
    if (percentage < 90) return 'Almost done';
    return 'Nearly finished';
  }
}

/// Compact episode status indicator for list items
class CompactEpisodeStatus extends StatelessWidget {
  final String episodeId;
  final EpisodeProgressProvider? progressProvider;
  final bool showProgress;

  const CompactEpisodeStatus({
    super.key,
    required this.episodeId,
    this.progressProvider,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    if (progressProvider == null) {
      return _buildDefaultIndicator();
    }

    return Consumer<EpisodeProgressProvider>(
      builder: (context, provider, child) {
        final displayStatus = provider.getEpisodeDisplayStatus(episodeId);

        return _buildCompactIndicator(displayStatus);
      },
    );
  }

  Widget _buildCompactIndicator(Map<String, dynamic> displayStatus) {
    final status = displayStatus['status'] as String;
    final progress = displayStatus['progress'] as double;
    final isPlaying = displayStatus['isPlaying'] as bool;
    final isBuffering = displayStatus['isBuffering'] as bool;
    final isPaused = displayStatus['isPaused'] as bool;
    final statusColor = displayStatus['statusColor'] as Color?;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status icon
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getIndicatorBackgroundColor(status, isPlaying, isBuffering),
            border: Border.all(
              color: statusColor ?? Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Icon(
            _getIndicatorIcon(status, isPlaying, isBuffering, isPaused),
            size: 4.w,
            color: statusColor ?? Colors.grey.shade600,
          ),
        ),

        SizedBox(width: 2.w),

        // Status text
        Text(
          status,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: _getStatusTextColor(status, isPlaying, isBuffering),
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),

        // Progress percentage
        if (showProgress && progress > 0) ...[
          SizedBox(width: 2.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.w),
            decoration: BoxDecoration(
              color:
                  statusColor?.withValues(alpha: 0.1) ?? Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(progress * 100).round()}%',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: statusColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultIndicator() {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: Icon(
        Icons.play_arrow,
        size: 4.w,
        color: Colors.grey.shade600,
      ),
    );
  }

  IconData _getIndicatorIcon(
      String status, bool isPlaying, bool isBuffering, bool isPaused) {
    if (isBuffering) return Icons.hourglass_empty;
    if (isPlaying) return Icons.play_arrow;
    if (isPaused) return Icons.pause;
    if (status == 'Completed') return Icons.check;
    if (status == 'Resume Available') return Icons.replay;
    return Icons.play_arrow;
  }

  Color _getIndicatorBackgroundColor(
      String status, bool isPlaying, bool isBuffering) {
    if (isPlaying) return Colors.green.withValues(alpha: 0.2);
    if (isBuffering) return Colors.orange.withValues(alpha: 0.2);
    if (status == 'Completed') return Colors.green.withValues(alpha: 0.2);
    if (status == 'Resume Available') return Colors.blue.withValues(alpha: 0.2);
    return Colors.grey.shade100;
  }

  Color _getStatusTextColor(String status, bool isPlaying, bool isBuffering) {
    if (isPlaying) return Colors.green.shade700;
    if (isBuffering) return Colors.orange.shade700;
    if (status == 'Completed') return Colors.green.shade700;
    if (status == 'Resume Available') return Colors.blue.shade700;
    return Colors.grey.shade700;
  }
}
