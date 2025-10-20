import 'package:flutter/material.dart';
import '../services/history_service.dart';

/// Example widget demonstrating how to use HistoryService with proper error handling
class HistoryServiceExample extends StatefulWidget {
  const HistoryServiceExample({super.key});

  @override
  State<HistoryServiceExample> createState() => _HistoryServiceExampleState();
}

class _HistoryServiceExampleState extends State<HistoryServiceExample> {
  final HistoryService _historyService = HistoryService();
  List<dynamic> _playHistory = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayHistory();
  }

  /// Load play history with proper error handling
  Future<void> _loadPlayHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _historyService.getPlayHistory(
        context: context,
        onRetry: _loadPlayHistory, // Retry function
      );

      setState(() {
        _playHistory = history;
        _isLoading = false;
      });

      // Show success message
      if (history.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully loaded ${history.length} history items'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      // Error is already handled by the service with snackbar
    }
  }

  /// Update play history with error handling
  Future<void> _updatePlayHistory() async {
    try {
      await _historyService.updatePlayHistory(
        episodeId: 'test_episode_id',
        status: 'played',
        position: 100,
        progressSeconds: 60,
        totalListeningTime: 120,
        context: context,
        onRetry: _updatePlayHistory,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Play history updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Error is already handled by the service with snackbar
    }
  }

  /// Delete play history with error handling
  Future<void> _deletePlayHistory(int historyId) async {
    try {
      await _historyService.deletePlayHistory(
        historyId,
        context: context,
        onRetry: () => _deletePlayHistory(historyId),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History item deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload the list
      _loadPlayHistory();
    } catch (e) {
      // Error is already handled by the service with snackbar
    }
  }

  /// Get recent play history with error handling
  Future<void> _loadRecentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recentHistory = await _historyService.getRecentPlayHistory(
        days: 7,
        limit: 10,
        context: context,
        onRetry: _loadRecentHistory,
      );

      setState(() {
        _playHistory = recentHistory;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded ${recentHistory.length} recent items'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      // Error is already handled by the service with snackbar
    }
  }

  /// Clear all history with confirmation
  Future<void> _clearAllHistory() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to clear all play history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _historyService.clearAllPlayHistory(
          context: context,
          onRetry: _clearAllHistory,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All play history cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload the list
        _loadPlayHistory();
      } catch (e) {
        // Error is already handled by the service with snackbar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Service Example'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadPlayHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadRecentHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('Recent'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updatePlayHistory,
                    icon: const Icon(Icons.update),
                    label: const Text('Update'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearAllHistory,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Error display
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Error',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadPlayHistory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // History list
          Expanded(
            child: _playHistory.isEmpty && !_isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No play history found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your listening history will appear here',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _playHistory.length,
                    itemBuilder: (context, index) {
                      final item = _playHistory[index];
                      return ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(item.toString()),
                        subtitle: Text('Item ${index + 1}'),
                        trailing: IconButton(
                          onPressed: () => _deletePlayHistory(index),
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
