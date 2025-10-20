import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/recommendation_filter_widget.dart';
import './widgets/recommendation_search_widget.dart';
import './widgets/recommendations_list_widget.dart';
import '../../data/models/podcast.dart';
import '../../data/repositories/podcast_repository.dart';
import '../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../presentation/home_screen/widgets/featured_podcast_card_widget.dart';
import '../../core/routes/app_routes.dart';

// lib/presentation/recommendations_screen/recommendations_screen.dart

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();
  List<Podcast> _allRecommendations = [];
  String _search = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = PodcastRepository();
      await repo.initialize();
      final podcasts = await repo.getRecommendedPodcasts(context: context);
      setState(() {
        _allRecommendations = podcasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations.';
        _isLoading = false;
      });
    }
  }

  void _onPodcastTap(Podcast podcast) {
    _navigationService.navigateTo(AppRoutes.podcastDetailScreen, arguments: {
      'id': podcast.id,
      'title': podcast.title,
      'creator': podcast.creator,
      'author': podcast.author,
      'coverImage': podcast.coverImage,
      'image':
          podcast.coverImage, // Also include 'image' field for compatibility
      'duration': podcast.duration,
      'isDownloaded': podcast.isDownloaded,
      'description': podcast.description,
      'category': podcast.category,
      'categories': podcast.categories,
      'audioUrl': podcast.audioUrl,
      'url': podcast.url,
      'originalUrl': podcast.originalUrl,
      'link': podcast.link,
      'totalEpisodes': podcast.totalEpisodes,
      'episodeCount': podcast.episodeCount,
      'languages': podcast.languages,
      'explicit': podcast.explicit,
      'isFeatured': podcast.isFeatured,
      'isSubscribed': podcast.isSubscribed,
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final filtered = _allRecommendations
        .where((p) => p.title.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended for You'),
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
              controller: _searchController,
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
          if (_isLoading)
            Expanded(child: Center(child: CircularProgressIndicator())),
          if (_errorMessage != null)
            Expanded(child: Center(child: Text(_errorMessage!))),
          if (!_isLoading && _errorMessage == null)
            SizedBox(
              height: 70.h,
              child: filtered.isEmpty
                  ? Center(child: Text('No podcasts found'))
                  : GridView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 2.h,
                        crossAxisSpacing: 4.w,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => FeaturedPodcastCardWidget(
                        podcast: filtered[i].toJson(),
                        isSubscribed: subscriptionProvider
                            .isSubscribed(filtered[i].id.toString()),
                        onTap: () => _onPodcastTap(filtered[i]),
                        onSubscribe: () async {
                          final podcastId = filtered[i].id.toString();
                          final isSubscribed =
                              subscriptionProvider.isSubscribed(podcastId);
                          await handleSubscribeAction(
                            context: context,
                            podcastId: podcastId,
                            isCurrentlySubscribed: isSubscribed,
                            onStateChanged: (subscribed) {
                              if (subscribed) {
                                subscriptionProvider.addSubscription(podcastId);
                              } else {
                                subscriptionProvider
                                    .removeSubscription(podcastId);
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
