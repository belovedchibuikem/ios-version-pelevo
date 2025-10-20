import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/confirmation_button_widget.dart';
import './widgets/security_verification_widget.dart';
import './widgets/terms_agreement_widget.dart';
import './widgets/withdrawal_summary_widget.dart';
import '../../core/routes/app_routes.dart';

// lib/presentation/withdrawal_confirmation_screen/withdrawal_confirmation_screen.dart

class WithdrawalConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> withdrawalData;

  const WithdrawalConfirmationScreen({
    super.key,
    required this.withdrawalData,
  });

  @override
  State<WithdrawalConfirmationScreen> createState() =>
      _WithdrawalConfirmationScreenState();
}

class _WithdrawalConfirmationScreenState
    extends State<WithdrawalConfirmationScreen> with TickerProviderStateMixin {
  final NavigationService _navigationService = NavigationService();
  int _selectedTabIndex = 3; // Wallet tab is index 3

  // Security verification
  final TextEditingController _pinController = TextEditingController();
  bool _termsAccepted = false;
  bool _isProcessing = false;
  bool _pinVerified = false;
  bool _showPinError = false;

  // Mock data
  final double _currentCoins = 2458.50;
  final double _exchangeRate = 1650.0; // 1 USD = 1650 NGN
  final double _processingFee = 25.0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _navigationService.trackNavigation(AppRoutes.withdrawalConfirmationScreen);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    switch (index) {
      case 0:
        _navigationService.navigateTo(AppRoutes.homeScreen);
        break;
      case 1:
        _navigationService.navigateTo(AppRoutes.earnScreen);
        break;
      case 2:
        _navigationService.navigateTo(AppRoutes.libraryScreen);
        break;
      case 3:
        _navigationService.navigateTo(AppRoutes.walletScreen);
        break;
      case 4:
        _navigationService.navigateTo(AppRoutes.profileScreen);
        break;
    }
  }

  void _verifyPin() {
    setState(() {
      _showPinError = false;
    });

    // Mock PIN verification (demo PIN: 1234)
    if (_pinController.text == '1234') {
      setState(() {
        _pinVerified = true;
      });
      HapticFeedback.lightImpact();
      _showSnackBar('PIN verified successfully');
    } else {
      setState(() {
        _showPinError = true;
      });
      HapticFeedback.vibrate();
      _showSnackBar('Invalid PIN. Please try again.', isError: true);
    }
  }

  Future<void> _processWithdrawal() async {
    if (!_pinVerified || !_termsAccepted) {
      _showSnackBar('Please complete security verification and accept terms',
          isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Mock processing delay
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isProcessing = false;
    });

    HapticFeedback.heavyImpact();

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  size: 48,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Withdrawal Successful!',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                'Your withdrawal request has been submitted successfully.',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Transaction Reference',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigationService
                    .navigateTo(AppRoutes.withdrawalHistoryScreen);
              },
              child: Text(
                'View History',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigationService.navigateTo(AppRoutes.walletScreen);
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalAmount = widget.withdrawalData['amount'] ?? 1000.0;
    final nairaAmount = withdrawalAmount * _exchangeRate;
    final finalAmount = nairaAmount - _processingFee;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Confirm Withdrawal',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => _navigationService.goBack(),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'security',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              _showSecurityInfo();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    children: [
                      // Withdrawal Summary
                      WithdrawalSummaryWidget(
                        withdrawalAmount: withdrawalAmount,
                        currentCoins: _currentCoins,
                        exchangeRate: _exchangeRate,
                        nairaAmount: nairaAmount,
                        processingFee: _processingFee,
                        finalAmount: finalAmount,
                        bankDetails: widget.withdrawalData,
                      ),

                      SizedBox(height: 3.h),

                      // Security Verification
                      SecurityVerificationWidget(
                        pinController: _pinController,
                        pinVerified: _pinVerified,
                        showPinError: _showPinError,
                        onVerifyPin: _verifyPin,
                      ),

                      SizedBox(height: 3.h),

                      // Terms Agreement
                      TermsAgreementWidget(
                        termsAccepted: _termsAccepted,
                        onTermsChanged: (value) {
                          setState(() {
                            _termsAccepted = value;
                          });
                        },
                      ),

                      SizedBox(height: 4.h),

                      // Confirmation Button
                      ConfirmationButtonWidget(
                        isEnabled: _pinVerified && _termsAccepted,
                        isProcessing: _isProcessing,
                        onPressed: _processWithdrawal,
                      ),

                      SizedBox(height: 12.h), // Space for bottom navigation
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CommonBottomNavigationWidget(
              currentIndex: _selectedTabIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Security Information',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSecurityItem(
                'PIN Verification',
                'Your transaction PIN is required to authorize withdrawals.',
                'lock',
              ),
              SizedBox(height: 2.h),
              _buildSecurityItem(
                'Secure Processing',
                'All transactions are encrypted and processed through secure banking channels.',
                'security',
              ),
              SizedBox(height: 2.h),
              _buildSecurityItem(
                'Processing Time',
                'Bank transfers typically take 1-3 business days to complete.',
                'schedule',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityItem(String title, String description, String iconName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 16,
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
    );
  }
}
