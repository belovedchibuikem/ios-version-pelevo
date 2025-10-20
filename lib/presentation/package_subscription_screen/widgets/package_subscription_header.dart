import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class PackageSubscriptionHeader extends StatelessWidget {
  final Map<String, dynamic>? currentSubscription;
  final bool hasActiveSubscription;
  final String? currentPlanName;
  final DateTime? expiryDate;

  const PackageSubscriptionHeader({
    super.key,
    this.currentSubscription,
    required this.hasActiveSubscription,
    this.currentPlanName,
    this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasActiveSubscription ? Icons.star : Icons.star_border,
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  hasActiveSubscription
                      ? 'Active Subscription'
                      : 'No Active Subscription',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (hasActiveSubscription && currentPlanName != null) ...[
            Text(
              'Current Plan: $currentPlanName',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            if (expiryDate != null) ...[
              Text(
                'Expires: ${_formatDate(expiryDate!)}',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary
                      .withValues(alpha: 0.8),
                ),
              ),
            ],
          ] else ...[
            Text(
              'Upgrade to Premium for unlimited access',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
