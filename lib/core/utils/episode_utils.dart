import 'package:flutter/foundation.dart';

/// Utility functions for episode data handling
class EpisodeUtils {
  /// Extract audio URL from episode data
  /// Tries multiple possible keys where the audio URL might be stored
  static String? extractAudioUrl(Map<String, dynamic> episode) {
    // Try different possible keys for audio URL
    final possibleKeys = [
      'audioUrl',
      'enclosureUrl',
      'audio_url',
      'enclosure_url',
      'url',
      'link',
      'enclosure',
      'mediaUrl',
      'media_url',
    ];

    for (final key in possibleKeys) {
      final value = episode[key];
      if (value != null && value is String && value.isNotEmpty) {
        debugPrint('Found audio URL in key "$key": $value');
        return value;
      }
    }

    debugPrint(
        'No audio URL found in episode data. Available keys: ${episode.keys.toList()}');
    return null;
  }

  /// Extract episode ID from episode data
  static String? extractEpisodeId(Map<String, dynamic> episode) {
    final possibleKeys = [
      'id',
      'episodeId',
      'episode_id',
      'guid',
    ];

    for (final key in possibleKeys) {
      final value = episode[key];
      if (value != null) {
        return value.toString();
      }
    }

    return null;
  }

  /// Extract episode title from episode data
  static String extractEpisodeTitle(Map<String, dynamic> episode) {
    final possibleKeys = [
      'title',
      'name',
      'episodeTitle',
      'episode_title',
    ];

    for (final key in possibleKeys) {
      final value = episode[key];
      if (value != null && value is String && value.isNotEmpty) {
        return value;
      }
    }

    return 'Unknown Episode';
  }

  /// Check if episode has valid audio URL for download
  static bool hasValidAudioUrl(Map<String, dynamic> episode) {
    final audioUrl = extractAudioUrl(episode);
    return audioUrl != null && audioUrl.isNotEmpty;
  }

  /// Get episode info for download
  static Map<String, String?> getEpisodeDownloadInfo(
      Map<String, dynamic> episode) {
    return {
      'episodeId': extractEpisodeId(episode),
      'episodeTitle': extractEpisodeTitle(episode),
      'audioUrl': extractAudioUrl(episode),
    };
  }
}
