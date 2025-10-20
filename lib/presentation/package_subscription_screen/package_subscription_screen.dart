import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../providers/package_subscription_provider.dart';
import '../../data/models/package_subscription_plan.dart';
import './widgets/package_subscription_plan_card.dart';
import './widgets/package_subscription_header.dart';

class PackageSubscriptionScreen extends StatefulWidget {
  const PackageSubscriptionScreen({super.key});

  @override
  State<PackageSubscriptionScreen> createState() =>
      _PackageSubscriptionScreenState();
}

class _PackageSubscriptionScreenState extends State<PackageSubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<PackageSubscriptionProvider>(context, listen: false);
      provider.loadSubscriptionPlans();
      provider.loadUserSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PackageSubscriptionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            elevation: 0,
            title: Text(
              'Subscription Plans',
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? _buildErrorWidget(provider)
                  : _buildContent(provider),
        );
      },
    );
  }

  Widget _buildErrorWidget(PackageSubscriptionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.lightTheme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Error Loading Plans',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.error,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            provider.error ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              provider.clearError();
              provider.loadSubscriptionPlans();
              provider.loadUserSubscription();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PackageSubscriptionProvider provider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with current subscription info
          PackageSubscriptionHeader(
            currentSubscription: provider.currentSubscription,
            hasActiveSubscription: provider.hasActiveSubscription,
            currentPlanName: provider.getCurrentPlanName(),
            expiryDate: provider.getSubscriptionExpiryDate(),
          ),

          SizedBox(height: 4.h),

          // Plans section
          Text(
            'Choose Your Plan',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 2.h),

          // Subscription plans
          ...provider.plans.map((plan) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: PackageSubscriptionPlanCard(
                  plan: plan,
                  isCurrentPlan: provider.getCurrentPlanName() == plan.name,
                  onSubscribe: () => _handleSubscription(provider, plan),
                ),
              )),

          SizedBox(height: 4.h),

          // Cancel subscription button (if user has active subscription)
          if (provider.hasActiveSubscription)
            ElevatedButton(
              onPressed: () => _showCancelSubscriptionDialog(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
                foregroundColor: AppTheme.lightTheme.colorScheme.onError,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: const Text('Cancel Subscription'),
            ),
        ],
      ),
    );
  }

  void _handleSubscription(
      PackageSubscriptionProvider provider, PackageSubscriptionPlan plan) {
    if (plan.price == 0) {
      // Free plan - no purchase needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already on the free plan'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
      return;
    }

    // For Android, use Google Play Billing directly; for iOS, show Apple placeholder
    if (Theme.of(context).platform == TargetPlatform.android) {
      _purchaseOnGooglePlay(provider, plan);
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      _purchaseOnApple(provider, plan);
    } else {
      _purchaseOnGooglePlay(provider, plan);
    }
  }

  void _purchaseOnGooglePlay(
      PackageSubscriptionProvider provider, PackageSubscriptionPlan plan) {
    final String? productId = plan.googlePlayProductId;
    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not available on Google Play for this plan'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
      return;
    }

    // Find the ProductDetails from provider products
    dynamic product;
    try {
      product = provider.products.firstWhere((p) => p.id == productId);
    } catch (_) {
      product = null;
    }

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found in store. Please try again later.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
      return;
    }

    provider.purchaseProduct(product);
  }

  void _purchaseOnApple(
      PackageSubscriptionProvider provider, PackageSubscriptionPlan plan) {
    // This would integrate with Apple StoreKit
    // For now, we'll show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apple App Store purchase integration coming soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _showCancelSubscriptionDialog(PackageSubscriptionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? '
          'You will lose access to premium features at the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.cancelSubscription();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Subscription cancelled successfully'),
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(provider.error ?? 'Failed to cancel subscription'),
                    backgroundColor: AppTheme.lightTheme.colorScheme.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}
