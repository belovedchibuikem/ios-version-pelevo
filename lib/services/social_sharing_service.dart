import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/episode_bookmark.dart';

/// Service for social sharing of episodes, progress, and bookmarks
class SocialSharingService {
  static final SocialSharingService _instance =
      SocialSharingService._internal();
  factory SocialSharingService() => _instance;
  SocialSharingService._internal();

  /// Share episode information
  Future<void> shareEpisode({
    required String episodeTitle,
    required String podcastTitle,
    String? episodeDescription,
    String? episodeUrl,
    String? imageUrl,
    String? customMessage,
  }) async {
    try {
      final message = _buildEpisodeShareMessage(
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        episodeDescription: episodeDescription,
        episodeUrl: episodeUrl,
        customMessage: customMessage,
      );

      await Share.share(
        message,
        subject: 'Check out this episode: $episodeTitle',
      );
    } catch (e) {
      debugPrint('Error sharing episode: $e');
      rethrow;
    }
  }

  /// Share episode progress
  Future<void> shareProgress({
    required String episodeTitle,
    required String podcastTitle,
    required int currentPosition,
    required int totalDuration,
    String? customMessage,
  }) async {
    try {
      final message = _buildProgressShareMessage(
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        customMessage: customMessage,
      );

      await Share.share(
        message,
        subject: 'My listening progress: $episodeTitle',
      );
    } catch (e) {
      debugPrint('Error sharing progress: $e');
      rethrow;
    }
  }

  /// Share bookmark
  Future<void> shareBookmark({
    required EpisodeBookmark bookmark,
    required String episodeTitle,
    required String podcastTitle,
    String? customMessage,
  }) async {
    try {
      final message = _buildBookmarkShareMessage(
        bookmark: bookmark,
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        customMessage: customMessage,
      );

      await Share.share(
        message,
        subject: 'Bookmark: ${bookmark.title}',
      );
    } catch (e) {
      debugPrint('Error sharing bookmark: $e');
      rethrow;
    }
  }

  /// Share listening statistics
  Future<void> shareStatistics({
    required int totalEpisodes,
    required int completedEpisodes,
    required int totalListeningTime,
    String? customMessage,
  }) async {
    try {
      final message = _buildStatisticsShareMessage(
        totalEpisodes: totalEpisodes,
        completedEpisodes: completedEpisodes,
        totalListeningTime: totalListeningTime,
        customMessage: customMessage,
      );

      await Share.share(
        message,
        subject: 'My Podcast Listening Stats',
      );
    } catch (e) {
      debugPrint('Error sharing statistics: $e');
      rethrow;
    }
  }

  /// Share podcast recommendations
  Future<void> shareRecommendations({
    required List<String> podcastTitles,
    String? customMessage,
  }) async {
    try {
      final message = _buildRecommendationsShareMessage(
        podcastTitles: podcastTitles,
        customMessage: customMessage,
      );

      await Share.share(
        message,
        subject: 'Podcast Recommendations',
      );
    } catch (e) {
      debugPrint('Error sharing recommendations: $e');
      rethrow;
    }
  }

  /// Share podcast information
  Future<void> sharePodcast({
    required String podcastTitle,
    String? podcastDescription,
    String? podcastUrl,
    String? imageUrl,
    String? customMessage,
  }) async {
    try {
      final message = _buildPodcastShareMessage(
        podcastTitle: podcastTitle,
        podcastDescription: podcastDescription,
        podcastUrl: podcastUrl,
        customMessage: customMessage,
      );

      await Share.share(
        message,
        subject: 'Check out this podcast: $podcastTitle',
      );
    } catch (e) {
      debugPrint('Error sharing podcast: $e');
      rethrow;
    }
  }

  /// Build episode share message
  String _buildEpisodeShareMessage({
    required String episodeTitle,
    required String podcastTitle,
    String? episodeDescription,
    String? episodeUrl,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }

    buffer.writeln('🎧 $episodeTitle');
    buffer.writeln('📻 $podcastTitle');

    if (episodeDescription != null && episodeDescription.isNotEmpty) {
      // Truncate description if too long
      final truncatedDescription = episodeDescription.length > 200
          ? '${episodeDescription.substring(0, 200)}...'
          : episodeDescription;
      buffer.writeln();
      buffer.writeln(truncatedDescription);
    }

    if (episodeUrl != null && episodeUrl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🔗 Listen here: $episodeUrl');
    }

    buffer.writeln();
    buffer.writeln('Shared via Pelevo Podcast App');

    return buffer.toString();
  }

  /// Build progress share message
  String _buildProgressShareMessage({
    required String episodeTitle,
    required String podcastTitle,
    required int currentPosition,
    required int totalDuration,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }

    buffer.writeln('🎧 Currently listening to:');
    buffer.writeln('📻 $episodeTitle');
    buffer.writeln('🎵 $podcastTitle');
    buffer.writeln();

    final progressPercentage = (currentPosition / totalDuration * 100).round();
    final currentTime = _formatDuration(currentPosition);
    final totalTime = _formatDuration(totalDuration);

    buffer.writeln(
        '⏱️ Progress: $progressPercentage% ($currentTime / $totalTime)');
    buffer.writeln();
    buffer.writeln('Shared via Pelevo Podcast App');

    return buffer.toString();
  }

  /// Build bookmark share message
  String _buildBookmarkShareMessage({
    required EpisodeBookmark bookmark,
    required String episodeTitle,
    required String podcastTitle,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }

    buffer.writeln('🔖 Bookmark: ${bookmark.title}');
    buffer.writeln('🎧 Episode: $episodeTitle');
    buffer.writeln('📻 Podcast: $podcastTitle');
    buffer.writeln();

    final position = _formatDuration(bookmark.position);
    buffer.writeln('⏱️ Position: $position');

    if (bookmark.notes != null && bookmark.notes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 Notes: ${bookmark.notes}');
    }

    if (bookmark.category != null && bookmark.category!.isNotEmpty) {
      buffer.writeln('🏷️ Category: ${bookmark.category}');
    }

    if (bookmark.tags != null && bookmark.tags!.isNotEmpty) {
      buffer.writeln('🏷️ Tags: ${bookmark.tags!.join(', ')}');
    }

    buffer.writeln();
    buffer.writeln('Shared via Pelevo Podcast App');

    return buffer.toString();
  }

  /// Build statistics share message
  String _buildStatisticsShareMessage({
    required int totalEpisodes,
    required int completedEpisodes,
    required int totalListeningTime,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }

    buffer.writeln('📊 My Podcast Listening Stats');
    buffer.writeln();
    buffer.writeln('🎧 Total Episodes: $totalEpisodes');
    buffer.writeln('✅ Completed: $completedEpisodes');
    buffer.writeln(
        '⏱️ Total Listening Time: ${_formatDuration(totalListeningTime)}');

    if (totalEpisodes > 0) {
      final completionRate = (completedEpisodes / totalEpisodes * 100).round();
      buffer.writeln('📈 Completion Rate: $completionRate%');
    }

    buffer.writeln();
    buffer.writeln('Shared via Pelevo Podcast App');

    return buffer.toString();
  }

  /// Build recommendations share message
  String _buildRecommendationsShareMessage({
    required List<String> podcastTitles,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }

    buffer.writeln('🎧 Podcast Recommendations');
    buffer.writeln();

    for (int i = 0; i < podcastTitles.length; i++) {
      buffer.writeln('${i + 1}. ${podcastTitles[i]}');
    }

    buffer.writeln();
    buffer.writeln('Shared via Pelevo Podcast App');

    return buffer.toString();
  }

  /// Build podcast share message
  String _buildPodcastShareMessage({
    required String podcastTitle,
    String? podcastDescription,
    String? podcastUrl,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }

    buffer.writeln('📻 $podcastTitle');

    if (podcastDescription != null && podcastDescription.isNotEmpty) {
      // Truncate description if too long
      final truncatedDescription = podcastDescription.length > 300
          ? '${podcastDescription.substring(0, 300)}...'
          : podcastDescription;
      buffer.writeln();
      buffer.writeln(truncatedDescription);
    }

    if (podcastUrl != null && podcastUrl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🔗 Listen here: $podcastUrl');
    }

    buffer.writeln();
    buffer.writeln('Shared via Pelevo Podcast App');

    return buffer.toString();
  }

  /// Format duration in human-readable format
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  /// Generate shareable link for episode
  String generateEpisodeLink({
    required String episodeId,
    required String podcastId,
    String? baseUrl,
  }) {
    final url = baseUrl ?? 'https://pelevo.app';
    return '$url/episode/$podcastId/$episodeId';
  }

  /// Generate shareable link for bookmark
  String generateBookmarkLink({
    required String episodeId,
    required int position,
    String? baseUrl,
  }) {
    final url = baseUrl ?? 'https://pelevo.app';
    return '$url/bookmark/$episodeId?pos=$position';
  }

  /// Generate shareable link for podcast
  String generatePodcastLink({
    required String podcastId,
    String? baseUrl,
  }) {
    final url = baseUrl ?? 'https://pelevo.app';
    return '$url/podcast/$podcastId';
  }
}

