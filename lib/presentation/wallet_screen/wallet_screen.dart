import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import '../../widgets/coming_soon_widget.dart';
import './widgets/balance_card_widget.dart';
import './widgets/earnings_stats_widget.dart';
import './widgets/transaction_item_widget.dart';
import './widgets/withdrawal_section_widget.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/mini_player_positioning.dart';

// lib/presentation/wallet_screen/wallet_screen.dart

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  final NavigationService _navigationService = NavigationService();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Toggle for coming soon vs full functionality
  bool _showComingSoon = true; // Set to false to show full functionality

  // Mock wallet data
  final Map<String, dynamic> walletData = {
    'totalBalance': 2458.50,
    'todayEarnings': 45.75,
    'weeklyEarnings': 312.25,
    'monthlyEarnings': 1248.90,
    'pendingAmount': 125.00,
    'availableForWithdrawal': 2333.50,
  };

  // Mock earnings data
  final Map<String, int> dailyEarnings = {
    'Mon': 45,
    'Tue': 52,
    'Wed': 38,
    'Thu': 61,
    'Fri': 47,
    'Sat': 55,
    'Sun': 42,
  };

  final Map<String, int> weeklyEarnings = {
    'Week 1': 285,
    'Week 2': 312,
    'Week 3': 298,
    'Week 4': 341,
  };

  final Map<String, int> monthlyEarnings = {
    'Jan': 1248,
    'Feb': 1156,
    'Mar': 1389,
    'Apr': 1205,
    'May': 1432,
    'Jun': 1298,
  };

  // Mock transaction history
  final List<Map<String, dynamic>> transactions = [
    {
      'id': 'tx_001',
      'type': 'earning',
      'amount': 15.50,
      'description': 'Listened to "The Future of AI"',
      'date': '2024-01-20',
      'time': '14:30',
      'status': 'completed',
      'podcastTitle': 'TechTalk Weekly',
    },
    {
      'id': 'tx_002',
      'type': 'withdrawal',
      'amount': -50.00,
      'description': 'PayPal withdrawal',
      'date': '2024-01-19',
      'time': '09:15',
      'status': 'processing',
      'transactionId': 'WD-2024-001',
    },
    {
      'id': 'tx_003',
      'type': 'earning',
      'amount': 22.75,
      'description': 'Listened to "Sustainable Tech"',
      'date': '2024-01-19',
      'time': '16:45',
      'status': 'completed',
      'podcastTitle': 'GreenTech Solutions',
    },
    {
      'id': 'tx_004',
      'type': 'bonus',
      'amount': 25.00,
      'description': 'Weekly listening bonus',
      'date': '2024-01-18',
      'time': '12:00',
      'status': 'completed',
      'note': 'Congratulations on completing 5 episodes this week!',
    },
    {
      'id': 'tx_005',
      'type': 'earning',
      'amount': 18.30,
      'description': 'Listened to "Business Models"',
      'date': '2024-01-17',
      'time': '11:20',
      'status': 'completed',
      'podcastTitle': 'Entrepreneur Hub',
    },
    {
      'id': 'tx_006',
      'type': 'withdrawal',
      'amount': -100.00,
      'description': 'Bank transfer',
      'date': '2024-01-15',
      'time': '10:30',
      'status': 'completed',
      'transactionId': 'WD-2024-002',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Mini-player will auto-detect bottom navigation positioning

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    // Track this route
    _navigationService.trackNavigation(AppRoutes.walletScreen);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Wallet updated successfully'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          behavior: SnackBarBehavior.floating));
    }
  }

  void _onWithdrawal() {
    _showWithdrawalBottomSheet();
  }

  void _onTransactionTap(Map<String, dynamic> transaction) {
    _showTransactionDetails(transaction);
  }

  void _showWithdrawalBottomSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            height: 70.h,
            decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: WithdrawalSectionWidget(
              conversionRate: 0.0,
              currentCoins: 0,
              isEligible: false,
              onWithdrawTap: _processWithdrawal,
            )));
  }

  void _processWithdrawal(double amount, String method) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Withdrawal request submitted: \$${amount.toStringAsFixed(2)} via $method'),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3)));
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Transaction Details',
                  style: AppTheme.lightTheme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Amount',
                        transaction['type'] == 'earning' ||
                                transaction['type'] == 'bonus'
                            ? '+\$${transaction['amount'].toStringAsFixed(2)}'
                            : '\$${transaction['amount'].abs().toStringAsFixed(2)}'),
                    _buildDetailRow(
                        'Type', transaction['type'].toString().toUpperCase()),
                    _buildDetailRow('Date',
                        '${transaction['date']} ${transaction['time']}'),
                    _buildDetailRow('Status',
                        transaction['status'].toString().toUpperCase()),
                    if (transaction['transactionId'] != null)
                      _buildDetailRow(
                          'Transaction ID', transaction['transactionId']),
                    if (transaction['podcastTitle'] != null)
                      _buildDetailRow('Podcast', transaction['podcastTitle']),
                    if (transaction['note'] != null)
                      _buildDetailRow('Note', transaction['note']),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close',
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600))),
              ]);
        });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 20.w,
              child: Text('$label:',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant))),
          Expanded(
              child:
                  Text(value, style: AppTheme.lightTheme.textTheme.bodyMedium)),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    // Show coming soon if toggle is enabled
    if (_showComingSoon) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: ComingSoonWidget(
          title: 'Digital Wallet',
          description:
              'Manage your earnings, track your balance, and withdraw your rewards. This feature will provide a complete financial dashboard for your podcast earnings.',
          icon: Icons.account_balance_wallet,
        ),
      );
    }

    // Show full functionality
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          elevation: 0,
          title: Text('My Wallet',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.onSurface)),
          centerTitle: true,
          leading: IconButton(
              icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24),
              onPressed: () => _navigationService.goBack()),
          actions: [
            IconButton(
                icon: CustomIconWidget(
                    iconName: 'history',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24),
                onPressed: () {
                  // Navigate to full transaction history
                }),
          ]),
      body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.lightTheme.colorScheme.primary,
          child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: [
                SizedBox(height: 2.h),

                // Balance card
                BalanceCardWidget(
                  animation: _animation,
                  conversionRate: 0.0,
                  currentCoins: 0,
                ),

                SizedBox(height: 3.h),

                // Withdrawal button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _onWithdrawal,
                      icon: CustomIconWidget(
                        iconName: 'account_balance_wallet',
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'Withdraw Funds',
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Earnings stats
                EarningsStatsWidget(
                  dailyEarnings: dailyEarnings,
                  weeklyEarnings: weeklyEarnings,
                  monthlyEarnings: monthlyEarnings,
                ),

                SizedBox(height: 3.h),

                SizedBox(height: 2.h),

                // Recent transactions
                Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Recent Transactions',
                                        style: AppTheme
                                            .lightTheme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.lightTheme
                                                    .colorScheme.onSurface)),
                                    TextButton(
                                        onPressed: () {
                                          // Navigate to full transaction history
                                          _navigationService.navigateTo(
                                              AppRoutes
                                                  .withdrawalHistoryScreen);
                                        },
                                        child: Text('View All',
                                            style: AppTheme.lightTheme.textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                    color: AppTheme.lightTheme
                                                        .colorScheme.primary,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                  ])),
                          ...transactions.take(5).map((transaction) {
                            return TransactionItemWidget(
                                transaction: transaction);
                          }),
                          SizedBox(height: 2.h),
                        ])),

                SizedBox(height: 12.h), // Space for bottom navigation
              ]))),
    );
  }
}
