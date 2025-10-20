import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/social_sharing_service.dart';
import '../../../services/subscription_helper.dart';
import './rating_widget.dart';

// lib/presentation/podcast_detail_screen/widgets/podcast_header_widget.dart

class PodcastHeaderWidget extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final bool isSubscribed;
  final bool notificationsEnabled;
  final VoidCallback onSubscriptionToggle;
  final VoidCallback onNotificationToggle;

  const PodcastHeaderWidget({
    super.key,
    required this.podcast,
    required this.isSubscribed,
    required this.notificationsEnabled,
    required this.onSubscriptionToggle,
    required this.onNotificationToggle,
  });

  @override
  State<PodcastHeaderWidget> createState() => _PodcastHeaderWidgetState();
}

class _PodcastHeaderWidgetState extends State<PodcastHeaderWidget> {
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.isSubscribed;
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    await handleSubscribeAction(
      context: context,
      podcastId: widget.podcast['id'].toString(),
      isCurrentlySubscribed: _isSubscribed,
      onStateChanged: (bool subscribed) {
        setState(() {
          _isSubscribed = subscribed;
          _isLoading = false;
        });
      },
    );
    setState(() => _isLoading = false);
  }

  Future<void> _sharePodcast() async {
    try {
      final podcastTitle = widget.podcast['title'] ?? 'Unknown Podcast';
      final podcastDescription = widget.podcast['description'] ?? '';
      final podcastUrl = widget.podcast['url'] ?? widget.podcast['feedUrl'] ?? '';
      final imageUrl = widget.podcast['coverImage'] ?? widget.podcast['image'] ?? '';

      await SocialSharingService().sharePodcast(
        podcastTitle: podcastTitle,
        podcastDescription: podcastDescription,
        podcastUrl: podcastUrl.isNotEmpty ? podcastUrl : null,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        customMessage: 'Check out this amazing podcast!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.share, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Podcast shared successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing podcast: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing podcast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PodcastHeaderWidget: podcast data: ${widget.podcast}');
    debugPrint('PodcastHeaderWidget: podcast ID: ${widget.podcast['id']}');
    return SizedBox(
        height: 45.h,
        child: Stack(children: [
          // Background cover image with gradient
          Container(
              height: 35.h,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(widget.podcast['coverImage'] ??
                          widget.podcast['image'] ??
                          ''),
                      fit: BoxFit.cover)),
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ])))),

          // Back button
          Positioned(
              top: MediaQuery.of(context).padding.top + 1.h,
              left: 4.w,
              child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8)),
                      child: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: Colors.white,
                          size: 24)))),

          // Share button
          Positioned(
              top: MediaQuery.of(context).padding.top + 1.h,
              right: 4.w,
              child: GestureDetector(
                  onTap: _sharePodcast,
                  child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8)),
                      child: CustomIconWidget(
                          iconName: 'share', color: Colors.white, size: 24)))),

          // Podcast info card
          Positioned(
              bottom: 0,
              left: 4.w,
              right: 4.w,
              child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 4)),
                      ]),
                  child: Row(children: [
                    // Podcast cover
                    Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2)),
                            ]),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomImageWidget(
                                imageUrl: widget.podcast['coverImage'] ??
                                    widget.podcast['image'] ??
                                    '',
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.cover))),

                    SizedBox(width: 4.w),

                    // Podcast info
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(widget.podcast['title'] ?? '',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          SizedBox(height: 1.h),
                          Text(
                              widget.podcast['author'] ??
                                  widget.podcast['creator'] ??
                                  '',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          SizedBox(height: 2.h),

                          // Subscribe button and notification toggle
                          Row(children: [
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubscribe,
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                          (states) {
                                    if (_isSubscribed) {
                                      return Colors.teal;
                                    }
                                    return Theme.of(context)
                                        .colorScheme
                                        .primary;
                                  }),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                  ),
                                  padding:
                                      MaterialStateProperty.all<EdgeInsets>(
                                    EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 10),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isSubscribed
                                                ? Icons.check
                                                : Icons.add,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            _isSubscribed
                                                ? 'Subscribed'
                                                : 'Subscribe',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (_isSubscribed) ...[
                              SizedBox(width: 2.w),
                              GestureDetector(
                                  onTap: widget.onNotificationToggle,
                                  child: Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                          color: widget.notificationsEnabled
                                              ? AppTheme.lightTheme.colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1)
                                              : AppTheme.lightTheme.colorScheme
                                                  .outline
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: widget.notificationsEnabled
                                                  ? AppTheme.lightTheme
                                                      .colorScheme.primary
                                                  : AppTheme.lightTheme
                                                      .colorScheme.outline)),
                                      child: CustomIconWidget(
                                          iconName: widget.notificationsEnabled ? 'notifications' : 'notifications_off',
                                          color: widget.notificationsEnabled ? AppTheme.lightTheme.colorScheme.primary : AppTheme.lightTheme.colorScheme.outline,
                                          size: 20))),
                            ],
                          ]),

                          // Rating widget
                          SizedBox(height: 2.h),
                          RatingWidget(
                            podcastId: widget.podcast['id'].toString(),
                            podcastTitle: widget.podcast['title'] ?? '',
                            onRatingSubmitted: (rating) {
                              // Handle rating submission
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Thank you for rating this podcast!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ])),
                  ]))),
        ]));
  }
}
