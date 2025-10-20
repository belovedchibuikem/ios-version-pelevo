import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/services/unified_auth_service.dart';
import '../models/package_subscription_plan.dart';
import '../models/package_transaction.dart';

class PackageSubscriptionRepository {
  final Dio _dio = Dio();
  final UnifiedAuthService _authService = UnifiedAuthService();

  PackageSubscriptionRepository() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl + '/api',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  Future<List<PackageSubscriptionPlan>> getSubscriptionPlans() async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Fetching subscription plans...');

      final token = await _authService.getToken();
      final response = await _dio.get(
        '/package/plans',
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          final plans = (responseData['data'] as List)
              .map((plan) => PackageSubscriptionPlan.fromJson(plan))
              .toList();

          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Successfully fetched ${plans.length} plans');
          return plans;
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch subscription plans');
        }
      } else {
        throw Exception(
            'Failed to fetch subscription plans: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserSubscription() async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Fetching user subscription...');

      final token = await _authService.getToken();
      final response = await _dio.get(
        '/package/subscription',
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Successfully fetched user subscription');
          return responseData['data'];
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch user subscription');
        }
      } else {
        throw Exception(
            'Failed to fetch user subscription: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    required String transactionId,
    required double amount,
  }) async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Processing Google Play purchase...');

      final token = await _authService.getToken();
      final response = await _dio.post(
        '/package/purchase/google',
        data: {
          'product_id': productId,
          'purchase_token': purchaseToken,
          'transaction_id': transactionId,
          'amount': amount,
        },
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Google Play purchase processed successfully');
          return responseData['data'] ?? {};
        } else {
          throw Exception(responseData['message'] ??
              'Failed to process Google Play purchase');
        }
      } else {
        throw Exception(
            'Failed to process Google Play purchase: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processApplePurchase({
    required String productId,
    required String receiptData,
    required String transactionId,
    required double amount,
  }) async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Processing Apple purchase...');

      final token = await _authService.getToken();
      final response = await _dio.post(
        '/package/purchase/apple',
        data: {
          'product_id': productId,
          'receipt_data': receiptData,
          'transaction_id': transactionId,
          'amount': amount,
        },
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Apple purchase processed successfully');
          return responseData['data'] ?? {};
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to process Apple purchase');
        }
      } else {
        throw Exception(
            'Failed to process Apple purchase: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Cancelling subscription...');

      final token = await _authService.getToken();
      final response = await _dio.post(
        '/package/subscription/cancel',
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Subscription cancelled successfully');
          return true;
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to cancel subscription');
        }
      } else {
        throw Exception(
            'Failed to cancel subscription: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }

  Future<List<PackageTransaction>> getUserTransactions() async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Fetching user transactions...');

      final token = await _authService.getToken();
      final response = await _dio.get(
        '/package/transactions',
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          final transactions = (responseData['data'] as List)
              .map((transaction) => PackageTransaction.fromJson(transaction))
              .toList();

          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Successfully fetched ${transactions.length} transactions');
          return transactions;
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch transactions');
        }
      } else {
        throw Exception('Failed to fetch transactions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Fetching transaction stats...');

      final token = await _authService.getToken();
      final response = await _dio.get(
        '/package/transactions/stats',
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Successfully fetched transaction stats');
          return responseData['data'];
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to fetch transaction stats');
        }
      } else {
        throw Exception(
            'Failed to fetch transaction stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyTransaction({
    required String transactionId,
    required String platform,
  }) async {
    try {
      debugPrint('📦 PACKAGE SUBSCRIPTION: Verifying transaction...');

      final token = await _authService.getToken();
      final response = await _dio.post(
        '/package/transactions/verify',
        data: {
          'transaction_id': transactionId,
          'platform': platform,
        },
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(
          '📦 PACKAGE SUBSCRIPTION: Response status: ${response.statusCode}');
      debugPrint('📦 PACKAGE SUBSCRIPTION: Response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          debugPrint(
              '📦 PACKAGE SUBSCRIPTION: Transaction verified successfully');
          return responseData['data'] ?? {};
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to verify transaction');
        }
      } else {
        throw Exception('Failed to verify transaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 PACKAGE SUBSCRIPTION ERROR: $e');
      rethrow;
    }
  }
}
