import 'package:flutter/material.dart';
import '../models/play_history.dart';
import '../services/history_service.dart';
import '../core/utils/network_error_handler.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();

  // State variables
  List<PlayHistory> _playHistory = [];
  List<PlayHistory> _filteredHistory = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Filter variables
  String? _statusFilter;
  String? _searchQuery;
  String? _podcastIdFilter;
  String _sortBy = 'last_played_at';
  String _sortOrder = 'desc';

  // Getters
  List<PlayHistory> get playHistory => _playHistory;
  List<PlayHistory> get filteredHistory => _filteredHistory;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;
  String? get podcastIdFilter => _podcastIdFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  // Computed getters
  List<PlayHistory> get completedEpisodes =>
      _playHistory.where((h) => h.isCompleted).toList();

  List<PlayHistory> get inProgressEpisodes => _playHistory
      .where((h) => !h.isCompleted && h.status != 'abandoned')
      .toList();

  List<PlayHistory> get recentEpisodes => _playHistory.take(10).toList();

  /// Load play history with optional filters
  Future<void> loadPlayHistory({
    bool refresh = false,
    String? status,
    String? search,
    String? podcastId,
    String? sortBy,
    String? sortOrder,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _playHistory.clear();
      _filteredHistory.clear();
    }

    // Update filters
    if (status != null) _statusFilter = status;
    if (search != null) _searchQuery = search;
    if (podcastId != null) _podcastIdFilter = podcastId;
    if (sortBy != null) _sortBy = sortBy;
    if (sortOrder != null) _sortOrder = sortOrder;

    _setLoading(true);
    _error = null;

    try {
      final newHistory = await _historyService.getPlayHistory(
        page: _currentPage,
        status: _statusFilter,
        search: _searchQuery,
        podcastId: _podcastIdFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (refresh) {
        _playHistory = newHistory;
      } else {
        _playHistory.addAll(newHistory);
      }

      _filteredHistory = _playHistory;
      _hasMore = newHistory.isNotEmpty;
      _currentPage++;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Load more history entries
  Future<void> loadMoreHistory() async {
    if (_isLoadingMore || !_hasMore) return;

    _setLoadingMore(true);

    try {
      final newHistory = await _historyService.getPlayHistory(
        page: _currentPage,
        status: _statusFilter,
        search: _searchQuery,
        podcastId: _podcastIdFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      _playHistory.addAll(newHistory);
      _filteredHistory = _playHistory;
      _hasMore = newHistory.isNotEmpty;
      _currentPage++;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoadingMore(false);
    }
  }

  /// Load recent play history
  Future<void> loadRecentHistory({int days = 7, int limit = 10}) async {
    _setLoading(true);
    _error = null;

    try {
      final recentHistory = await _historyService.getRecentPlayHistory(
        days: days,
        limit: limit,
      );

      _playHistory = recentHistory;
      _filteredHistory = recentHistory;
      _currentPage = 1;
      _hasMore = false;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Load completed episodes
  Future<void> loadCompletedEpisodes({int page = 1}) async {
    await loadPlayHistory(
      refresh: page == 1,
      status: 'completed',
    );
  }

  /// Load in-progress episodes
  Future<void> loadInProgressEpisodes({int page = 1}) async {
    await loadPlayHistory(
      refresh: page == 1,
      status: 'in_progress',
    );
  }

  /// Search play history
  Future<void> searchHistory(String query) async {
    await loadPlayHistory(
      refresh: true,
      search: query,
    );
  }

  /// Load statistics
  Future<void> loadStatistics({int days = 30}) async {
    try {
      _statistics = await _historyService.getListeningStatistics(days: days);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update play history entry
  Future<void> updatePlayHistory({
    required String episodeId,
    required String status,
    required int position,
    int? progressSeconds,
    int? totalListeningTime,
  }) async {
    try {
      final updatedHistory = await _historyService.updatePlayHistory(
        episodeId: episodeId,
        status: status,
        position: position,
        progressSeconds: progressSeconds,
        totalListeningTime: totalListeningTime,
      );

      // Update existing entry or add new one
      final index =
          _playHistory.indexWhere((h) => h.podcastindexEpisodeId == episodeId);
      if (index != -1) {
        _playHistory[index] = updatedHistory;
      } else {
        _playHistory.insert(0, updatedHistory);
      }

      _filteredHistory = _playHistory;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark episode as completed
  Future<void> markEpisodeCompleted(int playHistoryId) async {
    try {
      final updatedHistory =
          await _historyService.markEpisodeCompleted(playHistoryId);

      final index = _playHistory.indexWhere((h) => h.id == playHistoryId);
      if (index != -1) {
        _playHistory[index] = updatedHistory;
        _filteredHistory = _playHistory;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete play history entry
  Future<void> deletePlayHistory(int playHistoryId) async {
    try {
      await _historyService.deletePlayHistory(playHistoryId);

      _playHistory.removeWhere((h) => h.id == playHistoryId);
      _filteredHistory = _playHistory;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Batch delete play history entries
  Future<void> batchDeletePlayHistory(List<int> playHistoryIds) async {
    try {
      await _historyService.batchDeletePlayHistory(playHistoryIds);

      _playHistory.removeWhere((h) => playHistoryIds.contains(h.id));
      _filteredHistory = _playHistory;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear all play history
  Future<void> clearAllPlayHistory() async {
    try {
      await _historyService.clearAllPlayHistory();

      _playHistory.clear();
      _filteredHistory.clear();
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Real-time progress update
  Future<void> updateProgress({
    required String episodeId,
    required int progressSeconds,
    required int totalListeningTime,
  }) async {
    try {
      await _historyService.updateProgress(
        episodeId: episodeId,
        progressSeconds: progressSeconds,
        totalListeningTime: totalListeningTime,
      );

      // Update local state
      final index =
          _playHistory.indexWhere((h) => h.podcastindexEpisodeId == episodeId);
      if (index != -1) {
        final updatedHistory = _playHistory[index].copyWith(
          progressSeconds: progressSeconds,
          totalListeningTime: totalListeningTime,
          lastPlayedAt: DateTime.now(),
        );
        _playHistory[index] = updatedHistory;
        _filteredHistory = _playHistory;
        notifyListeners();
      }
    } catch (e) {
      // Don't show error for progress updates
      debugPrint('Error updating progress: $e');
    }
  }

  /// Filter history by status
  void filterByStatus(String? status) {
    _statusFilter = status;
    _applyFilters();
  }

  /// Filter history by podcast
  void filterByPodcast(String? podcastId) {
    _podcastIdFilter = podcastId;
    _applyFilters();
  }

  /// Sort history
  void sortHistory(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _applyFilters();
  }

  /// Apply current filters
  void _applyFilters() {
    _filteredHistory = _playHistory.where((history) {
      // Status filter
      if (_statusFilter != null && history.status != _statusFilter) {
        return false;
      }

      // Podcast filter
      if (_podcastIdFilter != null &&
          history.episode?.podcast?.id.toString() != _podcastIdFilter) {
        return false;
      }

      // Search filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        final title = history.episode?.title.toLowerCase() ?? '';
        final author = history.episode?.podcast?.author?.toLowerCase() ?? '';

        if (!title.contains(query) && !author.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort filtered results
    _filteredHistory.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'last_played_at':
          comparison = (a.lastPlayedAt ?? DateTime(1900))
              .compareTo(b.lastPlayedAt ?? DateTime(1900));
          break;
        case 'progress_seconds':
          comparison = a.progressSeconds.compareTo(b.progressSeconds);
          break;
        case 'title':
          comparison =
              (a.episode?.title ?? '').compareTo(b.episode?.title ?? '');
          break;
        default:
          comparison = (a.lastPlayedAt ?? DateTime(1900))
              .compareTo(b.lastPlayedAt ?? DateTime(1900));
      }

      return _sortOrder == 'desc' ? -comparison : comparison;
    });

    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _statusFilter = null;
    _searchQuery = null;
    _podcastIdFilter = null;
    _sortBy = 'last_played_at';
    _sortOrder = 'desc';
    _filteredHistory = _playHistory;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set loading more state
  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadPlayHistory(refresh: true);
    await loadStatistics();
  }

  /// Ensure episodes exist for play history entries
  Future<Map<String, dynamic>> ensureEpisodesExist() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _historyService.ensureEpisodesExist();

      // Reload play history after ensuring episodes exist
      await loadPlayHistory(refresh: true);

      return result;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error ensuring episodes exist: $e');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
