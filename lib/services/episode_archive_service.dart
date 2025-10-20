import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/services/unified_auth_service.dart';

class EpisodeArchiveService {
  static final EpisodeArchiveService _instance =
      EpisodeArchiveService._internal();
  factory EpisodeArchiveService() => _instance;
  EpisodeArchiveService._internal();

  late Dio _dio;
  final UnifiedAuthService _authService = UnifiedAuthService();

  /// Initialize the service
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('Archive Service Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Archive an episode
  Future<Map<String, dynamic>> archiveEpisode({
    required String episodeId,
    required String podcastId,
    required String episodeTitle,
    required String podcastTitle,
    Map<String, dynamic>? episodeData,
  }) async {
    try {
      debugPrint('=== ARCHIVE EPISODE METHOD ===');
      debugPrint('Episode ID: $episodeId');
      debugPrint('Podcast ID: $podcastId');
      debugPrint('Episode Title: $episodeTitle');
      debugPrint('Podcast Title: $podcastTitle');
      debugPrint('Episode Data: $episodeData');

      await initialize();

      final requestData = {
        'episode_id': episodeId,
        'podcast_id': podcastId,
        'episode_title': episodeTitle,
        'podcast_title': podcastTitle,
        if (episodeData != null) 'episode_data': episodeData,
      };

      debugPrint('Request data: $requestData');
      debugPrint('Making POST request to /api/episodes/archive...');

      final response =
          await _dio.post('/api/episodes/archive', data: requestData);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      return response.data;
    } catch (e) {
      debugPrint('Error archiving episode: $e');
      if (e is DioException) {
        debugPrint('DioException details:');
        debugPrint('  Type: ${e.type}');
        debugPrint('  Message: ${e.message}');
        debugPrint('  Response: ${e.response?.data}');
        debugPrint('  Status Code: ${e.response?.statusCode}');
      }
      return {
        'success': false,
        'message': 'Failed to archive episode',
        'error': e.toString(),
      };
    }
  }

  /// Unarchive an episode
  Future<Map<String, dynamic>> unarchiveEpisode(String episodeId) async {
    try {
      await initialize();

      final response = await _dio.delete('/api/episodes/archive/$episodeId');

      return response.data;
    } catch (e) {
      debugPrint('Error unarchiving episode: $e');
      return {
        'success': false,
        'message': 'Failed to unarchive episode',
        'error': e.toString(),
      };
    }
  }

  /// Toggle archive status (archive if not archived, unarchive if archived)
  Future<Map<String, dynamic>> toggleArchive({
    required String episodeId,
    required String podcastId,
    required String episodeTitle,
    required String podcastTitle,
    Map<String, dynamic>? episodeData,
  }) async {
    try {
      await initialize();

      final response = await _dio.post('/api/episodes/archive/toggle', data: {
        'episode_id': episodeId,
        'podcast_id': podcastId,
        'episode_title': episodeTitle,
        'podcast_title': podcastTitle,
        if (episodeData != null) 'episode_data': episodeData,
      });

      return response.data;
    } catch (e) {
      debugPrint('Error toggling archive: $e');
      return {
        'success': false,
        'message': 'Failed to toggle archive status',
        'error': e.toString(),
      };
    }
  }

  /// Get archived episodes with pagination and search
  Future<Map<String, dynamic>> getArchivedEpisodes({
    int perPage = 20,
    String? search,
  }) async {
    try {
      await initialize();

      final queryParameters = <String, dynamic>{
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _dio.get(
        '/api/episodes/archive',
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (e) {
      debugPrint('Error getting archived episodes: $e');
      return {
        'success': false,
        'message': 'Failed to get archived episodes',
        'error': e.toString(),
      };
    }
  }

  /// Check if an episode is archived
  Future<bool> isEpisodeArchived(String episodeId) async {
    try {
      await initialize();

      final response =
          await _dio.get('/api/episodes/archive/$episodeId/status');

      if (response.data['success'] == true) {
        return response.data['data']['is_archived'] ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking archive status: $e');
      return false;
    }
  }

  /// Get archive statistics
  Future<Map<String, dynamic>> getArchiveStats() async {
    try {
      await initialize();

      final response = await _dio.get('/api/episodes/archive/stats');

      return response.data;
    } catch (e) {
      debugPrint('Error getting archive stats: $e');
      return {
        'success': false,
        'message': 'Failed to get archive statistics',
        'error': e.toString(),
      };
    }
  }

  /// Bulk unarchive episodes
  Future<Map<String, dynamic>> bulkUnarchive(List<String> episodeIds) async {
    try {
      await initialize();

      final response =
          await _dio.post('/api/episodes/archive/bulk-unarchive', data: {
        'episode_ids': episodeIds,
      });

      return response.data;
    } catch (e) {
      debugPrint('Error bulk unarchiving episodes: $e');
      return {
        'success': false,
        'message': 'Failed to bulk unarchive episodes',
        'error': e.toString(),
      };
    }
  }

  /// Archive episode from episode data map
  Future<Map<String, dynamic>> archiveEpisodeFromData(
      Map<String, dynamic> episodeData) async {
    try {
      debugPrint('=== ARCHIVE SERVICE DEBUG ===');
      debugPrint('Episode data received: $episodeData');
      debugPrint('Episode data keys: ${episodeData.keys.toList()}');

      final episodeId = episodeData['id']?.toString();

      // Try multiple sources for podcast ID
      String? podcastId = episodeData['podcast']?['id']?.toString() ??
          episodeData['podcastId']?.toString() ??
          episodeData['feedId']?.toString() ??
          episodeData['podcast']?['feedId']?.toString();

      final episodeTitle = episodeData['title'] ?? 'Unknown Episode';
      final podcastTitle = episodeData['podcast']?['title'] ??
          episodeData['podcastName'] ??
          episodeData['creator'] ??
          'Unknown Podcast';

      debugPrint('Extracted data:');
      debugPrint('  Episode ID: $episodeId');
      debugPrint('  Podcast ID: $podcastId');
      debugPrint('  Episode Title: $episodeTitle');
      debugPrint('  Podcast Title: $podcastTitle');

      // If we still don't have a podcast ID, try to generate one from the episode ID
      if (podcastId == null || podcastId.isEmpty) {
        // Use a fallback approach - generate a podcast ID from episode ID
        // This is a temporary solution until the episode data structure is fixed
        podcastId = 'podcast_${episodeId}_fallback';
        debugPrint('  Using fallback podcast ID: $podcastId');
      }

      if (episodeId == null || episodeId.isEmpty) {
        debugPrint('ERROR: Missing episode ID');
        return {
          'success': false,
          'message': 'Invalid episode data: missing episode_id',
        };
      }

      debugPrint('Calling archiveEpisode with extracted data...');
      final result = await archiveEpisode(
        episodeId: episodeId,
        podcastId: podcastId,
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        episodeData: episodeData,
      );

      debugPrint('Archive episode result: $result');
      return result;
    } catch (e) {
      debugPrint('Error archiving episode from data: $e');
      return {
        'success': false,
        'message': 'Failed to archive episode',
        'error': e.toString(),
      };
    }
  }

  /// Toggle archive from episode data map
  Future<Map<String, dynamic>> toggleArchiveFromData(
      Map<String, dynamic> episodeData) async {
    try {
      final episodeId = episodeData['id']?.toString();

      // Try multiple sources for podcast ID
      String? podcastId = episodeData['podcast']?['id']?.toString() ??
          episodeData['podcastId']?.toString() ??
          episodeData['feedId']?.toString() ??
          episodeData['podcast']?['feedId']?.toString();

      final episodeTitle = episodeData['title'] ?? 'Unknown Episode';
      final podcastTitle = episodeData['podcast']?['title'] ??
          episodeData['podcastName'] ??
          episodeData['creator'] ??
          'Unknown Podcast';

      // If we still don't have a podcast ID, try to generate one from the episode ID
      if (podcastId == null || podcastId.isEmpty) {
        // Use a fallback approach - generate a podcast ID from episode ID
        podcastId = 'podcast_${episodeId}_fallback';
      }

      if (episodeId == null || episodeId.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid episode data: missing episode_id',
        };
      }

      return await toggleArchive(
        episodeId: episodeId,
        podcastId: podcastId,
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        episodeData: episodeData,
      );
    } catch (e) {
      debugPrint('Error toggling archive from data: $e');
      return {
        'success': false,
        'message': 'Failed to toggle archive status',
        'error': e.toString(),
      };
    }
  }
}
