import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_export.dart';

class PlayerControlsWidget extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool isEarningActive;
  final double playbackSpeed;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBackward;
  final VoidCallback onSpeedControl;

  // Playlist navigation callbacks
  final VoidCallback? onPlayNext;
  final VoidCallback? onPlayPrevious;
  final bool isPlaylistMode;
  final bool canPlayNext;
  final bool canPlayPrevious;

  const PlayerControlsWidget({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.isEarningActive,
    required this.playbackSpeed,
    required this.onPlayPause,
    required this.onSkipForward,
    required this.onSkipBackward,
    required this.onSpeedControl,
    this.onPlayNext,
    this.onPlayPrevious,
    this.isPlaylistMode = false,
    this.canPlayNext = false,
    this.canPlayPrevious = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on theme and earning status
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color primaryControlColor =
        isDarkTheme ? Colors.white : AppTheme.lightTheme.colorScheme.onSurface;
    final Color secondaryControlColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.8)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.8);
    final Color disabledControlColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.5)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5);
    final Color controlBackgroundColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.1)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.1);
    final Color controlBorderColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.2)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.2);

    return Column(
      children: [
        // Playlist navigation row (only show in playlist mode)
        if (isPlaylistMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous episode button
              GestureDetector(
                onTap: canPlayPrevious ? onPlayPrevious : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: canPlayPrevious
                        ? controlBackgroundColor
                        : controlBackgroundColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: canPlayPrevious
                          ? controlBorderColor
                          : controlBorderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'skip_previous',
                      color: canPlayPrevious
                          ? primaryControlColor
                          : disabledControlColor,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Playlist info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: controlBackgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Playlist',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: primaryControlColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Next episode button
              GestureDetector(
                onTap: canPlayNext ? onPlayNext : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: canPlayNext
                        ? controlBackgroundColor
                        : controlBackgroundColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: canPlayNext
                          ? controlBorderColor
                          : controlBorderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'skip_next',
                      color: canPlayNext
                          ? primaryControlColor
                          : disabledControlColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (isPlaylistMode) SizedBox(height: 16),

        // Main player controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speed control
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onSpeedControl();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEarningActive
                  ? controlBackgroundColor.withValues(alpha: 0.5)
                  : controlBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isEarningActive
                    ? controlBorderColor.withValues(alpha: 0.5)
                    : controlBorderColor,
              ),
            ),
            child: Center(
              child: Text(
                '${playbackSpeed}x',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: isEarningActive
                      ? disabledControlColor
                      : primaryControlColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // Skip backward
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSkipBackward();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEarningActive
                  ? controlBackgroundColor.withValues(alpha: 0.5)
                  : controlBackgroundColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'replay_10',
                  color: isEarningActive
                      ? disabledControlColor
                      : primaryControlColor,
                  size: 28,
                ),
                if (isEarningActive)
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Play/Pause button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            onPlayPause();
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successLight.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: isPlaying ? 'pause' : 'play_arrow',
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
        ),

        // Skip forward
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSkipForward();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEarningActive
                  ? controlBackgroundColor.withValues(alpha: 0.5)
                  : controlBackgroundColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'forward_30',
                  color: isEarningActive
                      ? disabledControlColor
                      : primaryControlColor,
                  size: 28,
                ),
                if (isEarningActive)
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bookmark
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Implement bookmark functionality
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: controlBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: controlBorderColor,
              ),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'bookmark_border',
                color: primaryControlColor,
                size: 24,
              ),
            ),
          ),
            ),
          ],
        ),
      ],
    );
  }
}
