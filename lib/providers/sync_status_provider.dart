import 'package:flutter/foundation.dart';
import '../core/services/service_manager.dart';

class SyncStatusProvider extends ChangeNotifier {
  final ServiceManager _serviceManager;

  // Sync status
  bool _isOnline = true;
  bool _isSyncing = false;
  String _syncStatus = 'idle';
  String? _lastSyncError;
  DateTime? _lastSyncTime;

  // Queue status
  int _pendingOperations = 0;
  int _failedOperations = 0;
  bool _isProcessingQueue = false;

  // Network status
  String _networkType = 'unknown';
  bool _isConnected = true;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingOperations => _pendingOperations;
  int get failedOperations => _failedOperations;
  bool get isProcessingQueue => _isProcessingQueue;
  String get networkType => _networkType;
  bool get isConnected => _isConnected;

  // Computed getters
  bool get hasPendingWork => _pendingOperations > 0;
  bool get hasFailedOperations => _failedOperations > 0;
  bool get needsAttention => hasFailedOperations || _lastSyncError != null;

  // Status messages
  String get statusMessage {
    if (_isSyncing) return 'Synchronizing...';
    if (hasFailedOperations) return '${_failedOperations} operations failed';
    if (hasPendingWork) return '${_pendingOperations} operations pending';
    if (!_isOnline) return 'Offline mode';
    if (_lastSyncError != null) return 'Sync error occurred';
    return 'Up to date';
  }

  // Status color (for UI)
  String get statusColor {
    if (_isSyncing) return 'blue';
    if (hasFailedOperations || _lastSyncError != null) return 'red';
    if (hasPendingWork) return 'orange';
    if (!_isOnline) return 'gray';
    return 'green';
  }

  SyncStatusProvider(this._serviceManager) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Start monitoring sync status
      _startStatusMonitoring();

      // Perform initial status check
      await _updateStatus();

      debugPrint('✅ SyncStatusProvider initialized');
    } catch (e) {
      debugPrint('❌ Error initializing SyncStatusProvider: $e');
    }
  }

  void _startStatusMonitoring() {
    // Monitor service health every 30 seconds, but only if services are ready
    Future.delayed(const Duration(seconds: 30), () {
      if (_serviceManager.isReady) {
        _updateStatus();
      }
      _startStatusMonitoring(); // Recursive call for continuous monitoring
    });
  }

  Future<void> _updateStatus() async {
    try {
      // Check if services are available before using them
      if (!_serviceManager.isReady) {
        debugPrint('⚠️ Services not ready, skipping status update');
        return;
      }

      final health = await _serviceManager.getServiceHealth();

      // Update sync status safely
      if (health['services'] != null) {
        final services = health['services'] as Map<String, dynamic>;
        _isSyncing = services['backgroundSync'] == 'syncing';
        _syncStatus = services['backgroundSync'] ?? 'idle';
        _isOnline = services['dataSync'] == 'online';
      }

      // Update queue status safely
      if (_serviceManager.hasBackgroundSync) {
        try {
          final queueStats =
              await _serviceManager.offlineQueue!.getQueueStats();
          _pendingOperations = queueStats['pendingCount'] ?? 0;
          _failedOperations = queueStats['failedCount'] ?? 0;
          _isProcessingQueue = queueStats['isProcessing'] ?? false;
        } catch (e) {
          debugPrint('⚠️ Could not get queue stats: $e');
        }
      }

      // Update network status
      _isConnected = _isOnline;
      _networkType = _isOnline ? 'wifi' : 'none';

      // Update last sync info
      if (health['sync'] != null) {
        final sync = health['sync'];
        _lastSyncTime = sync['lastSyncAttempt'] != null
            ? DateTime.tryParse(sync['lastSyncAttempt'])
            : null;
        _lastSyncError = sync['lastSyncError'];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating sync status: $e');
      _syncStatus = 'error';
      _lastSyncError = e.toString();
      notifyListeners();
    }
  }

  // Manual sync trigger
  Future<void> triggerManualSync() async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress');
      return;
    }

    try {
      _isSyncing = true;
      _syncStatus = 'manual_sync';
      notifyListeners();

      await _serviceManager.triggerManualSync();

      // Update status after sync
      await _updateStatus();

      debugPrint('✅ Manual sync completed');
    } catch (e) {
      debugPrint('❌ Manual sync failed: $e');
      _lastSyncError = e.toString();
      _syncStatus = 'error';
      notifyListeners();
    }
  }

  // Retry failed operations
  Future<void> retryFailedOperations() async {
    try {
      if (_serviceManager.offlineQueue != null) {
        await _serviceManager.offlineQueue!.processQueue();
        await _updateStatus();
        debugPrint('✅ Retrying failed operations');
      } else {
        debugPrint('⚠️ Offline queue not available');
      }
    } catch (e) {
      debugPrint('❌ Error retrying failed operations: $e');
    }
  }

  // Clear sync errors
  void clearSyncErrors() {
    _lastSyncError = null;
    _syncStatus = 'idle';
    notifyListeners();
  }

  // Get detailed sync information
  Future<Map<String, dynamic>> getDetailedStatus() async {
    try {
      final health = await _serviceManager.getServiceHealth();
      final stats = await _serviceManager.getServiceStats();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'overall': health['overall'],
        'services': health['services'],
        'sync': health['sync'],
        'queue': health['queue'],
        'database': stats['database'],
        'notifications': stats['notifications'],
        'media': stats['media'],
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Check if app needs to sync
  Future<bool> needsSync() async {
    try {
      final health = await _serviceManager.getServiceHealth();
      return health['overall'] == 'error' ||
          health['services']['dataSync'] == 'offline' ||
          _pendingOperations > 0;
    } catch (e) {
      return true; // Assume sync is needed if we can't check
    }
  }

  // Get sync progress (0.0 to 1.0)
  double get syncProgress {
    if (_pendingOperations == 0) return 1.0;
    if (_isSyncing) return 0.5; // Indeterminate progress
    return 0.0;
  }

  // Get formatted last sync time
  String get formattedLastSyncTime {
    if (_lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${_lastSyncTime!.day}/${_lastSyncTime!.month}/${_lastSyncTime!.year}';
  }

  // Get sync summary for UI
  Map<String, dynamic> get syncSummary {
    return {
      'status': _syncStatus,
      'message': statusMessage,
      'color': statusColor,
      'progress': syncProgress,
      'isOnline': _isOnline,
      'hasPendingWork': hasPendingWork,
      'hasFailedOperations': hasFailedOperations,
      'needsAttention': needsAttention,
      'lastSyncTime': formattedLastSyncTime,
      'pendingCount': _pendingOperations,
      'failedCount': _failedOperations,
    };
  }

  @override
  void dispose() {
    debugPrint('🧹 SyncStatusProvider disposed');
    super.dispose();
  }
}
