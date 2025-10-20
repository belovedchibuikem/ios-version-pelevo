import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../core/routes/app_routes.dart';

// lib/presentation/debug_screen/widgets/navigation_diagnostics_widget.dart

class NavigationDiagnosticsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> navigationEvents;
  final Function(String route, String action) onTrackEvent;

  const NavigationDiagnosticsWidget({
    super.key,
    required this.navigationEvents,
    required this.onTrackEvent,
  });

  @override
  State<NavigationDiagnosticsWidget> createState() =>
      _NavigationDiagnosticsWidgetState();
}

class _NavigationDiagnosticsWidgetState
    extends State<NavigationDiagnosticsWidget> {
  final Map<String, bool> _routeHealth = {};

  @override
  void initState() {
    super.initState();
    _checkRouteHealth();
  }

  void _checkRouteHealth() {
    final routes = AppRoutes.routes.keys.toList();

    setState(() {
      for (final route in routes) {
        _routeHealth[route] = true; // Assume healthy by default
      }
    });
  }

  void _testRoute(String route) {
    widget.onTrackEvent(route, 'test_navigation');

    try {
      // Test route navigation (we won't actually navigate in debug mode)
      final routeExists = AppRoutes.routes.containsKey(route);

      setState(() {
        _routeHealth[route] = routeExists;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            routeExists
                ? 'Route $route is accessible'
                : 'Route $route not found',
          ),
          backgroundColor: routeExists ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _routeHealth[route] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing route $route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Stack Info
          _buildNavigationStackCard(),
          const SizedBox(height: 16),

          // Route Health Check
          _buildRouteHealthCard(),
          const SizedBox(height: 16),

          // Recent Navigation Events
          _buildNavigationEventsCard(),
        ],
      ),
    );
  }

  Widget _buildNavigationStackCard() {
    final canPop = Navigator.of(context).canPop();
    final currentRoute = ModalRoute.of(context)?.settings.name ?? 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.alt_route,
                  color: AppTheme.lightTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Navigation Stack',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Current Route', currentRoute),
            _buildInfoRow('Can Pop', canPop ? 'Yes' : 'No'),
            _buildInfoRow('Stack Depth', canPop ? '2+' : '1'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  onPressed: () {
                    setState(() {});
                    widget.onTrackEvent('debug_screen', 'navigation_refresh');
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.home, size: 16),
                  label: const Text('Go Home'),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.homeScreen,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHealthCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: AppTheme.lightTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Route Health Check',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _checkRouteHealth,
                  child: const Text('Check All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...AppRoutes.routes.keys
                .map((route) => _buildRouteHealthItem(route)),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHealthItem(String route) {
    final isHealthy = _routeHealth[route] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              route,
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 16),
            onPressed: () => _testRoute(route),
            tooltip: 'Test route',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationEventsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: AppTheme.lightTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Navigation Events',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${widget.navigationEvents.length} events',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.navigationEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No navigation events recorded'),
                ),
              )
            else
              Column(
                children: widget.navigationEvents
                    .take(10)
                    .map((event) => _buildNavigationEventItem(event))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationEventItem(Map<String, dynamic> event) {
    final route = event['route'] ?? 'Unknown';
    final action = event['action'] ?? 'Unknown';
    final timestamp = event['timestamp'] ?? '';

    Color actionColor;
    IconData actionIcon;

    switch (action) {
      case 'tap':
        actionColor = Colors.blue;
        actionIcon = Icons.touch_app;
        break;
      case 'test_navigation':
        actionColor = Colors.orange;
        actionIcon = Icons.bug_report;
        break;
      case 'navigation_refresh':
        actionColor = Colors.green;
        actionIcon = Icons.refresh;
        break;
      default:
        actionColor = Colors.grey;
        actionIcon = Icons.navigation;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            actionIcon,
            color: actionColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              route,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              action,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: actionColor,
              ),
            ),
          ),
          Text(
            _formatEventTime(timestamp),
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label:',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatEventTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
