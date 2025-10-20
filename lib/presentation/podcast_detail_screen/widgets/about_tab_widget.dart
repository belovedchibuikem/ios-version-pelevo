import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../data/models/episode.dart';
import '../../../data/models/podcast.dart';
import '../../../services/rating_service.dart';
import '../../../services/subscriber_service.dart';
import '../../../core/utils/mini_player_positioning.dart';

// lib/presentation/podcast_detail_screen/widgets/about_tab_widget.dart

class AboutTabWidget extends StatefulWidget {
  final Podcast? podcast;
  final int episodeCount;
  final List episodes;
  final bool fromEarnTab;

  const AboutTabWidget({
    super.key,
    required this.podcast,
    required this.episodeCount,
    required this.episodes,
    this.fromEarnTab = false,
  });

  @override
  State<AboutTabWidget> createState() => _AboutTabWidgetState();
}

class _AboutTabWidgetState extends State<AboutTabWidget> {
  bool isDescriptionExpanded = false;
  late RatingService _ratingService;
  late SubscriberService _subscriberService;
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isLoadingRating = true;
  int _subscriberCount = 0;
  bool _isLoadingSubscriberCount = true;

  @override
  void initState() {
    super.initState();
    _ratingService = RatingService();
    _subscriberService = SubscriberService();
    _loadRatingData();
    _loadSubscriberCount();
  }

  Future<void> _loadRatingData() async {
    if (widget.podcast?.id == null) return;

    try {
      final result = await _ratingService.getPodcastRating(widget.podcast!.id);
      if (mounted) {
        if (result['success'] == true) {
          final data = result['data'];
          setState(() {
            _averageRating = data['average_rating']?.toDouble() ?? 0.0;
            _totalRatings = data['total_ratings'] ?? 0;
            _isLoadingRating = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading rating data: $e');
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  Future<void> _loadSubscriberCount() async {
    if (widget.podcast?.id == null) return;

    try {
      final result = await _subscriberService.getPodcastSubscriberCount(
        podcastId: widget.podcast!.id,
        context: context,
        onRetry: _loadSubscriberCount,
      );

      if (mounted) {
        if (result['success'] == true) {
          final data = result['data'];
          setState(() {
            _subscriberCount = data['subscriber_count'] ?? 0;
            _isLoadingSubscriberCount = false;
          });
        } else {
          setState(() {
            _subscriberCount = 0;
            _isLoadingSubscriberCount = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading subscriber count: $e');
      if (mounted) {
        setState(() {
          _subscriberCount = 0;
          _isLoadingSubscriberCount = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.lightTheme.scaffoldBackgroundColor,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics section
          _buildStatisticsSection(),

          SizedBox(height: 3.h),

          // Description section
          _buildDescriptionSection(),

          SizedBox(height: 3.h),

          // Key features section
          _buildKeyFeaturesSection(),

          SizedBox(height: 3.h),

          // Creator info section
          _buildCreatorInfoSection(),

          SizedBox(height: 3.h),

          // Category and tags section
          _buildCategorySection(),

          // Bottom padding for mini-player
          SizedBox(height: MiniPlayerPositioning.bottomPaddingForScrollables()),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final String totalDuration = _calculateTotalDuration(widget.episodes);
    debugPrint(
        'AboutTabWidget: episodeCount from widget: ${widget.episodeCount}');
    debugPrint(
        'AboutTabWidget: episodeCount type: ${widget.episodeCount.runtimeType}');
    debugPrint(
        'AboutTabWidget: episodeCount toString: ${widget.episodeCount.toString()}');
    debugPrint('AboutTabWidget: episodes length: ${widget.episodes.length}');
    debugPrint(
        'AboutTabWidget: final episode count to display: ${widget.episodeCount > 0 ? widget.episodeCount : widget.episodes.length}');
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podcast Statistics',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Episodes',
                  (widget.episodeCount > 0
                          ? widget.episodeCount
                          : widget.episodes.length)
                      .toString(),
                  'podcasts',
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatItem(
                  'Rating',
                  _isLoadingRating
                      ? '...'
                      : _totalRatings > 0
                          ? '${_averageRating.toStringAsFixed(1)} ⭐'
                          : 'No ratings',
                  'star',
                  AppTheme.earningActiveLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Subscribers',
                  _isLoadingSubscriberCount
                      ? '...'
                      : _subscriberCount > 0
                          ? _formatSubscriberCount(_subscriberCount)
                          : '0',
                  'group',
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatItem(
                  'Update Frequency',
                  'Weekly',
                  'schedule',
                  AppTheme.lightTheme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Duration',
                  totalDuration,
                  'timer',
                  AppTheme.lightTheme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTotalDuration(List episodes) {
    debugPrint(
        'AboutTabWidget: Calculating duration for ${episodes.length} episodes');
    int totalSeconds = 0;
    for (final episode in episodes) {
      String? durationStr;
      if (episode is Map) {
        durationStr = episode['duration'] as String?;
        debugPrint('AboutTabWidget: Episode duration from Map: $durationStr');
      } else if (episode is Episode) {
        durationStr = episode.duration;
        debugPrint(
            'AboutTabWidget: Episode duration from Episode: $durationStr');
      }
      durationStr ??= '0m';
      final seconds = _parseDurationToSeconds(durationStr);
      debugPrint(
          'AboutTabWidget: Parsed duration: $durationStr -> $seconds seconds');
      totalSeconds += seconds;
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final result = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    debugPrint(
        'AboutTabWidget: Total duration: $totalSeconds seconds -> $result');
    return result;
  }

  String _formatSubscriberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  int _parseDurationToSeconds(String duration) {
    // Accepts formats like '1h 23m', '45m', '3600', '1:23:00', etc.
    final regex = RegExp(r'(?:(\d+)h)?\s*(\d+)m');
    final match = regex.firstMatch(duration);
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      return hours * 3600 + minutes * 60;
    }
    // Try parsing as seconds
    final seconds = int.tryParse(duration);
    if (seconds != null) return seconds;
    // Try parsing as HH:MM:SS
    final parts = duration.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return h * 3600 + m * 60 + s;
    }
    return 0;
  }

  Widget _buildStatItem(
      String label, String value, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    // Prefer the model's description if available, fallback to map
    final String description = _stripHtmlTags(
      (widget.podcast?.description ?? '').toString(),
    );

    final bool isLongDescription = description.length > 200;
    final String displayText = isDescriptionExpanded || !isLongDescription
        ? description
        : '${description.substring(0, 200)}...';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Podcast',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            displayText,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (isLongDescription)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isDescriptionExpanded = !isDescriptionExpanded;
                  });
                },
                child: Text(
                  isDescriptionExpanded ? 'Show less' : 'Read more',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyFeaturesSection() {
    debugPrint('AboutTabWidget: fromEarnTab = ${widget.fromEarnTab}');
    final List<Map<String, dynamic>> features = [
      if (widget.fromEarnTab == true)
        {
          'title': 'Earning Opportunities',
          'description': 'Earn coins by listening to sponsored episodes',
          'icon': 'monetization_on',
          'color': AppTheme.earningActiveLight,
        },
      {
        'title': 'Offline Downloads',
        'description': 'Download episodes for offline listening',
        'icon': 'download',
        'color': AppTheme.lightTheme.colorScheme.tertiary,
      },
      {
        'title': 'Expert Insights',
        'description': 'Learn from industry leaders and professionals',
        'icon': 'school',
        'color': AppTheme.lightTheme.colorScheme.secondary,
      },
      {
        'title': 'Weekly Updates',
        'description': 'Fresh content delivered every week',
        'icon': 'schedule',
        'color': AppTheme.lightTheme.colorScheme.primary,
      },
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Features',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          ...features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: feature['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: feature['icon'],
                        color: feature['color'],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'],
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            feature['description'],
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCreatorInfoSection() {
    // Debug: Print podcast data to understand the issue
    debugPrint('=== CREATOR INFO DEBUG ===');
    debugPrint('Podcast object: ${widget.podcast}');
    debugPrint('Podcast author: ${widget.podcast?.author}');
    debugPrint('Podcast creator: ${widget.podcast?.creator}');
    debugPrint('Podcast title: ${widget.podcast?.title}');

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator Information',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              CircleAvatar(
                radius: 8.w,
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                child: Text(
                  (() {
                    final authorOrCreator =
                        (widget.podcast?.author?.isNotEmpty == true)
                            ? widget.podcast!.author
                            : (widget.podcast?.creator?.isNotEmpty == true)
                                ? widget.podcast!.creator
                                : 'Unknown';
                    if (authorOrCreator.isNotEmpty &&
                        authorOrCreator != 'Unknown') {
                      return authorOrCreator.substring(0, 1).toUpperCase();
                    } else {
                      return 'U';
                    }
                  })(),
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.podcast?.author?.isNotEmpty == true)
                          ? widget.podcast!.author
                          : (widget.podcast?.creator?.isNotEmpty == true)
                              ? widget.podcast!.creator
                              : 'Unknown',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Podcast Host & Creator',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Social links
          Row(
            children: [
              _buildSocialButton('Website', 'link', widget.podcast?.url),
              SizedBox(width: 2.w),
              _buildSocialButton(
                  'RSS', 'rss_feed', widget.podcast?.originalUrl),
              SizedBox(width: 2.w),
              _buildSocialButton('Link', 'link', widget.podcast?.link),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label, String iconName, String? url) {
    return Expanded(
      child: GestureDetector(
        onTap: url != null && url.isNotEmpty
            ? () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 16,
              ),
              SizedBox(width: 1.w),
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    // Use the podcast model's categories field directly for cleaner code
    List<String> categories = [];
    final catData = widget.podcast?.categories;
    if (catData is String && catData.isNotEmpty) {
      categories = catData
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    } else if (catData is Map) {
      categories = catData.values
          .map((v) => v.toString())
          .where((c) => c.isNotEmpty)
          .toList();
    } else if (catData is List) {
      categories =
          catData.map((c) => c.toString()).where((c) => c.isNotEmpty).toList();
    }
    if (categories.isEmpty) {
      categories = ['Uncategorized'];
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories & Tags',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: categories
                .map((category) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        category,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme
                              .lightTheme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
