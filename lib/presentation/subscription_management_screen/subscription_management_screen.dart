import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import '../../providers/package_subscription_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/package_subscription_plan.dart';
import '../../data/models/package_transaction.dart';

// lib/presentation/subscription_management_screen/subscription_management_screen.dart

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final NavigationService _navigationService = NavigationService();
  int _selectedTabIndex = 4;

  @override
  void initState() {
    super.initState();
    _navigationService.trackNavigation(AppRoutes.subscriptionManagementScreen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provider =
            Provider.of<PackageSubscriptionProvider>(context, listen: false);
        debugPrint('📦 SUBSCRIPTION MANAGEMENT: Initializing provider...');

        // Initialize the provider with proper error handling
        provider.initialize().catchError((error) {
          debugPrint(
              '❌ SUBSCRIPTION MANAGEMENT: Error initializing provider: $error');
        });
      } catch (e) {
        debugPrint('❌ SUBSCRIPTION MANAGEMENT: Error initializing: $e');
      }
    });
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

  void _navigateToPackageSubscription() {
    _navigationService.navigateTo(AppRoutes.packageSubscriptionScreen);
  }

  // Handle product purchase
  Future<void> _handleProductPurchase(ProductDetails product) async {
    try {
      final provider =
          Provider.of<PackageSubscriptionProvider>(context, listen: false);

      debugPrint(
          '📦 SUBSCRIPTION MANAGEMENT: Starting purchase for ${product.id}');

      final success = await provider.purchaseProduct(product);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Purchase initiated successfully',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to initiate purchase',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('❌ SUBSCRIPTION MANAGEMENT: Error purchasing product: $e');
      Fluttertoast.showToast(
        msg: 'Purchase error: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Handle restore purchases
  Future<void> _handleRestorePurchases() async {
    try {
      final provider =
          Provider.of<PackageSubscriptionProvider>(context, listen: false);

      debugPrint('📦 SUBSCRIPTION MANAGEMENT: Restoring purchases...');

      await provider.restorePurchases();

      Fluttertoast.showToast(
        msg: 'Purchases restored successfully',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      debugPrint('❌ SUBSCRIPTION MANAGEMENT: Error restoring purchases: $e');
      Fluttertoast.showToast(
        msg: 'Restore error: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Handle plan selection
  Future<void> _handlePlanSelection(PackageSubscriptionPlan plan,
      PackageSubscriptionProvider provider) async {
    try {
      // Find the corresponding product in the IAP service
      final productId = plan.googlePlayProductId ?? plan.appleProductId;
      if (productId == null || productId.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Product not available for purchase',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      // Find the product details
      final product = provider.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      // Initiate purchase
      await _handleProductPurchase(product);
    } catch (e) {
      debugPrint('❌ SUBSCRIPTION MANAGEMENT: Error selecting plan: $e');
      Fluttertoast.showToast(
        msg: 'Error selecting plan: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _cancelSubscription() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final currentTheme = Theme.of(context);
          return AlertDialog(
              title: Text('Cancel Subscription',
                  style: currentTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: currentTheme.colorScheme.error)),
              content: Text(
                  'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your current billing period.',
                  style: currentTheme.textTheme.bodyMedium),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Keep Subscription',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.primary))),
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        final provider =
                            Provider.of<PackageSubscriptionProvider>(context,
                                listen: false);
                        debugPrint(
                            '📦 SUBSCRIPTION MANAGEMENT: Cancelling subscription...');
                        final success = await provider.cancelSubscription();

                        if (success) {
                          Fluttertoast.showToast(
                              msg: 'Subscription cancelled successfully',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM);
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Failed to cancel subscription',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM);
                        }
                      } catch (e) {
                        debugPrint(
                            '❌ SUBSCRIPTION MANAGEMENT: Error cancelling subscription: $e');
                        Fluttertoast.showToast(
                            msg: 'Failed to cancel subscription: $e',
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM);
                      }
                    },
                    child: Text('Cancel Subscription',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.error,
                            fontWeight: FontWeight.w600))),
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
        backgroundColor: currentTheme.scaffoldBackgroundColor,
        appBar: AppBar(
            backgroundColor: currentTheme.colorScheme.surface,
            elevation: 0,
            title: Text('Subscription Management',
                style: currentTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: currentTheme.colorScheme.onSurface)),
            centerTitle: true,
            leading: IconButton(
                icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: currentTheme.colorScheme.onSurface,
                    size: 24),
                onPressed: () => _navigationService.goBack())),
        body: Consumer<PackageSubscriptionProvider>(
          builder: (context, provider, child) {
            return Stack(children: [
              SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current Subscription Card
                            _buildCurrentSubscriptionCard(
                                currentTheme, provider),
                            SizedBox(height: 3.h),

                            // Package Subscription Management
                            Text('Package Subscriptions',
                                style: currentTheme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            currentTheme.colorScheme.primary)),
                            SizedBox(height: 2.h),

                            // Package Subscription Button
                            Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _navigateToPackageSubscription,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      currentTheme.colorScheme.primary,
                                  foregroundColor:
                                      currentTheme.colorScheme.onPrimary,
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Manage Package Subscriptions',
                                  style: currentTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 3.h),

                            // Available Plans
                            Text('Available Plans',
                                style: currentTheme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            currentTheme.colorScheme.primary)),
                            SizedBox(height: 2.h),

                            // Show loading or plans
                            if (provider.isLoading)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(4.h),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (provider.error != null)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(4.h),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Error loading plans',
                                        style: currentTheme
                                            .textTheme.titleMedium
                                            ?.copyWith(
                                          color: currentTheme.colorScheme.error,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        provider.error!,
                                        style: currentTheme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: currentTheme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 2.h),
                                      ElevatedButton(
                                        onPressed: () {
                                          provider.loadSubscriptionPlans();
                                          provider.loadUserSubscription();
                                        },
                                        child: Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (provider.plans.isNotEmpty)
                              ...provider.plans.map((plan) =>
                                  _buildPlanCard(currentTheme, plan, provider))
                            else
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(4.h),
                                  child: Column(
                                    children: [
                                      Text(
                                        'No plans available',
                                        style: currentTheme
                                            .textTheme.titleMedium
                                            ?.copyWith(
                                          color: currentTheme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        'Debug: Plans count: ${provider.plans.length}',
                                        style: currentTheme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: currentTheme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            SizedBox(height: 3.h),

                            // Billing History
                            Text('Billing History',
                                style: currentTheme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            currentTheme.colorScheme.primary)),
                            SizedBox(height: 2.h),
                            _buildBillingHistoryCard(currentTheme, provider),
                            SizedBox(height: 12.h),
                          ]))),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CommonBottomNavigationWidget(
                    currentIndex: _selectedTabIndex,
                    onTabSelected: _onTabSelected),
              ),
            ]);
          },
        ));
  }

  Widget _buildCurrentSubscriptionCard(
      ThemeData currentTheme, PackageSubscriptionProvider provider) {
    final hasActiveSubscription = provider.hasActiveSubscription;
    final currentPlanName = provider.getCurrentPlanName();
    final expiryDate = provider.getSubscriptionExpiryDate();

    return Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  currentTheme.colorScheme.primary,
                  currentTheme.colorScheme.primaryContainer,
                ]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: currentTheme.colorScheme.shadow.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Current Plan',
                  style: currentTheme.textTheme.bodyMedium?.copyWith(
                      color:
                          currentTheme.colorScheme.onPrimary.withOpacity(0.8))),
              Text(
                  hasActiveSubscription
                      ? (currentPlanName ?? 'Premium Plan')
                      : 'Free Plan',
                  style: currentTheme.textTheme.headlineSmall?.copyWith(
                      color: currentTheme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold)),
            ]),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                    color: currentTheme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(hasActiveSubscription ? 'Active' : 'Free',
                    style: currentTheme.textTheme.bodySmall?.copyWith(
                        color: currentTheme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w600))),
          ]),
          SizedBox(height: 2.h),
          if (hasActiveSubscription) ...[
            Text('Premium Access',
                style: currentTheme.textTheme.titleLarge?.copyWith(
                    color: currentTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 1.h),
            Text(
                'Expires: ${expiryDate != null ? expiryDate.toString().split(' ')[0] : 'Unknown'}',
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                    color:
                        currentTheme.colorScheme.onPrimary.withOpacity(0.8))),
          ] else ...[
            Text('Upgrade to Premium',
                style: currentTheme.textTheme.titleLarge?.copyWith(
                    color: currentTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 1.h),
            Text('Unlock premium features',
                style: currentTheme.textTheme.bodyMedium?.copyWith(
                    color:
                        currentTheme.colorScheme.onPrimary.withOpacity(0.8))),
          ],
          SizedBox(height: 2.h),
          Row(children: [
            if (hasActiveSubscription) ...[
              Expanded(
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: currentTheme.colorScheme.onPrimary,
                          side: BorderSide(
                              color: currentTheme.colorScheme.onPrimary)),
                      onPressed: _cancelSubscription,
                      child: Text('Cancel'))),
              SizedBox(width: 3.w),
            ],
            Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: currentTheme.colorScheme.secondary,
                        foregroundColor: currentTheme.colorScheme.onSecondary),
                    onPressed: _navigateToPackageSubscription,
                    child: Text(hasActiveSubscription ? 'Manage' : 'Upgrade'))),
          ]),
          SizedBox(height: 1.h),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: currentTheme.colorScheme.onPrimary,
                      side: BorderSide(
                          color: currentTheme.colorScheme.onPrimary
                              .withOpacity(0.5))),
                  onPressed: _handleRestorePurchases,
                  child: Text('Restore Purchases'))),
        ]));
  }

  Widget _buildPlanCard(ThemeData currentTheme, PackageSubscriptionPlan plan,
      PackageSubscriptionProvider provider) {
    final bool isCurrentPlan = provider.getCurrentPlanName() == plan.name;
    final bool isFreePlan = plan.name.toLowerCase().contains('free');

    return Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: currentTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: plan.isPopular
                ? Border.all(color: currentTheme.colorScheme.primary, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                  color: currentTheme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(plan.name,
                    style: currentTheme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (plan.isPopular)
                  Container(
                      margin: EdgeInsets.only(left: 2.w),
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                          color: currentTheme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('POPULAR',
                          style: currentTheme.textTheme.labelSmall?.copyWith(
                              color: currentTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600))),
              ]),
              Text(isFreePlan ? 'Free' : plan.formattedPrice,
                  style: currentTheme.textTheme.titleLarge?.copyWith(
                      color: currentTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ]),
            if (isCurrentPlan)
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                      color: currentTheme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Current',
                      style: currentTheme.textTheme.bodySmall?.copyWith(
                          color: currentTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600))),
          ]),
          SizedBox(height: 2.h),
          ...plan.features
              .map<Widget>((feature) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.5.h),
                  child: Row(children: [
                    CustomIconWidget(
                        iconName: 'check_circle',
                        color: currentTheme.colorScheme.primary,
                        size: 16),
                    SizedBox(width: 2.w),
                    Expanded(
                        child: Text(feature,
                            style: currentTheme.textTheme.bodyMedium)),
                  ])))
              .toList(),
          if (!isCurrentPlan && !isFreePlan) ...[
            SizedBox(height: 2.h),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => _handlePlanSelection(plan, provider),
                    child: Text('Select Plan'))),
          ],
        ]));
  }

  Widget _buildBillingHistoryCard(
      ThemeData currentTheme, PackageSubscriptionProvider provider) {
    final transactions = provider.transactions;

    return Container(
        decoration: BoxDecoration(
            color: currentTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: currentTheme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ]),
        child: transactions.isEmpty
            ? Padding(
                padding: EdgeInsets.all(4.w),
                child: Center(
                  child: Text(
                    'No transactions yet',
                    style: currentTheme.textTheme.bodyMedium?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: currentTheme.colorScheme.outline.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final PackageTransaction tx = transactions[index];
                  final String planLabel = tx.planName ?? 'Subscription';
                  final String dateLabel = tx.purchasedAt != null
                      ? tx.purchasedAt!.toLocal().toString().split('.')[0]
                      : '-';
                  final String statusLabel = _formatStatus(tx.status);
                  final String amountLabel =
                      _formatAmount(tx.amount, tx.currency);
                  return ListTile(
                      leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: currentTheme.colorScheme.primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: CustomIconWidget(
                              iconName: 'receipt',
                              color: currentTheme.colorScheme.primary,
                              size: 20)),
                      title: Text(planLabel,
                          style: currentTheme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                      subtitle: Text('$dateLabel • ${tx.transactionId}',
                          style: currentTheme.textTheme.bodySmall?.copyWith(
                              color:
                                  currentTheme.colorScheme.onSurfaceVariant)),
                      trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(amountLabel,
                                style: currentTheme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 0.5.h),
                                decoration: BoxDecoration(
                                    color: currentTheme.colorScheme.secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(statusLabel,
                                    style: currentTheme.textTheme.labelSmall
                                        ?.copyWith(
                                            color: currentTheme
                                                .colorScheme.secondary,
                                            fontWeight: FontWeight.w600))),
                          ]));
                }));
  }

  String _formatStatus(String raw) {
    if (raw.isEmpty) return 'Unknown';
    final normalized = raw.replaceAll('_', ' ');
    return normalized.substring(0, 1).toUpperCase() + normalized.substring(1);
  }

  String _formatAmount(double amount, String currency) {
    final code = currency.toUpperCase();
    switch (code) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'NGN':
        return '₦${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '$code ${amount.toStringAsFixed(2)}';
    }
  }
}
