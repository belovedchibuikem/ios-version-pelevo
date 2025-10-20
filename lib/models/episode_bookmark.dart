class EpisodeBookmark {
  final String episodeId;
  final String podcastId;
  final int position;
  final String title;
  final String? notes;
  final String color;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? category;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  EpisodeBookmark({
    required this.episodeId,
    required this.podcastId,
    required this.position,
    required this.title,
    this.notes,
    this.color = '#2196F3',
    this.isPublic = false,
    required this.createdAt,
    this.updatedAt,
    this.category,
    this.tags,
    this.metadata,
  });

  factory EpisodeBookmark.fromJson(Map<String, dynamic> json) {
    return EpisodeBookmark(
      episodeId: json['episode_id'] ?? '',
      podcastId: json['podcast_id'] ?? '',
      position: json['position'] ?? 0,
      title: json['title'] ?? '',
      notes: json['notes'],
      color: json['color'] ?? '#2196F3',
      isPublic: json['is_public'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episode_id': episodeId,
      'podcast_id': podcastId,
      'position': position,
      'title': title,
      'notes': notes,
      'color': color,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'category': category,
      'tags': tags,
      'metadata': metadata,
    };
  }

  EpisodeBookmark copyWith({
    String? episodeId,
    String? podcastId,
    int? position,
    String? title,
    String? notes,
    String? color,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return EpisodeBookmark(
      episodeId: episodeId ?? this.episodeId,
      podcastId: podcastId ?? this.podcastId,
      position: position ?? this.position,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  String get formattedPosition {
    return _formatDuration(position);
  }

  String get formattedPositionShort {
    final hours = position ~/ 3600;
    final minutes = (position % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
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
    return other is EpisodeBookmark &&
        other.episodeId == episodeId &&
        other.position == position;
  }

  @override
  int get hashCode {
    return episodeId.hashCode ^ position.hashCode;
  }

  @override
  String toString() {
    return 'EpisodeBookmark(title: $title, position: $formattedPosition)';
  }
}
