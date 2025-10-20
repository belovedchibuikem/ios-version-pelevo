import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../services/episode_progress_service.dart';

/// Widget to display sync status and allow manual sync
class SyncStatusWidget extends StatefulWidget {
  final VoidCallback? onSyncComplete;
  final bool showDetails;

  const SyncStatusWidget({
    super.key,
    this.onSyncComplete,
    this.showDetails = true,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final EpisodeProgressService _progressService = EpisodeProgressService();
  bool _isSyncing = false;
  bool _isOnline = true;
  int _pendingCount = 0;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      await _progressService.initialize();
      _updateSyncStatus();
    } catch (e) {
      debugPrint('Error loading sync status: $e');
    }
  }

  void _updateSyncStatus() {
    setState(() {
      _isSyncing = _progressService.isSyncing;
      _isOnline = _progressService.isOnline;
      _pendingCount = _progressService.pendingSyncCount;
      _lastSyncTime = _progressService.lastSyncTime;
    });
  }

  Future<void> _triggerManualSync() async {
    if (_isSyncing || !_isOnline) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _progressService.syncAllProgress();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        widget.onSyncComplete?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      _updateSyncStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sync icon and status
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _getStatusText(),
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
              if (_isOnline && !_isSyncing && _pendingCount > 0)
                ElevatedButton(
                  onPressed: _triggerManualSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Sync Now',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          if (widget.showDetails) ...[
            SizedBox(height: 2.h),

            // Sync details
            Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  size: 16,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 4.w),
                if (_pendingCount > 0) ...[
                  Icon(
                    Icons.queue,
                    size: 16,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '$_pendingCount pending',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),

            if (_lastSyncTime != null) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Last sync: ${_formatLastSyncTime(_lastSyncTime!)}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_isSyncing) {
      return AppTheme.lightTheme.colorScheme.primary;
    } else if (!_isOnline) {
      return AppTheme.lightTheme.colorScheme.error;
    } else if (_pendingCount > 0) {
      return AppTheme.lightTheme.colorScheme.tertiary;
    } else {
      return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  IconData _getStatusIcon() {
    if (_isSyncing) {
      return Icons.sync;
    } else if (!_isOnline) {
      return Icons.cloud_off;
    } else if (_pendingCount > 0) {
      return Icons.cloud_queue;
    } else {
      return Icons.cloud_done;
    }
  }

  String _getStatusText() {
    if (_isSyncing) {
      return 'Syncing...';
    } else if (!_isOnline) {
      return 'Offline - Sync pending';
    } else if (_pendingCount > 0) {
      return 'Sync pending ($_pendingCount items)';
    } else {
      return 'All synced';
    }
  }

  String _formatLastSyncTime(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Compact sync indicator for use in other widgets
class CompactSyncIndicator extends StatelessWidget {
  final EpisodeProgressService progressService;
  final VoidCallback? onTap;

  const CompactSyncIndicator({
    super.key,
    required this.progressService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = progressService.isOnline;
    final isSyncing = progressService.isSyncing;
    final pendingCount = progressService.pendingSyncCount;

    if (isSyncing) {
      return Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              'Syncing...',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!isOnline) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 16,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
              SizedBox(width: 2.w),
              Text(
                'Offline',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pendingCount > 0) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.tertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_queue,
                size: 16,
                color: AppTheme.lightTheme.colorScheme.tertiary,
              ),
              SizedBox(width: 2.w),
              Text(
                '$pendingCount pending',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // All synced
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_done,
              size: 16,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(width: 2.w),
            Text(
              'Synced',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
