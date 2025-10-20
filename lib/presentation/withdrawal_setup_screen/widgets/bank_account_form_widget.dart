import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/withdrawal_setup_screen/widgets/bank_account_form_widget.dart

class BankAccountFormWidget extends StatelessWidget {
  final TextEditingController accountNumberController;
  final TextEditingController accountNameController;
  final String? selectedBank;
  final List<String> banks;
  final bool isLoading;
  final bool accountVerified;
  final ValueChanged<String?> onBankChanged;
  final ValueChanged<String> onAccountNumberChanged;
  final VoidCallback onVerifyAccount;

  const BankAccountFormWidget({
    super.key,
    required this.accountNumberController,
    required this.accountNameController,
    required this.selectedBank,
    required this.banks,
    required this.isLoading,
    required this.accountVerified,
    required this.onBankChanged,
    required this.onAccountNumberChanged,
    required this.onVerifyAccount,
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
                iconName: 'account_balance',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Bank Account Details',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Account Number Field
          Text(
            'Account Number',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: accountNumberController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: 'Enter 10-digit account number',
              counterText: '',
              suffixIcon: accountVerified
                  ? CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      size: 20,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: onAccountNumberChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter account number';
              }
              if (value.length != 10) {
                return 'Account number must be 10 digits';
              }
              return null;
            },
          ),

          SizedBox(height: 3.h),

          // Bank Selection
          Text(
            'Select Bank',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            value: selectedBank,
            hint: Text(
              'Choose your bank',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            items: banks.map((String bank) {
              return DropdownMenuItem<String>(
                value: bank,
                child: Text(
                  bank,
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onBankChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your bank';
              }
              return null;
            },
          ),

          SizedBox(height: 3.h),

          // Account Name Field
          Text(
            'Account Name',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: accountNameController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Account name will appear after verification',
              filled: true,
              fillColor: accountVerified
                  ? AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: accountVerified
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: accountVerified ? FontWeight.w600 : FontWeight.w400,
            ),
          ),

          SizedBox(height: 3.h),

          // Verify Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: accountNumberController.text.length == 10 &&
                      selectedBank != null &&
                      !isLoading &&
                      !accountVerified
                  ? onVerifyAccount
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                backgroundColor: accountVerified
                    ? AppTheme.lightTheme.colorScheme.tertiary
                    : AppTheme.lightTheme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (accountVerified)
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 18,
                          ),
                        if (accountVerified) SizedBox(width: 2.w),
                        Text(
                          accountVerified
                              ? 'Account Verified'
                              : 'Verify Account',
                          style: AppTheme.lightTheme.textTheme.labelLarge
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (accountVerified) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.tertiary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'verified',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Account verification successful. Your withdrawal will be processed to this account.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
