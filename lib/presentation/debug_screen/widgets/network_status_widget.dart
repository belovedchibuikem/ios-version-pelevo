import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/debug_screen/widgets/network_status_widget.dart

class NetworkStatusWidget extends StatelessWidget {
  final Map<String, dynamic> networkStatus;

  const NetworkStatusWidget({
    super.key,
    required this.networkStatus,
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
                  Icons.wifi,
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network Status',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                const Spacer(),
                _buildConnectionIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            if (networkStatus.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              ...networkStatus.entries.map((entry) => _buildNetworkItem(
                    entry.key,
                    entry.value,
                  )),
            const SizedBox(height: 16),
            _buildNetworkActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    if (networkStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final isConnected = networkStatus['is_connected'] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkItem(String key, dynamic value) {
    IconData icon;
    Color iconColor;
    String displayValue = value.toString();

    switch (key) {
      case 'connectivity_type':
        icon = _getConnectivityIcon(displayValue);
        iconColor = _getConnectivityColor(displayValue);
        displayValue = _formatConnectivityType(displayValue);
        break;
      case 'is_connected':
        icon = value ? Icons.check_circle : Icons.cancel;
        iconColor = value ? Colors.green : Colors.red;
        displayValue = value ? 'Yes' : 'No';
        break;
      case 'api_endpoints':
        icon = _getEndpointIcon(displayValue);
        iconColor = _getEndpointColor(displayValue);
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
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
              _formatValue(displayValue, key),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Test Connection'),
            onPressed: () => _testConnection(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.speed, size: 16),
            label: const Text('Speed Test'),
            onPressed: () => _runSpeedTest(context),
          ),
        ),
      ],
    );
  }

  IconData _getConnectivityIcon(String type) {
    if (type.contains('wifi') || type.contains('WiFi')) {
      return Icons.wifi;
    } else if (type.contains('mobile') || type.contains('cellular')) {
      return Icons.signal_cellular_4_bar;
    } else if (type.contains('none')) {
      return Icons.signal_cellular_off;
    } else {
      return Icons.device_unknown;
    }
  }

  Color _getConnectivityColor(String type) {
    if (type.contains('none')) {
      return Colors.red;
    } else if (type.contains('wifi') || type.contains('WiFi')) {
      return Colors.green;
    } else if (type.contains('mobile') || type.contains('cellular')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  IconData _getEndpointIcon(String status) {
    if (status.contains('reachable')) {
      return Icons.cloud_done;
    } else if (status.contains('testing')) {
      return Icons.cloud_sync;
    } else {
      return Icons.cloud_off;
    }
  }

  Color _getEndpointColor(String status) {
    if (status.contains('reachable')) {
      return Colors.green;
    } else if (status.contains('testing')) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  String _formatValue(String value, String key) {
    if (key == 'last_check' || key == 'last_change') {
      return _formatTimestamp(value);
    }
    return value;
  }

  String _formatConnectivityType(String type) {
    if (type.contains('ConnectivityResult.')) {
      return type
          .replaceAll('ConnectivityResult.', '')
          .replaceAll('[', '')
          .replaceAll(']', '');
    }
    return type;
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
      } else {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  void _testConnection(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connection...'),
          ],
        ),
      ),
    );

    // Simulate connection test
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context);

      final isConnected = networkStatus['is_connected'] ?? false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected
                ? 'Connection test successful'
                : 'Connection test failed',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _runSpeedTest(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running speed test...'),
            SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    // Simulate speed test
    await Future.delayed(const Duration(seconds: 4));

    if (context.mounted) {
      Navigator.pop(context);

      // Mock speed test results
      final downloadSpeed = (10 + (DateTime.now().millisecond % 40)).toString();
      final uploadSpeed = (5 + (DateTime.now().millisecond % 20)).toString();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Speed Test Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Download:'),
                  Text('$downloadSpeed Mbps'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upload:'),
                  Text('$uploadSpeed Mbps'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
