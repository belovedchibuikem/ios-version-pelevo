import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/debug_screen/widgets/error_log_widget.dart

class ErrorLogWidget extends StatefulWidget {
  final List<String> errorLogs;
  final VoidCallback onRefresh;

  const ErrorLogWidget({
    super.key,
    required this.errorLogs,
    required this.onRefresh,
  });

  @override
  State<ErrorLogWidget> createState() => _ErrorLogWidgetState();
}

class _ErrorLogWidgetState extends State<ErrorLogWidget> {
  String _filterLevel = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredLogs {
    List<String> filtered = widget.errorLogs;

    // Filter by level
    if (_filterLevel != 'ALL') {
      filtered = filtered
          .where((log) =>
              log.toUpperCase().contains('[${_filterLevel.toUpperCase()}]'))
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (log) => log.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filter Chips
              Row(
                children: [
                  Text(
                    'Filter:',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['ALL', 'ERROR', 'WARNING', 'INFO', 'SUCCESS']
                            .map((level) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(level),
                                    selected: _filterLevel == level,
                                    onSelected: (selected) {
                                      setState(() {
                                        _filterLevel = level;
                                      });
                                    },
                                    selectedColor: AppTheme
                                        .lightTheme.primaryColor
                                        .withValues(alpha: 0.2),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: widget.onRefresh,
                    tooltip: 'Refresh logs',
                  ),
                ],
              ),
            ],
          ),
        ),
        // Logs List
        Expanded(
          child: _filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.errorLogs.isEmpty
                            ? 'No logs available'
                            : 'No logs match your filter',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    return _buildLogItem(log, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogItem(String log, int index) {
    final parts = log.split('] ');
    String timestamp = '';
    String level = '';
    String message = log;

    if (parts.length >= 3) {
      timestamp = parts[0].replaceAll('[', '');
      level = parts[1].replaceAll('[', '');
      message = parts.sublist(2).join('] ');
    } else if (parts.length == 2) {
      final firstPart = parts[0];
      if (firstPart.contains('[')) {
        timestamp = firstPart.split('[')[0];
        level = firstPart.split('[')[1];
        message = parts[1];
      }
    }

    Color levelColor = _getLevelColor(level);
    IconData levelIcon = _getLevelIcon(level);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          levelIcon,
          color: levelColor,
          size: 20,
        ),
        title: Text(
          message.length > 60 ? '${message.substring(0, 60)}...' : message,
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                level,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timestamp.isNotEmpty
                  ? _formatTimestamp(timestamp)
                  : 'Unknown time',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Message:',
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: log));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Log copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      case 'SUCCESS':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Icons.error;
      case 'WARNING':
        return Icons.warning;
      case 'INFO':
        return Icons.info;
      case 'SUCCESS':
        return Icons.check_circle;
      default:
        return Icons.notes;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inSeconds < 60) {
        return '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
