import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/wallet_screen/widgets/earnings_stats_widget.dart

class EarningsStatsWidget extends StatefulWidget {
  final Map<String, int> dailyEarnings;
  final Map<String, int> weeklyEarnings;
  final Map<String, int> monthlyEarnings;

  const EarningsStatsWidget({
    super.key,
    required this.dailyEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
  });

  @override
  State<EarningsStatsWidget> createState() => _EarningsStatsWidgetState();
}

class _EarningsStatsWidgetState extends State<EarningsStatsWidget> {
  String _selectedPeriod = 'Daily';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings Statistics',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          SizedBox(height: 3.h),
          _buildStatsCards(),
          SizedBox(height: 3.h),
          SizedBox(
            height: 200,
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Daily', 'Weekly', 'Monthly'].map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                period,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards() {
    final currentData = _getCurrentData();
    final total = currentData.values.fold(0, (sum, value) => sum + value);
    final average = currentData.isNotEmpty ? total / currentData.length : 0;
    final max = currentData.isNotEmpty
        ? currentData.values.reduce((a, b) => a > b ? a : b)
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total', total.toString(), 'monetization_on'),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
              'Average', average.toStringAsFixed(1), 'trending_up'),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard('Best Day', max.toString(), 'star'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String iconName) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            size: 20,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final data = _getCurrentData();
    final spots = data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      return FlSpot(index.toDouble(), entry.value.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final keys = data.keys.toList();
                if (value.toInt() < keys.length) {
                  return Text(
                    keys[value.toInt()],
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.lightTheme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: AppTheme.lightTheme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getCurrentData() {
    switch (_selectedPeriod) {
      case 'Weekly':
        return widget.weeklyEarnings;
      case 'Monthly':
        return widget.monthlyEarnings;
      case 'Daily':
      default:
        return widget.dailyEarnings;
    }
  }
}
