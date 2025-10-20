import 'package:flutter/foundation.dart';

/// Buffering states for audio playback
enum BufferingState {
  idle, // No audio loaded
  loading, // Loading audio source
  buffering, // Buffering audio data
  ready, // Ready to play
  error, // Error occurred
  paused // Audio is paused
}

/// Network quality levels for adaptive buffering
enum NetworkQuality {
  excellent, // > 10 Mbps
  good, // 2-10 Mbps
  poor, // < 2 Mbps
  unknown // Unable to determine
}

/// Audio quality levels for adaptive streaming
enum AudioQuality {
  low, // 64kbps - poor connection
  medium, // 128kbps - normal connection
  high, // 256kbps - good connection
  original // Original quality - excellent connection
}

/// Repeat modes for playlist playback
enum RepeatMode {
  none, // No repeat
  single, // Repeat current episode
  all // Repeat entire playlist
}

/// Buffering information for an episode
class BufferingInfo {
  final double progress; // 0.0 to 1.0
  final Duration bufferedDuration;
  final Duration totalDuration;
  final bool isReady;
  final BufferingState state;
  final NetworkQuality networkQuality;
  final AudioQuality audioQuality;

  const BufferingInfo({
    required this.progress,
    required this.bufferedDuration,
    required this.totalDuration,
    required this.isReady,
    required this.state,
    required this.networkQuality,
    required this.audioQuality,
  });

  /// Create a default buffering info
  factory BufferingInfo.defaultState() {
    return const BufferingInfo(
      progress: 0.0,
      bufferedDuration: Duration.zero,
      totalDuration: Duration.zero,
      isReady: false,
      state: BufferingState.idle,
      networkQuality: NetworkQuality.unknown,
      audioQuality: AudioQuality.medium,
    );
  }

  /// Create a copy with updated values
  BufferingInfo copyWith({
    double? progress,
    Duration? bufferedDuration,
    Duration? totalDuration,
    bool? isReady,
    BufferingState? state,
    NetworkQuality? networkQuality,
    AudioQuality? audioQuality,
  }) {
    return BufferingInfo(
      progress: progress ?? this.progress,
      bufferedDuration: bufferedDuration ?? this.bufferedDuration,
      totalDuration: totalDuration ?? this.totalDuration,
      isReady: isReady ?? this.isReady,
      state: state ?? this.state,
      networkQuality: networkQuality ?? this.networkQuality,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }

  @override
  String toString() {
    return 'BufferingInfo(progress: $progress, buffered: ${bufferedDuration.inSeconds}s, total: ${totalDuration.inSeconds}s, ready: $isReady, state: $state)';
  }
}

/// Episode information for queue management
class Episode {
  final String id;
  final String title;
  final String? description;
  final Duration? duration;
  final String? imageUrl;
  final String? audioUrl;
  final String? podcastTitle;
  final String? podcastAuthor;
  final DateTime? publishedAt;

  const Episode({
    required this.id,
    required this.title,
    this.description,
    this.duration,
    this.imageUrl,
    this.audioUrl,
    this.podcastTitle,
    this.podcastAuthor,
    this.publishedAt,
  });

  /// Create from JSON
  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      duration:
          json['duration'] != null ? Duration(seconds: json['duration']) : null,
      imageUrl: json['image_url'] ?? json['imageUrl'],
      audioUrl: json['audio_url'] ?? json['audioUrl'] ?? json['enclosureUrl'],
      podcastTitle: json['podcast_title'] ?? json['podcastTitle'],
      podcastAuthor: json['podcast_author'] ?? json['podcastAuthor'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration?.inSeconds,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'podcast_title': podcastTitle,
      'podcast_author': podcastAuthor,
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Episode(id: $id, title: $title, duration: $duration)';
  }
}

/// Queue state for playlist management
class QueueState {
  final List<Episode> queue;
  final int currentIndex;
  final bool isShuffled;
  final RepeatMode repeatMode;
  final bool isAutoPlayEnabled;
  final bool isPlaying;

  const QueueState({
    required this.queue,
    required this.currentIndex,
    required this.isShuffled,
    required this.repeatMode,
    required this.isAutoPlayEnabled,
    required this.isPlaying,
  });

  /// Create default queue state
  factory QueueState.defaultState() {
    return const QueueState(
      queue: [],
      currentIndex: -1,
      isShuffled: false,
      repeatMode: RepeatMode.none,
      isAutoPlayEnabled: true,
      isPlaying: false,
    );
  }

  /// Get current episode
  Episode? get currentEpisode {
    if (currentIndex >= 0 && currentIndex < queue.length) {
      return queue[currentIndex];
    }
    return null;
  }

  /// Get next episode
  Episode? get nextEpisode {
    if (currentIndex + 1 < queue.length) {
      return queue[currentIndex + 1];
    }
    return null;
  }

  /// Get previous episode
  Episode? get previousEpisode {
    if (currentIndex - 1 >= 0) {
      return queue[currentIndex - 1];
    }
    return null;
  }

  /// Check if there's a next episode
  bool get hasNext => nextEpisode != null;

  /// Check if there's a previous episode
  bool get hasPrevious => previousEpisode != null;

  /// Create a copy with updated values
  QueueState copyWith({
    List<Episode>? queue,
    int? currentIndex,
    bool? isShuffled,
    RepeatMode? repeatMode,
    bool? isAutoPlayEnabled,
    bool? isPlaying,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      isAutoPlayEnabled: isAutoPlayEnabled ?? this.isAutoPlayEnabled,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  String toString() {
    return 'QueueState(queue: ${queue.length} episodes, current: $currentIndex, playing: $isPlaying)';
  }
}
