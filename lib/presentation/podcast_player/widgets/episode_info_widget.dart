import 'package:flutter/material.dart';
import 'dart:math';

import '../../../../core/app_export.dart';

// lib/presentation/podcast_player/widgets/episode_info_widget.dart

class EpisodeInfoWidget extends StatelessWidget {
  final Map<String, dynamic> episode;
  final bool
      isEarningEnabled; // Add parameter to track if earning is enabled for this session
  final Map<String, dynamic>? podcast;

  const EpisodeInfoWidget({
    super.key,
    required this.episode,
    required this.isEarningEnabled, // Add required parameter
    this.podcast,
  });

  @override
  Widget build(BuildContext context) {
    // Determine text colors based on theme brightness
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color primaryTextColor =
        isDarkTheme ? Colors.white : AppTheme.lightTheme.colorScheme.onSurface;
    final Color secondaryTextColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.9);
    final Color tertiaryTextColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7);
    final Color subtleTextColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6);
    final Color dividerColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.4)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Column(
      children: [
        // Episode title
        Text(
          episode["title"] ?? "Unknown Episode",
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            color: primaryTextColor,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Podcast name
        Text(
          episode["podcastName"] ??
              (podcast != null
                  ? (podcast!["title"] ?? "Unknown Podcast")
                  : "Unknown Podcast"),
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Creator
        Text(
          'by ${episode["author"] ?? episode["creator"] ?? (podcast != null ? (podcast!["author"] ?? podcast!["creator"]) : null) ?? "Unknown Creator"}',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: tertiaryTextColor,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 16),

        // Episode badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Earning badge - only show if episode supports earning AND was played from Earn tab
            if (episode["isEarningEpisode"] == true && isEarningEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successLight.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'monetization_on',
                      color: AppTheme.successLight,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Earning',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            if (episode["isEarningEpisode"] == true &&
                isEarningEnabled &&
                (episode["isDownloaded"] == true ||
                    episode["isOffline"] == true))
              const SizedBox(width: 8),

            // Downloaded badge
            if (episode["isDownloaded"] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'download_done',
                      color: Colors.blue,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Downloaded',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            // Offline indicator for downloaded episodes
            if (episode["isOffline"] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'offline_bolt',
                      color: Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Episode description (with ellipsis and Read more)
        _EpisodeDescription(
            description: episode["description"] ?? "No description available"),

        const SizedBox(height: 12),

        // Category and duration
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getDisplayCategory(),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: subtleTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              _formatDuration(episode["duration"] ?? 0),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: subtleTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper method to extract and randomly select a category from episode data
  String _getDisplayCategory() {
    dynamic categoryData = episode["category"];
    if (categoryData == null ||
        categoryData.toString().isEmpty ||
        categoryData.toString().toLowerCase() == 'uncategorized') {
      // Try podcast category if episode category is missing/empty/uncategorized
      if (podcast != null &&
          podcast!["category"] != null &&
          podcast!["category"].toString().isNotEmpty &&
          podcast!["category"].toString().toLowerCase() != 'uncategorized') {
        categoryData = podcast!["category"];
      } else {
        return "Uncategorized";
      }
    }
    // If category is a string, check if it contains multiple categories separated by commas
    if (categoryData is String) {
      final categories = categoryData
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (categories.isEmpty) {
        return "Uncategorized";
      } else if (categories.length == 1) {
        return categories.first;
      } else {
        final random = Random();
        return categories[random.nextInt(categories.length)];
      }
    }
    // If category is a Map (categories object), extract and randomly select
    if (categoryData is Map<String, dynamic>) {
      final categories = categoryData.values
          .where((v) => v != null && v.toString().isNotEmpty)
          .toList();
      if (categories.isEmpty) {
        return "Uncategorized";
      } else if (categories.length == 1) {
        return categories.first.toString();
      } else {
        final random = Random();
        return categories[random.nextInt(categories.length)].toString();
      }
    }
    // If category is a List, randomly select from the list
    if (categoryData is List) {
      final categories = categoryData
          .where((c) => c != null && c.toString().isNotEmpty)
          .toList();
      if (categories.isEmpty) {
        return "Uncategorized";
      } else if (categories.length == 1) {
        return categories.first.toString();
      } else {
        final random = Random();
        return categories[random.nextInt(categories.length)].toString();
      }
    }
    // Fallback to string representation
    return categoryData.toString();
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '0m';

    // Convert to double
    double seconds;
    if (duration is int) {
      seconds = duration.toDouble();
    } else if (duration is double) {
      seconds = duration;
    } else if (duration is String) {
      // Try to parse as seconds first
      seconds = double.tryParse(duration) ?? 0.0;
      // If that fails, try to parse duration string like "47m 27s"
      if (seconds == 0.0) {
        seconds = DurationUtils.parseDurationToSeconds(duration);
      }
    } else {
      seconds = 0.0;
    }

    // Format back to a readable string
    final int hours = (seconds / 3600).floor();
    final int minutes = ((seconds % 3600) / 60).floor();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class _EpisodeDescription extends StatefulWidget {
  final String description;
  const _EpisodeDescription({Key? key, required this.description})
      : super(key: key);

  @override
  State<_EpisodeDescription> createState() => _EpisodeDescriptionState();
}

class _EpisodeDescriptionState extends State<_EpisodeDescription> {
  bool _expanded = false;
  static const int _maxLength = 120;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTheme.lightTheme.textTheme.bodyMedium;
    final color = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.85)
        : AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.85);
    final String desc = _stripHtmlTags(widget.description.trim());
    if (desc.isEmpty) {
      return SizedBox.shrink();
    }
    if (desc.length <= _maxLength || _expanded) {
      return Text(
        desc,
        style: textTheme?.copyWith(color: color),
        textAlign: TextAlign.center,
      );
    }
    // Truncated with Read more
    return Column(
      children: [
        Text(
          desc.substring(0, _maxLength) + '... ',
          style: textTheme?.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Text(
            'Read more',
            style: textTheme?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  String _stripHtmlTags(String htmlText) {
    final RegExp exp =
        RegExp(r'<[^>]+>', multiLine: true, caseSensitive: false);
    return htmlText
        .replaceAll(exp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
