import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../core/navigation_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/performance_dashboard.dart';
import '../../widgets/common_bottom_navigation_widget.dart';

class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  State<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends State<PerformanceDashboardScreen> {
  final NavigationService _navigationService = NavigationService();

  @override
  void initState() {
    super.initState();
    _navigationService.trackNavigation(AppRoutes.performanceDashboardScreen);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: currentTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Performance Dashboard',
          style: currentTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: currentTheme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: currentTheme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => _navigationService.goBack(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: currentTheme.colorScheme.onSurface,
            ),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'About Performance Dashboard',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            margin: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: currentTheme.colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    currentTheme.colorScheme.primaryContainer.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: currentTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Monitor your app\'s performance, memory usage, and system health in real-time.',
                    style: currentTheme.textTheme.bodyMedium?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Performance Dashboard Widget
          Expanded(
            child: PerformanceDashboard(
              showDetailedMetrics: true,
              onRefresh: () {
                // The PerformanceDashboard widget handles its own refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Performance data refreshed'),
                    backgroundColor: currentTheme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final currentTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Performance Dashboard',
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This dashboard provides real-time monitoring of:',
                style: currentTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              _buildInfoItem(
                  '📊 System Performance', 'CPU, memory, and battery usage'),
              _buildInfoItem('🔍 Memory Management',
                  'Memory allocation and garbage collection'),
              _buildInfoItem(
                  '⚠️ Error Tracking', 'App errors and performance warnings'),
              _buildInfoItem(
                  '📱 Device Health', 'Overall system health status'),
              SizedBox(height: 2.h),
              Text(
                'Use this dashboard to identify performance issues and optimize your app experience.',
                style: currentTheme.textTheme.bodySmall?.copyWith(
                  color: currentTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
