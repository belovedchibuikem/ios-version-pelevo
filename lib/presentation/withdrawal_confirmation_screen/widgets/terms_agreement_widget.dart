import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/withdrawal_confirmation_screen/widgets/terms_agreement_widget.dart

class TermsAgreementWidget extends StatefulWidget {
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;

  const TermsAgreementWidget({
    super.key,
    required this.termsAccepted,
    required this.onTermsChanged,
  });

  @override
  State<TermsAgreementWidget> createState() => _TermsAgreementWidgetState();
}

class _TermsAgreementWidgetState extends State<TermsAgreementWidget> {
  bool _isExpanded = false;

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
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: widget.termsAccepted
                      ? AppTheme.lightTheme.colorScheme.tertiary
                          .withValues(alpha: 0.1)
                      : AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: widget.termsAccepted ? 'verified' : 'description',
                  color: widget.termsAccepted
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Please review and accept the withdrawal terms',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Terms Acceptance Checkbox
          GestureDetector(
            onTap: () => widget.onTermsChanged(!widget.termsAccepted),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: widget.termsAccepted
                    ? AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.termsAccepted
                      ? AppTheme.lightTheme.colorScheme.tertiary
                          .withValues(alpha: 0.3)
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: widget.termsAccepted,
                    onChanged: (bool? value) {
                      if (value != null) {
                        widget.onTermsChanged(value);
                      }
                    },
                    activeColor: AppTheme.lightTheme.colorScheme.tertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Withdrawal Terms',
                            style: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Expandable Terms Section
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'article',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _isExpanded ? 'Hide Terms' : 'Read Full Terms',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Terms Content
          if (_isExpanded) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Withdrawal Terms & Conditions',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildTermsItem(
                    '1. Processing Time',
                    'Bank transfers typically take 1-3 business days to complete. Processing times may vary during weekends and public holidays.',
                  ),
                  _buildTermsItem(
                    '2. Transaction Fees',
                    'A processing fee of ₦25 applies to all bank transfers. Mobile money transfers are subject to a 1.5% transaction fee.',
                  ),
                  _buildTermsItem(
                    '3. Minimum Withdrawal',
                    'The minimum withdrawal amount is ₦1,000. Ensure your account balance meets this threshold before initiating a withdrawal.',
                  ),
                  _buildTermsItem(
                    '4. Account Verification',
                    'Your bank account details must be verified before processing any withdrawal. Incorrect details may result in failed transactions.',
                  ),
                  _buildTermsItem(
                    '5. Cancellation Policy',
                    'Withdrawal requests cannot be cancelled once submitted. Please review all details carefully before confirming.',
                  ),
                  _buildTermsItem(
                    '6. Support',
                    'For any issues with your withdrawal, please contact our support team within 7 days of the transaction.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
