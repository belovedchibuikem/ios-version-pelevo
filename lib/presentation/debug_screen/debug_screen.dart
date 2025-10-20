import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
//import '../../services/ad_service.dart';
import './widgets/error_log_widget.dart';
import './widgets/framework_diagnostics_widget.dart';
import './widgets/memory_monitor_widget.dart';
import './widgets/navigation_diagnostics_widget.dart';
import './widgets/network_status_widget.dart';
import '../../core/routes/app_routes.dart';
import './widgets/system_status_widget.dart';
import '../../core/first_launch_service.dart';

// lib/presentation/debug_screen/debug_screen.dart

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _errorLogs = [];
  final List<Map<String, dynamic>> _navigationEvents = [];
  Map<String, dynamic> _systemStatus = {};
  Map<String, dynamic> _memoryStats = {};
  Map<String, dynamic> _networkStatus = {};
  bool _isMonitoring = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeDebugSession();
    _startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDebugSession() async {
    await _checkSystemStatus();
    await _checkNetworkStatus();
    await _collectMemoryStats();
    _logDebugEvent('Debug session started', DebugEventType.info);
  }

  void _startRealTimeMonitoring() {
    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      _updateNetworkStatus([result]);
    });

    // Periodic system checks
    Future.doWhile(() async {
      if (!_isMonitoring || !mounted) return false;
      await Future.delayed(const Duration(seconds: 5));
      await _collectMemoryStats();
      await _checkSystemStatus();
      return true;
    });
  }

  Future<void> _checkSystemStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      final isOnboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      final isAuthenticated = prefs.getBool('is_authenticated') ?? false;

      setState(() {
        _systemStatus = {
          'app_initialization': 'healthy',
          'shared_preferences': 'accessible',
          'first_launch_status':
              isFirstLaunch ? 'first_time' : 'returning_user',
          'onboarding_status': isOnboardingCompleted ? 'completed' : 'pending',
          'authentication_status':
              isAuthenticated ? 'authenticated' : 'not_authenticated',
          'theme_service': 'initialized',
          'navigation_service': 'active',
          'ad_service': 'checking...',
          'audio_service': 'checking...',
          'last_check': DateTime.now().toIso8601String(),
        };
      });

      // Check Ad Service
      /* try {
        await AdService().initialize();
        _systemStatus['ad_service'] = 'initialized';
      } catch (e) {
        _systemStatus['ad_service'] = 'failed: ${e.toString()}';
        _logDebugEvent('Ad Service Error: $e', DebugEventType.error);
      }*/

      // Check Audio Service
      try {
        AudioPlayerService();
        _systemStatus['audio_service'] = 'initialized';
      } catch (e) {
        _systemStatus['audio_service'] = 'failed: ${e.toString()}';
        _logDebugEvent('Audio Service Error: $e', DebugEventType.error);
      }

      if (mounted) setState(() {});
    } catch (e) {
      _logDebugEvent('System Status Check Failed: $e', DebugEventType.error);
    }
  }

  Future<void> _checkNetworkStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected =
          await Connectivity().checkConnectivity() != ConnectivityResult.none;

      setState(() {
        _networkStatus = {
          'connectivity_type': connectivityResult.toString(),
          'is_connected': isConnected,
          'api_endpoints': 'testing...',
          'last_check': DateTime.now().toIso8601String(),
        };
      });

      // Test API connectivity (mock for now)
      await Future.delayed(const Duration(seconds: 1));
      _networkStatus['api_endpoints'] =
          isConnected ? 'reachable' : 'unreachable';

      if (mounted) setState(() {});
    } catch (e) {
      _logDebugEvent('Network Status Check Failed: $e', DebugEventType.error);
    }
  }

  void _updateNetworkStatus(List<ConnectivityResult> result) {
    setState(() {
      _networkStatus['connectivity_type'] = result.toString();
      _networkStatus['last_change'] = DateTime.now().toIso8601String();
    });
    _logDebugEvent(
        'Network connectivity changed: $result', DebugEventType.info);
  }

  Future<void> _collectMemoryStats() async {
    try {
      setState(() {
        _memoryStats = {
          'widget_tree_depth': _calculateWidgetTreeDepth(),
          'navigation_stack_size': _getNavigationStackSize(),
          'error_count': _errorLogs.length,
          'navigation_events': _navigationEvents.length,
          'timestamp': DateTime.now().toIso8601String(),
        };
      });
    } catch (e) {
      _logDebugEvent(
          'Memory Stats Collection Failed: $e', DebugEventType.warning);
    }
  }

  int _calculateWidgetTreeDepth() {
    // Simplified widget tree depth calculation
    return context.widget.runtimeType.toString().length % 10 + 5;
  }

  int _getNavigationStackSize() {
    final navigator = Navigator.of(context);
    return navigator.canPop() ? 2 : 1; // Simplified calculation
  }

  void _logDebugEvent(String message, DebugEventType type) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] [${type.name.toUpperCase()}] $message';

    setState(() {
      _errorLogs.insert(0, logEntry);
      if (_errorLogs.length > 100) {
        _errorLogs.removeLast();
      }
    });

    // Also log to console
    switch (type) {
      case DebugEventType.error:
        debugPrint(message);
        break;
      case DebugEventType.warning:
        debugPrint(message);
        break;
      case DebugEventType.info:
        debugPrint(message);
        break;
      case DebugEventType.success:
        debugPrint(message);
        break;
    }
  }

  Future<Map<String, bool>> _getOnboardingState() async {
    return {
      'isFirstLaunch': await FirstLaunchService.isFirstLaunch(),
      'isOnboardingCompleted': await FirstLaunchService.isOnboardingCompleted(),
      'isOnboardingSkipped': await FirstLaunchService.isOnboardingSkipped(),
    };
  }

  Widget _buildStateRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _trackNavigationEvent(String route, String action) {
    setState(() {
      _navigationEvents.insert(0, {
        'route': route,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (_navigationEvents.length > 50) {
        _navigationEvents.removeLast();
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _errorLogs.clear();
      _navigationEvents.clear();
    });
    _logDebugEvent('Debug logs cleared', DebugEventType.info);
  }

  Future<void> _exportDebugReport() async {
    try {
      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'system_status': _systemStatus,
        'network_status': _networkStatus,
        'memory_stats': _memoryStats,
        'error_logs': _errorLogs.take(20).toList(),
        'navigation_events': _navigationEvents.take(20).toList(),
      };

      // Copy to clipboard for now (in a real app, you might use share functionality)
      await Clipboard.setData(ClipboardData(text: report.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Debug report copied to clipboard'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      _logDebugEvent('Export failed: $e', DebugEventType.error);
    }
  }

  void _resetApp() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Reset App State'),
                content: const Text(
                    'This will clear all app data and restart from splash screen. Are you sure?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, AppRoutes.initial, (route) => false);
                        }
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: Colors.red))),
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Debug Screen'),
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
            actions: [
              IconButton(
                  icon: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _isMonitoring = !_isMonitoring;
                    });
                    _logDebugEvent(
                        _isMonitoring
                            ? 'Monitoring resumed'
                            : 'Monitoring paused',
                        DebugEventType.info);
                  }),
              PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'clear':
                        _clearLogs();
                        break;
                      case 'export':
                        _exportDebugReport();
                        break;
                      case 'reset':
                        _resetApp();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'clear',
                            child: Row(children: [
                              Icon(Icons.clear_all),
                              SizedBox(width: 8),
                              Text('Clear Logs'),
                            ])),
                        const PopupMenuItem(
                            value: 'export',
                            child: Row(children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Export Report'),
                            ])),
                        const PopupMenuItem(
                            value: 'reset',
                            child: Row(children: [
                              Icon(Icons.restart_alt, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Reset App',
                                  style: TextStyle(color: Colors.red)),
                            ])),
                      ]),
            ],
            bottom: TabBar(controller: _tabController, tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Status'),
              Tab(icon: Icon(Icons.bug_report), text: 'Logs'),
              Tab(icon: Icon(Icons.navigation), text: 'Navigation'),
              Tab(icon: Icon(Icons.memory), text: 'Performance'),
              Tab(icon: Icon(Icons.play_arrow), text: 'Onboarding'),
            ])),
        body: TabBarView(controller: _tabController, children: [
          // System Status Tab
          SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                SystemStatusWidget(systemStatus: _systemStatus),
                const SizedBox(height: 16),
                NetworkStatusWidget(networkStatus: _networkStatus),
                const SizedBox(height: 16),
                FrameworkDiagnosticsWidget(onRunDiagnostics: () {
                  _logDebugEvent(
                      'Framework diagnostics initiated', DebugEventType.info);
                  _checkSystemStatus();
                }),
              ])),
          // Error Logs Tab
          ErrorLogWidget(
              errorLogs: _errorLogs,
              onRefresh: () {
                _logDebugEvent(
                    'Error logs refreshed manually', DebugEventType.info);
              }),
          // Navigation Diagnostics Tab
          NavigationDiagnosticsWidget(
              navigationEvents: _navigationEvents,
              onTrackEvent: _trackNavigationEvent),
          // Performance Tab
          MemoryMonitorWidget(
              memoryStats: _memoryStats, onRefresh: _collectMemoryStats),
          // Onboarding Test Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onboarding Flow Test',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Onboarding Flow',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reset the onboarding state to test the first launch flow on new device installations.',
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirstLaunchService.forceFirstLaunch();
                                  _logDebugEvent('Forced first launch state',
                                      DebugEventType.success);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'First launch state set. Restart app to see onboarding.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Force First Launch'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await FirstLaunchService
                                      .resetOnboardingState();
                                  _logDebugEvent('Reset onboarding state',
                                      DebugEventType.success);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Onboarding state reset. Restart app to see onboarding.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset Onboarding'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await FirstLaunchService.resetFirstLaunch();
                            _logDebugEvent('Reset all first launch data',
                                DebugEventType.success);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'All first launch data reset. Restart app to see onboarding.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Reset All First Launch Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final serviceManager =
                                  Provider.of<ServiceManager>(context,
                                      listen: false);
                              final notificationService =
                                  await serviceManager.notificationsSafe;
                              if (notificationService != null) {
                                await notificationService.requestPermissions();
                                final granted = await notificationService
                                    .areNotificationsEnabled();
                                _logDebugEvent(
                                    'iOS notification permission result: $granted',
                                    DebugEventType.info);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'iOS notification permission: ${granted ? "Granted" : "Denied"}'),
                                    backgroundColor:
                                        granted ? Colors.green : Colors.orange,
                                  ),
                                );
                              } else {
                                _logDebugEvent(
                                    'Notification service not available',
                                    DebugEventType.warning);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Notification service not available'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              _logDebugEvent(
                                  'Error testing iOS notifications: $e',
                                  DebugEventType.error);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications),
                          label: const Text('Test iOS Notifications'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current State',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, bool>>(
                          future: _getOnboardingState(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final state = snapshot.data!;
                              return Column(
                                children: [
                                  _buildStateRow('First Launch',
                                      state['isFirstLaunch'] ?? false),
                                  _buildStateRow('Onboarding Completed',
                                      state['isOnboardingCompleted'] ?? false),
                                  _buildStateRow('Onboarding Skipped',
                                      state['isOnboardingSkipped'] ?? false),
                                ],
                              );
                            }
                            return const CircularProgressIndicator();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
        floatingActionButton: FloatingActionButton(
            onPressed: _exportDebugReport,
            tooltip: 'Export Debug Report',
            child: const Icon(Icons.file_download)));
  }
}

enum DebugEventType {
  info,
  warning,
  error,
  success,
}
