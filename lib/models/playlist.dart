import 'package:flutter/foundation.dart';

class Playlist {
  final int id;
  final String name;
  final String? description;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlaylistItem>? items;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    try {
      return Playlist(
        id: json['id'] is int
            ? json['id']
            : (json['id'] != null ? int.parse(json['id'].toString()) : 0),
        name: json['name'] ?? '',
        description: json['description'],
        order: json['order'] is int
            ? json['order']
            : (json['order'] != null ? int.parse(json['order'].toString()) : 0),
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(
            json['updated_at'] ?? DateTime.now().toIso8601String()),
        items: json['items'] != null
            ? (json['items'] as List)
                .map((item) => PlaylistItem.fromJson(item))
                .toList()
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing Playlist JSON: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  int get itemsCount => items?.length ?? 0;
}

class PlaylistItem {
  final int id;
  final int playlistId;
  final int episodeId;
  final int order;
  final DateTime? addedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Episode? episode;

  PlaylistItem({
    required this.id,
    required this.playlistId,
    required this.episodeId,
    required this.order,
    this.addedAt,
    required this.createdAt,
    required this.updatedAt,
    this.episode,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.parse(json['id'].toString()) : 0),
      playlistId: json['playlist_id'] is int
          ? json['playlist_id']
          : (json['playlist_id'] != null
              ? int.parse(json['playlist_id'].toString())
              : 0),
      episodeId: json['episode_id'] is int
          ? json['episode_id']
          : (json['episode_id'] != null
              ? int.parse(json['episode_id'].toString())
              : 0),
      order: json['order'] is int
          ? json['order']
          : (json['order'] != null ? int.parse(json['order'].toString()) : 0),
      addedAt:
          json['added_at'] != null ? DateTime.parse(json['added_at']) : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      episode:
          json['episode'] != null ? Episode.fromJson(json['episode']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playlist_id': playlistId,
      'episode_id': episodeId,
      'order': order,
      'added_at': addedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'episode': episode?.toJson(),
    };
  }
}

class Episode {
  final int id;
  final String title;
  final String? description;
  final int? duration;
  final DateTime? pubDate;
  final String? image;
  final String? audioUrl;
  final Podcast? podcast;

  Episode({
    required this.id,
    required this.title,
    this.description,
    this.duration,
    this.pubDate,
    this.image,
    this.audioUrl,
    this.podcast,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.parse(json['id'].toString()) : 0),
      title: json['title'] ?? '',
      description: json['description'],
      duration: json['duration'] is int
          ? json['duration']
          : (json['duration'] != null
              ? int.parse(json['duration'].toString())
              : null),
      pubDate:
          json['pub_date'] != null ? DateTime.parse(json['pub_date']) : null,
      image: json['image'],
      audioUrl: json['audio_url'] ?? json['enclosureUrl'],
      podcast:
          json['podcast'] != null ? Podcast.fromJson(json['podcast']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'pub_date': pubDate?.toIso8601String(),
      'image': image,
      'audio_url': audioUrl,
      'podcast': podcast?.toJson(),
    };
  }

  String get durationFormatted {
    if (duration == null) return 'Unknown';

    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    final seconds = duration! % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
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
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.parse(json['id'].toString()) : 0),
      title: json['title'] ?? '',
      description: json['description'],
      author: json['author'],
      image: json['image'],
      episodeCount: json['episode_count'] is int
          ? json['episode_count']
          : (json['episode_count'] != null
              ? int.parse(json['episode_count'].toString())
              : null),
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
