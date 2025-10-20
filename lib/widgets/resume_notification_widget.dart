import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';

/// Widget to show resume notifications when episodes resume from saved positions
class ResumeNotificationWidget extends StatelessWidget {
  final Duration resumePosition;
  final Duration totalDuration;
  final VoidCallback? onDismiss;
  final VoidCallback? onRestart;
  final VoidCallback? onContinue;

  const ResumeNotificationWidget({
    super.key,
    required this.resumePosition,
    required this.totalDuration,
    this.onDismiss,
    this.onRestart,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
        (resumePosition.inMilliseconds / totalDuration.inMilliseconds) * 100;
    final remainingTime = totalDuration - resumePosition;

    return RepaintBoundary(
      child: SafeAreaUtils.wrapWithSafeArea(
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildNotificationContent(context),
        ),
      ),
    );
  }

  Widget _buildNotificationContent(BuildContext context) {
    final progressPercentage =
        (resumePosition.inMilliseconds / totalDuration.inMilliseconds) * 100;
    final remainingTime = totalDuration - resumePosition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with resume icon and title
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Resuming Episode',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.lightTheme.colorScheme.onSurface,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),

        SizedBox(height: 2.h),

        // Progress information
        Row(
          children: [
            Icon(
              Icons.timer,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.lightTheme.colorScheme.onSurface,
            ),
            SizedBox(width: 2.w),
            Text(
              'Resuming from ${_formatDuration(resumePosition)} of ${_formatDuration(totalDuration)}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        SizedBox(height: 1.h),

        // Progress bar
        LinearProgressIndicator(
          value: progressPercentage / 100,
          backgroundColor:
              AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.colorScheme.primary,
          ),
          minHeight: 6,
        ),

        SizedBox(height: 1.h),

        // Progress details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progressPercentage.toStringAsFixed(1)}% complete',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.lightTheme.colorScheme.onSurface)
                    .withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${_formatDuration(remainingTime)} remaining',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.lightTheme.colorScheme.onSurface)
                    .withValues(alpha: 0.8),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Action buttons
        Row(
          children: [
            if (onRestart != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onRestart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                    side: BorderSide(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                  child: Text(
                    'Start Over',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: onContinue ?? onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  'Continue',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Compact version for inline display
class CompactResumeIndicator extends StatelessWidget {
  final Duration resumePosition;
  final Duration totalDuration;
  final VoidCallback? onRestart;

  const CompactResumeIndicator({
    super.key,
    required this.resumePosition,
    required this.totalDuration,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
        (resumePosition.inMilliseconds / totalDuration.inMilliseconds) * 100;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : AppTheme.lightTheme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 16,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(width: 2.w),
          Text(
            'Resume from ${_formatDuration(resumePosition)}',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRestart != null) ...[
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: onRestart,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.refresh,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
