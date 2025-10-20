import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../data/repositories/package_subscription_repository.dart';
import 'google_play_debug_helper.dart';

/// In-app purchase service that handles both Google Play and Apple App Store purchases
/// Implements the latest in_app_purchase plugin (3.2.3) best practices
class InAppPurchaseService {
  static const String _kPremiumMonthlyId = 'premium_monthly_pelevo';
  static const String _kPremiumYearlyId = 'premium_yearly_pelevo';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final PackageSubscriptionRepository _repository =
      PackageSubscriptionRepository();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Initialize the in-app purchase service
  Future<void> initialize({Set<String>? productIds}) async {
    if (_isInitialized) {
      debugPrint('🛒 IN-APP PURCHASE: Already initialized');
      return;
    }

    try {
      debugPrint('🛒 IN-APP PURCHASE: Initializing...');

      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        debugPrint('🛒 IN-APP PURCHASE: Not available on this device');
        _error = 'In-app purchases are not available on this device';
        return;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          debugPrint('🛒 IN-APP PURCHASE: Purchase stream closed');
          _subscription?.cancel();
        },
        onError: (error) {
          debugPrint('🔴 IN-APP PURCHASE ERROR: $error');
          _error = error.toString();
        },
      );

      // Load products (optionally with provided IDs)
      if (productIds != null && productIds.isNotEmpty) {
        await loadProductsWithIds(productIds);
      } else {
        await loadProducts();
      }

      // Run debug checks
      await GooglePlayDebugHelper.checkGooglePlayConfiguration();
      GooglePlayDebugHelper.checkTestEnvironment();

      _isInitialized = true;
      debugPrint('🛒 IN-APP PURCHASE: Initialized successfully');
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Load available products with default IDs
  Future<void> loadProducts() async {
    try {
      debugPrint('🛒 IN-APP PURCHASE: Loading products...');

      final Set<String> ids = <String>{
        _kPremiumMonthlyId,
        _kPremiumYearlyId,
      };

      debugPrint('🛒 IN-APP PURCHASE: Loading products with IDs: $ids');
      await _loadProductsWithIds(ids);
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Load products for specific product IDs (e.g., from backend plans)
  Future<void> loadProductsWithIds(Set<String> ids) async {
    try {
      if (ids.isEmpty) {
        _products = [];
        return;
      }
      debugPrint('🛒 IN-APP PURCHASE: Loading products for ids: $ids');
      await _loadProductsWithIds(ids);
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Internal method to load products with IDs
  Future<void> _loadProductsWithIds(Set<String> ids) async {
    debugPrint('🛒 IN-APP PURCHASE: Querying product details for IDs: $ids');

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(ids);

    debugPrint(
        '🛒 IN-APP PURCHASE: Response received - Found: ${response.productDetails.length}, Not Found: ${response.notFoundIDs.length}');

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          '🔴 IN-APP PURCHASE: Products not found in store: ${response.notFoundIDs}');
      debugPrint(
          '🔴 IN-APP PURCHASE: Make sure these products are configured in Google Play Console or App Store Connect');
    }

    if (response.error != null) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: ${response.error}');
      _error = response.error!.message;
    }

    _products = response.productDetails;
    debugPrint(
        '🛒 IN-APP PURCHASE: Successfully loaded ${_products.length} products');

    // Log product details for debugging
    for (final product in _products) {
      debugPrint(
          '🛒 IN-APP PURCHASE: Product - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}, Currency: ${product.currencyCode}');
    }

    // If no products were found, provide helpful debugging info
    if (_products.isEmpty) {
      debugPrint('🔴 IN-APP PURCHASE: No products loaded!');
      debugPrint('🔴 IN-APP PURCHASE: Check the following:');
      debugPrint(
          '🔴 IN-APP PURCHASE: 1. Products are configured in Google Play Console/App Store Connect');
      debugPrint(
          '🔴 IN-APP PURCHASE: 2. Product IDs match exactly (case-sensitive)');
      debugPrint('🔴 IN-APP PURCHASE: 3. Products are published and active');
      debugPrint(
          '🔴 IN-APP PURCHASE: 4. App is signed with the correct certificate');
      debugPrint('🔴 IN-APP PURCHASE: 5. Using a test account for testing');
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(ProductDetails product) async {
    try {
      debugPrint('🛒 IN-APP PURCHASE: Purchasing ${product.id}...');

      if (!_isAvailable) {
        _error = 'In-app purchases are not available';
        return false;
      }

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);

      bool success = false;

      // Determine if it's a consumable or non-consumable product
      if (_isConsumableProduct(product)) {
        success =
            await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } else {
        success =
            await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

      if (success) {
        debugPrint('🛒 IN-APP PURCHASE: Purchase initiated successfully');
      } else {
        debugPrint('🛒 IN-APP PURCHASE: Purchase failed to initiate');
        _error = 'Failed to initiate purchase';
      }

      return success;
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Determine if a product is consumable based on its ID or platform-specific properties
  bool _isConsumableProduct(ProductDetails product) {
    // For now, we'll treat all products as non-consumable (subscriptions)
    // You can modify this logic based on your product configuration
    return false;
  }

  /// Handle purchase updates from the stream
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint(
          '🛒 IN-APP PURCHASE: Purchase update - ${purchaseDetails.productID}, Status: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('🛒 IN-APP PURCHASE: Purchase pending');
          break;
        case PurchaseStatus.error:
          debugPrint('🔴 IN-APP PURCHASE ERROR: ${purchaseDetails.error}');
          _error = purchaseDetails.error?.message;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          debugPrint('🛒 IN-APP PURCHASE: Purchase completed');
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          debugPrint('🛒 IN-APP PURCHASE: Purchase canceled');
          break;
      }

      // Complete the purchase if needed
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('🛒 IN-APP PURCHASE: Processing successful purchase...');

      // Extract platform-specific data
      String? purchaseToken;
      String? receiptData;
      String platform = 'unknown';

      if (purchaseDetails is GooglePlayPurchaseDetails) {
        purchaseToken = purchaseDetails.billingClientPurchase.purchaseToken;
        platform = 'google_play';
        debugPrint(
            '🛒 IN-APP PURCHASE: Google Play purchase token: $purchaseToken');
      } else if (purchaseDetails is AppStorePurchaseDetails) {
        receiptData =
            purchaseDetails.skPaymentTransaction.transactionIdentifier;
        platform = 'apple_app_store';
        debugPrint('🛒 IN-APP PURCHASE: Apple receipt data: $receiptData');
      }

      // Get product details
      final ProductDetails? product = _products.firstWhere(
        (p) => p.id == purchaseDetails.productID,
        orElse: () =>
            throw Exception('Product not found: ${purchaseDetails.productID}'),
      );

      // Process purchase with backend
      if (platform == 'google_play' && purchaseToken != null) {
        await _repository.processGooglePlayPurchase(
          productId: purchaseDetails.productID,
          purchaseToken: purchaseToken,
          transactionId: purchaseDetails.purchaseID ?? '',
          amount: double.tryParse(product?.price ?? '0') ?? 0.0,
        );
      } else if (platform == 'apple_app_store' && receiptData != null) {
        await _repository.processApplePurchase(
          productId: purchaseDetails.productID,
          receiptData: receiptData,
          transactionId: purchaseDetails.purchaseID ?? '',
          amount: double.tryParse(product?.price ?? '0') ?? 0.0,
        );
      }

      debugPrint('🛒 IN-APP PURCHASE: Purchase processed successfully');
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      debugPrint('🛒 IN-APP PURCHASE: Restoring purchases...');
      await _inAppPurchase.restorePurchases();
      debugPrint('🛒 IN-APP PURCHASE: Purchases restored successfully');
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Get subscription offers (Google Play Billing 8.0.0+ feature)
  Future<List<dynamic>> getSubscriptionOffers() async {
    try {
      debugPrint('🛒 IN-APP PURCHASE: Getting subscription offers...');

      // For Google Play Billing 8.0.0+, we can get subscription offers
      // This would typically involve calling your backend to get available offers
      // For now, return empty list - implement based on your backend logic
      debugPrint(
          '🛒 IN-APP PURCHASE: Subscription offers feature available with Billing 8.0.0+');
      return [];
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
      return [];
    }
  }

  /// Check subscription eligibility (Google Play Billing 8.0.0+ feature)
  Future<bool> checkSubscriptionEligibility(String offerId) async {
    try {
      debugPrint(
          '🛒 IN-APP PURCHASE: Checking subscription eligibility for offer: $offerId');

      // For Google Play Billing 8.0.0+, we can check if user is eligible for offers
      // This would typically involve calling your backend
      // For now, return true - implement based on your backend logic
      debugPrint(
          '🛒 IN-APP PURCHASE: Subscription eligibility check available with Billing 8.0.0+');
      return true;
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Get subscription status with enhanced details (Google Play Billing 8.0.0+ feature)
  Future<Map<String, dynamic>> getEnhancedSubscriptionStatus() async {
    try {
      debugPrint('🛒 IN-APP PURCHASE: Getting enhanced subscription status...');

      // For Google Play Billing 8.0.0+, we can get more detailed subscription info
      // This would typically involve calling your backend
      // For now, return basic info - implement based on your backend logic
      debugPrint(
          '🛒 IN-APP PURCHASE: Enhanced subscription status available with Billing 8.0.0+');

      return {
        'hasActiveSubscription': false,
        'subscriptionType': null,
        'expiryDate': null,
        'autoRenew': false,
        'familySharing': false,
        'promotionalOffers': [],
      };
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
      return {};
    }
  }

  /// Present code redemption sheet (iOS 14+)
  Future<void> presentCodeRedemptionSheet() async {
    try {
      if (Platform.isIOS) {
        debugPrint('🛒 IN-APP PURCHASE: Presenting code redemption sheet...');
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.presentCodeRedemptionSheet();
        debugPrint('🛒 IN-APP PURCHASE: Code redemption sheet presented');
      } else {
        debugPrint(
            '🛒 IN-APP PURCHASE: Code redemption sheet only available on iOS');
      }
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Set up price consent handling for iOS
  Future<void> setupPriceConsentHandling() async {
    try {
      if (Platform.isIOS) {
        debugPrint('🛒 IN-APP PURCHASE: Setting up price consent handling...');
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(PriceConsentDelegate());
        debugPrint('🛒 IN-APP PURCHASE: Price consent handling set up');
      }
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Show price consent if needed (iOS)
  Future<void> showPriceConsentIfNeeded() async {
    try {
      if (Platform.isIOS) {
        debugPrint('🛒 IN-APP PURCHASE: Showing price consent if needed...');
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.showPriceConsentIfNeeded();
        debugPrint('🛒 IN-APP PURCHASE: Price consent shown if needed');
      }
    } catch (e) {
      debugPrint('🔴 IN-APP PURCHASE ERROR: $e');
      _error = e.toString();
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}

/// Price consent delegate for iOS
class PriceConsentDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    // Allow the transaction to continue
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    // Return false to prevent the default popup and show it manually later
    return false;
  }
}
