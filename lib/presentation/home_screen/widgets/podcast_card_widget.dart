import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../data/models/podcast.dart';
import '../../../services/library_api_service.dart';
import '../../../services/subscription_helper.dart';
import './subscribe_button.dart';

class PodcastCardWidget extends StatefulWidget {
  final Podcast podcast;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Future<void> Function(Podcast)? onSubscribe;
  final VoidCallback? onPlay;

  const PodcastCardWidget({
    super.key,
    required this.podcast,
    required this.onTap,
    this.onLongPress,
    this.onSubscribe,
    this.onPlay,
  });

  @override
  State<PodcastCardWidget> createState() => _PodcastCardWidgetState();
}

class _PodcastCardWidgetState extends State<PodcastCardWidget> {
  bool _isLoading = false;

  void _handleSubscribe() async {
    if (widget.onSubscribe == null) return;
    setState(() => _isLoading = true);
    await widget.onSubscribe!(widget.podcast);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('=== PODCAST CARD TAP ===');
        debugPrint('Podcast Title: ${widget.podcast.title}');
        debugPrint('Podcast ID: ${widget.podcast.id}');
        debugPrint('Calling widget.onTap');
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Subscribe Button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CustomImageWidget(
                      imageUrl: widget.podcast.coverImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Subscribe Button Overlay (visible, top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _handleSubscribe,
                      behavior: HitTestBehavior.opaque,
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
                            isSubscribed: widget.podcast.isSubscribed,
                            isLoading: _isLoading,
                            onPressed: _handleSubscribe,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Download Status
                  if (widget.podcast.isDownloaded)
                    Positioned(
                      top: 2.w,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.tertiary
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomIconWidget(
                          iconName: 'download_done',
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  // Play button overlay (bottom right)
                  if (widget.onPlay != null)
                    Positioned(
                      bottom: 2.w,
                      right: 2.w,
                      child: GestureDetector(
                        onTap: widget.onPlay,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.all(1.5.w),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.play_arrow,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        widget.podcast.title,
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    // Creator only (no duration, no badge/label row)
                    Text(
                      widget.podcast.creator,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
