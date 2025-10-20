class PlayHistory {
  final int id;
  final int userId;
  final String podcastindexEpisodeId;
  final String status;
  final int position;
  final int progressSeconds;
  final int totalListeningTime;
  final int playCount;
  final DateTime? lastPlayedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Episode? episode;

  // Computed properties
  late final double progressPercentage;
  late final bool isCompleted;
  late final int timeRemaining;
  late final String formattedProgressTime;
  late final String formattedTotalTime;

  PlayHistory({
    required this.id,
    required this.userId,
    required this.podcastindexEpisodeId,
    required this.status,
    required this.position,
    required this.progressSeconds,
    required this.totalListeningTime,
    required this.playCount,
    this.lastPlayedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.episode,
  }) {
    _calculateComputedProperties();
  }

  void _calculateComputedProperties() {
    // Calculate progress percentage
    if (episode?.duration != null && episode!.duration! > 0) {
      final calculatedPercentage = (progressSeconds / episode!.duration!) * 100;
      progressPercentage = calculatedPercentage.clamp(0.0, 100.0);
    } else {
      progressPercentage = 0.0;
    }

    // Check if completed
    isCompleted = status == 'completed' || completedAt != null;

    // Calculate time remaining
    if (episode?.duration != null) {
      timeRemaining =
          (episode!.duration! - progressSeconds).clamp(0, episode!.duration!);
    } else {
      timeRemaining = 0;
    }

    // Format progress time
    final progressMinutes = (progressSeconds / 60).floor();
    final progressSecs = progressSeconds % 60;
    formattedProgressTime =
        '${progressMinutes.toString().padLeft(2, '0')}:${progressSecs.toString().padLeft(2, '0')}';

    // Format total time
    if (episode?.duration != null) {
      final totalMinutes = (episode!.duration! / 60).floor();
      final totalSecs = episode!.duration! % 60;
      formattedTotalTime =
          '${totalMinutes.toString().padLeft(2, '0')}:${totalSecs.toString().padLeft(2, '0')}';
    } else {
      formattedTotalTime = '00:00';
    }
  }

  factory PlayHistory.fromJson(Map<String, dynamic> json) {
    return PlayHistory(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      podcastindexEpisodeId: json['podcastindex_episode_id']?.toString() ?? '',
      status: json['status'] ?? '',
      position: _parseInt(json['position']) ?? 0,
      progressSeconds: _parseInt(json['progress_seconds']) ?? 0,
      totalListeningTime: _parseInt(json['total_listening_time']) ?? 0,
      playCount: _parseInt(json['play_count']) ?? 1,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      episode:
          json['episode'] != null ? Episode.fromJson(json['episode']) : null,
    );
  }

  /// Helper method to safely parse integer values from JSON
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'podcastindex_episode_id': podcastindexEpisodeId,
      'status': status,
      'position': position,
      'progress_seconds': progressSeconds,
      'total_listening_time': totalListeningTime,
      'play_count': playCount,
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'episode': episode?.toJson(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'played':
        return 'Played';
      case 'paused':
        return 'Paused';
      case 'completed':
        return 'Completed';
      case 'abandoned':
        return 'Abandoned';
      default:
        return 'Unknown';
    }
  }

  String get timeAgo {
    if (lastPlayedAt == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastPlayedAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Create a copy with updated values
  PlayHistory copyWith({
    int? id,
    int? userId,
    String? podcastindexEpisodeId,
    String? status,
    int? position,
    int? progressSeconds,
    int? totalListeningTime,
    int? playCount,
    DateTime? lastPlayedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Episode? episode,
  }) {
    return PlayHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      podcastindexEpisodeId:
          podcastindexEpisodeId ?? this.podcastindexEpisodeId,
      status: status ?? this.status,
      position: position ?? this.position,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      totalListeningTime: totalListeningTime ?? this.totalListeningTime,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      episode: episode ?? this.episode,
    );
  }
}

class Episode {
  final int id;
  final String title;
  final String? description;
  final int? duration;
  final String? image;
  final String? enclosureUrl;
  final int? datePublished;
  final String? datePublishedPretty;
  final Podcast? podcast;

  Episode({
    required this.id,
    required this.title,
    this.description,
    this.duration,
    this.image,
    this.enclosureUrl,
    this.datePublished,
    this.datePublishedPretty,
    this.podcast,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: _parseInt(json['id']) ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      duration: _parseInt(json['duration']),
      image: json['image'] ?? json['coverImage'],
      enclosureUrl: json['enclosure_url'],
      datePublished: _parseInt(json['date_published']),
      datePublishedPretty: json['date_published_pretty'],
      podcast:
          json['podcast'] != null ? Podcast.fromJson(json['podcast']) : null,
    );
  }

  /// Helper method to safely parse integer values from JSON
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'image': image,
      'enclosure_url': enclosureUrl,
      'date_published': datePublished,
      'date_published_pretty': datePublishedPretty,
      'podcast': podcast?.toJson(),
    };
  }
}

class Podcast {
  final int id;
  final String title;
  final String? author;
  final String? description;
  final String? image;
  final String? feedUrl;
  final int? episodeCount;

  Podcast({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.image,
    this.feedUrl,
    this.episodeCount,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: _parseInt(json['id']) ?? 0,
      title: json['title'] ?? '',
      author: json['author'],
      description: json['description'],
      image: json['image'] ?? json['coverImage'],
      feedUrl: json['feed_url'],
      episodeCount: _parseInt(json['episode_count']),
    );
  }

  /// Helper method to safely parse integer values from JSON
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'image': image,
      'feed_url': feedUrl,
      'episode_count': episodeCount,
    };
  }
}
