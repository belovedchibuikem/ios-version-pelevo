import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../data/models/podcast.dart';
import './widgets/featured_podcast_card_widget.dart';
import '../../core/services/auth_service.dart';
import '../../services/podcastindex_service.dart';
import '../../services/library_api_service.dart';
import 'package:dio/dio.dart';
import './widgets/subscribe_button.dart';
import '../../../services/subscription_helper.dart';
import './widgets/podcasts_grid_widget.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core/routes/app_routes.dart';

class TrendingPodcastsScreen extends StatefulWidget {
  final List<Podcast> podcasts;
  const TrendingPodcastsScreen({Key? key, required this.podcasts})
      : super(key: key);

  @override
  State<TrendingPodcastsScreen> createState() => _TrendingPodcastsScreenState();
}

class _TrendingPodcastsScreenState extends State<TrendingPodcastsScreen> {
  final NavigationService _navigationService = NavigationService();
  String _search = '';
  bool _isGrid = true; // Default to grid view
  bool _isLoading = false; // Add this to the state

  void _onPodcastTap(Podcast podcast) {
    _navigationService.navigateTo(AppRoutes.podcastDetailScreen, arguments: {
      'id': podcast.id,
      'title': podcast.title,
      'creator': podcast.creator,
      'coverImage': podcast.coverImage,
      'duration': podcast.duration,
      'isDownloaded': podcast.isDownloaded,
      'description': podcast.description,
      'category': podcast.category,
      'audioUrl': podcast.audioUrl,
    });
  }

  Future<void> _handleSubscribe(Podcast podcast) async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    final podcastId = podcast.id.toString();
    final isSubscribed = subscriptionProvider.isSubscribed(podcastId);
    await handleSubscribeAction(
      context: context,
      podcastId: podcastId,
      isCurrentlySubscribed: isSubscribed,
      onStateChanged: (subscribed) {
        if (subscribed) {
          subscriptionProvider.addSubscription(podcastId);
        } else {
          subscriptionProvider.removeSubscription(podcastId);
        }
        setState(() {}); // Refresh UI
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final filtered = widget.podcasts
        .where((p) => p.title.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Podcasts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search podcasts...',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _isLoading && filtered.isEmpty
                ? PodcastsGridSkeletonWidget(itemCount: 6)
                : PodcastsGridWidget(
                    podcasts: filtered,
                    onPodcastTap: _onPodcastTap,
                    onSubscribe: (podcast, _) async {
                      await _handleSubscribe(podcast);
                    },
                    isSubscribed: (podcast) => subscriptionProvider
                        .isSubscribed(podcast.id.toString()),
                  ),
          ),
        ],
      ),
    );
  }
}
