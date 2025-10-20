import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/subscriber_service.dart';
import '../../../services/rating_service.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';

// lib/presentation/podcast_player/widgets/player_description_tab_widget.dart

class PlayerDescriptionTabWidget extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final int episodeCount;
  final String totalDuration;
  final bool isSubscribed;
  final bool notificationsEnabled;
  final bool isInWatchLater;
  final bool isInPlaylist;
  final VoidCallback onSubscriptionToggle;
  final VoidCallback onNotificationToggle;
  final VoidCallback onWatchLaterToggle;
  final VoidCallback onPlaylistToggle;

  const PlayerDescriptionTabWidget({
    super.key,
    required this.podcast,
    required this.episodeCount,
    required this.totalDuration,
    required this.isSubscribed,
    required this.notificationsEnabled,
    required this.isInWatchLater,
    required this.isInPlaylist,
    required this.onSubscriptionToggle,
    required this.onNotificationToggle,
    required this.onWatchLaterToggle,
    required this.onPlaylistToggle,
  });

  @override
  State<PlayerDescriptionTabWidget> createState() =>
      _PlayerDescriptionTabWidgetState();
}

class _PlayerDescriptionTabWidgetState
    extends State<PlayerDescriptionTabWidget> {
  bool isDescriptionExpanded = false;
  late SubscriberService _subscriberService;
  late RatingService _ratingService;
  String? _currentPodcastId;
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isLoadingRating = true;
  int _subscriberCount = 0;
  bool _isLoadingSubscriberCount = true;

  @override
  void initState() {
    super.initState();
    _subscriberService = SubscriberService();
    _ratingService = RatingService();
    _currentPodcastId = widget.podcast['id']?.toString();

    // Load subscriber count and rating data
    if (_currentPodcastId != null) {
      _loadSubscriberCount();
      _loadRatingData();
    }
  }

  Future<void> _loadSubscriberCount() async {
    if (_currentPodcastId == null) return;

    try {
      final result = await _subscriberService.getPodcastSubscriberCount(
        podcastId: _currentPodcastId!,
        context: context,
        onRetry: _loadSubscriberCount,
      );

      if (result['success'] == true && mounted) {
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

  String _formatSubscriberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Future<void> _loadRatingData() async {
    if (_currentPodcastId == null) return;

    try {
      final result = await _ratingService.getPodcastRating(_currentPodcastId!);
      if (result['success'] == true && mounted) {
        final data = result['data'];
        setState(() {
          _averageRating = data['average_rating']?.toDouble() ?? 0.0;
          _totalRatings = data['total_ratings'] ?? 0;
          _isLoadingRating = false;
        });
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

  @override
  void dispose() {
    // Clean up when widget is disposed
    super.dispose();
  }

  @override
  void didUpdateWidget(PlayerDescriptionTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle podcast change
    final newPodcastId = widget.podcast['id']?.toString();
    if (newPodcastId != _currentPodcastId) {
      // Load data for new podcast
      if (newPodcastId != null) {
        _loadSubscriberCount();
        _loadRatingData();
      }

      _currentPodcastId = newPodcastId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.lightTheme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons section
            _buildActionButtonsSection(),

            SizedBox(height: 3.h),

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

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection() {
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
            'Quick Actions',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),

          // Primary actions row
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: widget.isSubscribed ? 'Subscribed' : 'Subscribe',
                  iconName: widget.isSubscribed ? 'check_circle' : 'add_circle',
                  color: widget.isSubscribed
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.primary,
                  onTap: widget.onSubscriptionToggle,
                  isPrimary: true,
                ),
              ),
              SizedBox(width: 3.w),
              _buildIconActionButton(
                iconName: widget.notificationsEnabled
                    ? 'notifications_active'
                    : 'notifications_off',
                color: widget.notificationsEnabled
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                onTap: widget.onNotificationToggle,
                tooltip: widget.notificationsEnabled
                    ? 'Disable notifications'
                    : 'Enable notifications',
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Secondary actions row
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label:
                      widget.isInWatchLater ? 'In Watch Later' : 'Watch Later',
                  iconName: 'schedule',
                  color: widget.isInWatchLater
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.secondary,
                  onTap: widget.onWatchLaterToggle,
                  isPrimary: false,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildActionButton(
                  label:
                      widget.isInPlaylist ? 'In Playlist' : 'Add to Playlist',
                  iconName: 'playlist_add',
                  color: widget.isInPlaylist
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.secondary,
                  onTap: widget.onPlaylistToggle,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    // Debug: Print the values being used in statistics
    debugPrint('=== PLAYER STATISTICS DEBUG ===');
    debugPrint('Player episodeCount: ${widget.episodeCount}');
    debugPrint('Player totalDuration: ${widget.totalDuration}');
    debugPrint('Player podcast keys: ${widget.podcast.keys}');
    debugPrint(
        'Player podcast episodeCount: ${widget.podcast['episodeCount']}');
    debugPrint(
        'Player podcast totalDuration: ${widget.podcast['totalDuration']}');
    debugPrint('Player episodeCount type: ${widget.episodeCount.runtimeType}');
    debugPrint(
        'Player totalDuration type: ${widget.totalDuration.runtimeType}');

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
            'Podcast Summary',
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
                  widget.episodeCount.toString(),
                  'podcasts',
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
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
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
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
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatItem(
                  'Total Duration',
                  widget.totalDuration,
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
    final String description = widget.podcast['description'] ??
        'Explore cutting-edge topics in technology, innovation, and their impact on society. Our expert hosts dive deep into the latest trends, interview industry leaders, and provide actionable insights for both professionals and enthusiasts. From artificial intelligence to sustainable tech solutions, we cover it all with in-depth analysis and engaging discussions.';

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
                  isDescriptionExpanded ? 'Show less' : 'Show more',
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
          _buildFeatureItem('Expert Hosts', 'Verified experts in their fields'),
          _buildFeatureItem('Weekly Updates', 'Fresh content every week'),
          _buildFeatureItem('High Quality', 'Studio-quality audio production'),
          _buildFeatureItem('Ad-Free', 'Uninterrupted listening experience'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorInfoSection() {
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
                    final author = (widget.podcast['author'] ??
                            widget.podcast['creator'] ??
                            'Unknown')
                        .toString();
                    if (author.isNotEmpty) {
                      return author.substring(0, 1).toUpperCase();
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
                      widget.podcast['author'] ??
                          widget.podcast['creator'] ??
                          'Unknown',
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
              _buildSocialButton('Website', 'link', widget.podcast['url']),
              SizedBox(width: 2.w),
              _buildSocialButton(
                  'RSS', 'rss_feed', widget.podcast['originalUrl']),
              SizedBox(width: 2.w),
              _buildSocialButton('Link', 'link', widget.podcast['link']),
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
    // Use the same logic as podcast detail screen
    List<String> categories = [];
    final catData = widget.podcast['categories'];
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

  Widget _buildActionButton({
    required String label,
    required String iconName,
    required Color color,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 3.w),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isPrimary ? Colors.white : color,
              size: 18,
            ),
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                label,
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconActionButton({
    required String iconName,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
