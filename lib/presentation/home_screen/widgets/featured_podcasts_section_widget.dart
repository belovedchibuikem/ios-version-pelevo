import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/podcast.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import 'featured_podcast_card_widget.dart';
import '../../home_screen/widgets/subscribe_button.dart';
import '../../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';

class FeaturedPodcastsSectionWidget extends StatefulWidget {
  final List<Podcast> podcasts;
  final bool isLoading;
  final void Function(Podcast) onPodcastTap;
  final void Function(Podcast, Map<String, dynamic>)? onPlayEpisode;
  final void Function(Podcast, int)? onSubscribe;

  const FeaturedPodcastsSectionWidget({
    Key? key,
    required this.podcasts,
    required this.isLoading,
    required this.onPodcastTap,
    this.onPlayEpisode,
    this.onSubscribe,
  }) : super(key: key);

  @override
  State<FeaturedPodcastsSectionWidget> createState() =>
      _FeaturedPodcastsSectionWidgetState();
}

class _FeaturedPodcastsSectionWidgetState
    extends State<FeaturedPodcastsSectionWidget> {
  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    // Only show loading spinner if we have no data AND are loading
    if (widget.isLoading && widget.podcasts.isEmpty) {
      return SizedBox(
        height: 35.h,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Don't show subscription errors in this widget - they're handled elsewhere
    // if (subscriptionProvider.errorMessage != null) {
    //   return SizedBox(
    //     height: 35.h,
    //     child:
    //         Center(child: Text('Error: ' + subscriptionProvider.errorMessage!)),
    //   );
    // }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Podcasts',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: (widget.isLoading && widget.podcasts.isEmpty)
              ? _buildLoadingSkeleton()
              : widget.podcasts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.podcasts.length,
                      itemBuilder: (context, index) {
                        final podcast = widget.podcasts[index];
                        final isSubscribed = subscriptionProvider
                            .isSubscribed(podcast.id.toString());
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          child: FeaturedPodcastCardWidget(
                            podcast: podcast.toJson(),
                            isSubscribed: isSubscribed,
                            onTap: () => widget.onPodcastTap(podcast),
                            onSubscribe: () async {
                              final podcastId = podcast.id.toString();
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
                            onPlay: widget.onPlayEpisode != null
                                ? () => widget.onPlayEpisode!(
                                    podcast, podcast.toJson())
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 280,
          height: 270,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background Image Skeleton
                Container(
                  width: double.infinity,
                  height: 270,
                  color: Colors.grey[300],
                ),
                // Gradient Overlay
                Container(
                  width: double.infinity,
                  height: 270,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.15),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                // Subscribe Button Skeleton
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Download Status Skeleton
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Category Tag Skeleton
                Positioned(
                  top: 16,
                  left: 56,
                  child: Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Content Skeleton
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          color: Colors.grey[200],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.grey[200],
                            ),
                            SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 12,
                              color: Colors.grey[200],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 24,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            iconName: 'podcasts',
            size: 64,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No featured podcasts available',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Check back later or explore other sections!',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeaturedPodcastCardWithSubscribe extends StatefulWidget {
  final Podcast podcast;
  final VoidCallback? onTap;
  const _FeaturedPodcastCardWithSubscribe({
    Key? key,
    required this.podcast,
    this.onTap,
  }) : super(key: key);

  @override
  State<_FeaturedPodcastCardWithSubscribe> createState() =>
      _FeaturedPodcastCardWithSubscribeState();
}

class _FeaturedPodcastCardWithSubscribeState
    extends State<_FeaturedPodcastCardWithSubscribe> {
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    final isSubscribed = provider.isSubscribed(widget.podcast.id.toString());
    await handleSubscribeAction(
      context: context,
      podcastId: widget.podcast.id.toString(),
      isCurrentlySubscribed: isSubscribed,
      onStateChanged: (bool subscribed) {
        if (subscribed) {
          provider.addSubscription(widget.podcast.id.toString());
        } else {
          provider.removeSubscription(widget.podcast.id.toString());
        }
        setState(() => _isLoading = false);
      },
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final isSubscribed = provider.isSubscribed(widget.podcast.id.toString());
    final podcast = widget.podcast;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        child: Stack(
          children: [
            // Background Image Skeleton
            Container(
              width: double.infinity,
              height: 270,
              color: Colors.grey[300],
            ),
            // Gradient Overlay
            Container(
              width: double.infinity,
              height: 270,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.15),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Subscribe Button Skeleton
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Download Status Skeleton
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Category Tag Skeleton
            Positioned(
              top: 16,
              left: 56,
              child: Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // Content Skeleton
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: Colors.grey[200],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          color: Colors.grey[200],
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 12,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 24,
                      color: Colors.grey[200],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: SubscribeButton(
                    isSubscribed: isSubscribed,
                    isLoading: _isLoading,
                    onPressed: _handleSubscribe,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
