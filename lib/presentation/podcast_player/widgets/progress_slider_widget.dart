import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/podcast_player/widgets/progress_slider_widget.dart

class ProgressSliderWidget extends StatelessWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final Function(double) onSeek;

  const ProgressSliderWidget({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  double get _progressValue {
    if (totalDuration.inMilliseconds <= 0) return 0.0;
    return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Time labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentPosition),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 1.h),

        // Progress slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
            inactiveTrackColor:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            thumbColor: AppTheme.lightTheme.colorScheme.primary,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 4,
            ),
            overlayColor:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 20,
            ),
            trackHeight: 4,
          ),
          child: Slider(
            value: _progressValue.clamp(0.0, 1.0),
            onChanged: onSeek,
            min: 0.0,
            max: 1.0,
          ),
        ),
      ],
    );
  }
}
