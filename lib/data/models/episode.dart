// lib/data/models/episode.dart

class Episode {
  final int id;
  final String title;
  final String podcastName;
  final String creator;
  final String coverImage;
  final String duration;
  final bool isDownloaded;
  final String description;
  final String? audioUrl;
  final DateTime releaseDate;
  final String? podcastId;

  // Progress tracking fields
  final int? lastPlayedPosition; // in milliseconds
  final int? totalDuration; // in milliseconds
  final DateTime? lastPlayedAt;
  final bool isCompleted;

  Episode({
    required this.id,
    required this.title,
    required this.podcastName,
    required this.creator,
    required this.coverImage,
    required this.duration,
    this.isDownloaded = false,
    required this.description,
    this.audioUrl,
    required this.releaseDate,
    this.lastPlayedPosition,
    this.totalDuration,
    this.lastPlayedAt,
    this.isCompleted = false,
    this.podcastId,
  });

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (lastPlayedPosition == null ||
        totalDuration == null ||
        totalDuration == 0) {
      return 0.0;
    }
    return (lastPlayedPosition! / totalDuration!).clamp(0.0, 1.0);
  }

  /// Get remaining time in milliseconds
  int? get remainingTime {
    if (lastPlayedPosition == null || totalDuration == null) {
      return null;
    }
    return (totalDuration! - lastPlayedPosition!).clamp(0, totalDuration!);
  }

  /// Get formatted remaining time string
  String get formattedRemainingTime {
    final remaining = remainingTime;
    if (remaining == null) return '';

    final hours = remaining ~/ 3600000;
    final minutes = (remaining % 3600000) ~/ 60000;
    final seconds = (remaining % 60000) ~/ 1000;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s remaining';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s remaining';
    } else {
      return '${seconds}s remaining';
    }
  }

  /// Check if episode is partially played
  bool get isPartiallyPlayed {
    return lastPlayedPosition != null &&
        totalDuration != null &&
        lastPlayedPosition! > 0 &&
        lastPlayedPosition! < totalDuration!;
  }

  /// Check if episode is in progress (started but not completed)
  bool get isInProgress {
    return isPartiallyPlayed && !isCompleted;
  }

  /// Create a copy with updated progress
  Episode copyWith({
    int? id,
    String? title,
    String? podcastName,
    String? creator,
    String? coverImage,
    String? duration,
    bool? isDownloaded,
    String? description,
    String? audioUrl,
    DateTime? releaseDate,
    int? lastPlayedPosition,
    int? totalDuration,
    DateTime? lastPlayedAt,
    bool? isCompleted,
    String? podcastId,
  }) {
    return Episode(
      id: id ?? this.id,
      title: title ?? this.title,
      podcastName: podcastName ?? this.podcastName,
      creator: creator ?? this.creator,
      coverImage: coverImage ?? this.coverImage,
      duration: duration ?? this.duration,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      lastPlayedPosition: lastPlayedPosition ?? this.lastPlayedPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      podcastId: podcastId ?? this.podcastId,
    );
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    try {
      // Convert UNIX timestamp to DateTime
      DateTime releaseDate;
      if (json['datePublished'] is int) {
        releaseDate = DateTime.fromMillisecondsSinceEpoch(
            json['datePublished'] * 1000,
            isUtc: true);
      } else if (json['datePublished'] is String) {
        releaseDate =
            DateTime.tryParse(json['datePublished']) ?? DateTime.now();
      } else {
        releaseDate = DateTime.now();
      }

      // Format duration
      int durationSeconds = 0;
      if (json['duration'] is int) {
        durationSeconds = json['duration'];
      } else if (json['duration'] is String) {
        durationSeconds = int.tryParse(json['duration']) ?? 0;
      }
      String durationStr = durationSeconds >= 3600
          ? '${durationSeconds ~/ 3600}h ${(durationSeconds % 3600) ~/ 60}m'
          : '${(durationSeconds % 3600) ~/ 60}m';

      // Try to find audio URL from multiple possible fields
      String? audioUrl;
      final possibleAudioFields = [
        'enclosureUrl',
        'audioUrl',
        'audio',
        'url',
        'mp3',
        'm4a',
        'enclosure',
        'mediaUrl',
        'streamUrl',
        'downloadUrl',
        'fileUrl',
        'sourceUrl',
        'link',
        'href'
      ];

      for (final field in possibleAudioFields) {
        if (json[field] != null && json[field].toString().isNotEmpty) {
          audioUrl = json[field].toString();
          break;
        }
      }

      // Check nested objects like enclosure
      if (audioUrl == null &&
          json['enclosure'] != null &&
          json['enclosure'] is Map) {
        final enclosure = json['enclosure'] as Map;
        final enclosureFields = ['url', 'href', 'link', 'src', 'source'];
        for (final field in enclosureFields) {
          if (enclosure[field] != null &&
              enclosure[field].toString().isNotEmpty) {
            audioUrl = enclosure[field].toString();
            break;
          }
        }
      }

      // Parse progress tracking fields
      int? lastPlayedPosition;
      if (json['lastPlayedPosition'] != null) {
        lastPlayedPosition = json['lastPlayedPosition'] is int
            ? json['lastPlayedPosition']
            : int.tryParse(json['lastPlayedPosition'].toString());
      }

      int? totalDuration;
      if (json['totalDuration'] != null) {
        totalDuration = json['totalDuration'] is int
            ? json['totalDuration']
            : int.tryParse(json['totalDuration'].toString());
      } else if (durationSeconds > 0) {
        // Convert duration string to milliseconds if available
        totalDuration = durationSeconds * 1000;
      }

      DateTime? lastPlayedAt;
      if (json['lastPlayedAt'] != null) {
        if (json['lastPlayedAt'] is int) {
          lastPlayedAt =
              DateTime.fromMillisecondsSinceEpoch(json['lastPlayedAt']);
        } else if (json['lastPlayedAt'] is String) {
          lastPlayedAt = DateTime.tryParse(json['lastPlayedAt']);
        }
      }

      // Ensure isCompleted is always a boolean, never null
      bool isCompleted = false;
      if (json['isCompleted'] != null) {
        if (json['isCompleted'] is bool) {
          isCompleted = json['isCompleted'] as bool;
        } else if (json['isCompleted'] is int) {
          isCompleted = json['isCompleted'] == 1;
        } else if (json['isCompleted'] is String) {
          isCompleted = json['isCompleted'].toLowerCase() == 'true';
        }
      }

      // Extract podcast image with comprehensive fallback logic
      String coverImage = '';

      // Try podcast-specific image fields first
      if (json['podcast'] != null && json['podcast'] is Map) {
        final podcast = json['podcast'] as Map<String, dynamic>;
        coverImage = podcast['coverImage']?.toString() ??
            podcast['cover_image']?.toString() ??
            podcast['image']?.toString() ??
            podcast['artwork']?.toString() ??
            '';
      }

      // Fallback to episode-level image fields
      if (coverImage.isEmpty) {
        coverImage = json['image']?.toString() ??
            json['feedImage']?.toString() ??
            json['feed_image']?.toString() ??
            json['coverImage']?.toString() ??
            json['cover_image']?.toString() ??
            json['artwork']?.toString() ??
            '';
      }

      final episode = Episode(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title'] ?? 'Unknown Episode',
        podcastName: json['feedTitle'] ?? 'Unknown Podcast',
        creator: json['author'] ?? 'Unknown Creator',
        coverImage: coverImage,
        duration: durationStr,
        isDownloaded: false,
        description: json['description'] ?? '',
        audioUrl: audioUrl,
        releaseDate: releaseDate,
        podcastId: json['feedId']?.toString(), // Map from backend feedId
        lastPlayedPosition: lastPlayedPosition,
        totalDuration: totalDuration,
        lastPlayedAt: lastPlayedAt,
        isCompleted: isCompleted,
      );

      return episode;
    } catch (e) {
      // Return a safe default episode
      return Episode(
        id: 0,
        title: 'Error Episode',
        podcastName: 'Unknown Podcast',
        creator: 'Unknown Creator',
        coverImage: '',
        duration: '0m',
        description: 'Failed to load episode data',
        releaseDate: DateTime.now(),
        isCompleted: false, // Always false for error cases
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'podcastName': podcastName,
      'creator': creator,
      'coverImage': coverImage,
      'duration': duration,
      'isDownloaded': isDownloaded,
      'description': description,
      'audioUrl': audioUrl,
      'releaseDate': releaseDate.toIso8601String(),
      'lastPlayedPosition': lastPlayedPosition,
      'totalDuration': totalDuration,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'podcastId': podcastId,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'podcastName': podcastName,
      'creator': creator,
      'coverImage': coverImage,
      'image': coverImage, // Add alias for compatibility
      'feedImage': coverImage, // Add alias for compatibility
      'duration': duration,
      'isDownloaded': isDownloaded,
      'description': description,
      'audioUrl': audioUrl,
      'releaseDate': releaseDate.toIso8601String(),
      'lastPlayedPosition': lastPlayedPosition,
      'totalDuration': totalDuration,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'podcastId': podcastId,
      'feedId': podcastId, // Add alias for compatibility
      'feedTitle': podcastName, // Add alias for compatibility
      'author': creator, // Add alias for compatibility
      // Add podcast object structure for player components
      'podcast': {
        'id': podcastId,
        'title': podcastName,
        'coverImage': coverImage,
        'cover_image': coverImage,
        'image': coverImage,
        'artwork': coverImage,
      },
    };
  }

  /// Create a map with additional podcast data for player components
  Map<String, dynamic> toMapWithPodcastData(Map<String, dynamic>? podcastData) {
    final baseMap = toMap();

    // If podcast data is provided, merge it with the episode data
    if (podcastData != null) {
      baseMap['podcast'] = {
        'id': podcastData['id']?.toString() ?? podcastId,
        'title': podcastData['title']?.toString() ?? podcastName,
        'coverImage': podcastData['coverImage']?.toString() ??
            podcastData['cover_image']?.toString() ??
            podcastData['image']?.toString() ??
            podcastData['artwork']?.toString() ??
            coverImage,
        'cover_image': podcastData['cover_image']?.toString() ??
            podcastData['coverImage']?.toString() ??
            podcastData['image']?.toString() ??
            podcastData['artwork']?.toString() ??
            coverImage,
        'image': podcastData['image']?.toString() ??
            podcastData['coverImage']?.toString() ??
            podcastData['cover_image']?.toString() ??
            podcastData['artwork']?.toString() ??
            coverImage,
        'artwork': podcastData['artwork']?.toString() ??
            podcastData['coverImage']?.toString() ??
            podcastData['cover_image']?.toString() ??
            podcastData['image']?.toString() ??
            coverImage,
        'author': podcastData['author']?.toString() ??
            podcastData['creator']?.toString() ??
            creator,
        'creator': podcastData['creator']?.toString() ??
            podcastData['author']?.toString() ??
            creator,
      };

      // Also update the episode-level image fields with the best available image
      final bestImage = baseMap['podcast']['coverImage'];
      baseMap['coverImage'] = bestImage;
      baseMap['image'] = bestImage;
      baseMap['feedImage'] = bestImage;
    }

    return baseMap;
  }
}
