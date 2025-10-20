import 'package:flutter/material.dart';

/// Utility class for handling podcast and episode image extraction
class ImageUtils {
  /// Extract the best available image URL from episode data
  /// This function handles all possible image field variations
  static String extractPodcastImage(Map<String, dynamic> episodeData) {
    // Debug logging
    debugPrint('=== IMAGE EXTRACTION DEBUG ===');
    debugPrint('Episode data keys: ${episodeData.keys.toList()}');
    debugPrint('Episode coverImage: ${episodeData['coverImage']}');
    debugPrint('Episode image: ${episodeData['image']}');
    debugPrint('Episode feedImage: ${episodeData['feedImage']}');
    debugPrint('Episode feed_image: ${episodeData['feed_image']}');

    // Check if podcast object exists
    if (episodeData['podcast'] != null && episodeData['podcast'] is Map) {
      final podcast = episodeData['podcast'] as Map<String, dynamic>;
      debugPrint('Podcast object found: ${podcast.keys.toList()}');
      debugPrint('Podcast coverImage: ${podcast['coverImage']}');
      debugPrint('Podcast cover_image: ${podcast['cover_image']}');
      debugPrint('Podcast image: ${podcast['image']}');
      debugPrint('Podcast artwork: ${podcast['artwork']}');

      // Try podcast-specific image fields first
      final podcastImage = podcast['coverImage']?.toString() ??
          podcast['cover_image']?.toString() ??
          podcast['image']?.toString() ??
          podcast['artwork']?.toString() ??
          '';

      if (podcastImage.isNotEmpty) {
        debugPrint('Found podcast image: $podcastImage');
        debugPrint('=== END IMAGE EXTRACTION DEBUG ===');
        return podcastImage;
      }
    }

    // Fallback to episode-level image fields
    final episodeImage = episodeData['coverImage']?.toString() ??
        episodeData['image']?.toString() ??
        episodeData['feedImage']?.toString() ??
        episodeData['feed_image']?.toString() ??
        episodeData['cover_image']?.toString() ??
        episodeData['artwork']?.toString() ??
        '';

    debugPrint('Final extracted image: $episodeImage');
    debugPrint('=== END IMAGE EXTRACTION DEBUG ===');
    return episodeImage;
  }

  /// Extract podcast image with fallback to first episode in list
  static String extractPodcastImageWithFallback(
    Map<String, dynamic> episodeData,
    List<Map<String, dynamic>> episodesList,
  ) {
    // First try to get image from current episode
    String imageUrl = extractPodcastImage(episodeData);

    // If no image found and episodes list is available, try first episode
    if (imageUrl.isEmpty && episodesList.isNotEmpty) {
      debugPrint(
          'No image found in current episode, trying first episode in list');
      imageUrl = extractPodcastImage(episodesList.first);
    }

    return imageUrl;
  }

  /// Check if image URL is valid
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Get fallback widget for when no image is available
  static Widget getFallbackWidget({
    double width = 60,
    double height = 60,
    Color? backgroundColor,
    IconData icon = Icons.music_note,
    Color? iconColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: iconColor ?? Colors.grey[600],
        size: (width * 0.4).clamp(16.0, 32.0),
      ),
    );
  }
}

