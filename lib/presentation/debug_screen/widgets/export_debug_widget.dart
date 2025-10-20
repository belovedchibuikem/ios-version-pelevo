import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/debug_screen/widgets/export_debug_widget.dart

class ExportDebugWidget extends StatelessWidget {
  final Map<String, dynamic> debugData;
  final VoidCallback onExport;

  const ExportDebugWidget({
    super.key,
    required this.debugData,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_download,
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Export Debug Data',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Export comprehensive debug information for troubleshooting and analysis.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildExportOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy to Clipboard'),
                onPressed: () => _copyToClipboard(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share Report'),
                onPressed: () => _shareReport(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.description, size: 16),
            label: const Text('Generate Detailed Report'),
            onPressed: () => _generateDetailedReport(context),
          ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      final report = _generateQuickReport();
      await Clipboard.setData(ClipboardData(text: report));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug report copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareReport(BuildContext context) {
    final report = _generateQuickReport();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Debug Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'The debug report has been generated. You can copy it and share via your preferred method.',
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  report,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report copied to clipboard'),
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _generateDetailedReport(BuildContext context) {
    final detailedReport = _generateDetailedReportContent();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Debug Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generated: ${DateTime.now().toIso8601String()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    detailedReport,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: detailedReport));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Detailed report copied to clipboard'),
                ),
              );
            },
            child: const Text('Copy All'),
          ),
        ],
      ),
    );
  }

  String _generateQuickReport() {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();

    buffer.writeln('=== PELEVO PODCAST DEBUG REPORT ===');
    buffer.writeln('Generated: $timestamp');
    buffer.writeln();

    if (debugData.containsKey('system_status')) {
      buffer.writeln('SYSTEM STATUS:');
      final systemStatus = debugData['system_status'] as Map<String, dynamic>;
      systemStatus.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
      buffer.writeln();
    }

    if (debugData.containsKey('network_status')) {
      buffer.writeln('NETWORK STATUS:');
      final networkStatus = debugData['network_status'] as Map<String, dynamic>;
      networkStatus.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
      buffer.writeln();
    }

    if (debugData.containsKey('error_logs')) {
      final errors = debugData['error_logs'] as List;
      buffer.writeln('RECENT ERRORS (${errors.length}):');
      for (int i = 0; i < errors.length && i < 5; i++) {
        buffer.writeln('  ${i + 1}. ${errors[i]}');
      }
      buffer.writeln();
    }

    buffer.writeln('=== END REPORT ===');
    return buffer.toString();
  }

  String _generateDetailedReportContent() {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();

    buffer.writeln('PELEVO PODCAST - COMPREHENSIVE DEBUG REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln('Generated: $timestamp');
    buffer.writeln('Report Type: Detailed Analysis');
    buffer.writeln();

    // System Information
    buffer.writeln('SYSTEM INFORMATION:');
    buffer.writeln('-' * 20);
    if (debugData.containsKey('system_status')) {
      final systemStatus = debugData['system_status'] as Map<String, dynamic>;
      systemStatus.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    }
    buffer.writeln();

    // Network Information
    buffer.writeln('NETWORK INFORMATION:');
    buffer.writeln('-' * 20);
    if (debugData.containsKey('network_status')) {
      final networkStatus = debugData['network_status'] as Map<String, dynamic>;
      networkStatus.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    }
    buffer.writeln();

    // Performance Metrics
    buffer.writeln('PERFORMANCE METRICS:');
    buffer.writeln('-' * 20);
    if (debugData.containsKey('memory_stats')) {
      final memoryStats = debugData['memory_stats'] as Map<String, dynamic>;
      memoryStats.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    }
    buffer.writeln();

    // Error Logs
    buffer.writeln('ERROR LOGS:');
    buffer.writeln('-' * 20);
    if (debugData.containsKey('error_logs')) {
      final errors = debugData['error_logs'] as List;
      buffer.writeln('Total Errors: ${errors.length}');
      buffer.writeln();
      for (int i = 0; i < errors.length && i < 10; i++) {
        buffer.writeln('${i + 1}. ${errors[i]}');
      }
      if (errors.length > 10) {
        buffer.writeln('... and ${errors.length - 10} more errors');
      }
    }
    buffer.writeln();

    // Navigation Events
    buffer.writeln('NAVIGATION EVENTS:');
    buffer.writeln('-' * 20);
    if (debugData.containsKey('navigation_events')) {
      final events = debugData['navigation_events'] as List;
      buffer.writeln('Total Events: ${events.length}');
      buffer.writeln();
      for (int i = 0; i < events.length && i < 10; i++) {
        final event = events[i] as Map<String, dynamic>;
        buffer.writeln(
            '${i + 1}. Route: ${event['route']}, Action: ${event['action']}, Time: ${event['timestamp']}');
      }
      if (events.length > 10) {
        buffer.writeln('... and ${events.length - 10} more events');
      }
    }
    buffer.writeln();

    // Recommendations
    buffer.writeln('RECOMMENDATIONS:');
    buffer.writeln('-' * 20);
    final recommendations = _generateRecommendations();
    for (int i = 0; i < recommendations.length; i++) {
      buffer.writeln('${i + 1}. ${recommendations[i]}');
    }
    buffer.writeln();

    buffer.writeln('=' * 50);
    buffer.writeln('END OF DETAILED REPORT');

    return buffer.toString();
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // Analyze system status
    if (debugData.containsKey('system_status')) {
      final systemStatus = debugData['system_status'] as Map<String, dynamic>;

      systemStatus.forEach((key, value) {
        final valueStr = value.toString();
        if (valueStr.contains('failed') || valueStr.contains('error')) {
          recommendations.add('Fix $key issue: $valueStr');
        }
      });
    }

    // Analyze error count
    if (debugData.containsKey('error_logs')) {
      final errors = debugData['error_logs'] as List;
      if (errors.length > 10) {
        recommendations.add(
            'High error count detected (${errors.length}). Review and fix recurring issues.');
      }
    }

    // Analyze network
    if (debugData.containsKey('network_status')) {
      final networkStatus = debugData['network_status'] as Map<String, dynamic>;
      final isConnected = networkStatus['is_connected'] ?? false;
      if (!isConnected) {
        recommendations.add(
            'Network connectivity issues detected. Check internet connection.');
      }
    }

    // General recommendations
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'App appears to be running normally',
        'Continue monitoring for any performance issues',
        'Regular debug checks recommended for optimal performance',
      ]);
    } else {
      recommendations.add('Run diagnostics again after addressing issues');
      recommendations.add('Consider reaching out to support if issues persist');
    }

    return recommendations;
  }
}
