import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/debug_screen/widgets/framework_diagnostics_widget.dart

class FrameworkDiagnosticsWidget extends StatefulWidget {
  final VoidCallback onRunDiagnostics;

  const FrameworkDiagnosticsWidget({
    super.key,
    required this.onRunDiagnostics,
  });

  @override
  State<FrameworkDiagnosticsWidget> createState() =>
      _FrameworkDiagnosticsWidgetState();
}

class _FrameworkDiagnosticsWidgetState
    extends State<FrameworkDiagnosticsWidget> {
  Map<String, dynamic> _diagnostics = {};
  bool _isRunningDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _runFrameworkDiagnostics();
  }

  Future<void> _runFrameworkDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
    });

    try {
      final diagnostics = <String, dynamic>{};

      // Flutter version info
      diagnostics['flutter_version'] = 'Flutter 3.16.0';
      diagnostics['dart_version'] = 'Dart 3.2.0';

      // Debug mode info
      diagnostics['debug_mode'] = kDebugMode;
      diagnostics['profile_mode'] = kProfileMode;
      diagnostics['release_mode'] = kReleaseMode;

      // Platform info
      diagnostics['platform'] = Theme.of(context).platform.toString();

      // Widget inspector
      diagnostics['widget_inspector'] =
          kDebugMode ? 'Available' : 'Not available';

      // Performance overlay
      diagnostics['performance_overlay'] = 'Available';

      // Rendering info
      final mediaQuery = MediaQuery.of(context);
      diagnostics['screen_size'] =
          '${mediaQuery.size.width.toInt()}x${mediaQuery.size.height.toInt()}';
      diagnostics['device_pixel_ratio'] =
          mediaQuery.devicePixelRatio.toStringAsFixed(1);
      diagnostics['text_scale_factor'] =
          mediaQuery.textScaleFactor.toStringAsFixed(1);

      // Memory info (simplified)
      diagnostics['widget_count'] = _estimateWidgetCount();
      diagnostics['render_objects'] = _estimateRenderObjectCount();

      // Navigation info
      diagnostics['navigation_stack'] =
          Navigator.of(context).canPop() ? 'Multi-level' : 'Root level';

      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate diagnostic time

      setState(() {
        _diagnostics = diagnostics;
        _isRunningDiagnostics = false;
      });
    } catch (e) {
      setState(() {
        _diagnostics = {'error': 'Failed to run diagnostics: $e'};
        _isRunningDiagnostics = false;
      });
    }
  }

  int _estimateWidgetCount() {
    // This is a simplified estimation
    return (context.size?.width ?? 400).toInt() ~/ 10;
  }

  int _estimateRenderObjectCount() {
    // This is a simplified estimation
    return _estimateWidgetCount() ~/ 3;
  }

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
                  Icons.build,
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Framework Diagnostics',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                const Spacer(),
                if (_isRunningDiagnostics)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _runFrameworkDiagnostics();
                      widget.onRunDiagnostics();
                    },
                    tooltip: 'Run diagnostics',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_diagnostics.isEmpty && !_isRunningDiagnostics)
              const Center(
                child: Text('No diagnostics data available'),
              )
            else if (_isRunningDiagnostics)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ..._diagnostics.entries.map((entry) => _buildDiagnosticItem(
                    entry.key,
                    entry.value,
                  )),
            const SizedBox(height: 16),
            _buildDiagnosticActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticItem(String key, dynamic value) {
    IconData icon;
    Color iconColor;
    String displayValue = value.toString();

    switch (key) {
      case 'flutter_version':
      case 'dart_version':
        icon = Icons.code;
        iconColor = Colors.blue;
        break;
      case 'debug_mode':
      case 'profile_mode':
      case 'release_mode':
        icon =
            value == true ? Icons.check_circle : Icons.radio_button_unchecked;
        iconColor = value == true ? Colors.green : Colors.grey;
        displayValue = value == true ? 'Active' : 'Inactive';
        break;
      case 'widget_inspector':
        icon = displayValue.contains('Available')
            ? Icons.search
            : Icons.search_off;
        iconColor =
            displayValue.contains('Available') ? Colors.green : Colors.orange;
        break;
      case 'screen_size':
        icon = Icons.phone_android;
        iconColor = Colors.purple;
        break;
      case 'widget_count':
      case 'render_objects':
        icon = Icons.widgets;
        iconColor = Colors.teal;
        break;
      case 'navigation_stack':
        icon = Icons.layers;
        iconColor = Colors.indigo;
        break;
      case 'error':
        icon = Icons.error;
        iconColor = Colors.red;
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
              displayValue,
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

  Widget _buildDiagnosticActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Widget Inspector'),
                onPressed: kDebugMode ? _openWidgetInspector : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.speed, size: 16),
                label: const Text('Performance'),
                onPressed: _showPerformanceOverlay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.memory, size: 16),
                label: const Text('Memory Info'),
                onPressed: _showMemoryInfo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('Debug Info'),
                onPressed: _showDebugInfo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openWidgetInspector() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Widget Inspector is available in IDE when debugging'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPerformanceOverlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Overlay'),
        content: const Text(
          'Performance overlay shows frame rendering times and can be enabled in debug mode. '
          'Look for dropped frames (red bars) and optimize accordingly.',
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

  void _showMemoryInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Memory Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Estimated Widget Count: ${_diagnostics['widget_count'] ?? 'Unknown'}'),
            Text(
                'Estimated Render Objects: ${_diagnostics['render_objects'] ?? 'Unknown'}'),
            const SizedBox(height: 12),
            const Text(
              'Note: These are estimated values. Use Flutter DevTools for accurate memory profiling.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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

  void _showDebugInfo() {
    final debugInfo = {
      'Build Mode': kDebugMode
          ? 'Debug'
          : kReleaseMode
              ? 'Release'
              : 'Profile',
      'Assertions Enabled': kDebugMode.toString(),
      'Platform': Theme.of(context).platform.toString(),
      'Screen Metrics': _diagnostics['screen_size'] ?? 'Unknown',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: debugInfo.entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('${entry.key}: '),
                        Text(
                          entry.value,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ))
              .toList(),
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

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}
