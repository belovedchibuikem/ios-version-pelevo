import 'package:flutter/foundation.dart';
import '../data/models/package_subscription_plan.dart';
import '../data/models/package_transaction.dart';
import '../data/repositories/package_subscription_repository.dart';
import '../core/services/in_app_purchase_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PackageSubscriptionProvider extends ChangeNotifier {
  final PackageSubscriptionRepository _repository =
      PackageSubscriptionRepository();
  final InAppPurchaseService _purchaseService = InAppPurchaseService();

  List<PackageSubscriptionPlan> _plans = [];
  Map<String, dynamic>? _currentSubscription;
  List<PackageTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // In-app purchase properties
  List<ProductDetails> get products => _purchaseService.products;
  bool get isPurchaseAvailable => _purchaseService.isAvailable;
  String? get purchaseError => _purchaseService.error;

  // Getters
  List<PackageSubscriptionPlan> get plans => _plans;
  Map<String, dynamic>? get currentSubscription => _currentSubscription;
  List<PackageTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSubscription {
    final hasSubscription = _currentSubscription?['has_subscription'];
    return hasSubscription == true; // Handle null values properly
  }

  // Initialize the provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('📦 PACKAGE SUBSCRIPTION PROVIDER: Initializing...');

      // Initialize in-app purchase service first
      await _purchaseService.initialize();

      // Load subscription plans to get product IDs
      await loadSubscriptionPlans();

      // Update IAP service with product IDs from plans
      final Set<String> productIds = _plans
          .map((p) => p.googlePlayProductId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      if (productIds.isNotEmpty) {
        await _purchaseService.loadProductsWithIds(productIds);
      }

      // Load user subscription and transactions
      await Future.wait([
        loadUserSubscription(),
        loadUserTransactions(),
      ]);

      debugPrint('📦 PACKAGE SUBSCRIPTION PROVIDER: Initialized successfully');
    } catch (e) {
      _setError('Failed to initialize: $e');
      debugPrint('🔴 PACKAGE SUBSCRIPTION PROVIDER ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load subscription plans
  Future<void> loadSubscriptionPlans() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Loading subscription plans...');
      _plans = await _repository.getSubscriptionPlans();

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Loaded ${_plans.length} plans');
      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Plans: ${_plans.map((p) => p.name).toList()}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load subscription plans: $e');
      debugPrint('🔴 PACKAGE SUBSCRIPTION PROVIDER ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user subscription
  Future<void> loadUserSubscription() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Loading user subscription...');
      _currentSubscription = await _repository.getUserSubscription();

      debugPrint('📦 PACKAGE SUBSCRIPTION PROVIDER: User subscription loaded');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user subscription: $e');
      debugPrint('🔴 PACKAGE SUBSCRIPTION PROVIDER ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user transactions (billing history)
  Future<void> loadUserTransactions() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Loading user transactions...');
      _transactions = await _repository.getUserTransactions();

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Loaded ${_transactions.length} transactions');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions: $e');
      debugPrint('🔴 PACKAGE SUBSCRIPTION PROVIDER ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Purchase a product using in-app purchase
  Future<bool> purchaseProduct(ProductDetails product) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('📦 PACKAGE SUBSCRIPTION PROVIDER: Purchasing product...');

      if (!_purchaseService.isAvailable) {
        _setError('In-app purchases are not available on this device');
        return false;
      }

      final success = await _purchaseService.purchaseProduct(product);

      if (success) {
        debugPrint(
            '📦 PACKAGE SUBSCRIPTION PROVIDER: Purchase initiated successfully');
        // The purchase will be processed in the InAppPurchaseService
        // and the user subscription will be updated automatically
      } else {
        _setError('Failed to initiate purchase');
      }

      return success;
    } catch (e) {
      _setError('Failed to purchase product: $e');
      debugPrint('🔴 PACKAGE SUBSCRIPTION PROVIDER ERROR: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('📦 PACKAGE SUBSCRIPTION PROVIDER: Restoring purchases...');
      await _purchaseService.restorePurchases();

      // Reload user subscription after restore
      await loadUserSubscription();

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Purchases restored successfully');
    } catch (e) {
      _setError('Failed to restore purchases: $e');
      debugPrint('🔴 PACKAGE SUBSCRIPTION PROVIDER ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION PROVIDER: Cancelling subscription...');
      final success = await _repository.cancelSubscription();

      if (success) {
        // Reload user subscription after cancellation
        await loadUserSubscription();
        debugPrint(
            '📦 PACKAGE SUBSCRIPTION PROVIDER: Subscription cancelled successfully');
      }

      return success;
    } catch (e) {
      _setError('Failed to cancel subscription: $e');
      debugPrint('🔴 PACKAGE SUBSCRIPTION PROVIDER ERROR: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user has access to premium features
  bool hasPremiumAccess() {
    if (!hasActiveSubscription) return false;

    final subscription = _currentSubscription?['subscription'];
    if (subscription == null) return false;

    final status = subscription['status'];
    final expiresAt = subscription['expires_at'];

    if (status != 'active') return false;

    // Check if subscription has expired
    if (expiresAt != null) {
      final expiryDate = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiryDate)) return false;
    }

    return true;
  }

  // Get current plan name
  String? getCurrentPlanName() {
    if (!hasActiveSubscription) return null;

    final currentPlan = _currentSubscription?['current_plan'];
    return currentPlan?['name'];
  }

  // Get subscription expiry date
  DateTime? getSubscriptionExpiryDate() {
    if (!hasActiveSubscription) return null;

    final subscription = _currentSubscription?['subscription'];
    final expiresAt = subscription?['expires_at'];

    if (expiresAt != null) {
      return DateTime.parse(expiresAt);
    }

    return null;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}
