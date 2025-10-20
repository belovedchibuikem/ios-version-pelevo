import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'core/services/in_app_purchase_service.dart';
import 'core/services/google_play_debug_helper.dart';

/// Test screen for in-app purchase functionality
/// This screen can be used to test the in-app purchase implementation
class TestInAppPurchaseScreen extends StatefulWidget {
  const TestInAppPurchaseScreen({super.key});

  @override
  State<TestInAppPurchaseScreen> createState() =>
      _TestInAppPurchaseScreenState();
}

class _TestInAppPurchaseScreenState extends State<TestInAppPurchaseScreen> {
  final InAppPurchaseService _iapService = InAppPurchaseService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    try {
      await _iapService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('❌ TEST IAP: Error initializing: $e');
    }
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test In-App Purchase'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In-App Purchase Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Initialized: $_isInitialized'),
                    Text('Available: ${_iapService.isAvailable}'),
                    Text('Error: ${_iapService.error ?? 'None'}'),
                    Text('Products Count: ${_iapService.products.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products Section
            Text(
              'Available Products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _iapService.products.isEmpty
                  ? const Center(
                      child: Text('No products available'),
                    )
                  : ListView.builder(
                      itemCount: _iapService.products.length,
                      itemBuilder: (context, index) {
                        final product = _iapService.products[index];
                        return Card(
                          child: ListTile(
                            title: Text(product.title),
                            subtitle: Text(
                                '${product.price} ${product.currencyCode}'),
                            trailing: ElevatedButton(
                              onPressed: () => _testPurchase(product),
                              child: const Text('Test Purchase'),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testRestorePurchases,
                    child: const Text('Restore Purchases'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testLoadProducts,
                    child: const Text('Load Products'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testGooglePlayConfig,
                    child: const Text('Check Google Play Config'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _printSetupInstructions,
                    child: const Text('Print Setup Instructions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testPurchase(ProductDetails product) async {
    try {
      debugPrint('🧪 TEST IAP: Testing purchase for ${product.id}');
      final success = await _iapService.purchaseProduct(product);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase initiated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed')),
        );
      }
    } catch (e) {
      debugPrint('❌ TEST IAP: Purchase error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase error: $e')),
      );
    }
  }

  Future<void> _testRestorePurchases() async {
    try {
      debugPrint('🧪 TEST IAP: Testing restore purchases');
      await _iapService.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore purchases completed')),
      );
    } catch (e) {
      debugPrint('❌ TEST IAP: Restore error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore error: $e')),
      );
    }
  }

  Future<void> _testLoadProducts() async {
    try {
      debugPrint('🧪 TEST IAP: Testing load products');
      await _iapService.loadProducts();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Products loaded')),
      );
    } catch (e) {
      debugPrint('❌ TEST IAP: Load products error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load products error: $e')),
      );
    }
  }

  Future<void> _testGooglePlayConfig() async {
    try {
      debugPrint('🧪 TEST IAP: Testing Google Play configuration');
      await GooglePlayDebugHelper.checkGooglePlayConfiguration();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Google Play config check completed - see logs')),
      );
    } catch (e) {
      debugPrint('❌ TEST IAP: Google Play config error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Play config error: $e')),
      );
    }
  }

  void _printSetupInstructions() {
    GooglePlayDebugHelper.printSetupInstructions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup instructions printed to console')),
    );
  }
}
