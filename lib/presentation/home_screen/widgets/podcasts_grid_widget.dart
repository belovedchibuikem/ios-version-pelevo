import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/podcast.dart';
import './featured_podcast_card_widget.dart';
import '../../home_screen/widgets/subscribe_button.dart';
import '../../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';

class PodcastsGridWidget extends StatefulWidget {
  final List<Podcast> podcasts;
  final void Function(Podcast) onPodcastTap;
  final Future<void> Function(Podcast, int)? onSubscribe;
  final bool Function(Podcast) isSubscribed;

  const PodcastsGridWidget({
    Key? key,
    required this.podcasts,
    required this.onPodcastTap,
    this.onSubscribe,
    required this.isSubscribed,
  }) : super(key: key);

  @override
  State<PodcastsGridWidget> createState() => _PodcastsGridWidgetState();
}

class _PodcastsGridWidgetState extends State<PodcastsGridWidget> {
  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    // Debug print all podcast IDs being rendered
    debugPrint(
        'Subscribed podcast IDs:  [32m${subscriptionProvider.subscribedPodcastIds} [0m');
    for (final podcast in widget.podcasts) {
      debugPrint(
          'Rendering podcast in Grid: \x1B[36m${podcast.id.toString()}\x1B[0m');
    }
    if (subscriptionProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (subscriptionProvider.errorMessage != null) {
      return Center(
          child: Text('Error: ' + subscriptionProvider.errorMessage!));
    }
    if (widget.podcasts.isEmpty) {
      return Center(child: Text('No podcasts found'));
    }
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 3.h,
        crossAxisSpacing: 6.w,
        childAspectRatio: 0.8,
      ),
      itemCount: widget.podcasts.length,
      itemBuilder: (context, i) {
        final podcast = widget.podcasts[i];
        final id = podcast.id.toString();
        final isSubscribed = subscriptionProvider.isSubscribed(id);
        return FeaturedPodcastCardWidget(
          podcast: podcast.toJson(),
          isSubscribed: isSubscribed,
          onTap: () => widget.onPodcastTap(podcast),
          onSubscribe: () async {
            final isSubscribed = subscriptionProvider.isSubscribed(id);
            await handleSubscribeAction(
              context: context,
              podcastId: id,
              isCurrentlySubscribed: isSubscribed,
              onStateChanged: (subscribed) {
                if (subscribed) {
                  subscriptionProvider.addSubscription(id);
                } else {
                  subscriptionProvider.removeSubscription(id);
                }
              },
            );
          },
        );
      },
    );
  }
}

class PodcastsGridSkeletonWidget extends StatelessWidget {
  final int itemCount;
  const PodcastsGridSkeletonWidget({Key? key, this.itemCount = 6})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 3.h,
        crossAxisSpacing: 6.w,
        childAspectRatio: 0.8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Cover Image Skeleton
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(color: Colors.grey[300]),
              ),
            ),
            // Subscribe Button Skeleton
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content Skeleton
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 14,
                      color: Colors.grey[200],
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 12,
                      color: Colors.grey[200],
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 18,
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
  }
}
