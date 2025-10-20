import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'local_storage_service.dart';
import 'background_sync_service.dart';
import '../../data/models/database_models.dart';

class DataSyncManager {
  static final DataSyncManager _instance = DataSyncManager._internal();
  factory DataSyncManager() => _instance;
  DataSyncManager._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final BackgroundSyncService _backgroundSync = BackgroundSyncService();

  // Sync state tracking
  bool _isInitialized = false;
  bool _isOnline = false;
  Timer? _connectivityTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Sync queue for offline operations
  final List<Map<String, dynamic>> _syncQueue = [];
  final int _maxQueueSize = 100;

  // Initialize the sync manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local storage
      await _localStorage.initialize();

      // Initialize background sync
      await _backgroundSync.initialize();

      // Setup connectivity monitoring
      await _setupConnectivityMonitoring();

      // Check initial connectivity
      _isOnline = await _isNetworkAvailable();

      // Process sync queue if online
      if (_isOnline) {
        await _processSyncQueue();
      }

      _isInitialized = true;
      debugPrint('✅ DataSyncManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing DataSyncManager: $e');
      rethrow;
    }
  }

  // Setup connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    try {
      // Listen to connectivity changes
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((ConnectivityResult result) {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;

        if (!wasOnline && _isOnline) {
          // Came back online, process sync queue
          _processSyncQueue();
        }

        debugPrint(
            '🌐 Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      });

      // Periodic connectivity check
      _connectivityTimer =
          Timer.periodic(const Duration(minutes: 5), (timer) async {
        final currentConnectivity = await _isNetworkAvailable();
        if (currentConnectivity != _isOnline) {
          _isOnline = currentConnectivity;
          debugPrint(
              '🌐 Connectivity status updated: ${_isOnline ? 'Online' : 'Offline'}');
        }
      });
    } catch (e) {
      debugPrint('❌ Error setting up connectivity monitoring: $e');
    }
  }

  // Check network availability
  Future<bool> _isNetworkAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('❌ Error checking network connectivity: $e');
      return false;
    }
  }

  // Add item to sync queue
  Future<void> addToSyncQueue(
      String operation, Map<String, dynamic> data) async {
    if (_syncQueue.length >= _maxQueueSize) {
      // Remove oldest items if queue is full
      _syncQueue.removeRange(0, _syncQueue.length - _maxQueueSize + 1);
    }

    final queueItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
      'maxRetries': 3,
    };

    _syncQueue.add(queueItem);

    // Save queue to local storage
    await _localStorage.saveUserData('sync_queue', _syncQueue);

    debugPrint('📝 Added to sync queue: $operation');

    // Process queue if online
    if (_isOnline) {
      await _processSyncQueue();
    }
  }

  // Process sync queue
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty || !_isOnline) return;

    debugPrint('🔄 Processing sync queue (${_syncQueue.length} items)...');

    final itemsToProcess = List<Map<String, dynamic>>.from(_syncQueue);
    final failedItems = <Map<String, dynamic>>[];

    for (final item in itemsToProcess) {
      try {
        final success = await _processQueueItem(item);
        if (success) {
          _syncQueue.removeWhere((element) => element['id'] == item['id']);
        } else {
          failedItems.add(item);
        }
      } catch (e) {
        debugPrint('❌ Error processing queue item: $e');
        failedItems.add(item);
      }
    }

    // Update retry counts for failed items
    for (final item in failedItems) {
      final retryCount = (item['retryCount'] as int) + 1;
      if (retryCount < item['maxRetries']) {
        item['retryCount'] = retryCount;
      } else {
        // Remove items that have exceeded max retries
        _syncQueue.removeWhere((element) => element['id'] == item['id']);
        debugPrint(
            '⚠️ Removed failed sync item after ${item['maxRetries']} retries: ${item['operation']}');
      }
    }

    // Save updated queue
    await _localStorage.saveUserData('sync_queue', _syncQueue);

    debugPrint(
        '✅ Sync queue processed. Success: ${itemsToProcess.length - failedItems.length}, Failed: ${failedItems.length}');
  }

  // Process individual queue item
  Future<bool> _processQueueItem(Map<String, dynamic> item) async {
    try {
      final operation = item['operation'] as String;
      final data = item['data'] as Map<String, dynamic>;

      switch (operation) {
        case 'update_playback_position':
          return await _syncPlaybackPosition(data);
        case 'mark_episode_completed':
          return await _syncEpisodeCompleted(data);
        case 'add_bookmark':
          return await _syncBookmark(data);
        case 'update_subscription':
          return await _syncSubscription(data);
        case 'update_rating':
          return await _syncRating(data);
        default:
          debugPrint('⚠️ Unknown sync operation: $operation');
          return false;
      }
    } catch (e) {
      debugPrint('❌ Error processing queue item: $e');
      return false;
    }
  }

  // Sync playback position
  Future<bool> _syncPlaybackPosition(Map<String, dynamic> data) async {
    try {
      // This would typically send data to your backend
      // For now, we'll just mark it as successful
      debugPrint(
          '🔄 Syncing playback position for episode: ${data['episodeId']}');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing playback position: $e');
      return false;
    }
  }

  // Sync episode completed status
  Future<bool> _syncEpisodeCompleted(Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 Syncing episode completed status: ${data['episodeId']}');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing episode completed status: $e');
      return false;
    }
  }

  // Sync bookmark
  Future<bool> _syncBookmark(Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 Syncing bookmark: ${data['title']}');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing bookmark: $e');
      return false;
    }
  }

  // Sync subscription
  Future<bool> _syncSubscription(Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 Syncing subscription: ${data['podcastId']}');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing subscription: $e');
      return false;
    }
  }

  // Sync rating
  Future<bool> _syncRating(Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 Syncing rating: ${data['episodeId']}');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing rating: $e');
      return false;
    }
  }

  // Update playback position with sync
  Future<void> updatePlaybackPosition(
      int episodeId, int position, int duration) async {
    try {
      // Update local storage immediately
      await _localStorage.updatePlaybackPosition(episodeId, position, duration);

      // Add to sync queue
      await addToSyncQueue('update_playback_position', {
        'episodeId': episodeId,
        'position': position,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error updating playback position: $e');
    }
  }

  // Mark episode as completed with sync
  Future<void> markEpisodeCompleted(int episodeId) async {
    try {
      // Update local storage immediately
      // This would typically call a method on the episode repository

      // Add to sync queue
      await addToSyncQueue('mark_episode_completed', {
        'episodeId': episodeId,
        'completed': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error marking episode completed: $e');
    }
  }

  // Add bookmark with sync
  Future<void> addBookmark(Map<String, dynamic> bookmarkData) async {
    try {
      // Add to sync queue
      await addToSyncQueue('add_bookmark', bookmarkData);
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
    }
  }

  // Update subscription with sync
  Future<void> updateSubscription(int podcastId, bool isSubscribed) async {
    try {
      // Add to sync queue
      await addToSyncQueue('update_subscription', {
        'podcastId': podcastId,
        'isSubscribed': isSubscribed,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error updating subscription: $e');
    }
  }

  // Update rating with sync
  Future<void> updateRating(int episodeId, double rating) async {
    try {
      // Add to sync queue
      await addToSyncQueue('update_rating', {
        'episodeId': episodeId,
        'rating': rating,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error updating rating: $e');
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final backgroundSyncStatus = await _backgroundSync.getSyncStatus();

    return {
      ...backgroundSyncStatus,
      'isOnline': _isOnline,
      'queueSize': _syncQueue.length,
      'isInitialized': _isInitialized,
    };
  }

  // Manual sync trigger
  Future<void> triggerManualSync() async {
    if (!_isOnline) {
      debugPrint('⚠️ Cannot sync while offline');
      return;
    }

    await _backgroundSync.triggerManualSync();
  }

  // Get sync queue
  List<Map<String, dynamic>> getSyncQueue() {
    return List.unmodifiable(_syncQueue);
  }

  // Clear sync queue
  Future<void> clearSyncQueue() async {
    _syncQueue.clear();
    await _localStorage.saveUserData('sync_queue', _syncQueue);
    debugPrint('🧹 Sync queue cleared');
  }

  // Load sync queue from storage
  Future<void> _loadSyncQueue() async {
    try {
      final savedQueue = _localStorage.getUserData('sync_queue');
      if (savedQueue != null) {
        _syncQueue.addAll((savedQueue as List).cast<Map<String, dynamic>>());
        debugPrint('📥 Loaded ${_syncQueue.length} items from sync queue');
      }
    } catch (e) {
      debugPrint('❌ Error loading sync queue: $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      _connectivityTimer?.cancel();
      _connectivitySubscription?.cancel();
      await _backgroundSync.dispose();
      debugPrint('✅ DataSyncManager disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing DataSyncManager: $e');
    }
  }
}
