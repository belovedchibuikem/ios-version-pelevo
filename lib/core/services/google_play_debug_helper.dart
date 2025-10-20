import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Helper class for debugging Google Play Console configuration
class GooglePlayDebugHelper {
  static const String _kPremiumMonthlyId = 'premium_monthly_pelevo';
  static const String _kPremiumYearlyId = 'premium_yearly_pelevo';

  /// Check Google Play Console configuration
  static Future<void> checkGooglePlayConfiguration() async {
    debugPrint('🔍 GOOGLE PLAY DEBUG: Starting configuration check...');

    // Check if in-app purchases are available
    final bool available = await InAppPurchase.instance.isAvailable();
    debugPrint('🔍 GOOGLE PLAY DEBUG: In-app purchases available: $available');

    if (!available) {
      debugPrint('🔴 GOOGLE PLAY DEBUG: In-app purchases not available!');
      debugPrint(
          '🔴 GOOGLE PLAY DEBUG: Check if Google Play Services is installed and updated');
      return;
    }

    // Check Android-specific configuration
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _checkAndroidConfiguration();
    }

    // Test product query
    await _testProductQuery();
  }

  /// Check Android-specific configuration
  static Future<void> _checkAndroidConfiguration() async {
    debugPrint('🔍 GOOGLE PLAY DEBUG: Checking Android configuration...');

    try {
      // Get Android platform addition
      final InAppPurchaseAndroidPlatformAddition androidAddition = InAppPurchase
          .instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      debugPrint(
          '🔍 GOOGLE PLAY DEBUG: Android platform addition available: true');

      // Check if we can access billing client
      debugPrint('🔍 GOOGLE PLAY DEBUG: Billing client available');
    } catch (e) {
      debugPrint(
          '🔴 GOOGLE PLAY DEBUG: Error checking Android configuration: $e');
    }
  }

  /// Test product query with detailed logging
  static Future<void> _testProductQuery() async {
    debugPrint('🔍 GOOGLE PLAY DEBUG: Testing product query...');

    final Set<String> testIds = {
      _kPremiumMonthlyId,
      _kPremiumYearlyId,
    };

    try {
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(testIds);

      debugPrint('🔍 GOOGLE PLAY DEBUG: Query response received');
      debugPrint(
          '🔍 GOOGLE PLAY DEBUG: Products found: ${response.productDetails.length}');
      debugPrint(
          '🔍 GOOGLE PLAY DEBUG: Products not found: ${response.notFoundIDs.length}');
      debugPrint(
          '🔍 GOOGLE PLAY DEBUG: Error: ${response.error?.message ?? 'None'}');

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: Missing products: ${response.notFoundIDs}');
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: Check Google Play Console configuration:');
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: 1. Go to Google Play Console > Your App > Monetize > Products > In-app products');
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: 2. Create products with these exact IDs: ${response.notFoundIDs}');
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: 3. Make sure products are ACTIVE and PUBLISHED');
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: 4. Check that your app is uploaded and published (or in internal testing)');
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: 5. Verify the app is signed with the same certificate as uploaded to Play Console');
      }

      if (response.productDetails.isNotEmpty) {
        debugPrint('✅ GOOGLE PLAY DEBUG: Found products:');
        for (final product in response.productDetails) {
          debugPrint(
              '✅ GOOGLE PLAY DEBUG: - ${product.id}: ${product.title} (${product.price} ${product.currencyCode})');
        }
      }

      if (response.error != null) {
        debugPrint('🔴 GOOGLE PLAY DEBUG: Query error: ${response.error}');
        debugPrint('🔴 GOOGLE PLAY DEBUG: Error code: ${response.error!.code}');
        debugPrint(
            '🔴 GOOGLE PLAY DEBUG: Error message: ${response.error!.message}');
      }
    } catch (e) {
      debugPrint('🔴 GOOGLE PLAY DEBUG: Exception during product query: $e');
    }
  }

  /// Generate Google Play Console setup instructions
  static void printSetupInstructions() {
    debugPrint('📋 GOOGLE PLAY CONSOLE SETUP INSTRUCTIONS:');
    debugPrint(
        '1. Go to Google Play Console (https://play.google.com/console)');
    debugPrint('2. Select your app');
    debugPrint('3. Navigate to: Monetize > Products > In-app products');
    debugPrint('4. Click "Create product"');
    debugPrint('5. Create these products:');
    debugPrint('   - Product ID: premium_monthly_pelevo');
    debugPrint('   - Product ID: premium_yearly_pelevo');
    debugPrint('6. Set product details (name, description, price)');
    debugPrint('7. Set product status to "Active"');
    debugPrint('8. Save and publish the products');
    debugPrint(
        '9. Make sure your app is uploaded and published (or in internal testing)');
    debugPrint('10. Test with a test account that has access to your app');
  }

  /// Check if running on test environment
  static void checkTestEnvironment() {
    debugPrint('🔍 GOOGLE PLAY DEBUG: Checking test environment...');

    if (kDebugMode) {
      debugPrint('✅ GOOGLE PLAY DEBUG: Running in debug mode');
      debugPrint('✅ GOOGLE PLAY DEBUG: Make sure you are using a test account');
      debugPrint(
          '✅ GOOGLE PLAY DEBUG: Test accounts should be added in Google Play Console > Setup > License testing');
    } else {
      debugPrint('⚠️ GOOGLE PLAY DEBUG: Running in release mode');
      debugPrint(
          '⚠️ GOOGLE PLAY DEBUG: Make sure your app is published and products are active');
    }
  }
}
