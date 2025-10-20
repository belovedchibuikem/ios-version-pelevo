class Bookmark {
  final int id;
  final int userId;
  final String episodeId;
  final String podcastId;
  final int position;
  final int duration;
  final String title;
  final String? notes;
  final String? color;
  final bool isPublic;
  final String? category;
  final String? subcategory;
  final String? timestampLabel;
  final bool isFeatured;
  final int shareCount;
  final int viewCount;
  final List<String> tags;
  final String? bookmarkType;
  final int? priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bookmark({
    required this.id,
    required this.userId,
    required this.episodeId,
    required this.podcastId,
    required this.position,
    required this.duration,
    required this.title,
    this.notes,
    this.color,
    required this.isPublic,
    this.category,
    this.subcategory,
    this.timestampLabel,
    required this.isFeatured,
    required this.shareCount,
    required this.viewCount,
    required this.tags,
    this.bookmarkType,
    this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      userId: json['user_id'],
      episodeId: json['episode_id'],
      podcastId: json['podcast_id'],
      position: json['position'] ?? 0,
      duration: json['duration'] ?? 0,
      title: json['title'],
      notes: json['notes'],
      color: json['color'],
      isPublic: json['is_public'] ?? false,
      category: json['category'],
      subcategory: json['subcategory'],
      timestampLabel: json['timestamp_label'],
      isFeatured: json['is_featured'] ?? false,
      shareCount: json['share_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      bookmarkType: json['bookmark_type'],
      priority: json['priority'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'episode_id': episodeId,
      'podcast_id': podcastId,
      'position': position,
      'duration': duration,
      'title': title,
      'notes': notes,
      'color': color,
      'is_public': isPublic,
      'category': category,
      'subcategory': subcategory,
      'timestamp_label': timestampLabel,
      'is_featured': isFeatured,
      'share_count': shareCount,
      'view_count': viewCount,
      'tags': tags,
      'bookmark_type': bookmarkType,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Bookmark copyWith({
    int? id,
    int? userId,
    String? episodeId,
    String? podcastId,
    int? position,
    int? duration,
    String? title,
    String? notes,
    String? color,
    bool? isPublic,
    String? category,
    String? subcategory,
    String? timestampLabel,
    bool? isFeatured,
    int? shareCount,
    int? viewCount,
    List<String>? tags,
    String? bookmarkType,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      episodeId: episodeId ?? this.episodeId,
      podcastId: podcastId ?? this.podcastId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      isPublic: isPublic ?? this.isPublic,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      isFeatured: isFeatured ?? this.isFeatured,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      tags: tags ?? this.tags,
      bookmarkType: bookmarkType ?? this.bookmarkType,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getDurationFormatted() {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getPositionFormatted() {
    final minutes = position ~/ 60;
    final seconds = position % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getBookmarkTypeLabel() {
    switch (bookmarkType) {
      case 'note':
        return 'Note';
      case 'highlight':
        return 'Highlight';
      case 'quote':
        return 'Quote';
      case 'reminder':
        return 'Reminder';
      default:
        return 'Bookmark';
    }
  }

  String getPriorityLabel() {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Normal';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Critical';
      default:
        return 'Normal';
    }
  }
}
