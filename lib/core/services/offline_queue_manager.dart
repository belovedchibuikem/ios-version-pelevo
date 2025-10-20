import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'local_storage_service.dart';

class OfflineQueueManager {
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  // Queue storage keys
  static const String _queueKey = 'offline_operations_queue';
  static const String _failedQueueKey = 'failed_operations_queue';

  // Queue limits
  static const int _maxQueueSize = 200;
  static const int _maxFailedQueueSize = 50;

  // Queue processing
  bool _isProcessing = false;
  Timer? _retryTimer;

  // Initialize the manager
  Future<void> initialize() async {
    try {
      // Load existing queues from storage
      await _loadQueues();

      // Setup retry timer (every 30 minutes)
      _retryTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
        _processFailedQueue();
      });

      debugPrint('✅ OfflineQueueManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing OfflineQueueManager: $e');
    }
  }

  // Add operation to offline queue
  Future<void> addToQueue(
    String operation,
    Map<String, dynamic> data, {
    int priority = 1, // 1 = high, 2 = normal, 3 = low
    int maxRetries = 3,
  }) async {
    try {
      final queueItem = {
        'id': _generateOperationId(),
        'operation': operation,
        'data': data,
        'priority': priority,
        'maxRetries': maxRetries,
        'retryCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'lastAttempt': null,
        'status': 'pending', // pending, processing, failed, completed
      };

      final queue = await _getQueue();

      // Add to queue based on priority
      if (priority == 1) {
        // High priority items go to the front
        queue.insert(0, queueItem);
      } else {
        queue.add(queueItem);
      }

      // Enforce queue size limit
      if (queue.length > _maxQueueSize) {
        queue.removeRange(_maxQueueSize, queue.length);
      }

      await _saveQueue(queue);

      debugPrint('📝 Added to offline queue: $operation (Priority: $priority)');
    } catch (e) {
      debugPrint('❌ Error adding to offline queue: $e');
    }
  }

  // Process the offline queue
  Future<void> processQueue() async {
    if (_isProcessing) {
      debugPrint('⚠️ Queue processing already in progress');
      return;
    }

    _isProcessing = true;

    try {
      final queue = await _getQueue();
      if (queue.isEmpty) {
        debugPrint('ℹ️ Offline queue is empty');
        return;
      }

      debugPrint('🔄 Processing offline queue (${queue.length} items)...');

      final itemsToProcess = List<Map<String, dynamic>>.from(queue);
      final failedItems = <Map<String, dynamic>>[];
      final completedItems = <Map<String, dynamic>>[];

      for (final item in itemsToProcess) {
        try {
          final success = await _processQueueItem(item);

          if (success) {
            completedItems.add(item);
            debugPrint('✅ Processed: ${item['operation']}');
          } else {
            failedItems.add(item);
            debugPrint('❌ Failed: ${item['operation']}');
          }
        } catch (e) {
          debugPrint('❌ Error processing item: ${item['operation']} - $e');
          failedItems.add(item);
        }
      }

      // Remove completed items from queue
      for (final item in completedItems) {
        queue.removeWhere((element) => element['id'] == item['id']);
      }

      // Move failed items to failed queue
      await _moveToFailedQueue(failedItems);

      // Remove failed items from main queue
      for (final item in failedItems) {
        queue.removeWhere((element) => element['id'] == item['id']);
      }

      await _saveQueue(queue);

      debugPrint(
          '✅ Queue processing completed. Success: ${completedItems.length}, Failed: ${failedItems.length}');
    } catch (e) {
      debugPrint('❌ Error processing offline queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Process individual queue item
  Future<bool> _processQueueItem(Map<String, dynamic> item) async {
    try {
      // Update status to processing
      item['status'] = 'processing';
      item['lastAttempt'] = DateTime.now().toIso8601String();

      final operation = item['operation'] as String;
      final data = item['data'] as Map<String, dynamic>;

      // Here you would implement the actual operation logic
      // For now, we'll simulate different operations
      switch (operation) {
        case 'sync_playback_position':
          return await _syncPlaybackPosition(data);
        case 'sync_episode_completed':
          return await _syncEpisodeCompleted(data);
        case 'sync_bookmark':
          return await _syncBookmark(data);
        case 'sync_subscription':
          return await _syncSubscription(data);
        case 'sync_rating':
          return await _syncRating(data);
        case 'download_episode':
          return await _downloadEpisode(data);
        case 'delete_episode':
          return await _deleteEpisode(data);
        default:
          debugPrint('⚠️ Unknown operation: $operation');
          return false;
      }
    } catch (e) {
      debugPrint('❌ Error processing queue item: $e');
      return false;
    }
  }

  // Simulated sync operations
  Future<bool> _syncPlaybackPosition(Map<String, dynamic> data) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Simulate 90% success rate
    return DateTime.now().millisecond % 10 != 0;
  }

  Future<bool> _syncEpisodeCompleted(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return DateTime.now().millisecond % 10 != 0;
  }

  Future<bool> _syncBookmark(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return DateTime.now().millisecond % 10 != 0;
  }

  Future<bool> _syncSubscription(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return DateTime.now().millisecond % 10 != 0;
  }

  Future<bool> _syncRating(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return DateTime.now().millisecond % 10 != 0;
  }

  Future<bool> _downloadEpisode(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DateTime.now().millisecond % 10 != 0;
  }

  Future<bool> _deleteEpisode(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // Delete operations usually succeed
  }

  // Move failed items to failed queue
  Future<void> _moveToFailedQueue(
      List<Map<String, dynamic>> failedItems) async {
    try {
      final failedQueue = await _getFailedQueue();

      for (final item in failedItems) {
        item['status'] = 'failed';
        item['failedAt'] = DateTime.now().toIso8601String();

        // Add to failed queue
        failedQueue.add(item);
      }

      // Enforce failed queue size limit
      if (failedQueue.length > _maxFailedQueueSize) {
        failedQueue.removeRange(0, failedQueue.length - _maxFailedQueueSize);
      }

      await _saveFailedQueue(failedQueue);
    } catch (e) {
      debugPrint('❌ Error moving items to failed queue: $e');
    }
  }

  // Process failed queue (retry failed operations)
  Future<void> _processFailedQueue() async {
    try {
      final failedQueue = await _getFailedQueue();
      if (failedQueue.isEmpty) return;

      debugPrint('🔄 Processing failed queue (${failedQueue.length} items)...');

      final itemsToRetry = <Map<String, dynamic>>[];
      final itemsToRemove = <Map<String, dynamic>>[];

      for (final item in failedQueue) {
        final retryCount = item['retryCount'] as int;
        final maxRetries = item['maxRetries'] as int;

        if (retryCount < maxRetries) {
          // Retry the operation
          item['retryCount'] = retryCount + 1;
          item['status'] = 'pending';
          itemsToRetry.add(item);
        } else {
          // Exceeded max retries, remove from failed queue
          itemsToRemove.add(item);
          debugPrint(
              '⚠️ Removed operation after ${maxRetries} retries: ${item['operation']}');
        }
      }

      // Remove items that exceeded max retries
      for (final item in itemsToRemove) {
        failedQueue.removeWhere((element) => element['id'] == item['id']);
      }

      // Move retry items back to main queue
      if (itemsToRetry.isNotEmpty) {
        final mainQueue = await _getQueue();
        mainQueue.addAll(itemsToRetry);
        await _saveQueue(mainQueue);

        // Remove from failed queue
        for (final item in itemsToRetry) {
          failedQueue.removeWhere((element) => element['id'] == item['id']);
        }
      }

      await _saveFailedQueue(failedQueue);

      debugPrint(
          '✅ Failed queue processed. Retrying: ${itemsToRetry.length}, Removed: ${itemsToRemove.length}');
    } catch (e) {
      debugPrint('❌ Error processing failed queue: $e');
    }
  }

  // Get queue statistics
  Future<Map<String, dynamic>> getQueueStats() async {
    try {
      final queue = await _getQueue();
      final failedQueue = await _getFailedQueue();

      return {
        'pendingCount': queue.length,
        'failedCount': failedQueue.length,
        'isProcessing': _isProcessing,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting queue stats: $e');
      return {};
    }
  }

  // Get current queue
  Future<List<Map<String, dynamic>>> getQueue() async {
    return await _getQueue();
  }

  // Get failed queue
  Future<List<Map<String, dynamic>>> getFailedQueue() async {
    return await _getFailedQueue();
  }

  // Clear all queues
  Future<void> clearAllQueues() async {
    try {
      await _localStorage.deleteUserData(_queueKey);
      await _localStorage.deleteUserData(_failedQueueKey);
      debugPrint('🧹 All queues cleared');
    } catch (e) {
      debugPrint('❌ Error clearing queues: $e');
    }
  }

  // Clear specific queue
  Future<void> clearQueue(String queueType) async {
    try {
      if (queueType == 'main') {
        await _localStorage.deleteUserData(_queueKey);
        debugPrint('🧹 Main queue cleared');
      } else if (queueType == 'failed') {
        await _localStorage.deleteUserData(_failedQueueKey);
        debugPrint('🧹 Failed queue cleared');
      }
    } catch (e) {
      debugPrint('❌ Error clearing queue: $e');
    }
  }

  // Load queues from storage
  Future<void> _loadQueues() async {
    try {
      await _getQueue(); // This will load from storage
      await _getFailedQueue(); // This will load from storage
    } catch (e) {
      debugPrint('❌ Error loading queues: $e');
    }
  }

  // Get main queue from storage
  Future<List<Map<String, dynamic>>> _getQueue() async {
    try {
      final data = _localStorage.getUserData(_queueKey);
      if (data != null) {
        return (data as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('❌ Error getting queue: $e');
    }
    return [];
  }

  // Get failed queue from storage
  Future<List<Map<String, dynamic>>> _getFailedQueue() async {
    try {
      final data = _localStorage.getUserData(_failedQueueKey);
      if (data != null) {
        return (data as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('❌ Error getting failed queue: $e');
    }
    return [];
  }

  // Save main queue to storage
  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    try {
      await _localStorage.saveUserData(_queueKey, queue);
    } catch (e) {
      debugPrint('❌ Error saving queue: $e');
    }
  }

  // Save failed queue to storage
  Future<void> _saveFailedQueue(List<Map<String, dynamic>> queue) async {
    try {
      await _localStorage.saveUserData(_failedQueueKey, queue);
    } catch (e) {
      debugPrint('❌ Error saving failed queue: $e');
    }
  }

  // Generate unique operation ID
  String _generateOperationId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      _retryTimer?.cancel();
      debugPrint('✅ OfflineQueueManager disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing OfflineQueueManager: $e');
    }
  }
}
