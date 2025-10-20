import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/export_options_widget.dart';
import './widgets/history_filter_widget.dart';
import './widgets/transaction_list_widget.dart';
import '../../core/routes/app_routes.dart';

// lib/presentation/withdrawal_history_screen/withdrawal_history_screen.dart

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen>
    with TickerProviderStateMixin {
  final NavigationService _navigationService = NavigationService();
  int _selectedTabIndex = 3; // Wallet tab is index 3
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;
  double _minAmount = 0;
  double _maxAmount = 100000;
  String _searchQuery = '';

  // Mock transaction data
  final List<Map<String, dynamic>> _allTransactions = [
    {
      'id': 'WD-2024-001',
      'amount': 50000.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'bankName': 'Access Bank',
      'accountNumber': '0123456789',
      'accountName': 'John Doe',
      'processingFee': 25.0,
      'reference': 'REF-001',
      'processingTime': '2 business days',
    },
    {
      'id': 'WD-2024-002',
      'amount': 25000.0,
      'status': 'pending',
      'date': DateTime.now().subtract(const Duration(hours: 6)),
      'bankName': 'GTBank',
      'accountNumber': '9876543210',
      'accountName': 'John Doe',
      'processingFee': 25.0,
      'reference': 'REF-002',
      'processingTime': '1-3 business days',
    },
    {
      'id': 'WD-2024-003',
      'amount': 75000.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'bankName': 'Zenith Bank',
      'accountNumber': '5555666677',
      'accountName': 'John Doe',
      'processingFee': 25.0,
      'reference': 'REF-003',
      'processingTime': '1 business day',
    },
    {
      'id': 'WD-2024-004',
      'amount': 15000.0,
      'status': 'failed',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'bankName': 'First Bank',
      'accountNumber': '1111222233',
      'accountName': 'John Doe',
      'processingFee': 25.0,
      'reference': 'REF-004',
      'processingTime': 'Failed',
      'failureReason': 'Invalid account details',
    },
    {
      'id': 'WD-2024-005',
      'amount': 100000.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'bankName': 'UBA',
      'accountNumber': '4444555566',
      'accountName': 'John Doe',
      'processingFee': 25.0,
      'reference': 'REF-005',
      'processingTime': '3 business days',
    },
  ];

  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _navigationService.trackNavigation(AppRoutes.withdrawalHistoryScreen);
    _filteredTransactions = List.from(_allTransactions);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        // Status filter
        if (_selectedStatus != 'All' &&
            transaction['status'] != _selectedStatus.toLowerCase()) {
          return false;
        }

        // Date range filter
        if (_selectedDateRange != null) {
          final transactionDate = transaction['date'] as DateTime;
          if (transactionDate.isBefore(_selectedDateRange!.start) ||
              transactionDate.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }

        // Amount range filter
        final amount = transaction['amount'] as double;
        if (amount < _minAmount || amount > _maxAmount) {
          return false;
        }

        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final id = transaction['id'].toString().toLowerCase();
          final bankName = transaction['bankName'].toString().toLowerCase();
          final reference = transaction['reference'].toString().toLowerCase();

          if (!id.contains(searchLower) &&
              !bankName.contains(searchLower) &&
              !reference.contains(searchLower)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Mock refresh delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    _showSnackBar('Transaction history updated');
  }

  void _onTransactionTap(Map<String, dynamic> transaction) {
    _showTransactionDetails(transaction);
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 2.h),
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transaction Details',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTransactionDetailCard(transaction),
                    SizedBox(height: 3.h),
                    if (transaction['status'] == 'completed')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _downloadReceipt(transaction);
                        },
                        icon: CustomIconWidget(
                          iconName: 'download',
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 18,
                        ),
                        label: Text('Download Receipt'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailCard(Map<String, dynamic> transaction) {
    return Container(
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
          _buildDetailRow('Transaction ID', transaction['id']),
          _buildDetailRow(
              'Amount', '₦${transaction['amount'].toStringAsFixed(2)}'),
          _buildDetailRow('Processing Fee',
              '₦${transaction['processingFee'].toStringAsFixed(2)}'),
          _buildDetailRow('Status', transaction['status'].toUpperCase()),
          _buildDetailRow('Date', _formatDate(transaction['date'])),
          _buildDetailRow('Bank', transaction['bankName']),
          _buildDetailRow('Account',
              '${transaction['accountNumber']} (${transaction['accountName']})'),
          _buildDetailRow('Reference', transaction['reference']),
          _buildDetailRow('Processing Time', transaction['processingTime']),
          if (transaction['failureReason'] != null)
            _buildDetailRow('Failure Reason', transaction['failureReason']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _downloadReceipt(Map<String, dynamic> transaction) {
    _showSnackBar('Receipt downloaded: ${transaction['id']}.pdf');
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
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Withdrawal History',
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
              iconName: 'file_download',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              _showExportOptions();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.lightTheme.colorScheme.primary,
            child: Column(
              children: [
                // Search and Filter Section
                HistoryFilterWidget(
                  searchController: _searchController,
                  selectedStatus: _selectedStatus,
                  selectedDateRange: _selectedDateRange,
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                  onStatusChanged: (status) {
                    setState(() {
                      _selectedStatus = status;
                    });
                    _applyFilters();
                  },
                  onDateRangeChanged: (range) {
                    setState(() {
                      _selectedDateRange = range;
                    });
                    _applyFilters();
                  },
                  onAmountRangeChanged: (min, max) {
                    setState(() {
                      _minAmount = min;
                      _maxAmount = max;
                    });
                    _applyFilters();
                  },
                ),

                // Transaction List
                Expanded(
                  child: TransactionListWidget(
                    transactions: _filteredTransactions,
                    isLoading: _isLoading,
                    onTransactionTap: _onTransactionTap,
                  ),
                ),
              ],
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

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportOptionsWidget(
        onExportPdf: () {
          Navigator.of(context).pop();
          _showSnackBar('Exporting PDF report...');
        },
        onExportCsv: () {
          Navigator.of(context).pop();
          _showSnackBar('Exporting CSV report...');
        },
        onShare: () {
          Navigator.of(context).pop();
          _showSnackBar('Sharing transaction summary...');
        },
      ),
    );
  }
}
