class Subscription {
  final int id;
  final int podcastId;
  final DateTime? subscribedAt;
  final DateTime? unsubscribedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Podcast? podcast;

  Subscription({
    required this.id,
    required this.podcastId,
    this.subscribedAt,
    this.unsubscribedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.podcast,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Handle both local database subscriptions and PodcastIndex subscriptions
    if (json.containsKey('feed_id')) {
      // PodcastIndex subscription
      return Subscription(
        id: int.parse(json['id'].toString()),
        podcastId: int.parse(json['feed_id']
            .toString()), // Use feed_id as podcastId for compatibility
        subscribedAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        unsubscribedAt: null,
        isActive: true,
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(
            json['updated_at'] ?? DateTime.now().toIso8601String()),
        podcast: null, // PodcastIndex subscriptions don't include podcast data
      );
    } else {
      // Local database subscription
      return Subscription(
        id: int.parse(json['id'].toString()),
        podcastId: int.parse(json['podcast_id'].toString()),
        subscribedAt: json['subscribed_at'] != null
            ? DateTime.parse(json['subscribed_at'])
            : null,
        unsubscribedAt: json['unsubscribed_at'] != null
            ? DateTime.parse(json['unsubscribed_at'])
            : null,
        isActive: json['is_active'] is bool
            ? json['is_active']
            : (json['is_active'].toString() == '1' ||
                json['is_active'].toString().toLowerCase() == 'true'),
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        podcast:
            json['podcast'] != null ? Podcast.fromJson(json['podcast']) : null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'podcast_id': podcastId,
      'subscribed_at': subscribedAt?.toIso8601String(),
      'unsubscribed_at': unsubscribedAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'podcast': podcast?.toJson(),
    };
  }
}

class Podcast {
  final int id;
  final String title;
  final String? description;
  final String? author;
  final String? image;
  final int? episodeCount;
  final List<String>? categories;

  Podcast({
    required this.id,
    required this.title,
    this.description,
    this.author,
    this.image,
    this.episodeCount,
    this.categories,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      author: json['author'],
      image: json['image'],
      episodeCount: json['episode_count'],
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'image': image,
      'episode_count': episodeCount,
      'categories': categories,
    };
  }
}
