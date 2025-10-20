import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/withdrawal_setup_screen/widgets/withdrawal_preferences_widget.dart

class WithdrawalPreferencesWidget extends StatelessWidget {
  final double minimumThreshold;
  final bool automaticWithdrawal;
  final String payoutFrequency;
  final ValueChanged<double> onThresholdChanged;
  final ValueChanged<bool> onAutomaticChanged;
  final ValueChanged<String> onFrequencyChanged;

  const WithdrawalPreferencesWidget({
    super.key,
    required this.minimumThreshold,
    required this.automaticWithdrawal,
    required this.payoutFrequency,
    required this.onThresholdChanged,
    required this.onAutomaticChanged,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Withdrawal Preferences',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Minimum Threshold Setting
          Text(
            'Minimum Withdrawal Amount',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₦${minimumThreshold.toStringAsFixed(0)}',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Minimum: ₦1,000',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
                    inactiveTrackColor: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                    thumbColor: AppTheme.lightTheme.colorScheme.primary,
                    overlayColor: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: minimumThreshold,
                    min: 1000,
                    max: 10000,
                    divisions: 18,
                    onChanged: onThresholdChanged,
                  ),
                ),
                Text(
                  'Set the minimum amount in your wallet before withdrawal is available',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Automatic Withdrawal Toggle
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: automaticWithdrawal
                  ? AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: automaticWithdrawal
                    ? AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.3)
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: automaticWithdrawal
                        ? AppTheme.lightTheme.colorScheme.tertiary
                        : AppTheme.lightTheme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'schedule',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automatic Withdrawal',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Automatically withdraw when threshold is reached',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: automaticWithdrawal,
                  onChanged: onAutomaticChanged,
                  activeColor: AppTheme.lightTheme.colorScheme.tertiary,
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Payout Frequency Selection
          Text(
            'Payout Frequency',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),

          Column(
            children: [
              _buildFrequencyOption(
                'Manual',
                'Withdraw manually when needed',
                'touch_app',
                payoutFrequency == 'Manual',
                () => onFrequencyChanged('Manual'),
              ),
              SizedBox(height: 2.h),
              _buildFrequencyOption(
                'Weekly',
                'Automatic weekly withdrawal (if threshold met)',
                'date_range',
                payoutFrequency == 'Weekly',
                () => onFrequencyChanged('Weekly'),
              ),
              SizedBox(height: 2.h),
              _buildFrequencyOption(
                'Monthly',
                'Automatic monthly withdrawal (if threshold met)',
                'calendar_today',
                payoutFrequency == 'Monthly',
                () => onFrequencyChanged('Monthly'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(
    String title,
    String description,
    String iconName,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.onPrimary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
