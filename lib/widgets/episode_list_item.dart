import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../core/utils/duration_utils.dart';
import 'resume_notification_widget.dart';
import '../services/smart_buffering_service.dart';

class EpisodeListItem extends StatefulWidget {
  final Map<String, dynamic> episode;
  final VoidCallback onPlay;
  final VoidCallback onLongPress;
  final VoidCallback onShowDetails;
  final bool showTranscriptIcon;
  final bool showArchived;
  final double playProgress;
  final bool isCurrentlyPlaying;
  final bool isActiveEpisode;
  final bool isPlaying;
  final int? lastPlayedPosition;
  final int? totalDuration;
  final DateTime? lastPlayedAt;

  EpisodeListItem({
    super.key,
    required this.episode,
    required this.onPlay,
    required this.onLongPress,
    required this.onShowDetails,
    this.showTranscriptIcon = false,
    this.showArchived = false,
    this.playProgress = 0.0,
    this.isCurrentlyPlaying = false,
    this.isActiveEpisode = false,
    this.isPlaying = false,
    this.lastPlayedPosition,
    this.totalDuration,
    this.lastPlayedAt,
  });

  @override
  bool get wantKeepAlive => true; // Prevents state loss during scrolling

  @override
  State<EpisodeListItem> createState() => _EpisodeListItemState();
}

class _EpisodeListItemState extends State<EpisodeListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Prevents state loss during scrolling

  /// Get progress percentage from episode data
  double get _episodeProgress {
    if (widget.playProgress != null) return widget.playProgress;
    if (widget.lastPlayedPosition != null &&
        widget.totalDuration != null &&
        widget.totalDuration! > 0) {
      return (widget.lastPlayedPosition! / widget.totalDuration!)
          .clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Get remaining time string
  String get _remainingTimeString {
    if (widget.lastPlayedPosition == null || widget.totalDuration == null)
      return '';

    final remaining = widget.totalDuration! - widget.lastPlayedPosition!;
    if (remaining <= 0) return '';

    final hours = remaining ~/ 3600000;
    final minutes = (remaining % 3600000) ~/ 60000;
    final seconds = (remaining % 60000) ~/ 1000;

    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s remaining';
    } else {
      return '${seconds}s remaining';
    }
  }

  /// Check if episode is partially played
  bool get _isPartiallyPlayed {
    return _episodeProgress > 0.0 && _episodeProgress < 1.0;
  }

  /// Check if episode is completed
  bool get _isCompleted {
    return _episodeProgress >= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final String title = widget.episode['title'] ?? 'Untitled Episode';
    final dynamic duration = widget.episode['duration'];
    final String formattedDuration = DurationUtils.formatDuration(duration);
    final bool hasTranscript = widget.episode['hasTranscript'] ?? false;

    // Determine episode state using new progress properties
    final bool isPlayed = _isCompleted;
    final bool isPartiallyPlayed = _isPartiallyPlayed;
    final bool isUnplayed = _episodeProgress == 0.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Row(
            children: [
              // Episode info (title and duration) - Clickable for showing episode details
              Expanded(
                child: GestureDetector(
                  onTap: widget.onShowDetails,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Now Playing badge (only show for active episode)
                          if (widget.isActiveEpisode) ...[
                            StreamBuilder<bool>(
                              stream: SmartBufferingService().bufferingStream,
                              initialData: false,
                              builder: (context, bufferingSnapshot) {
                                final isBuffering =
                                    bufferingSnapshot.data ?? false;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 0.5.h),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2.w, vertical: 0.3.h),
                                  decoration: BoxDecoration(
                                    color: isBuffering
                                        ? Colors.orange
                                        : AppTheme
                                            .lightTheme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isBuffering
                                            ? Icons.radio
                                            : (widget.isPlaying
                                                ? Icons.play_arrow
                                                : Icons.pause),
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        isBuffering
                                            ? 'Buffering...'
                                            : (widget.isPlaying
                                                ? 'Now Playing'
                                                : 'Paused'),
                                        style: AppTheme
                                            .lightTheme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          // Episode title
                          Text(
                            title,
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                              color: isPlayed
                                  ? AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6)
                                  : AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 1.h),

                          // Progress and time information
                          if (isPartiallyPlayed || widget.isActiveEpisode) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  _remainingTimeString.isNotEmpty
                                      ? _remainingTimeString
                                      : 'Resume available',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                          ],

                          // Resume indicator for episodes with significant progress
                          if (_isPartiallyPlayed &&
                              !widget.isActiveEpisode &&
                              _episodeProgress > 0.1) ...[
                            CompactResumeIndicator(
                              resumePosition: Duration(
                                  milliseconds: widget.lastPlayedPosition ?? 0),
                              totalDuration: Duration(
                                  milliseconds: widget.totalDuration ?? 0),
                              onRestart: () {
                                // TODO: Implement restart functionality
                                debugPrint(
                                    'Restart episode: ${widget.episode['title']}');
                              },
                            ),
                            SizedBox(height: 0.5.h),
                          ],

                          // Completion indicator for finished episodes
                          if (_isCompleted && !widget.isActiveEpisode) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  'Completed',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (widget.lastPlayedAt != null) ...[
                                  SizedBox(width: 2.w),
                                  Text(
                                    _formatLastPlayedDate(widget.lastPlayedAt!),
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                          ],

                          // Duration, date, and transcript icon
                          Row(
                            children: [
                              if (widget.showTranscriptIcon &&
                                  hasTranscript) ...[
                                Container(
                                  margin: EdgeInsets.only(right: 2.w),
                                  child: Icon(
                                    Icons.text_fields,
                                    size: 16,
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                  ),
                                ),
                              ],
                              Text(
                                formattedDuration,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: isPlayed
                                      ? AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.5)
                                      : AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              // Add datePublished display (with fallback)
                              if (_hasValidDate(widget.episode)) ...[
                                SizedBox(width: 2.w),
                                Text(
                                  ' • ',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                Text(
                                  _formatDateWithFallback(widget.episode),
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: isPlayed
                                        ? AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.5)
                                        : AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Progress-aware play button - Clickable for playing episode directly
              Container(
                margin: EdgeInsets.only(left: 4.w),
                child: GestureDetector(
                  onTap: widget.onPlay,
                  onLongPress: widget.onLongPress,
                  onDoubleTap: widget.onShowDetails,
                  child: _buildProgressButton(),
                ),
              ),
            ],
          ),
        ),
        // Progress bar (show for partially played episodes or active episode)
        if ((isPartiallyPlayed && !widget.isCurrentlyPlaying) ||
            widget.isActiveEpisode)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _episodeProgress,
                  backgroundColor: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isActiveEpisode
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
                // Progress text
                if (isPartiallyPlayed && !widget.isActiveEpisode) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    '${(_episodeProgress * 100).round()}% complete',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        // Line divider between episodes
        Divider(
          height: 1,
          thickness: 1.0,
          color: AppTheme.lightTheme.colorScheme.outline,
          indent: 4.w,
          endIndent: 4.w,
        ),
      ],
    );
  }

  Widget _buildProgressButton() {
    final bool isPlayed = _isCompleted;
    final bool isPartiallyPlayed = _isPartiallyPlayed;
    final bool isUnplayed = _episodeProgress == 0.0;

    return Container(
      width: 12.w,
      height: 12.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getButtonBorderColor(),
                width: 2,
              ),
              color: _getButtonBackgroundColor(),
            ),
          ),

          // Progress indicator (for partially played episodes)
          if (isPartiallyPlayed)
            SizedBox(
              width: 12.w,
              height: 12.w,
              child: CircularProgressIndicator(
                value: _episodeProgress,
                strokeWidth: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),

          // Icon
          Icon(
            _getButtonIcon(),
            color: _getButtonIconColor(),
            size: 6.w,
          ),
        ],
      ),
    );
  }

  Color _getButtonBorderColor() {
    if (widget.isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (_episodeProgress > 0.0) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return AppTheme.lightTheme.colorScheme.onSurface;
    }
  }

  Color _getButtonBackgroundColor() {
    if (widget.isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1);
    } else if (_episodeProgress >= 1.0) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return Colors.transparent;
    }
  }

  IconData _getButtonIcon() {
    if (widget.isCurrentlyPlaying) {
      return Icons.pause;
    } else if (_episodeProgress >= 1.0) {
      return Icons.check;
    } else if (_episodeProgress > 0.0) {
      return Icons.play_arrow;
    } else {
      return Icons.play_arrow;
    }
  }

  Color _getButtonIconColor() {
    if (widget.isCurrentlyPlaying) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (_episodeProgress >= 1.0) {
      return Colors.white;
    } else if (_episodeProgress > 0.0) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else {
      return AppTheme.lightTheme.colorScheme.onSurface;
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

  /// Format datePublished field (Unix timestamp) for display
  String _formatDatePublished(dynamic datePublished) {
    debugPrint(
        '📅 _formatDatePublished called for episode: ${widget.episode['title']}');
    debugPrint(
        '  - datePublished: $datePublished (${datePublished.runtimeType})');
    debugPrint(
        '  - publishedAt: ${widget.episode['publishedAt']} (${widget.episode['publishedAt'].runtimeType})');
    debugPrint(
        '  - releaseDate: ${widget.episode['releaseDate']} (${widget.episode['releaseDate'].runtimeType})');
    debugPrint(
        '  - pubDate: ${widget.episode['pubDate']} (${widget.episode['pubDate'].runtimeType})');
    debugPrint(
        '  - date_published: ${widget.episode['date_published']} (${widget.episode['date_published'].runtimeType})');

    if (datePublished == null) {
      debugPrint('❌ datePublished is null, returning empty string');
      return '';
    }

    DateTime date;

    // Handle Unix timestamp (seconds since epoch)
    if (datePublished is int) {
      date = DateTime.fromMillisecondsSinceEpoch(datePublished * 1000);
      debugPrint('✅ Parsed int timestamp: $datePublished -> $date');
    } else if (datePublished is String) {
      final timestamp = int.tryParse(datePublished);
      if (timestamp != null) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        debugPrint('✅ Parsed string timestamp: $datePublished -> $date');
      } else {
        debugPrint('❌ Could not parse string timestamp: $datePublished');
        return '';
      }
    } else {
      debugPrint(
          '❌ Unsupported datePublished type: ${datePublished.runtimeType}');
      return '';
    }

    // Format as "28 OCTOBER, 2025"
    final result = _formatDateAsRequested(date);
    debugPrint('📅 Formatted date result: $result');
    return result;
  }

  /// Check if episode has any valid date field
  bool _hasValidDate(Map<String, dynamic> episode) {
    final dateFields = [
      'datePublished',
      'publishedAt',
      'releaseDate',
      'pubDate',
      'date_published'
    ];

    for (final field in dateFields) {
      if (episode[field] != null) {
        return true;
      }
    }
    return false;
  }

  /// Format date with fallback to other date fields
  String _formatDateWithFallback(Map<String, dynamic> episode) {
    // Try datePublished first
    if (episode['datePublished'] != null) {
      return _formatDatePublished(episode['datePublished']);
    }

    // Try other date fields
    final fallbackFields = [
      'publishedAt',
      'releaseDate',
      'pubDate',
      'date_published'
    ];
    for (final field in fallbackFields) {
      if (episode[field] != null) {
        debugPrint('📅 Using fallback date field $field: ${episode[field]}');
        try {
          final date = DateTime.parse(episode[field].toString());
          return _formatDateAsRequested(date);
        } catch (e) {
          debugPrint('❌ Error parsing fallback date ${episode[field]}: $e');
          continue;
        }
      }
    }

    return '';
  }

  /// Format date as "TODAY", "YESTERDAY", or "28 OCTOBER, 2025"
  String _formatDateAsRequested(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final episodeDate = DateTime(date.year, date.month, date.day);

    // Check if it's today
    if (episodeDate == today) {
      return 'TODAY';
    }

    // Check if it's yesterday
    if (episodeDate == yesterday) {
      return 'YESTERDAY';
    }

    // For all other dates, use the "28 OCTOBER, 2025" format
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];

    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;

    return '$day $month, $year';
  }
}
