import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../home_screen/widgets/podcast_card_widget.dart';
import '../../../data/models/podcast.dart';
import '../../../core/utils/smooth_scroll_utils.dart';
import '../../../widgets/episode_detail_modal.dart';
import '../../../data/repositories/podcast_repository.dart';

// lib/presentation/recommendations_screen/widgets/recommendations_list_widget.dart

class RecommendationsListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> recommendations;
  final Function(Map<String, dynamic>) onPodcastTap;
  final Function(Map<String, dynamic>, bool) onLikeDislike;
  final ScrollController? scrollController;

  const RecommendationsListWidget({
    super.key,
    required this.recommendations,
    required this.onPodcastTap,
    required this.onLikeDislike,
    this.scrollController,
  });

  @override
  State<RecommendationsListWidget> createState() =>
      _RecommendationsListWidgetState();
}

class _RecommendationsListWidgetState extends State<RecommendationsListWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.recommendations.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            controller: widget.scrollController,
            physics: SmoothScrollUtils.defaultPhysics,
            padding: EdgeInsets.all(4.w),
            itemCount: widget.recommendations.length,
            itemBuilder: (context, index) {
              final rec = widget.recommendations[index];
              final podcast = Podcast.fromJson(rec);
              return Padding(
                padding: EdgeInsets.only(bottom: 5.h),
                child: PodcastCardWidget(
                  podcast: podcast,
                  onTap: () => widget.onPodcastTap(rec),
                  onLongPress: () => _onPodcastLongPress(podcast),
                ),
              );
            },
          );
  }

  Widget _buildFeedbackButtons(Map<String, dynamic> recommendation) {
    final isLiked = recommendation['isLiked'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => widget.onLikeDislike(recommendation, true),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isLiked == true
                  ? AppTheme.lightTheme.colorScheme.primary.withAlpha(26)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'thumb_up',
              color: isLiked == true
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                      .withAlpha(153),
              size: 18,
            ),
          ),
        ),
        SizedBox(width: 2.w),
        GestureDetector(
          onTap: () => widget.onLikeDislike(recommendation, false),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isLiked == false
                  ? AppTheme.lightTheme.colorScheme.error.withAlpha(26)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'thumb_down',
              color: isLiked == false
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                      .withAlpha(153),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 90) {
      return const Color(0xFF4CAF50); // Green
    } else if (percentage >= 70) {
      return const Color(0xFF8BC34A); // Light Green
    } else if (percentage >= 50) {
      return const Color(0xFFFFC107); // Amber
    } else if (percentage >= 30) {
      return const Color(0xFFFF9800); // Orange
    } else {
      return const Color(0xFFF44336); // Red
    }
  }

  /// Handle long press on podcast card to show episode details
  void _onPodcastLongPress(Podcast podcast) async {
    try {
      // Fetch episodes for this podcast
      final podcastId =
          podcast.id is int ? podcast.id as int : int.tryParse(podcast.id) ?? 0;
      final episodes = await PodcastRepository().getPodcastEpisodes(podcastId);

      if (episodes.isNotEmpty) {
        final episode = episodes.first;

        // Convert episodes to map format for the modal
        final episodeMaps = episodes.map((e) => e.toJson()).toList();
        final episodeIndex = 0; // First episode

        // Show episode detail modal
        _showEpisodeDetailModal(
            context, episode.toJson(), episodeMaps, episodeIndex);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No episodes available for this podcast.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading episodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show episode detail modal for a specific episode
  void _showEpisodeDetailModal(
      BuildContext context,
      Map<String, dynamic> episode,
      List<Map<String, dynamic>> episodes,
      int episodeIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        Container(
          width: double.infinity,
          height: double.infinity,
          child: EpisodeDetailModal(
            episode: episode,
            episodes: episodes,
            episodeIndex: episodeIndex,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'recommend',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'No recommendations found',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your search or filter criteria',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }
}

String _stripHtmlTags(String htmlText) {
  final RegExp exp = RegExp(r'<[^>]+>', multiLine: true, caseSensitive: false);
  return htmlText
      .replaceAll(exp, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}
