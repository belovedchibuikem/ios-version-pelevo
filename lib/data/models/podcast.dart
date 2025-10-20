// lib/data/models/podcast.dart
import 'package:flutter/foundation.dart';

class Podcast {
  final String id;
  final String title;
  final String creator;
  final String author;
  final String coverImage;
  final String duration;
  final bool isDownloaded;
  final String description;
  final String category;
  final dynamic categories;
  final String? audioUrl;
  final String? url;
  final String? originalUrl;
  final String? link;
  final int totalEpisodes;
  final int episodeCount;
  final List<String> languages;
  final bool explicit;
  final bool isFeatured;
  final bool isSubscribed;

  Podcast({
    required this.id,
    required this.title,
    required this.creator,
    String? author,
    required this.coverImage,
    required this.duration,
    this.isDownloaded = false,
    required this.description,
    required this.category,
    this.categories,
    this.audioUrl,
    this.url,
    this.originalUrl,
    this.link,
    this.totalEpisodes = 0,
    this.episodeCount = 0,
    this.languages = const [],
    this.explicit = false,
    this.isFeatured = false,
    this.isSubscribed = false,
  }) : author = author ?? '';

  Podcast copyWith({
    String? id,
    String? title,
    String? creator,
    String? author,
    String? coverImage,
    String? duration,
    bool? isDownloaded,
    String? description,
    String? category,
    dynamic categories,
    String? audioUrl,
    String? url,
    String? originalUrl,
    String? link,
    int? totalEpisodes,
    int? episodeCount,
    List<String>? languages,
    bool? explicit,
    bool? isFeatured,
    bool? isSubscribed,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      author: author ?? this.author,
      coverImage: coverImage ?? this.coverImage,
      duration: duration ?? this.duration,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      description: description ?? this.description,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      audioUrl: audioUrl ?? this.audioUrl,
      url: url ?? this.url,
      originalUrl: originalUrl ?? this.originalUrl,
      link: link ?? this.link,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      episodeCount: episodeCount ?? this.episodeCount,
      languages: languages ?? this.languages,
      explicit: explicit ?? this.explicit,
      isFeatured: isFeatured ?? this.isFeatured,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: Print the raw JSON data to understand the structure
      debugPrint(
          '🔍 Podcast.fromJson: Parsing podcast data: ${json.keys.toList()}');

      // Debug all numeric fields that might cause type issues
      final numericFields = [
        'id',
        'feedId',
        'episodeCount',
        'totalEpisodes',
        'itunesId',
        'lastUpdateTime',
        'lastCrawlTime',
        'lastParseTime',
        'priority',
        'lastGoodHttpStatusTime',
        'lastHttpStatus',
        'type',
        'dead',
        'crawlErrors',
        'parseErrors',
        'locked',
        'imageUrlHash',
        'newestItemPubdate'
      ];
      for (final field in numericFields) {
        if (json.containsKey(field)) {
          debugPrint(
              '🔍 Podcast.fromJson: $field type: ${json[field].runtimeType}, value: ${json[field]}');
        }
      }

      // Always use PodcastIndex ID for 'id' field
      final podcastIndexId = json['podcastindex_podcast_id']?.toString() ??
          json['feedId']?.toString() ??
          json['id']?.toString() ??
          '';

      // Categories: normalize to string and keep raw
      String categoryString = '';
      dynamic rawCategories = json['categories'];
      try {
        if (rawCategories is Map) {
          categoryString =
              rawCategories.values.map((v) => v.toString()).join(', ');
        } else if (rawCategories is List) {
          categoryString = rawCategories.map((v) => v.toString()).join(', ');
        } else if (rawCategories is String) {
          categoryString = rawCategories;
        }
      } catch (_) {}

      // Normalize explicit to bool
      final dynamic explicitRaw = json['explicit'];
      final bool explicitBool = (() {
        try {
          if (explicitRaw is bool) return explicitRaw;
          if (explicitRaw is num) return explicitRaw != 0;
          if (explicitRaw is String) return explicitRaw.toLowerCase() == 'true';
          return false;
        } catch (e) {
          debugPrint(
              '❌ Podcast.fromJson: Error parsing explicit: $e, value: $explicitRaw');
          return false;
        }
      })();

      // Prefer artwork when image missing; also support cached key 'coverImage'
      final String cover = (json['image'] ?? json['artwork'] ?? json['coverImage'] ?? '').toString();

      // Prefer a sensible creator
      final String creatorVal =
          (json['creator'] ?? json['author'] ?? json['ownerName'] ?? '')
              .toString();

      return Podcast(
        id: podcastIndexId,
        title: json['title'] ?? '',
        creator: creatorVal,
        author: (json['author'] ?? json['creator'] ?? '')?.toString() ?? '',
        coverImage: cover,
        duration: json['duration'] ?? '', // fallback if not present
        isDownloaded: (() {
          try {
            final value = json['isDownloaded'];
            if (value is bool) return value;
            if (value is String) return value.toLowerCase() == 'true';
            if (value is num) return value != 0;
            return false;
          } catch (e) {
            debugPrint(
                '❌ Podcast.fromJson: Error parsing isDownloaded: $e, value: ${json['isDownloaded']}');
            return false;
          }
        })(),
        description: json['description'] ?? '',
        category: categoryString,
        categories: rawCategories,
        audioUrl: json['url'] ?? '',
        url: json['url'],
        originalUrl: json['originalUrl'],
        link: json['link'],
        totalEpisodes: (() {
          try {
            final value = json['totalEpisodes'];
            if (value is int) return value;
            if (value is String) return int.tryParse(value) ?? 0;
            if (value is double) return value.toInt();
            return 0;
          } catch (e) {
            debugPrint(
                '❌ Podcast.fromJson: Error parsing totalEpisodes: $e, value: ${json['totalEpisodes']}');
            return 0;
          }
        })(),
        episodeCount: (() {
          try {
            // Try episodeCount first
            final episodeCountValue = json['episodeCount'];
            if (episodeCountValue != null) {
              if (episodeCountValue is int) return episodeCountValue;
              if (episodeCountValue is String) {
                final parsed = int.tryParse(episodeCountValue);
                if (parsed != null) return parsed;
              }
              if (episodeCountValue is double) return episodeCountValue.toInt();
            }

            // Fallback to totalEpisodes
            final totalEpisodesValue = json['totalEpisodes'];
            if (totalEpisodesValue != null) {
              if (totalEpisodesValue is int) return totalEpisodesValue;
              if (totalEpisodesValue is String) {
                final parsed = int.tryParse(totalEpisodesValue);
                if (parsed != null) return parsed;
              }
              if (totalEpisodesValue is double)
                return totalEpisodesValue.toInt();
            }

            return 0;
          } catch (e) {
            debugPrint(
                '❌ Podcast.fromJson: Error parsing episodeCount: $e, episodeCount: ${json['episodeCount']}, totalEpisodes: ${json['totalEpisodes']}');
            return 0;
          }
        })(),
        languages: json['language'] != null ? [json['language']] : [],
        explicit: explicitBool, // normalized
        isFeatured: (() {
          try {
            final value = json['isFeatured'];
            if (value is bool) return value;
            if (value is String) return value.toLowerCase() == 'true';
            if (value is num) return value != 0;
            return false;
          } catch (e) {
            debugPrint(
                '❌ Podcast.fromJson: Error parsing isFeatured: $e, value: ${json['isFeatured']}');
            return false;
          }
        })(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Podcast.fromJson: CRITICAL ERROR parsing podcast: $e');
      debugPrint('❌ Podcast.fromJson: Stack trace: $stackTrace');
      debugPrint('❌ Podcast.fromJson: JSON data: $json');

      // Return a minimal podcast object to prevent crashes
      return Podcast(
        id: json['id']?.toString() ?? '0',
        title: json['title']?.toString() ?? 'Unknown Podcast',
        creator: json['author']?.toString() ??
            json['creator']?.toString() ??
            'Unknown',
        author: json['author']?.toString() ?? 'Unknown',
        coverImage:
            json['image']?.toString() ?? json['artwork']?.toString() ?? '',
        duration: '',
        isDownloaded: false,
        description: json['description']?.toString() ?? '',
        category: '',
        categories: {},
        audioUrl: json['url']?.toString() ?? '',
        url: json['url']?.toString(),
        originalUrl: json['originalUrl']?.toString(),
        link: json['link']?.toString(),
        totalEpisodes: 0,
        episodeCount: 0,
        languages: [],
        explicit: false,
        isFeatured: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'creator': creator,
      'author': author,
      'coverImage': coverImage,
      'duration': duration,
      'isDownloaded': isDownloaded,
      'description': description,
      'category': category,
      'categories': categories,
      'audioUrl': audioUrl,
      'url': url,
      'originalUrl': originalUrl,
      'link': link,
      'totalEpisodes': totalEpisodes,
      'episodeCount': episodeCount,
      'languages': languages,
      'explicit': explicit,
      'isFeatured': isFeatured,
      'isSubscribed': isSubscribed,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
