import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import 'dart:math';
import '../../../services/library_api_service.dart';
import './subscribe_button.dart';

class FeaturedPodcastCardWidget extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final bool isSubscribed;
  final VoidCallback onTap;
  final Future<void> Function()? onSubscribe;
  final VoidCallback? onPlay;

  const FeaturedPodcastCardWidget({
    super.key,
    required this.podcast,
    required this.isSubscribed,
    required this.onTap,
    this.onSubscribe,
    this.onPlay,
  });

  @override
  State<FeaturedPodcastCardWidget> createState() =>
      _FeaturedPodcastCardWidgetState();
}

class _FeaturedPodcastCardWidgetState extends State<FeaturedPodcastCardWidget> {
  bool _isLoading = false;

  void _handleSubscribe() async {
    if (widget.onSubscribe == null) return;
    setState(() => _isLoading = true);
    await widget.onSubscribe!();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = widget.isSubscribed;
    return GestureDetector(
      onTap: () {
        debugPrint('=== FEATURED PODCAST CARD TAP ===');
        debugPrint('Podcast Title: ${widget.podcast["title"]}');
        debugPrint('Podcast ID: ${widget.podcast["id"]}');
        debugPrint('Calling widget.onTap');
        widget.onTap(); // Only load podcast detail on card tap
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 180,
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
              // Background Image
              CustomImageWidget(
                imageUrl: widget.podcast["coverImage"] ?? "",
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              // Gradient Overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.podcast["title"] ?? "",
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.podcast["creator"] ?? "",
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            widget.podcast["duration"] ?? "",
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      if (widget.podcast["description"] != null)
                        Text(
                          _stripHtmlTags(widget.podcast["description"]),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              // Subscribe Button Overlay (visible, top-right)
              if (widget.onSubscribe != null)
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
                          isSubscribed: isSubscribed,
                          isLoading: _isLoading,
                          onPressed: _handleSubscribe,
                        ),
                      ),
                    ),
                  ),
                ),
              // Download Status
              if (widget.podcast["isDownloaded"] == true)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.tertiary
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomIconWidget(
                      iconName: 'download_done',
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              // Category Tag
              if (_getDisplayCategory(widget.podcast) != null)
                Positioned(
                  top: 16,
                  left: widget.podcast["isDownloaded"] == true ? 56 : 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDisplayCategory(widget.podcast)!,
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (widget.onPlay != null)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: widget.onPlay,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child:
                          Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _getDisplayCategory(Map<String, dynamic> podcast) {
  dynamic categoryData = podcast["category"];
  if (categoryData == null ||
      categoryData.toString().isEmpty ||
      categoryData.toString().toLowerCase() == 'uncategorized') {
    return null;
  }
  if (categoryData is String) {
    final categories = categoryData
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (categories.isEmpty) {
      return null;
    } else if (categories.length == 1) {
      return categories.first;
    } else {
      final random = Random();
      return categories[random.nextInt(categories.length)];
    }
  }
  if (categoryData is Map<String, dynamic>) {
    final categories = categoryData.values
        .where((v) => v != null && v.toString().isNotEmpty)
        .toList();
    if (categories.isEmpty) {
      return null;
    } else if (categories.length == 1) {
      return categories.first.toString();
    } else {
      final random = Random();
      return categories[random.nextInt(categories.length)].toString();
    }
  }
  if (categoryData is List) {
    final categories = categoryData
        .where((c) => c != null && c.toString().isNotEmpty)
        .toList();
    if (categories.isEmpty) {
      return null;
    } else if (categories.length == 1) {
      return categories.first.toString();
    } else {
      final random = Random();
      return categories[random.nextInt(categories.length)].toString();
    }
  }
  return categoryData.toString();
}

String _stripHtmlTags(String htmlText) {
  final RegExp exp = RegExp(r'<[^>]+>', multiLine: true, caseSensitive: false);
  return htmlText
      .replaceAll(exp, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}
