import 'package:flutter/material.dart';
import '../../../data/models/podcast.dart';
import '../../../theme/app_theme.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../core/services/auth_service.dart';
import '../../../services/podcastindex_service.dart';
import '../../../services/library_api_service.dart';
import './featured_podcast_card_widget.dart';
import './podcasts_grid_widget.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/subscription_helper.dart';

class PodcastForHealthSectionWidget extends StatefulWidget {
  final List<Podcast> podcasts;
  final Function(Podcast) onPodcastTap;
  final bool isLoading;
  final VoidCallback onSeeAll;
  final void Function(Podcast, int)? onSubscribe;

  const PodcastForHealthSectionWidget({
    Key? key,
    required this.podcasts,
    required this.onPodcastTap,
    required this.isLoading,
    required this.onSeeAll,
    this.onSubscribe,
  }) : super(key: key);

  @override
  State<PodcastForHealthSectionWidget> createState() =>
      _PodcastForHealthSectionWidgetState();
}

class _PodcastForHealthSectionWidgetState
    extends State<PodcastForHealthSectionWidget> {
  final int itemsPerPage = 3;
  late List<Podcast> _podcasts;

  @override
  void initState() {
    super.initState();
    _podcasts = List<Podcast>.from(widget.podcasts);
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    // Debug print all podcast IDs being rendered
    for (final podcast in _podcasts) {
      debugPrint(
          'Rendering podcast in Health:  [36m${podcast.id.toString()} [0m');
    }
    if (widget.isLoading) {
      return SizedBox(
        height: 18.h,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (subscriptionProvider.errorMessage != null) {
      return SizedBox(
        height: 18.h,
        child:
            Center(child: Text('Error: ' + subscriptionProvider.errorMessage!)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Podcast for Health',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
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
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.green[700],
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 9.h,
          child: widget.isLoading
              ? Center(child: CircularProgressIndicator())
              : _podcasts.isEmpty
                  ? Center(child: Text('No podcasts found'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      itemCount: _podcasts.length,
                      itemBuilder: (context, index) {
                        final podcast = _podcasts[index];
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
}
