import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/services/unified_auth_service.dart';
import '../core/utils/network_error_handler.dart';
import '../core/interceptors/retry_interceptor.dart';
import '../models/download.dart';
import '../models/subscription.dart';
import '../models/play_history.dart';
import '../models/playlist.dart';
import '../models/notification.dart';

class LibraryApiService {
  static final LibraryApiService _instance = LibraryApiService._internal();
  factory LibraryApiService() => _instance;
  LibraryApiService._internal();

  final Dio _dio = Dio();
  final UnifiedAuthService _authService = UnifiedAuthService();
  bool _isInitialized = false;
  String? _authToken;

  /// Set authentication token for requests
  void setAuthToken(String token) {
    _authToken = token.isEmpty ? null : token;
    // Update headers if already initialized
    if (_isInitialized) {
      if (_authToken != null) {
        _dio.options.headers['Authorization'] = 'Bearer $_authToken';
      } else {
        _dio.options.headers.remove('Authorization');
      }
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _dio.options = BaseOptions(
        baseUrl: '${ApiConfig.baseUrl}/api',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // Increased timeout
        sendTimeout: const Duration(seconds: 30),
      );

      // Add retry interceptor
      _dio.interceptors.add(RetryInterceptor(
        maxRetries: 3,
        baseDelay: const Duration(seconds: 1),
        retryOnTimeout: true,
        retryOnConnectionError: true,
        retryOnServerError: true,
      ));

      // Add auth interceptor
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Check authentication first
            final isAuthenticated = await _authService.isAuthenticated();
            if (!isAuthenticated) {
              debugPrint(
                  '⚠️ LibraryApiService: User not authenticated for request to ${options.path}');
              handler.reject(DioException(
                requestOptions: options,
                error: 'User not authenticated. Please log in again.',
                type: DioExceptionType.unknown,
              ));
              return;
            }

            final token = await _authService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              debugPrint(
                  '🔐 LibraryApiService: Authorization header set with token: ${token.substring(0, 10)}...');
            } else {
              debugPrint(
                  '⚠️ LibraryApiService: No token available for request to ${options.path}');
              handler.reject(DioException(
                requestOptions: options,
                error:
                    'No authentication token available. Please log in again.',
                type: DioExceptionType.unknown,
              ));
              return;
            }
            handler.next(options);
          } catch (e) {
            debugPrint('❌ LibraryApiService: Auth interceptor error: $e');
            handler.reject(DioException(
              requestOptions: options,
              error: 'Authentication error: $e',
              type: DioExceptionType.unknown,
            ));
          }
        },
        onError: (error, handler) {
          final code = error.response?.statusCode;
          if (code == 401) {
            debugPrint('🔐 LibraryApiService: Authentication error (401)');
            // Only clear auth on 401 (unauthenticated)
            _authService.clearAuthData();
          } else if (code == 403) {
            // Do NOT clear auth on 403 (forbidden). Keep session intact.
            debugPrint(
                '🔐 LibraryApiService: Forbidden (403) - leaving auth intact');
          }
          handler.next(error);
        },
      ));

      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
        ));
      }

      _isInitialized = true;
      debugPrint('LibraryApiService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LibraryApiService: $e');
      rethrow;
    }
  }

  /// Helper to ensure the latest token is set before every request
  Future<void> _ensureAuthToken() async {
    try {
      // Check if user is authenticated first
      final isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in again.');
      }

      final token = await _authService.getToken();
      debugPrint(
          'LibraryApiService: Token retrieved: ${token != null ? 'Present' : 'Null'}');

      if (token != null && token.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        debugPrint('LibraryApiService: Authorization header set');
      } else {
        _dio.options.headers.remove('Authorization');
        debugPrint(
            'LibraryApiService: Authorization header removed - no token');
        throw Exception(
            'No authentication token available. Please log in again.');
      }
    } catch (e) {
      debugPrint('LibraryApiService: Error ensuring auth token: $e');
      _dio.options.headers.remove('Authorization');
      rethrow;
    }
  }

  /// Get user's subscribed podcast IDs
  Future<Map<String, dynamic>> getSubscribedPodcastIds() async {
    await initialize();
    try {
      final response = await _dio.get('/subscriptions/ids');
      return response.data;
    } catch (e) {
      debugPrint('Error fetching subscribed podcast IDs: $e');
      rethrow;
    }
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  // ==================== DOWNLOADS ====================

  /// Get downloads with pagination
  Future<Map<String, dynamic>> getDownloads({
    int page = 1,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      final response = await _dio.get('/library/downloads', queryParameters: {
        'page': page,
      });

      final data = response.data['data'] as List;
      final downloads = data.map((json) => Download.fromJson(json)).toList();

      // Extract pagination metadata
      final meta = response.data['meta'] as Map<String, dynamic>;
      final hasMore = meta['current_page'] < meta['last_page'];

      return {
        'data': downloads,
        'hasMore': hasMore,
        'currentPage': meta['current_page'],
        'lastPage': meta['last_page'],
        'total': meta['total'],
      };
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getDownloads',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError, context: 'getDownloads');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error fetching downloads: $e');
      rethrow;
    }
  }

  /// Add download
  Future<void> addDownload({
    required String episodeId,
    String? filePath,
    int? fileSize,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      await _dio.post('/library/downloads', data: {
        'podcastindex_episode_id': episodeId,
        'file_path': filePath,
        'file_size': fileSize,
      });
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'addDownload',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError, context: 'addDownload');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error adding download: $e');
      rethrow;
    }
  }

  /// Remove download
  Future<void> removeDownload({
    required String episodeId,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      await _dio.delete('/library/downloads/$episodeId');
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'removeDownload',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError, context: 'removeDownload');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error removing download: $e');
      rethrow;
    }
  }

  /// Batch remove downloads
  Future<void> batchRemoveDownloads(List<int> downloadIds) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.post(
        '/library/downloads/batch-destroy',
        data: {
          'download_ids': downloadIds,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'batchRemoveDownloads');
        throw networkError;
      }
      debugPrint('Error batch removing downloads: $e');
      rethrow;
    }
  }

  /// Clear all downloads
  Future<void> clearAllDownloads() async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.delete(
        '/library/downloads/clear-all',
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'clearAllDownloads');
        throw networkError;
      }
      debugPrint('Error clearing all downloads: $e');
      rethrow;
    }
  }

  // ==================== SUBSCRIPTIONS ====================

  /// Get subscriptions with pagination
  Future<Map<String, dynamic>> getSubscriptions({
    int page = 1,
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      final response =
          await _dio.get('/library/subscriptions', queryParameters: {
        'page': page,
      });

      final data = response.data['data'] as List;
      final subscriptions =
          data.map((json) => Subscription.fromJson(json)).toList();

      // Extract pagination metadata
      final meta = response.data['meta'] as Map<String, dynamic>;
      final hasMore = meta['current_page'] < meta['last_page'];

      return {
        'data': subscriptions,
        'hasMore': hasMore,
        'currentPage': meta['current_page'],
        'lastPage': meta['last_page'],
        'total': meta['total'],
      };
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'getSubscriptions',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'getSubscriptions');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error fetching subscriptions: $e');
      rethrow;
    }
  }

  /// Subscribe to podcast
  Future<void> subscribeToPodcast(
    String podcastId, {
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      await _dio.post('/library/subscriptions/subscribe', data: {
        'podcastindex_podcast_id': podcastId,
      });
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'subscribeToPodcast',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'subscribeToPodcast');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error subscribing to podcast: $e');
      rethrow;
    }
  }

  /// Unsubscribe from podcast
  Future<void> unsubscribeFromPodcast(
    String podcastId, {
    BuildContext? context,
    VoidCallback? onRetry,
  }) async {
    await initialize();

    try {
      await _dio.post('/library/subscriptions/unsubscribe', data: {
        'podcastindex_podcast_id': podcastId,
      });
    } catch (e) {
      if (e is DioException) {
        if (context != null) {
          NetworkErrorHandler.handleNetworkError(
            context,
            e,
            errorContext: 'unsubscribeFromPodcast',
            onRetry: onRetry,
          );
        } else {
          final networkError = NetworkErrorHandler.handleDioException(e);
          NetworkErrorHandler.logError(networkError,
              context: 'unsubscribeFromPodcast');
        }
        throw NetworkErrorHandler.handleDioException(e);
      }
      debugPrint('Error unsubscribing from podcast: $e');
      rethrow;
    }
  }

  /// Batch unsubscribe from podcasts
  Future<void> batchUnsubscribe(List<int> subscriptionIds) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.post(
        '/library/subscriptions/batch-destroy',
        data: {
          'subscription_ids': subscriptionIds,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'batchUnsubscribe');
        throw networkError;
      }
      debugPrint('Error batch unsubscribing: $e');
      rethrow;
    }
  }

  // ==================== PLAY HISTORY ====================

  /// Get user play history
  Future<List<PlayHistory>> getPlayHistory({int page = 1}) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.get(
        '/library/play-history',
        queryParameters: {'page': page},
      );
      final data = response.data['data'] as List;
      return data.map((json) => PlayHistory.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getPlayHistory');
        throw networkError;
      }
      debugPrint('Error fetching play history: $e');
      rethrow;
    }
  }

  /// Add/update play history
  Future<PlayHistory> updatePlayHistory(
      Map<String, dynamic> historyData) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.post(
        '/library/play-history',
        data: historyData,
      );
      return PlayHistory.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'updatePlayHistory');
        throw networkError;
      }
      debugPrint('Error updating play history: $e');
      rethrow;
    }
  }

  /// Get recent play history
  Future<List<PlayHistory>> getRecentPlayHistory() async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.get(
        '/library/play-history/recent',
      );
      final data = response.data['data'] as List;
      return data.map((json) => PlayHistory.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'getRecentPlayHistory');
        throw networkError;
      }
      debugPrint('Error fetching recent play history: $e');
      rethrow;
    }
  }

  /// Clear all play history
  Future<void> clearAllPlayHistory() async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.delete(
        '/library/play-history/clear-all',
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'clearAllPlayHistory');
        throw networkError;
      }
      debugPrint('Error clearing play history: $e');
      rethrow;
    }
  }

  /// Batch remove play history entries
  Future<void> batchRemovePlayHistory(List<int> historyIds) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.post(
        '/library/play-history/batch-destroy',
        data: {
          'play_history_ids': historyIds,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'batchRemovePlayHistory');
        throw networkError;
      }
      debugPrint('Error batch removing play history: $e');
      rethrow;
    }
  }

  // ==================== PLAYLISTS ====================

  /// Get user playlists with pagination
  Future<Map<String, dynamic>> getPlaylists({int page = 1}) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.get(
        '/library/playlists',
        queryParameters: {'page': page},
      );
      debugPrint('Playlists API response: ${response.data}');
      final data = response.data['data'] as List;
      debugPrint('Playlists data length: ${data.length}');
      if (data.isNotEmpty) {
        debugPrint('First playlist data: ${data.first}');
      }

      final playlists = data.map((json) => Playlist.fromJson(json)).toList();

      // Extract pagination metadata
      final meta = response.data['meta'] as Map<String, dynamic>;
      final hasMore = meta['current_page'] < meta['last_page'];

      return {
        'data': playlists,
        'hasMore': hasMore,
        'currentPage': meta['current_page'],
        'lastPage': meta['last_page'],
        'total': meta['total'],
      };
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getPlaylists');
        throw networkError;
      }
      debugPrint('Error fetching playlists: $e');
      rethrow;
    }
  }

  /// Create a new playlist
  Future<Playlist> createPlaylist(Map<String, dynamic> playlistData) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.post(
        '/library/playlists',
        data: playlistData,
      );
      return Playlist.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'createPlaylist');
        throw networkError;
      }
      debugPrint('Error creating playlist: $e');
      rethrow;
    }
  }

  /// Update a playlist
  Future<Playlist> updatePlaylist(
      int playlistId, Map<String, dynamic> playlistData) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.put(
        '/library/playlists/$playlistId',
        data: playlistData,
      );
      return Playlist.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'updatePlaylist');
        throw networkError;
      }
      debugPrint('Error updating playlist: $e');
      rethrow;
    }
  }

  /// Delete a playlist
  Future<void> deletePlaylist(int playlistId) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.delete(
        '/library/playlists/$playlistId',
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'deletePlaylist');
        throw networkError;
      }
      debugPrint('Error deleting playlist: $e');
      rethrow;
    }
  }

  /// Add episode to playlist
  Future<void> addEpisodeToPlaylist(int playlistId, int episodeId) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      debugPrint(
          'LibraryApiService: Adding episode $episodeId to playlist $playlistId');
      final response = await _dio.post(
        '/library/playlists/$playlistId/add-episode',
        data: {
          'episode_id': episodeId.toString(),
        },
      );
      debugPrint(
          'LibraryApiService: Add episode response status: ${response.statusCode}');
      // The backend only returns a message, not playlist data
      debugPrint('LibraryApiService: Episode added successfully');
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'addEpisodeToPlaylist');
        throw networkError;
      }
      debugPrint('Error adding episode to playlist: $e');
      rethrow;
    }
  }

  /// Remove episode from playlist
  Future<void> removeEpisodeFromPlaylist(int playlistId, int episodeId) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.delete(
        '/library/playlists/$playlistId/remove-episode',
        data: {
          'episode_id': episodeId.toString(),
        },
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'removeEpisodeFromPlaylist');
        throw networkError;
      }
      debugPrint('Error removing episode from playlist: $e');
      rethrow;
    }
  }

  /// Reorder playlist items
  Future<Playlist> reorderPlaylist(
      int playlistId, List<Map<String, dynamic>> itemOrders) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.post(
        '/library/playlists/$playlistId/reorder',
        data: {
          'item_orders': itemOrders,
        },
      );
      return Playlist.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'reorderPlaylist');
        throw networkError;
      }
      debugPrint('Error reordering playlist: $e');
      rethrow;
    }
  }

  /// Batch delete playlists
  Future<void> batchDeletePlaylists(List<int> playlistIds) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.post(
        '/library/playlists/batch-destroy',
        data: {
          'playlist_ids': playlistIds,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'batchDeletePlaylists');
        throw networkError;
      }
      debugPrint('Error batch deleting playlists: $e');
      rethrow;
    }
  }

  /// Check if an episode is in any playlist
  Future<Map<String, dynamic>> checkEpisodeInPlaylists(String episodeId) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.get(
        '/library/playlists/check-episode',
        queryParameters: {
          'episode_id': episodeId,
        },
      );
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'checkEpisodeInPlaylists');
        throw networkError;
      }
      debugPrint('Error checking episode in playlists: $e');
      rethrow;
    }
  }

  // ==================== PLAYLIST ITEMS ====================

  /// Get playlist items
  Future<List<PlaylistItem>> getPlaylistItems(int playlistId,
      {int page = 1}) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      final response = await _dio.get(
        '/library/playlist-items',
        queryParameters: {
          'playlist_id': playlistId,
          'page': page,
        },
      );
      final data = response.data['data'] as List;
      return data.map((json) => PlaylistItem.fromJson(json)).toList();
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getPlaylistItems');
        throw networkError;
      }
      debugPrint('Error fetching playlist items: $e');
      rethrow;
    }
  }

  /// Batch remove playlist items
  Future<void> batchRemovePlaylistItems(List<int> itemIds) async {
    await _checkInitialization();
    await _ensureAuthToken();
    try {
      await _dio.post(
        '/library/playlist-items/batch-destroy',
        data: {
          'playlist_item_ids': itemIds,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'batchRemovePlaylistItems');
        throw networkError;
      }
      debugPrint('Error batch removing playlist items: $e');
      rethrow;
    }
  }

  // Notifications
  Future<List<NotificationModel>> getNotifications() async {
    await _ensureAuthToken();
    try {
      final response = await _dio.get('/api/notifications');
      final data = response.data['data'] ?? response.data;
      return (data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'getNotifications');
        throw networkError;
      }
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    await _ensureAuthToken();
    try {
      await _dio.post('/api/notifications/$id/read');
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'markNotificationAsRead');
        throw networkError;
      }
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    await _ensureAuthToken();
    try {
      await _dio.post('/api/notifications/read-all');
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError,
            context: 'markAllNotificationsAsRead');
        throw networkError;
      }
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // FCM Token
  Future<void> sendFcmToken(String token) async {
    await _ensureAuthToken();
    try {
      await _dio.post('/api/profile/fcm-token', data: {'fcm_token': token});
    } catch (e) {
      if (e is DioException) {
        final networkError = NetworkErrorHandler.handleDioException(e);
        NetworkErrorHandler.logError(networkError, context: 'sendFcmToken');
        throw networkError;
      }
      debugPrint('Error sending FCM token: $e');
      rethrow;
    }
  }

  /// Check if the service is initialized before making requests
  Future<void> _checkInitialization() async {
    if (!_isInitialized) {
      debugPrint('LibraryApiService not initialized. Initializing now...');
      await initialize();
    }
  }
}
