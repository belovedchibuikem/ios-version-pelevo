// Notification model for in-app notifications from backend
class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final String? podcastindexPodcastId;
  final String? podcastindexEpisodeId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.podcastindexPodcastId,
    this.podcastindexEpisodeId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      data: json['data'],
      podcastindexPodcastId: json['podcastindex_podcast_id'],
      podcastindexEpisodeId: json['podcastindex_episode_id'],
      isRead: json['is_read'] ?? false,
      readAt:
          json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'podcastindex_podcast_id': podcastindexPodcastId,
        'podcastindex_episode_id': podcastindexEpisodeId,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
