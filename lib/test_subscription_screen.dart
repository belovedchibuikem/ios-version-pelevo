import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/package_subscription_provider.dart';

/// Test version of subscription management screen to identify crash issues
class TestSubscriptionScreen extends StatefulWidget {
  const TestSubscriptionScreen({super.key});

  @override
  State<TestSubscriptionScreen> createState() => _TestSubscriptionScreenState();
}

class _TestSubscriptionScreenState extends State<TestSubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🧪 TEST: TestSubscriptionScreen initState called');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🧪 TEST: PostFrameCallback executing...');
      try {
        final provider =
            Provider.of<PackageSubscriptionProvider>(context, listen: false);
        debugPrint('🧪 TEST: Provider obtained successfully');

        // Test each method individually
        _testLoadPlans(provider);
        _testLoadSubscription(provider);
        _testLoadTransactions(provider);
      } catch (e) {
        debugPrint('❌ TEST ERROR: $e');
      }
    });
  }

  Future<void> _testLoadPlans(PackageSubscriptionProvider provider) async {
    try {
      debugPrint('🧪 TEST: Testing loadSubscriptionPlans...');
      await provider.loadSubscriptionPlans();
      debugPrint('✅ TEST: loadSubscriptionPlans completed');
    } catch (e) {
      debugPrint('❌ TEST ERROR in loadSubscriptionPlans: $e');
    }
  }

  Future<void> _testLoadSubscription(
      PackageSubscriptionProvider provider) async {
    try {
      debugPrint('🧪 TEST: Testing loadUserSubscription...');
      await provider.loadUserSubscription();
      debugPrint('✅ TEST: loadUserSubscription completed');
    } catch (e) {
      debugPrint('❌ TEST ERROR in loadUserSubscription: $e');
    }
  }

  Future<void> _testLoadTransactions(
      PackageSubscriptionProvider provider) async {
    try {
      debugPrint('🧪 TEST: Testing loadUserTransactions...');
      await provider.loadUserTransactions();
      debugPrint('✅ TEST: loadUserTransactions completed');
    } catch (e) {
      debugPrint('❌ TEST ERROR in loadUserTransactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🧪 TEST: TestSubscriptionScreen build called');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Subscription Screen'),
      ),
      body: Consumer<PackageSubscriptionProvider>(
        builder: (context, provider, child) {
          debugPrint('🧪 TEST: Consumer builder called');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Results:',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text('Loading: ${provider.isLoading}'),
                Text('Error: ${provider.error ?? "None"}'),
                Text('Plans count: ${provider.plans.length}'),
                Text('Has subscription: ${provider.hasActiveSubscription}'),
                Text('Transactions count: ${provider.transactions.length}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    debugPrint('🧪 TEST: Manual test button pressed');
                    final provider = Provider.of<PackageSubscriptionProvider>(
                        context,
                        listen: false);
                    provider.loadSubscriptionPlans();
                  },
                  child: const Text('Test Load Plans'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    debugPrint(
                        '🧪 TEST: Manual subscription test button pressed');
                    final provider = Provider.of<PackageSubscriptionProvider>(
                        context,
                        listen: false);
                    provider.loadUserSubscription();
                  },
                  child: const Text('Test Load Subscription'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    debugPrint(
                        '🧪 TEST: Manual transactions test button pressed');
                    final provider = Provider.of<PackageSubscriptionProvider>(
                        context,
                        listen: false);
                    provider.loadUserTransactions();
                  },
                  child: const Text('Test Load Transactions'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
