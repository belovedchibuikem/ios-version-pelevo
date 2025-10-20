import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/wallet_screen/widgets/withdrawal_section_widget.dart

class WithdrawalSectionWidget extends StatefulWidget {
  final double conversionRate;
  final int currentCoins;
  final bool isEligible;
  final void Function(double amount, String method) onWithdrawTap;

  const WithdrawalSectionWidget({
    super.key,
    required this.conversionRate,
    required this.currentCoins,
    required this.isEligible,
    required this.onWithdrawTap,
  });

  @override
  State<WithdrawalSectionWidget> createState() =>
      _WithdrawalSectionWidgetState();
}

class _WithdrawalSectionWidgetState extends State<WithdrawalSectionWidget> {
  String selectedMethod = 'Bank Transfer';
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showWithdrawalDialog() {
    final withdrawableAmount = (widget.currentCoins * widget.conversionRate);
    _amountController.text = withdrawableAmount.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Withdraw Funds',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available: ₦${withdrawableAmount.toStringAsFixed(2)}',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Amount',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      prefixText: '₦',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Withdrawal Method',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items:
                        ['Bank Transfer', 'Mobile Money'].map((String method) {
                      return DropdownMenuItem<String>(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedMethod = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    if (amount > 0 && amount <= withdrawableAmount) {
                      Navigator.of(context).pop();
                      widget.onWithdrawTap(amount, selectedMethod);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.error,
                        ),
                      );
                    }
                  },
                  child: Text('Withdraw'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final minThreshold = 1000; // Minimum coins required for withdrawal
    final withdrawableAmount = (widget.currentCoins * widget.conversionRate);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(6.w),
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
            children: [
              CustomIconWidget(
                iconName: 'account_balance',
                size: 24,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(width: 3.w),
              Text(
                'Withdrawal Options',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildThresholdInfo(context, minThreshold),
          SizedBox(height: 3.h),
          if (widget.isEligible)
            ..._buildEligibleContent(context, withdrawableAmount),
          if (!widget.isEligible) _buildGeoRestrictedContent(context),
        ],
      ),
    );
  }

  Widget _buildThresholdInfo(BuildContext context, int minThreshold) {
    final isAboveThreshold = widget.currentCoins >= minThreshold;
    final progress = widget.currentCoins / minThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Minimum Threshold',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            Text(
              '$minThreshold coins',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        LinearProgressIndicator(
          value: progress > 1.0 ? 1.0 : progress,
          backgroundColor:
              AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(
            isAboveThreshold
                ? AppTheme.lightTheme.colorScheme.tertiary
                : AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          isAboveThreshold
              ? 'You can withdraw your earnings!'
              : 'Earn ${minThreshold - widget.currentCoins} more coins to withdraw',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: isAboveThreshold
                ? AppTheme.lightTheme.colorScheme.tertiary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEligibleContent(
      BuildContext context, double withdrawableAmount) {
    return [
      Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color:
              AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              size: 24,
              color: AppTheme.lightTheme.colorScheme.tertiary,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available for Withdrawal',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₦${withdrawableAmount.toStringAsFixed(2)}',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 3.h),
      Text(
        'Withdrawal Methods',
        style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 2.h),
      _buildWithdrawalMethod(
        'Bank Transfer',
        'Transfer directly to your bank account',
        'account_balance',
      ),
      SizedBox(height: 2.h),
      _buildWithdrawalMethod(
        'Mobile Money',
        'Withdraw via mobile money services',
        'phone_android',
      ),
      SizedBox(height: 3.h),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.currentCoins >= 1000 ? _showWithdrawalDialog : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 2.h),
          ),
          child: Text('Withdraw Funds'),
        ),
      ),
    ];
  }

  Widget _buildWithdrawalMethod(
      String title, String description, String iconName) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              size: 20,
              color: AppTheme.lightTheme.colorScheme.primary,
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
        ],
      ),
    );
  }

  Widget _buildGeoRestrictedContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'location_off',
            size: 48,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'Withdrawal Not Available',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Earnings withdrawal is currently only available for users in Nigeria. Continue listening to earn coins!',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
