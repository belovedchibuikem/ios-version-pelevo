import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/debug_screen/widgets/system_status_widget.dart

class SystemStatusWidget extends StatelessWidget {
  final Map<String, dynamic> systemStatus;

  const SystemStatusWidget({
    super.key,
    required this.systemStatus,
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
                  Icons.monitor_heart,
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                const Spacer(),
                _buildOverallStatus(),
              ],
            ),
            const SizedBox(height: 16),
            if (systemStatus.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              ...systemStatus.entries.map((entry) => _buildStatusItem(
                    entry.key,
                    entry.value,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatus() {
    if (systemStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasErrors = systemStatus.values.any((value) =>
        value.toString().contains('failed') ||
        value.toString().contains('error'));

    final hasWarnings = systemStatus.values.any((value) =>
        value.toString().contains('checking') ||
        value.toString().contains('pending'));

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (hasErrors) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Issues Detected';
    } else if (hasWarnings) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Checking...';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Healthy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String key, dynamic value) {
    final statusValue = value.toString();
    Color statusColor;
    IconData statusIcon;

    if (statusValue.contains('failed') || statusValue.contains('error')) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (statusValue.contains('checking') ||
        statusValue.contains('pending')) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else if (statusValue.contains('healthy') ||
        statusValue.contains('initialized') ||
        statusValue.contains('active') ||
        statusValue.contains('completed') ||
        statusValue.contains('accessible') ||
        statusValue.contains('authenticated')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              _formatKey(key),
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatValue(statusValue),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  String _formatValue(String value) {
    if (value.contains('failed:')) {
      return 'Failed';
    }
    return value.split(':')[0]; // Take only the first part before colon
  }
}
