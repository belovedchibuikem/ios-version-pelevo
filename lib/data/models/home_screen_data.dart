import 'package:flutter/foundation.dart' hide Category;
import 'podcast.dart';
import 'category.dart';

/// Data model for home screen content
class HomeScreenData {
  final List<Podcast> featuredPodcasts;
  final List<Podcast> healthPodcasts;
  final List<Category> categories;
  final List<Podcast> crimeArchives;
  final List<Podcast> recommendedPodcasts;
  final List<Podcast> trendingPodcasts;
  final DateTime lastUpdated;
  final bool hasNewContent;

  const HomeScreenData({
    required this.featuredPodcasts,
    required this.healthPodcasts,
    required this.categories,
    required this.crimeArchives,
    required this.recommendedPodcasts,
    required this.trendingPodcasts,
    required this.lastUpdated,
    this.hasNewContent = false,
  });

  /// Create from JSON
  factory HomeScreenData.fromJson(Map<String, dynamic> json) {
    try {
      return HomeScreenData(
        featuredPodcasts: (json['featuredPodcasts'] as List?)
                ?.map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        healthPodcasts: (json['healthPodcasts'] as List?)
                ?.map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        categories: (json['categories'] as List?)
                ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        crimeArchives: (json['crimeArchives'] as List?)
                ?.map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        recommendedPodcasts: (json['recommendedPodcasts'] as List?)
                ?.map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        trendingPodcasts: (json['trendingPodcasts'] as List?)
                ?.map((e) => Podcast.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : DateTime.now(),
        hasNewContent: json['hasNewContent'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('❌ Error parsing HomeScreenData: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'featuredPodcasts': featuredPodcasts.map((e) => e.toJson()).toList(),
      'healthPodcasts': healthPodcasts.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'crimeArchives': crimeArchives.map((e) => e.toJson()).toList(),
      'recommendedPodcasts':
          recommendedPodcasts.map((e) => e.toJson()).toList(),
      'trendingPodcasts': trendingPodcasts.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'hasNewContent': hasNewContent,
    };
  }

  /// Create a copy with updated fields
  HomeScreenData copyWith({
    List<Podcast>? featuredPodcasts,
    List<Podcast>? healthPodcasts,
    List<Category>? categories,
    List<Podcast>? crimeArchives,
    List<Podcast>? recommendedPodcasts,
    List<Podcast>? trendingPodcasts,
    DateTime? lastUpdated,
    bool? hasNewContent,
  }) {
    return HomeScreenData(
      featuredPodcasts: featuredPodcasts ?? this.featuredPodcasts,
      healthPodcasts: healthPodcasts ?? this.healthPodcasts,
      categories: categories ?? this.categories,
      crimeArchives: crimeArchives ?? this.crimeArchives,
      recommendedPodcasts: recommendedPodcasts ?? this.recommendedPodcasts,
      trendingPodcasts: trendingPodcasts ?? this.trendingPodcasts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasNewContent: hasNewContent ?? this.hasNewContent,
    );
  }

  /// Check if data is stale (older than specified duration)
  bool isStale(Duration maxAge) {
    return DateTime.now().difference(lastUpdated) > maxAge;
  }

  /// Get total podcast count across all sections
  int get totalPodcastCount {
    return featuredPodcasts.length +
        healthPodcasts.length +
        crimeArchives.length +
        recommendedPodcasts.length;
  }

  /// Check if any section has content
  bool get hasContent {
    return featuredPodcasts.isNotEmpty ||
        healthPodcasts.isNotEmpty ||
        categories.isNotEmpty ||
        crimeArchives.isNotEmpty ||
        recommendedPodcasts.isNotEmpty ||
        trendingPodcasts.isNotEmpty;
  }

  /// Get all podcasts from all sections
  List<Podcast> get allPodcasts {
    return [
      ...featuredPodcasts,
      ...healthPodcasts,
      ...crimeArchives,
      ...recommendedPodcasts,
    ];
  }

  /// Get podcasts by category
  List<Podcast> getPodcastsByCategory(String categoryId) {
    return allPodcasts.where((podcast) {
      if (podcast.categories is List) {
        return (podcast.categories as List)
            .any((cat) => cat.toString() == categoryId);
      } else if (podcast.categories is String) {
        return podcast.categories == categoryId;
      }
      return podcast.category == categoryId;
    }).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeScreenData &&
        other.featuredPodcasts == featuredPodcasts &&
        other.healthPodcasts == healthPodcasts &&
        other.categories == categories &&
        other.crimeArchives == crimeArchives &&
        other.recommendedPodcasts == recommendedPodcasts &&
        other.lastUpdated == lastUpdated &&
        other.hasNewContent == hasNewContent;
  }

  @override
  int get hashCode {
    return Object.hash(
      featuredPodcasts,
      healthPodcasts,
      categories,
      crimeArchives,
      recommendedPodcasts,
      lastUpdated,
      hasNewContent,
    );
  }

  @override
  String toString() {
    return 'HomeScreenData('
        'featuredPodcasts: ${featuredPodcasts.length}, '
        'healthPodcasts: ${healthPodcasts.length}, '
        'categories: ${categories.length}, '
        'crimeArchives: ${crimeArchives.length}, '
        'recommendedPodcasts: ${recommendedPodcasts.length}, '
        'lastUpdated: $lastUpdated, '
        'hasNewContent: $hasNewContent)';
  }
}
