import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../services/library_api_service.dart';
import '../core/services/unified_auth_service.dart';

/// Provider for managing playlist state and real-time updates
class PlaylistProvider extends ChangeNotifier {
  final LibraryApiService _apiService = LibraryApiService();

  // State variables
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _error;
  Map<int, bool> _addingToPlaylist =
      {}; // Track which playlists are being added to
  Map<int, int> _playlistItemCounts =
      {}; // Cache item counts for real-time updates
  String? _lastAddMessage;
  bool _lastAddWasDuplicate = false;

  // Getters
  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isAddingToPlaylist(int playlistId) =>
      _addingToPlaylist[playlistId] ?? false;
  String? get lastAddMessage => _lastAddMessage;
  bool get lastAddWasDuplicate => _lastAddWasDuplicate;

  /// Get item count for a specific playlist
  int getPlaylistItemCount(int playlistId) {
    return _playlistItemCounts[playlistId] ?? 0;
  }

  /// Load playlists with caching and enhanced error handling
  Future<void> loadPlaylists({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('📋 PlaylistProvider: Loading playlists...');

      // Initialize the API service first (this sets up auth interceptors)
      await _apiService.initialize();

      // Check authentication first
      final authService = UnifiedAuthService();
      final isAuthenticated = await authService.isAuthenticated();
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in again.');
      }

      final response = await _apiService.getPlaylists();

      // Validate response structure
      if (!response.containsKey('data')) {
        throw Exception('Invalid response format: missing data field');
      }

      final data = response['data'];
      if (data == null) {
        throw Exception('No playlist data received');
      }

      if (data is! List) {
        throw Exception('Invalid playlist data format');
      }

      _playlists = data.cast<Playlist>();

      // Load item counts for each playlist (with error handling)
      await _loadPlaylistItemCounts();

      debugPrint('📋 PlaylistProvider: Loaded ${_playlists.length} playlists');
    } catch (e) {
      debugPrint('❌ PlaylistProvider: Error loading playlists: $e');

      // Provide more specific error messages
      String errorMessage = 'Failed to load playlists';
      if (e.toString().contains('authentication') ||
          e.toString().contains('401')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (e.toString().contains('server') ||
          e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else {
        errorMessage = 'Error loading playlists: ${e.toString()}';
      }

      _error = errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load item counts for all playlists
  Future<void> _loadPlaylistItemCounts() async {
    try {
      // Ensure API service is initialized
      await _apiService.initialize();

      for (final playlist in _playlists) {
        try {
          final items = await _apiService.getPlaylistItems(playlist.id);
          _playlistItemCounts[playlist.id] = items.length;
        } catch (e) {
          debugPrint(
              '⚠️ PlaylistProvider: Error loading item count for playlist ${playlist.id}: $e');
          _playlistItemCounts[playlist.id] = 0;
        }
      }
    } catch (e) {
      debugPrint('❌ PlaylistProvider: Error loading playlist item counts: $e');
    }
  }

  /// Add episode to playlist with real-time updates
  Future<bool> addEpisodeToPlaylist(int playlistId, int episodeId) async {
    try {
      _lastAddMessage = null;
      _lastAddWasDuplicate = false;
      // Set loading state for this playlist
      _addingToPlaylist[playlistId] = true;
      notifyListeners();

      debugPrint(
          '📋 PlaylistProvider: Adding episode $episodeId to playlist $playlistId');

      // Validate playlist ownership first
      final playlist = getPlaylistById(playlistId);
      if (playlist == null) {
        debugPrint(
            '❌ PlaylistProvider: Playlist $playlistId not found in local cache');
        _error = 'Playlist not found. Please refresh and try again.';
        return false;
      }

      // Ensure API service is initialized
      await _apiService.initialize();
      await _apiService.addEpisodeToPlaylist(playlistId, episodeId);

      // Update item count immediately for real-time feedback
      _playlistItemCounts[playlistId] =
          (_playlistItemCounts[playlistId] ?? 0) + 1;

      // Update the playlist in the list if it exists
      final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
      if (playlistIndex != -1) {
        // Update the playlist's updated_at timestamp
        _playlists[playlistIndex] = Playlist(
          id: _playlists[playlistIndex].id,
          name: _playlists[playlistIndex].name,
          order: _playlists[playlistIndex].order,
          createdAt: _playlists[playlistIndex].createdAt,
          updatedAt: DateTime.now(),
        );
      }

      debugPrint('📋 PlaylistProvider: Episode added successfully');
      _lastAddMessage = 'Episode added to playlist successfully';
      _lastAddWasDuplicate = false;
      return true;
    } catch (e) {
      debugPrint('❌ PlaylistProvider: Error adding episode to playlist: $e');

      // Provide user-friendly error messages
      String errorMessage = 'Failed to add episode to playlist';
      if (e.toString().contains('403') ||
          e.toString().contains('Unauthorized')) {
        errorMessage =
            'You do not have permission to modify this playlist. Please refresh your playlists.';
        // Auto-refresh playlists when there's a permission error
        debugPrint(
            '🔄 PlaylistProvider: Auto-refreshing playlists due to permission error');
        loadPlaylists(forceRefresh: true);
      } else if (e.toString().contains('404')) {
        errorMessage = 'Playlist not found. Please refresh your playlists.';
        // Auto-refresh playlists when playlist is not found
        debugPrint(
            '🔄 PlaylistProvider: Auto-refreshing playlists due to playlist not found');
        loadPlaylists(forceRefresh: true);
      } else if (e.toString().contains('422')) {
        // Treat duplicate as a soft-success for user UX
        _lastAddMessage = 'Episode is already in this playlist.';
        _lastAddWasDuplicate = true;
        debugPrint(
            'ℹ️ PlaylistProvider: Episode already in playlist (duplicate)');
        return true;
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      _error = errorMessage;
      return false;
    } finally {
      _addingToPlaylist[playlistId] = false;
      notifyListeners();
    }
  }

  /// Create new playlist with episode
  Future<Playlist?> createPlaylistWithEpisode(
      String name, int episodeId) async {
    try {
      debugPrint(
          '📋 PlaylistProvider: Creating playlist "$name" with episode $episodeId');

      // Ensure API service is initialized
      await _apiService.initialize();
      final newPlaylist = await _apiService.createPlaylist({
        'name': name,
        'description': null,
      });

      // Add episode to the new playlist
      await addEpisodeToPlaylist(newPlaylist.id, episodeId);

      // Add to local list
      _playlists.add(newPlaylist);
      _playlistItemCounts[newPlaylist.id] = 1;

      debugPrint('📋 PlaylistProvider: Playlist created successfully');
      return newPlaylist;
    } catch (e) {
      debugPrint('❌ PlaylistProvider: Error creating playlist: $e');
      _error = e.toString();
      return null;
    }
  }

  /// Create a new playlist (without adding an episode) and update local state
  Future<Playlist?> createPlaylistOnly(String name,
      {String? description}) async {
    try {
      debugPrint(
          '📋 PlaylistProvider: Creating playlist "$name" (no episode yet)');

      // Ensure API service is initialized
      await _apiService.initialize();
      final newPlaylist = await _apiService.createPlaylist({
        'name': name,
        'description': description,
      });

      // Add to local list and initialize count
      _playlists.add(newPlaylist);
      _playlistItemCounts[newPlaylist.id] = 0;
      notifyListeners();

      debugPrint('📋 PlaylistProvider: Playlist created');
      return newPlaylist;
    } catch (e) {
      debugPrint('❌ PlaylistProvider: Error creating playlist only: $e');
      _error = e.toString();
      return null;
    }
  }

  /// Remove episode from playlist
  Future<bool> removeEpisodeFromPlaylist(int playlistId, int episodeId) async {
    try {
      debugPrint(
          '📋 PlaylistProvider: Removing episode $episodeId from playlist $playlistId');

      // Ensure API service is initialized
      await _apiService.initialize();
      await _apiService.removeEpisodeFromPlaylist(playlistId, episodeId);

      // Update item count
      _playlistItemCounts[playlistId] =
          (_playlistItemCounts[playlistId] ?? 1) - 1;
      if (_playlistItemCounts[playlistId]! < 0) {
        _playlistItemCounts[playlistId] = 0;
      }

      debugPrint('📋 PlaylistProvider: Episode removed successfully');
      return true;
    } catch (e) {
      debugPrint(
          '❌ PlaylistProvider: Error removing episode from playlist: $e');
      _error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Delete playlist
  Future<bool> deletePlaylist(int playlistId) async {
    try {
      debugPrint('📋 PlaylistProvider: Deleting playlist $playlistId');

      // Ensure API service is initialized
      await _apiService.initialize();
      await _apiService.deletePlaylist(playlistId);

      // Remove from local list
      _playlists.removeWhere((p) => p.id == playlistId);
      _playlistItemCounts.remove(playlistId);

      debugPrint('📋 PlaylistProvider: Playlist deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ PlaylistProvider: Error deleting playlist: $e');
      _error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Refresh playlist data
  Future<void> refreshPlaylist(int playlistId) async {
    try {
      debugPrint('📋 PlaylistProvider: Refreshing playlist $playlistId');

      // Ensure API service is initialized
      await _apiService.initialize();
      // Reload the specific playlist - use getPlaylists and find the specific one
      final response = await _apiService.getPlaylists();
      final playlists = response['data'] as List<Playlist>;
      final updatedPlaylist = playlists.firstWhere((p) => p.id == playlistId);

      // Update in local list
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = updatedPlaylist;
      }

      // Reload item count
      final items = await _apiService.getPlaylistItems(playlistId);
      _playlistItemCounts[playlistId] = items.length;

      debugPrint('📋 PlaylistProvider: Playlist refreshed successfully');
    } catch (e) {
      debugPrint('❌ PlaylistProvider: Error refreshing playlist: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get playlist by ID
  Playlist? getPlaylistById(int id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if episode is in playlist
  Future<bool> isEpisodeInPlaylist(int playlistId, int episodeId) async {
    try {
      // Ensure API service is initialized
      await _apiService.initialize();
      final items = await _apiService.getPlaylistItems(playlistId);
      return items.any((item) => item.episodeId == episodeId);
    } catch (e) {
      debugPrint(
          '❌ PlaylistProvider: Error checking if episode is in playlist: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
