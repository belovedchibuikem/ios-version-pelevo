import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart';

import '../../../core/app_export.dart';
import '../../../data/models/podcast.dart';
import '../../../theme/app_theme.dart';
import '../../home_screen/widgets/subscribe_button.dart';
import '../../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';

class PodcastCategorySectionWidget extends StatefulWidget {
  final String title;
  final List<Podcast> podcasts;
  final Function(Podcast) onPodcastTap;
  final VoidCallback onSeeAll;
  final bool isLoading;
  final void Function(Podcast, Map<String, dynamic>)? onPlayEpisode;
  final void Function(Podcast, int)? onSubscribe;

  const PodcastCategorySectionWidget({
    Key? key,
    required this.title,
    required this.podcasts,
    required this.onPodcastTap,
    required this.onSeeAll,
    this.isLoading = false,
    this.onPlayEpisode,
    this.onSubscribe,
  }) : super(key: key);

  @override
  State<PodcastCategorySectionWidget> createState() =>
      _PodcastCategorySectionWidgetState();
}

class _PodcastCategorySectionWidgetState
    extends State<PodcastCategorySectionWidget> {
  late List<Podcast> _podcasts;

  @override
  void initState() {
    super.initState();
    _podcasts = List<Podcast>.from(widget.podcasts);
  }

  @override
  void didUpdateWidget(covariant PodcastCategorySectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.podcasts != widget.podcasts) {
      setState(() {
        _podcasts = List<Podcast>.from(widget.podcasts);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    // Only show loading spinner if we have no data AND are loading
    if (widget.isLoading && _podcasts.isEmpty) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: widget.title == 'Recommended for You'
                                  ? Colors.blue[700]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: widget.title == 'Recommended for You'
                            ? Colors.blue[700]
                            : Colors.orange[700],
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
          height: 38.h,
          child: _podcasts.isEmpty
              ? Center(child: Text('No podcasts found'))
              : PageView.builder(
                  controller: PageController(viewportFraction: 0.95),
                  itemCount: (_podcasts.length / 2).ceil(),
                  itemBuilder: (context, pageIndex) {
                    final start = pageIndex * 2;
                    final end = (start + 2) > _podcasts.length
                        ? _podcasts.length
                        : (start + 2);
                    final pageItems = _podcasts.sublist(start, end);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pageItems.length, (index) {
                        final podcast = pageItems[index];
                        final isSubscribed = subscriptionProvider
                            .isSubscribed(podcast.id.toString());
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Podcast image as background (clickable)
                                GestureDetector(
                                  onTap: () {
                                    debugPrint(
                                        '=== PODCAST CATEGORY IMAGE TAP ===');
                                    debugPrint(
                                        'Podcast Title: ${podcast.title}');
                                    debugPrint('Podcast ID: ${podcast.id}');
                                    debugPrint('Calling widget.onPodcastTap');
                                    widget.onPodcastTap(podcast);
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CustomImageWidget(
                                      imageUrl: podcast.coverImage,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Gradient overlay for readability
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Content overlay
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            debugPrint(
                                                '=== PODCAST CATEGORY TITLE TAP ===');
                                            debugPrint(
                                                'Podcast Title: ${podcast.title}');
                                            debugPrint(
                                                'Podcast ID: ${podcast.id}');
                                            debugPrint(
                                                'Calling widget.onPodcastTap');
                                            widget.onPodcastTap(podcast);
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Text(
                                            podcast.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          podcast.creator,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          podcast.description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.white,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Subscribe Button (top right)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final podcastId = podcast.id.toString();
                                      final isSubscribed = subscriptionProvider
                                          .isSubscribed(podcastId);
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
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.10),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: SubscribeButton(
                                          isSubscribed: isSubscribed,
                                          isLoading: false,
                                          onPressed: () async {
                                            final podcastId =
                                                podcast.id.toString();
                                            final isSubscribed =
                                                subscriptionProvider
                                                    .isSubscribed(podcastId);
                                            await handleSubscribeAction(
                                              context: context,
                                              podcastId: podcastId,
                                              isCurrentlySubscribed:
                                                  isSubscribed,
                                              onStateChanged: (subscribed) {
                                                if (subscribed) {
                                                  subscriptionProvider
                                                      .addSubscription(
                                                          podcastId);
                                                } else {
                                                  subscriptionProvider
                                                      .removeSubscription(
                                                          podcastId);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context, Podcast podcast) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: podcast.coverImage,
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podcast.title,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        podcast.creator,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            _buildContextMenuItem(
              context,
              'playlist_add',
              'Add to Playlist',
              () {
                Navigator.pop(context);
                // Handle add to playlist
              },
            ),
            _buildContextMenuItem(
              context,
              podcast.isDownloaded ? 'download_done' : 'download',
              podcast.isDownloaded ? 'Downloaded' : 'Download',
              () {
                Navigator.pop(context);
                // Handle download
              },
            ),
            _buildContextMenuItem(
              context,
              'share',
              'Share',
              () {
                Navigator.pop(context);
                // Handle share
              },
            ),
            _buildContextMenuItem(
              context,
              'not_interested',
              'Not Interested',
              () {
                Navigator.pop(context);
                // Handle not interested
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem(
    BuildContext context,
    String iconName,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
            SizedBox(width: 4.w),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(Podcast podcast, int index) async {
    if (widget.onSubscribe != null) {
      widget.onSubscribe!(podcast, index);
    }
  }
}

class _TrendingPodcastCardWithSubscribe extends StatefulWidget {
  final Podcast podcast;
  final VoidCallback? onTap;
  final Future<void> Function()? onSubscribe;
  const _TrendingPodcastCardWithSubscribe({
    Key? key,
    required this.podcast,
    this.onTap,
    this.onSubscribe,
  }) : super(key: key);

  @override
  State<_TrendingPodcastCardWithSubscribe> createState() =>
      _TrendingPodcastCardWithSubscribeState();
}

class _TrendingPodcastCardWithSubscribeState
    extends State<_TrendingPodcastCardWithSubscribe> {
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
        if (widget.onSubscribe != null) widget.onSubscribe!();
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
        width: 220,
        margin: const EdgeInsets.only(right: 18.0, bottom: 4.0, top: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: CustomImageWidget(
                    imageUrl: podcast.coverImage,
                    height: 140,
                    width: 220,
                    fit: BoxFit.cover,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    podcast.creator,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    podcast.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
