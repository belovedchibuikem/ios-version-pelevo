import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/debug_screen/widgets/memory_monitor_widget.dart

class MemoryMonitorWidget extends StatefulWidget {
  final Map<String, dynamic> memoryStats;
  final VoidCallback onRefresh;

  const MemoryMonitorWidget({
    super.key,
    required this.memoryStats,
    required this.onRefresh,
  });

  @override
  State<MemoryMonitorWidget> createState() => _MemoryMonitorWidgetState();
}

class _MemoryMonitorWidgetState extends State<MemoryMonitorWidget> {
  final List<FlSpot> _widgetTreeData = [];
  final List<FlSpot> _navigationData = [];
  final List<FlSpot> _errorData = [];
  int _dataPoints = 0;

  @override
  void initState() {
    super.initState();
    _updateChartData();
  }

  @override
  void didUpdateWidget(MemoryMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memoryStats != widget.memoryStats) {
      _updateChartData();
    }
  }

  void _updateChartData() {
    _dataPoints++;
    final x = _dataPoints.toDouble();

    final widgetTreeDepth =
        widget.memoryStats['widget_tree_depth']?.toDouble() ?? 0;
    final navigationStackSize =
        widget.memoryStats['navigation_stack_size']?.toDouble() ?? 0;
    final errorCount = widget.memoryStats['error_count']?.toDouble() ?? 0;

    setState(() {
      _widgetTreeData.add(FlSpot(x, widgetTreeDepth));
      _navigationData.add(FlSpot(x, navigationStackSize));
      _errorData.add(FlSpot(x, errorCount));

      // Keep only last 20 data points
      if (_widgetTreeData.length > 20) {
        _widgetTreeData.removeAt(0);
        _navigationData.removeAt(0);
        _errorData.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance Metrics Cards
          _buildMetricsGrid(),
          const SizedBox(height: 16),

          // Performance Chart
          _buildPerformanceChart(),
          const SizedBox(height: 16),

          // Memory Analysis
          _buildMemoryAnalysis(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Widget Tree',
          '${widget.memoryStats['widget_tree_depth'] ?? 0}',
          'levels deep',
          Icons.account_tree,
          Colors.blue,
        ),
        _buildMetricCard(
          'Navigation',
          '${widget.memoryStats['navigation_stack_size'] ?? 0}',
          'screens',
          Icons.layers,
          Colors.green,
        ),
        _buildMetricCard(
          'Errors',
          '${widget.memoryStats['error_count'] ?? 0}',
          'logged',
          Icons.error_outline,
          Colors.red,
        ),
        _buildMetricCard(
          'Events',
          '${widget.memoryStats['navigation_events'] ?? 0}',
          'tracked',
          Icons.timeline,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: AppTheme.lightTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Trend',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: widget.onRefresh,
                  tooltip: 'Refresh data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _widgetTreeData.isEmpty
                  ? const Center(
                      child: Text('No data available'),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          drawHorizontalLine: true,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _widgetTreeData,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: _navigationData,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: _errorData,
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Widget Tree', Colors.blue),
                _buildLegendItem('Navigation', Colors.green),
                _buildLegendItem('Errors', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMemoryAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppTheme.lightTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Analysis',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnalysisItem(
              'Widget Tree Depth',
              _getWidgetTreeAnalysis(),
              _getWidgetTreeHealthIcon(),
            ),
            _buildAnalysisItem(
              'Navigation Stack',
              _getNavigationAnalysis(),
              _getNavigationHealthIcon(),
            ),
            _buildAnalysisItem(
              'Error Rate',
              _getErrorAnalysis(),
              _getErrorHealthIcon(),
            ),
            const SizedBox(height: 16),
            // Recommendations
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String title, String analysis, Widget icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  analysis,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _getRecommendations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _getWidgetTreeAnalysis() {
    final depth = widget.memoryStats['widget_tree_depth'] ?? 0;
    if (depth < 8) return 'Optimal depth, good performance';
    if (depth < 15) return 'Moderate depth, monitor for issues';
    return 'Deep nesting detected, consider optimization';
  }

  Widget _getWidgetTreeHealthIcon() {
    final depth = widget.memoryStats['widget_tree_depth'] ?? 0;
    if (depth < 8) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    if (depth < 15) {
      return const Icon(Icons.warning, color: Colors.orange, size: 20);
    }
    return const Icon(Icons.error, color: Colors.red, size: 20);
  }

  String _getNavigationAnalysis() {
    final size = widget.memoryStats['navigation_stack_size'] ?? 0;
    if (size <= 3) return 'Normal navigation stack';
    if (size <= 7) return 'Growing stack, check for leaks';
    return 'Large stack detected, possible memory leak';
  }

  Widget _getNavigationHealthIcon() {
    final size = widget.memoryStats['navigation_stack_size'] ?? 0;
    if (size <= 3) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    if (size <= 7) {
      return const Icon(Icons.warning, color: Colors.orange, size: 20);
    }
    return const Icon(Icons.error, color: Colors.red, size: 20);
  }

  String _getErrorAnalysis() {
    final errors = widget.memoryStats['error_count'] ?? 0;
    if (errors == 0) return 'No errors detected';
    if (errors < 5) return 'Few errors, investigate if recurring';
    return 'Multiple errors detected, needs attention';
  }

  Widget _getErrorHealthIcon() {
    final errors = widget.memoryStats['error_count'] ?? 0;
    if (errors == 0) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    if (errors < 5) {
      return const Icon(Icons.warning, color: Colors.orange, size: 20);
    }
    return const Icon(Icons.error, color: Colors.red, size: 20);
  }

  List<String> _getRecommendations() {
    final recommendations = <String>[];

    final depth = widget.memoryStats['widget_tree_depth'] ?? 0;
    final navSize = widget.memoryStats['navigation_stack_size'] ?? 0;
    final errors = widget.memoryStats['error_count'] ?? 0;

    if (depth > 10) {
      recommendations
          .add('Consider flattening widget hierarchy to improve performance');
    }

    if (navSize > 5) {
      recommendations
          .add('Review navigation patterns to prevent stack overflow');
    }

    if (errors > 3) {
      recommendations.add('Address recurring errors to improve app stability');
    }

    if (recommendations.isEmpty) {
      recommendations.add('App performance looks good!');
    }

    return recommendations;
  }
}
