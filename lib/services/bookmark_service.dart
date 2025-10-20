import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/services/unified_auth_service.dart';
import '../core/interceptors/retry_interceptor.dart';
import '../models/bookmark.dart';
import '../models/bookmark_category.dart';
import '../models/bookmark_share.dart';

class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  final Dio _dio = Dio();
  final UnifiedAuthService _authService = UnifiedAuthService();
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _dio.options = BaseOptions(
        baseUrl: '${ApiConfig.baseUrl}/api',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
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
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint(
                '🔐 BookmarkService: Authorization header set with token: ${token.substring(0, 10)}...');
          } else {
            debugPrint(
                '⚠️ BookmarkService: No token available for request to ${options.path}');
          }
          handler.next(options);
        },
      ));

      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
        ));
      }

      _isInitialized = true;
      debugPrint('BookmarkService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BookmarkService: $e');
      rethrow;
    }
  }

  // Create timestamp bookmark with specific playback position
  Future<Map<String, dynamic>> createTimestampBookmark({
    required String episodeId,
    required String podcastId,
    required int position,
    required int duration,
    required String title,
    String? notes,
    String? category,
    String? timestampLabel,
    String? bookmarkType,
    int? priority,
    List<String>? tags,
  }) async {
    try {
      await _initialize();

      final response = await _dio.post(
        '/episodes/bookmarks/timestamp',
        data: {
          'episode_id': episodeId,
          'podcast_id': podcastId,
          'position': position,
          'duration': duration,
          'title': title,
          'notes': notes,
          'category': category,
          'timestamp_label': timestampLabel,
          'bookmark_type': bookmarkType,
          'priority': priority,
          'tags': tags,
        },
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to create timestamp bookmark');
      }
    } catch (e) {
      throw Exception('Error creating timestamp bookmark: $e');
    }
  }

  // Share a bookmark
  Future<Map<String, dynamic>> shareBookmark({
    required int bookmarkId,
    required String shareType,
    String? sharedWithUserId,
    String? shareMessage,
    int? expiryDays,
  }) async {
    try {
      await _initialize();

      final response = await _dio.post(
        '/episodes/bookmarks/share',
        data: {
          'bookmark_id': bookmarkId,
          'share_type': shareType,
          'shared_with_user_id': sharedWithUserId,
          'share_message': shareMessage,
          'expiry_days': expiryDays,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to share bookmark');
      }
    } catch (e) {
      throw Exception('Error sharing bookmark: $e');
    }
  }

  // Get bookmark categories
  Future<List<BookmarkCategory>> getCategories() async {
    try {
      await _initialize();

      final response = await _dio.get('/episodes/bookmarks/categories');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success']) {
          return (data['data'] as List)
              .map((category) => BookmarkCategory.fromJson(category))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get categories');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get categories');
      }
    } catch (e) {
      throw Exception('Error getting categories: $e');
    }
  }

  // Create a new bookmark category
  Future<BookmarkCategory> createCategory({
    required String name,
    String? description,
    String? color,
    String? icon,
    int? parentId,
    bool isPublic = false,
  }) async {
    try {
      await _initialize();

      final response = await _dio.post(
        '/episodes/bookmarks/categories',
        data: {
          'name': name,
          'description': description,
          'color': color,
          'icon': icon,
          'parent_id': parentId,
          'is_public': isPublic,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success']) {
          return BookmarkCategory.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create category');
        }
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to create category');
      }
    } catch (e) {
      throw Exception('Error creating category: $e');
    }
  }

  // Get shared bookmarks
  Future<Map<String, dynamic>> getSharedBookmarks({int perPage = 20}) async {
    try {
      await _initialize();

      final response =
          await _dio.get('/episodes/bookmarks/shared?per_page=$perPage');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to get shared bookmarks');
      }
    } catch (e) {
      throw Exception('Error getting shared bookmarks: $e');
    }
  }

  // Get bookmark statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      await _initialize();

      final response = await _dio.get('/episodes/bookmarks/statistics');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get statistics');
      }
    } catch (e) {
      throw Exception('Error getting statistics: $e');
    }
  }

  // Bulk operations on bookmarks
  Future<Map<String, dynamic>> bulkOperations({
    required String operation,
    required List<int> bookmarkIds,
    String? category,
    int? priority,
    List<String>? tags,
  }) async {
    try {
      await _initialize();

      final response = await _dio.post(
        '/episodes/bookmarks/bulk-operations',
        data: {
          'operation': operation,
          'bookmark_ids': bookmarkIds,
          'category': category,
          'priority': priority,
          'tags': tags,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to perform bulk operation');
      }
    } catch (e) {
      throw Exception('Error performing bulk operation: $e');
    }
  }

  // Get bookmarks with advanced filtering
  Future<Map<String, dynamic>> getBookmarks({
    String? category,
    String? type,
    int? priority,
    String? tags,
    bool? featured,
    String? sortBy,
    String? sortOrder,
    int perPage = 20,
  }) async {
    try {
      await _initialize();

      final queryParams = <String, String>{
        'per_page': perPage.toString(),
      };

      if (category != null) queryParams['category'] = category;
      if (type != null) queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority.toString();
      if (tags != null) queryParams['tags'] = tags;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final response =
          await _dio.get('/episodes/bookmarks', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get bookmarks');
      }
    } catch (e) {
      throw Exception('Error getting bookmarks: $e');
    }
  }
}
