import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/wallet_screen/widgets/transaction_item_widget.dart

class TransactionItemWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionItemWidget({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(children: [
              Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.lightTheme.colorScheme.surfaceContainer),
                  child: CustomImageWidget(
                      imageUrl: transaction['imageUrl'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover)),
              SizedBox(width: 4.w),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(transaction['episodeTitle'] ?? '',
                        style: AppTheme.lightTheme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 1.h),
                    Text(transaction['podcastName'] ?? '',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant)),
                    SizedBox(height: 1.h),
                    Row(children: [
                      CustomIconWidget(
                          iconName: 'access_time',
                          size: 14,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant),
                      SizedBox(width: 1.w),
                      Text(transaction['timestamp'] ?? '',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme
                                      .onSurfaceVariant)),
                    ]),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _getStatusColor(transaction['status'])
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      CustomIconWidget(
                          iconName: 'monetization_on',
                          size: 16,
                          color: _getStatusColor(transaction['status'])),
                      SizedBox(width: 1.w),
                      Text('+${transaction['coins']}',
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                                  color: _getStatusColor(transaction['status']),
                                  fontWeight: FontWeight.w600)),
                    ])),
                SizedBox(height: 1.h),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _getStatusColor(transaction['status'])
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(_getStatusText(transaction['status']),
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                                color: _getStatusColor(transaction['status']),
                                fontWeight: FontWeight.w500))),
              ]),
            ])));
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'pending':
        return AppTheme.lightTheme.colorScheme.outline;
      case 'failed':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Earned';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}
