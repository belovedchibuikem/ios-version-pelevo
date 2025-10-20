import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import 'dart:math';
import '../../home_screen/widgets/subscribe_button.dart';
import '../../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../home_screen/widgets/podcast_card_widget.dart';
import '../../../data/models/podcast.dart';
import '../../../core/error_handling/global_error_handler.dart';
import '../../../core/utils/smooth_scroll_utils.dart';
import '../../../widgets/episode_detail_modal.dart';
import '../../../data/repositories/podcast_repository.dart';

// lib/presentation/trending_podcasts_screen/widgets/trending_list_widget.dart

class TrendingListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> podcasts;
  final Function(Map<String, dynamic>) onPodcastTap;
  final ScrollController? scrollController;

  const TrendingListWidget({
    super.key,
    required this.podcasts,
    required this.onPodcastTap,
    this.scrollController,
  });

  @override
  State<TrendingListWidget> createState() => _TrendingListWidgetState();
}

class _TrendingListWidgetState extends State<TrendingListWidget>
    with SafeStateMixin, SmoothScrollMixin {
  late List<Map<String, dynamic>> _podcasts;

  @override
  void initState() {
    super.initState();
    _podcasts = List<Map<String, dynamic>>.from(widget.podcasts);
  }

  Future<void> _handleSubscribe(Map<String, dynamic> podcast) async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final id = podcast['id'].toString();
    final isSubscribed = subscriptionProvider.isSubscribed(id);
    await handleSubscribeAction(
      context: context,
      podcastId: id,
      isCurrentlySubscribed: isSubscribed,
      onStateChanged: (bool subscribed) {
        if (subscribed) {
          subscriptionProvider.addSubscription(id);
        } else {
          subscriptionProvider.removeSubscription(id);
        }
        safeSetState(() {}); // Refresh UI
      },
    );
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
      builder: (context) => Container(
        width: double.infinity,
        height: double.infinity,
        child: EpisodeDetailModal(
          episode: episode,
          episodes: episodes,
          episodeIndex: episodeIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    if (_podcasts.isEmpty) return _buildEmptyState();
    return GridView.builder(
      controller: scrollController,
      physics: SmoothScrollUtils.defaultPhysics,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 3.h,
        crossAxisSpacing: 4.w,
        childAspectRatio: 0.75,
      ),
      itemCount: _podcasts.length,
      itemBuilder: (context, index) {
        final podcastMap = _podcasts[index];
        final podcast = Podcast.fromJson(podcastMap);
        return PodcastCardWidget(
          podcast: podcast,
          onTap: () => widget.onPodcastTap(podcastMap),
          onSubscribe: (p) async => _handleSubscribe(podcastMap),
          onLongPress: () => _onPodcastLongPress(podcast),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'trending_down',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'No trending podcasts found',
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

String? _getDisplayCategory(Map<String, dynamic> podcast) {
  dynamic categoryData = podcast["category"];
  if (categoryData == null ||
      categoryData.toString().isEmpty ||
      categoryData.toString().toLowerCase() == 'uncategorized') {
    return null;
  }
  if (categoryData is String) {
    final categories = categoryData
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (categories.isEmpty) {
      return null;
    } else if (categories.length == 1) {
      return categories.first;
    } else {
      final random = Random();
      return categories[random.nextInt(categories.length)];
    }
  }
  if (categoryData is Map<String, dynamic>) {
    final categories = categoryData.values
        .where((v) => v != null && v.toString().isNotEmpty)
        .toList();
    if (categories.isEmpty) {
      return null;
    } else if (categories.length == 1) {
      return categories.first.toString();
    } else {
      final random = Random();
      return categories[random.nextInt(categories.length)].toString();
    }
  }
  if (categoryData is List) {
    final categories = categoryData
        .where((c) => c != null && c.toString().isNotEmpty)
        .toList();
    if (categories.isEmpty) {
      return null;
    } else if (categories.length == 1) {
      return categories.first.toString();
    } else {
      final random = Random();
      return categories[random.nextInt(categories.length)].toString();
    }
  }
  return categoryData.toString();
}
