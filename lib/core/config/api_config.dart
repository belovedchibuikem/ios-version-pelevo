/// API configuration constants
class ApiConfig {
  /// Base URL for the API
  static const String baseUrl = 'https://pelevo.com';

  /// API version
  static const String apiVersion = 'v1';

  /// Default timeout for requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Default retry count
  static const int defaultRetryCount = 3;

  /// Default retry delay
  static const Duration defaultRetryDelay = Duration(seconds: 2);

  /// Maximum retry delay
  static const Duration maxRetryDelay = Duration(seconds: 10);

  /// Cache TTL configurations
  static const Duration homeCacheTTL = Duration(minutes: 30);
  static const Duration libraryCacheTTL = Duration(hours: 2);
  static const Duration profileCacheTTL = Duration(hours: 4);
  static const Duration imageCacheTTL = Duration(days: 7);

  /// Endpoints
  static const String featuredPodcastsEndpoint = '/podcasts/featured';
  static const String healthPodcastsEndpoint = '/podcasts/health';
  static const String categoriesEndpoint = '/podcasts/categories';
  static const String crimeArchivesEndpoint = '/podcasts/true-crime';
  static const String recommendedPodcastsEndpoint = '/podcasts/recommended';
  static const String trendingPodcastsEndpoint = '/podcasts/trending';

  // Library endpoints
  static const String downloadedEpisodesEndpoint =
      '/library/downloaded-episodes';
  static const String favoritePodcastsEndpoint = '/library/favorite-podcasts';
  static const String recentlyPlayedEndpoint = '/library/recently-played';

  static const String removeDownloadedEpisodeEndpoint =
      '/library/play-history/statistics';
  static const String addFavoriteEndpoint = '/library/add-favorite';
  static const String removeFavoriteEndpoint = '/library/remove-favorite';

  // Profile endpoints
  static const String userProfileEndpoint = '/profile';

  /// Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
  };

  /// Get full API URL
  static String getApiUrl(String endpoint) {
    return '$baseUrl/api/$endpoint';
  }

  /// Get cache key for endpoint
  static String getCacheKey(String endpoint) {
    return endpoint.replaceAll('/', '_').replaceAll('-', '_');
  }

  /// Get appropriate cache TTL for endpoint
  static Duration getCacheTTL(String endpoint) {
    if (endpoint.startsWith('/podcasts')) {
      return homeCacheTTL;
    } else if (endpoint.startsWith('/library')) {
      return libraryCacheTTL;
    } else if (endpoint.startsWith('/profile')) {
      return profileCacheTTL;
    } else if (endpoint.contains('image') || endpoint.contains('cover')) {
      return imageCacheTTL;
    }
    return homeCacheTTL; // Default
  }
}
