import 'package:flutter/material.dart';
import '../../../data/models/podcast.dart';
import '../../../theme/app_theme.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import './featured_podcast_card_widget.dart';
import './podcasts_grid_widget.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/subscription_helper.dart';

class CrimeArchivesSectionWidget extends StatefulWidget {
  final List<Podcast> podcasts;
  final Function(Podcast) onPodcastTap;
  final VoidCallback? onSeeAll;
  final void Function(Podcast)? onSubscribe;
  final bool isLoading;

  const CrimeArchivesSectionWidget({
    Key? key,
    required this.podcasts,
    required this.onPodcastTap,
    this.onSeeAll,
    this.onSubscribe,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CrimeArchivesSectionWidget> createState() =>
      _CrimeArchivesSectionWidgetState();
}

class _CrimeArchivesSectionWidgetState
    extends State<CrimeArchivesSectionWidget> {
  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    // Debug print all podcast IDs being rendered
    for (final podcast in widget.podcasts) {
      debugPrint(
          'Rendering podcast in CrimeArchives:  [36m${podcast.id.toString()} [0m');
    }
    if (widget.isLoading) {
      return SizedBox(
        height: 35.h,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (subscriptionProvider.errorMessage != null) {
      return SizedBox(
        height: 35.h,
        child:
            Center(child: Text('Error: ' + subscriptionProvider.errorMessage!)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crime Archives',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
              ),
              if (widget.onSeeAll != null)
                GestureDetector(
                  onTap: widget.onSeeAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.deepPurple[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.deepPurple[700],
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 35.h,
          child: widget.isLoading
              ? _buildLoadingSkeleton()
              : widget.podcasts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: widget.podcasts.length,
                      itemBuilder: (context, index) {
                        final podcast = widget.podcasts[index];
                        final isSubscribed = subscriptionProvider
                            .isSubscribed(podcast.id.toString());
                        return FeaturedPodcastCardWidget(
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
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: 320,
      child: PodcastsGridSkeletonWidget(itemCount: 4),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'gavel',
            size: 64,
            color: Colors.deepPurple[300],
          ),
          SizedBox(height: 2.h),
          Text(
            'No crime archives podcasts available',
            style: TextStyle(
              color: Colors.deepPurple[900],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Check back later or explore other sections!',
            style: TextStyle(
              color: Colors.deepPurple[700],
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
