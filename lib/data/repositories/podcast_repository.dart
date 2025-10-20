// lib/data/repositories/podcast_repository.dart

import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/podcast.dart';
import '../models/category.dart';
import '../models/episode.dart';
import '../../services/podcastindex_service.dart';

class PodcastRepository {
  static final PodcastRepository _instance = PodcastRepository._internal();
  factory PodcastRepository() => _instance;

  final PodcastIndexService _podcastIndexService = PodcastIndexService();
  bool _useRealApi = true;

  // Hive box names
  static const String featuredPodcastsBox = 'featured_podcasts';
  static const String trendingPodcastsBox = 'trending_podcasts';
  static const String categoriesBox = 'categories';
  static const String recommendedPodcastsBox = 'recommended_podcasts';

  PodcastRepository._internal() {
    _useRealApi = true;
  }

  static Future<void> initHive() async {
    try {
      // Check if Hive is already initialized
      if (!Hive.isBoxOpen(featuredPodcastsBox)) {
        await Hive.openBox(featuredPodcastsBox);
      }
      if (!Hive.isBoxOpen(trendingPodcastsBox)) {
        await Hive.openBox(trendingPodcastsBox);
      }
      if (!Hive.isBoxOpen(categoriesBox)) {
        await Hive.openBox(categoriesBox);
      }
      if (!Hive.isBoxOpen(recommendedPodcastsBox)) {
        await Hive.openBox(recommendedPodcastsBox);
      }
      debugPrint('✅ Hive boxes opened successfully');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not open Hive boxes: $e');
      debugPrint('App will continue without Hive caching');
    }
  }

  Future<void> initialize() async {
    try {
      final sw = Stopwatch()..start();
      debugPrint(
          '🔐 PodcastRepository.initialize: Authentication is now automatic');
      debugPrint('PodcastRepository.initialize: initializing service...');
      await _podcastIndexService.initialize();
      debugPrint('PodcastRepository.initialize: service initialized in '
          '${sw.elapsedMilliseconds} ms');
      _useRealApi = true;

      // Try to initialize Hive, but don't fail if it doesn't work
      try {
        debugPrint('PodcastRepository.initialize: opening Hive boxes...');
        await PodcastRepository.initHive();
        debugPrint('PodcastRepository.initialize: hive ready in '
            '${sw.elapsedMilliseconds} ms');
      } catch (hiveError) {
        debugPrint('⚠️ Warning: Hive initialization failed: $hiveError');
        debugPrint('App will continue without Hive caching');
        _useRealApi = true; // Still use real API even without Hive
      }
    } catch (e) {
      debugPrint('Error initializing podcast repository: $e');
      _useRealApi = false;
    }
  }

  Future<void> clearCache() async {
    await Hive.box(featuredPodcastsBox).clear();
    await Hive.box(trendingPodcastsBox).clear();
    await Hive.box(categoriesBox).clear();
    await Hive.box(recommendedPodcastsBox).clear();
  }

  Future<List<Podcast>> getFeaturedPodcasts({BuildContext? context}) async {
    try {
      debugPrint('🔐 getFeaturedPodcasts: Authentication is now automatic');
      if (_useRealApi) {
        final response =
            await _podcastIndexService.getFeaturedPodcasts(context: context);

        // Debug: Print the first featured podcast data to see the structure
        if (response.isNotEmpty) {
          debugPrint('=== FEATURED PODCAST DEBUG ===');
          debugPrint('First featured podcast raw data: ${response.first}');
          debugPrint(
              'First featured podcast author: ${response.first['author']}');
          debugPrint(
              'First featured podcast creator: ${response.first['creator']}');
        }

        final List podcasts = response as List;
        final List<Podcast> parsed = [];
        for (final item in podcasts) {
          try {
            if (item is Map<String, dynamic>) {
              parsed.add(Podcast.fromJson(item));
            } else if (item is Map) {
              parsed.add(Podcast.fromJson(Map<String, dynamic>.from(item)));
            } else {
              debugPrint('PodcastRepository: Skipping non-map item: $item');
            }
          } catch (e) {
            debugPrint('PodcastRepository: Failed to parse podcast item: $e');
            // Fallback: build a minimal Podcast so UI can render
            try {
              final map = item is Map<String, dynamic>
                  ? item
                  : (item is Map
                      ? Map<String, dynamic>.from(item)
                      : <String, dynamic>{});
              if (map.isNotEmpty) {
                final String id = (map['id'] ?? map['feedId'] ?? '').toString();
                final String title = (map['title'] ?? 'Untitled').toString();
                final String creator =
                    (map['creator'] ?? map['author'] ?? map['ownerName'] ?? '')
                        .toString();
                final String cover =
                    (map['image'] ?? map['artwork'] ?? '').toString();
                String categoryString = '';
                final dynamic rawCategories = map['categories'];
                if (rawCategories is Map) {
                  categoryString =
                      rawCategories.values.map((v) => v.toString()).join(', ');
                } else if (rawCategories is List) {
                  categoryString =
                      rawCategories.map((v) => v.toString()).join(', ');
                } else if (rawCategories is String) {
                  categoryString = rawCategories;
                }
                if (id.isNotEmpty) {
                  parsed.add(Podcast(
                    id: id,
                    title: title,
                    creator: creator,
                    coverImage: cover,
                    duration: '',
                    description: (map['description'] ?? '').toString(),
                    category: categoryString,
                    categories: rawCategories,
                    audioUrl: (map['url'] ?? '').toString(),
                  ));
                }
              }
            } catch (e2) {
              debugPrint('PodcastRepository: Fallback parse also failed: $e2');
            }
          }
        }
        debugPrint(
            'PodcastRepository: Parsed ${parsed.length} podcasts from category response');
        return parsed;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching featured podcasts: $e');
      return [];
    }
  }

  Future<List<Podcast>> getTrendingPodcasts({BuildContext? context}) async {
    try {
      if (_useRealApi) {
        final response =
            await _podcastIndexService.getTrendingPodcasts(context: context);
        debugPrint('Trending podcasts API response: ' + response.toString());
        // The API now returns a List of podcast objects directly
        if (response is List) {
          return response.map((podcast) => Podcast.fromJson(podcast)).toList();
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching trending podcasts: $e');
      return [];
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      debugPrint('🔐 getCategories: Starting categories request');
      debugPrint('🔐 getCategories: _useRealApi: $_useRealApi');

      if (_useRealApi) {
        debugPrint('🔐 getCategories: Making API call to getCategories');
        final response = await _podcastIndexService.getCategories();
        final categories =
            (response as List).map((cat) => Category.fromJson(cat)).toList();
        debugPrint(
            '🔐 getCategories: Successfully retrieved ${categories.length} categories');
        return categories;
      } else {
        debugPrint('🔐 getCategories: Using cached data (API disabled)');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Podcast>> getRecommendedPodcasts({BuildContext? context}) async {
    try {
      if (_useRealApi) {
        final response =
            await _podcastIndexService.getRecommendedPodcasts(context: context);
        return (response as List)
            .map((podcast) => Podcast.fromJson(podcast))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching recommended podcasts: $e');
      return [];
    }
  }

  // Get podcasts by category
  Future<List<Podcast>> getPodcastsByCategory(
      String catId, String catName) async {
    try {
      if (_useRealApi) {
        debugPrint('PodcastRepository: getPodcastsByCategory '
                'catId=' +
            catId +
            ', catName=' +
            catName);
        final dynamic response = await _podcastIndexService
            .getPodcastsByCategorySearch(catId: catId, catName: catName);
        debugPrint('PodcastRepository: category response type=' +
            response.runtimeType.toString());

        // Normalize to List<dynamic> podcasts
        List<dynamic> podcasts;
        if (response is List) {
          podcasts = response;
          // Some backends wrap list in a single-element list
          if (podcasts.length == 1 && podcasts.first is List) {
            podcasts = List<dynamic>.from(podcasts.first as List);
          }
        } else if (response is Map) {
          final map = Map<String, dynamic>.from(response);
          if (map['data'] is Map && map['data']['feeds'] is List) {
            podcasts = List<dynamic>.from(map['data']['feeds'] as List);
          } else if (map['feeds'] is List) {
            podcasts = List<dynamic>.from(map['feeds'] as List);
          } else {
            // Last resort: take the first List value in the map
            final lists = map.values.whereType<List>().toList();
            podcasts = lists.isNotEmpty ? List<dynamic>.from(lists.first) : [];
          }
        } else {
          podcasts = [];
        }

        if (podcasts.isNotEmpty) {
          final first = podcasts.first;
          if (first is Map) {
            debugPrint('PodcastRepository: first item keys=' +
                (first as Map).keys.join(','));
          } else {
            debugPrint('PodcastRepository: first item type=' +
                first.runtimeType.toString());
          }
        }

        final List<Podcast> parsed = [];
        for (final item in podcasts) {
          try {
            if (item is Map<String, dynamic>) {
              parsed.add(Podcast.fromJson(item));
            } else if (item is Map) {
              parsed.add(Podcast.fromJson(Map<String, dynamic>.from(item)));
            } else {
              debugPrint('PodcastRepository: Skipping non-map item: $item');
            }
          } catch (e) {
            debugPrint('PodcastRepository: Failed to parse podcast item: $e');
            // Minimal fallback to keep UI non-empty
            try {
              final map = item is Map<String, dynamic>
                  ? item
                  : (item is Map
                      ? Map<String, dynamic>.from(item)
                      : <String, dynamic>{});
              if (map.isNotEmpty) {
                final String id = (map['id'] ?? map['feedId'] ?? '').toString();
                final String title = (map['title'] ?? 'Untitled').toString();
                final String creator =
                    (map['creator'] ?? map['author'] ?? map['ownerName'] ?? '')
                        .toString();
                final String cover =
                    (map['image'] ?? map['artwork'] ?? '').toString();
                String categoryString = '';
                final dynamic rawCategories = map['categories'];
                if (rawCategories is Map) {
                  categoryString =
                      rawCategories.values.map((v) => v.toString()).join(', ');
                } else if (rawCategories is List) {
                  categoryString =
                      rawCategories.map((v) => v.toString()).join(', ');
                } else if (rawCategories is String) {
                  categoryString = rawCategories;
                }
                if (id.isNotEmpty) {
                  parsed.add(Podcast(
                    id: id,
                    title: title,
                    creator: creator,
                    coverImage: cover,
                    duration: '',
                    description: (map['description'] ?? '').toString(),
                    category: categoryString,
                    categories: rawCategories,
                    audioUrl: (map['url'] ?? '').toString(),
                  ));
                }
              }
            } catch (e2) {
              debugPrint('PodcastRepository: Fallback parse also failed: $e2');
            }
          }
        }
        debugPrint(
            'PodcastRepository: Parsed ${parsed.length} podcasts from category response');
        return parsed;
      }
    } catch (e) {
      debugPrint('Error fetching podcasts by category from API: $e');
      // Fall back to empty list on error
    }
    return [];
  }

  // Get podcast details
  Future<Podcast?> getPodcastDetails(int podcastId) async {
    try {
      if (_useRealApi) {
        final response =
            await _podcastIndexService.getPodcastDetails(podcastId.toString());
        final podcasts = _processPodcastsResponse(response);
        return podcasts.isNotEmpty ? podcasts.first : null;
      }
    } catch (e) {
      debugPrint('Error fetching podcast details from API: $e');
      // Fall back to null on error
    }
    return null;
  }

  // Get episodes for a podcast
  Future<List<Episode>> getPodcastEpisodes(int podcastId) async {
    try {
      if (_useRealApi) {
        final response =
            await _podcastIndexService.getPodcastEpisodes(podcastId.toString());
        return (response as List).map((ep) => Episode.fromJson(ep)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching podcast episodes from API: $e');
      // Fall back to empty list on error
    }
    return [];
  }

  // Get podcast details with episodes in a single API call
  Future<Map<String, dynamic>> getPodcastDetailsWithEpisodes(String feedId,
      {BuildContext? context, int page = 1, int perPage = 50}) async {
    try {
      debugPrint(
          '🔐 getPodcastDetailsWithEpisodes: Authentication is now automatic');
      if (_useRealApi) {
        debugPrint(
            'Repository: Fetching podcast details with episodes for feedId: $feedId (page: $page, perPage: $perPage)');
        final response =
            await _podcastIndexService.getPodcastDetailsWithEpisodes(feedId,
                context: context, page: page, perPage: perPage);

        debugPrint('Repository: Raw API response keys: ${response.keys}');
        debugPrint(
            'Repository: Podcast data present: ${response.containsKey('podcast')}');
        debugPrint(
            'Repository: Episodes data present: ${response.containsKey('episodes')}');

        // Debug the podcast data structure
        if (response.containsKey('podcast')) {
          final podcastData = response['podcast'] as Map<String, dynamic>;
          debugPrint('Repository: Podcast data keys: ${podcastData.keys}');
          debugPrint(
              'Repository: Podcast episodeCount: ${podcastData['episodeCount']}');
          debugPrint(
              'Repository: Podcast totalEpisodes: ${podcastData['totalEpisodes']}');

          // Check if there's a feed object inside podcast
          if (podcastData.containsKey('feed')) {
            final feedData = podcastData['feed'] as Map<String, dynamic>;
            debugPrint('Repository: Feed data keys: ${feedData.keys}');
            debugPrint(
                'Repository: Feed episodeCount: ${feedData['episodeCount']}');
            debugPrint(
                'Repository: Feed totalEpisodes: ${feedData['totalEpisodes']}');
          }
        }

        // Debug the meta data structure
        if (response.containsKey('meta')) {
          final metaData = response['meta'] as Map<String, dynamic>;
          debugPrint('Repository: Meta data keys: ${metaData.keys}');
          debugPrint('Repository: Meta total: ${metaData['total']}');
        }

        // Process the response to extract podcast and episodes
        final podcastResponse =
            response['podcast'] as Map<String, dynamic>? ?? {};
        final feedData = podcastResponse['feed'] as Map<String, dynamic>? ?? {};
        var episodesData = response['episodes'];

        // Handle different episodes data structures
        List<dynamic> episodesList = [];
        if (episodesData is List) {
          episodesList = episodesData;
        } else if (episodesData is Map<String, dynamic>) {
          // Check if episodes are nested in 'items' field
          if (episodesData.containsKey('items') &&
              episodesData['items'] is List) {
            episodesList = episodesData['items'] as List;
          } else {
            // Try to extract episodes from other possible fields
            episodesList = episodesData.values
                .where((value) => value is List)
                .expand((list) => list as List)
                .toList();
          }
        }

        // Extract a clean, comma-separated category string
        String categoryString = '';
        final categoriesRaw = feedData['categories'];
        if (categoriesRaw is Map) {
          categoryString =
              categoriesRaw.values.map((v) => v.toString()).join(', ');
        } else if (categoriesRaw is String) {
          categoryString = categoriesRaw;
        } else if (categoriesRaw is List) {
          categoryString = categoriesRaw.map((v) => v.toString()).join(', ');
        }
        // Get episode count from podcast data (backend now includes episodeCount in feed data)
        final metaData = response['meta'] as Map<String, dynamic>?;
        final episodeCount = feedData['episodeCount'] ??
            feedData['totalEpisodes'] ??
            metaData?['total'] ??
            0;
        debugPrint(
            'Repository: Raw episodeCount from feedData: ${feedData['episodeCount']}');
        debugPrint(
            'Repository: Raw totalEpisodes from feedData: ${feedData['totalEpisodes']}');
        debugPrint('Repository: Meta total: ${metaData?['total']}');
        debugPrint('Repository: Final episodeCount: $episodeCount');

        final podcastMap = <String, dynamic>{
          ...feedData,
          ...podcastResponse,
          'description':
              feedData['description'] ?? podcastResponse['description'] ?? '',
          'categories': categoriesRaw,
          'category': categoryString,
          'episodeCount': episodeCount,
        };
        final podcast = Podcast.fromJson(podcastMap);

        debugPrint('Repository: Created podcast model: ${podcast.title}');
        debugPrint('Repository: Podcast episodeCount: ${podcast.episodeCount}');
        debugPrint(
            'Repository: Podcast totalEpisodes: ${podcast.totalEpisodes}');

        // Convert episodes data to Episode models
        final episodes = episodesList
            .map((episodeData) {
              if (episodeData is! Map<String, dynamic>) {
                debugPrint(
                    'Repository: Skipping invalid episode data: $episodeData');
                return null;
              }

              try {
                return Episode(
                  id: episodeData['id'] ?? 0,
                  title: episodeData['title'] ?? 'Unknown Episode',
                  podcastName: podcast.title,
                  creator: podcast.creator,
                  coverImage: episodeData['image'] ??
                      episodeData['feedImage'] ??
                      podcast.coverImage,
                  duration: _formatDuration(episodeData['duration'] ?? 0),
                  isDownloaded: false,
                  description: episodeData['description'] ?? '',
                  audioUrl: episodeData['enclosureUrl'],
                  releaseDate: _parseDate(episodeData['datePublished'] ??
                      episodeData['datePublishedPretty']),
                );
              } catch (e) {
                debugPrint('Repository: Error creating episode model: $e');
                return null;
              }
            })
            .where((episode) => episode != null)
            .cast<Episode>()
            .toList();

        debugPrint('Repository: Created ${episodes.length} episode models');

        return {
          'podcast': podcast,
          'episodes': episodes,
        };
      }
    } catch (e) {
      debugPrint(
          'Repository: Error fetching podcast details with episodes from API: $e');
      // Fall back to empty data on error
    }
    return {
      'podcast': null,
      'episodes': <Episode>[],
    };
  }

  // Process podcasts response
  List<Podcast> _processPodcastsResponse(Map<String, dynamic> response) {
    List<Podcast> podcasts = [];
    try {
      final podcastsData = response['podcasts'] as List<dynamic>? ?? [];
      podcasts = podcastsData.map((podcastData) {
        return Podcast(
          id: podcastData['id'] ?? 0,
          title: podcastData['title'] ?? 'Unknown Podcast',
          creator: podcastData['creator'] ?? 'Unknown Creator',
          author: podcastData['author'] ?? podcastData['creator'] ?? 'Unknown',
          coverImage:
              podcastData['cover_image'] ?? podcastData['coverImage'] ?? '',
          duration: podcastData['duration'] ?? '0m',
          isDownloaded: false,
          description: podcastData['description'] ?? '',
          category: podcastData['category'] ?? 'Uncategorized',
          audioUrl: podcastData['audio_url'] ?? podcastData['audioUrl'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error processing podcasts response: $e');
    }
    return podcasts;
  }

  // Process episodes response
  List<Episode> _processEpisodesResponse(
      Map<String, dynamic> response, int podcastId) {
    List<Episode> episodes = [];
    try {
      final podcastData = response['podcast'] as Map<String, dynamic>? ?? {};
      final episodesData = response['episodes'] as List<dynamic>? ?? [];
      final podcastName = podcastData['title'] ?? 'Unknown Podcast';
      final creator = podcastData['creator'] ?? 'Unknown Creator';
      final coverImage =
          podcastData['cover_image'] ?? podcastData['coverImage'] ?? '';

      episodes = episodesData.map((episodeData) {
        return Episode(
          id: episodeData['id'] ?? 0,
          title: episodeData['title'] ?? 'Unknown Episode',
          podcastName: podcastName,
          creator: creator,
          coverImage: episodeData['cover_image'] ??
              episodeData['coverImage'] ??
              coverImage,
          duration: episodeData['duration'] ?? '0m',
          isDownloaded: false,
          description: episodeData['description'] ?? '',
          audioUrl: episodeData['audio_url'] ?? episodeData['audioUrl'],
          releaseDate: DateTime.tryParse(episodeData['release_date'] ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error processing episodes response: $e');
    }
    return episodes;
  }

  // Map category name to appropriate icon
  String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('comedy')) return 'sentiment_very_satisfied';
    if (name.contains('true crime') || name.contains('crime')) return 'gavel';
    if (name.contains('education') || name.contains('learn')) return 'school';
    if (name.contains('news')) return 'newspaper';
    if (name.contains('business')) return 'business';
    if (name.contains('science')) return 'science';
    if (name.contains('tech')) return 'computer';
    if (name.contains('sport')) return 'sports_soccer';
    if (name.contains('health')) return 'favorite';
    if (name.contains('music')) return 'music_note';
    if (name.contains('art') || name.contains('culture')) return 'palette';
    if (name.contains('politics')) return 'account_balance';
    if (name.contains('religion') || name.contains('spiritual')) {
      return 'auto_awesome';
    }
    if (name.contains('history')) return 'auto_stories';

    // Default icon
    return 'podcasts';
  }

  Future<List<Podcast>> getCrimeArchivesPodcasts() async {
    try {
      debugPrint(
          '🔐 getCrimeArchivesPodcasts: Authentication is now automatic');
      if (_useRealApi) {
        final response = await _podcastIndexService.getTrueCrimePodcasts();
        if (response is List) {
          return response.map((podcast) => Podcast.fromJson(podcast)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching Crime Archives podcasts: $e');
    }
    return [];
  }

  Future<List<Podcast>> getHealthPodcasts() async {
    try {
      debugPrint('🔐 getHealthPodcasts: Authentication is now automatic');
      if (_useRealApi) {
        final response = await _podcastIndexService.getHealthPodcasts();
        if (response is List) {
          return response.map((podcast) => Podcast.fromJson(podcast)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching Health podcasts: $e');
    }
    return [];
  }

  Future<List<Podcast>> searchPodcasts(String query,
      {BuildContext? context}) async {
    try {
      if (_useRealApi) {
        final response =
            await _podcastIndexService.searchPodcasts(query, context: context);
        return (response as List)
            .map((podcast) => Podcast.fromJson(podcast))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error searching podcasts: $e');
      return [];
    }
  }

  /// Advanced search with filters
  Future<Map<String, dynamic>> advancedSearchPodcasts({
    required String query,
    String? category,
    String? language,
    bool? explicit,
    int? minEpisodes,
    int? maxEpisodes,
    String sortBy = 'relevance',
    String sortOrder = 'desc',
    int page = 1,
    int perPage = 50,
    BuildContext? context,
  }) async {
    try {
      if (_useRealApi) {
        final response =
            await _podcastIndexService.searchPodcasts(query, context: context);

        // For now, return the basic search results
        // In the future, this could be enhanced to use the advanced search endpoint
        final podcasts = (response as List)
            .map((podcast) => Podcast.fromJson(podcast))
            .toList();

        return {
          'podcasts': podcasts,
          'total': podcasts.length,
          'page': page,
          'per_page': perPage,
          'total_pages': 1,
          'has_more': false,
        };
      } else {
        return {
          'podcasts': <Podcast>[],
          'total': 0,
          'page': 1,
          'per_page': perPage,
          'total_pages': 0,
          'has_more': false,
        };
      }
    } catch (e) {
      debugPrint('Error in advanced search: $e');
      return {
        'podcasts': <Podcast>[],
        'total': 0,
        'page': 1,
        'per_page': perPage,
        'total_pages': 0,
        'has_more': false,
      };
    }
  }

  // Helper method to extract category from feed data
  String _extractCategoryFromFeed(Map<String, dynamic> feedData) {
    try {
      final categories = feedData['categories'] as Map<String, dynamic>?;
      if (categories != null && categories.isNotEmpty) {
        // Return the first category name
        return categories.values.first.toString();
      }
    } catch (e) {
      debugPrint('Error extracting category from feed: $e');
    }
    return 'Uncategorized';
  }

  // Helper method to format duration from seconds to readable format
  String _formatDuration(dynamic duration) {
    try {
      if (duration is int || duration is double) {
        final seconds = duration.toInt();
        final hours = seconds ~/ 3600;
        final minutes = (seconds % 3600) ~/ 60;

        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else {
          return '${minutes}m';
        }
      } else if (duration is String) {
        return duration;
      }
    } catch (e) {
      debugPrint('Error formatting duration: $e');
    }
    return '0m';
  }

  // Helper method to parse date from various formats
  DateTime _parseDate(dynamic dateValue) {
    try {
      if (dateValue is int) {
        // Unix timestamp
        return DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      } else if (dateValue is String) {
        // Try to parse as ISO string or other formats
        final parsed = DateTime.tryParse(dateValue);
        if (parsed != null) {
          return parsed;
        }

        // Try to parse common date formats
        final formats = [
          'MMMM d, yyyy h:mma',
          'MMMM d, yyyy',
          'MMM d, yyyy',
          'yyyy-MM-dd',
        ];

        for (final format in formats) {
          try {
            // You might need to add a date parsing library for this
            // For now, return current date if parsing fails
            return DateTime.now();
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return DateTime.now();
  }
}
