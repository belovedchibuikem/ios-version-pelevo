class EpisodeProgress {
  final String episodeId;
  final String podcastId;
  final int currentPosition;
  final int totalDuration;
  final double progressPercentage;
  final bool isCompleted;
  final DateTime? lastPlayedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? playbackData;

  EpisodeProgress({
    required this.episodeId,
    required this.podcastId,
    required this.currentPosition,
    required this.totalDuration,
    required this.progressPercentage,
    this.isCompleted = false,
    this.lastPlayedAt,
    this.completedAt,
    this.playbackData,
  });

  factory EpisodeProgress.fromJson(Map<String, dynamic> json) {
    return EpisodeProgress(
      episodeId: json['episode_id'] ?? '',
      podcastId: json['podcast_id'] ?? '',
      currentPosition: json['current_position'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      isCompleted: json['is_completed'] ?? false,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      playbackData: json['playback_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episode_id': episodeId,
      'podcast_id': podcastId,
      'current_position': currentPosition,
      'total_duration': totalDuration,
      'progress_percentage': progressPercentage,
      'is_completed': isCompleted,
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'playback_data': playbackData,
    };
  }

  EpisodeProgress copyWith({
    String? episodeId,
    String? podcastId,
    int? currentPosition,
    int? totalDuration,
    double? progressPercentage,
    bool? isCompleted,
    DateTime? lastPlayedAt,
    DateTime? completedAt,
    Map<String, dynamic>? playbackData,
  }) {
    return EpisodeProgress(
      episodeId: episodeId ?? this.episodeId,
      podcastId: podcastId ?? this.podcastId,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isCompleted: isCompleted ?? this.isCompleted,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      completedAt: completedAt ?? this.completedAt,
      playbackData: playbackData ?? this.playbackData,
    );
  }

  double get progressRatio {
    if (totalDuration <= 0) return 0.0;
    return currentPosition / totalDuration;
  }

  String get formattedCurrentPosition {
    return _formatDuration(currentPosition);
  }

  String get formattedTotalDuration {
    return _formatDuration(totalDuration);
  }

  String get formattedRemainingTime {
    final remaining = totalDuration - currentPosition;
    return _formatDuration(remaining > 0 ? remaining : 0);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeProgress &&
        other.episodeId == episodeId &&
        other.podcastId == podcastId;
  }

  @override
  int get hashCode {
    return episodeId.hashCode ^ podcastId.hashCode;
  }

  @override
  String toString() {
    return 'EpisodeProgress(episodeId: $episodeId, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%)';
  }
}
