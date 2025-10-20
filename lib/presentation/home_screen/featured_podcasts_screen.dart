import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../data/models/podcast.dart';
import './widgets/featured_podcast_card_widget.dart';
import 'package:dio/dio.dart';
import '../../services/library_api_service.dart';
import '../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core/routes/app_routes.dart';

class FeaturedPodcastsScreen extends StatefulWidget {
  final List<Podcast> podcasts;
  const FeaturedPodcastsScreen({Key? key, required this.podcasts})
      : super(key: key);

  @override
  State<FeaturedPodcastsScreen> createState() => _FeaturedPodcastsScreenState();
}

class _FeaturedPodcastsScreenState extends State<FeaturedPodcastsScreen> {
  final NavigationService _navigationService = NavigationService();
  String _search = '';
  bool _isGrid = false;

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
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final filtered = widget.podcasts
        .where((p) => p.title.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Featured Podcasts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGrid = !_isGrid),
            tooltip: _isGrid ? 'List view' : 'Grid view',
          ),
        ],
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
            child: filtered.isEmpty
                ? Center(child: Text('No podcasts found'))
                : _isGrid
                    ? GridView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 2.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 2.h,
                          crossAxisSpacing: 4.w,
                          childAspectRatio: 0.7,
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
                                  subscriptionProvider
                                      .addSubscription(podcastId);
                                } else {
                                  subscriptionProvider
                                      .removeSubscription(podcastId);
                                }
                              },
                            );
                          },
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 2.h),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: FeaturedPodcastCardWidget(
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
                                    subscriptionProvider
                                        .addSubscription(podcastId);
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
          ),
        ],
      ),
    );
  }
}
