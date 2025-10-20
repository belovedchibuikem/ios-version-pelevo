import 'package:flutter/foundation.dart';

class PackageTransaction {
  final int? id;
  final int? userId;
  final int? packageSubscriptionPlanId;
  final String transactionId;
  final String platform; // e.g., 'google', 'apple'
  final String status; // e.g., 'completed', 'pending', 'failed', 'refunded'
  final double amount;
  final String currency; // e.g., 'USD'
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final String? purchaseToken;
  final String? receiptData;
  final Map<String, dynamic>? platformData;
  final String? notes;
  final String? planName; // convenience field if backend includes plan

  PackageTransaction({
    required this.id,
    required this.userId,
    required this.packageSubscriptionPlanId,
    required this.transactionId,
    required this.platform,
    required this.status,
    required this.amount,
    required this.currency,
    required this.purchasedAt,
    required this.expiresAt,
    required this.purchaseToken,
    required this.receiptData,
    required this.platformData,
    required this.notes,
    required this.planName,
  });

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    debugPrint(
        'PackageTransaction: Unexpected amount type: ${value.runtimeType}');
    return 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory PackageTransaction.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    return PackageTransaction(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}'),
      userId: (json['user_id'] is int)
          ? json['user_id'] as int
          : int.tryParse('${json['user_id']}'),
      packageSubscriptionPlanId: (json['package_subscription_plan_id'] is int)
          ? json['package_subscription_plan_id'] as int
          : int.tryParse('${json['package_subscription_plan_id']}'),
      transactionId: (json['transaction_id'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: _parseAmount(json['amount']),
      currency: (json['currency'] ?? 'USD').toString(),
      purchasedAt: _parseDate(json['purchased_at']),
      expiresAt: _parseDate(json['expires_at']),
      purchaseToken: json['purchase_token']?.toString(),
      receiptData: json['receipt_data']?.toString(),
      platformData: (json['platform_data'] is Map<String, dynamic>)
          ? json['platform_data'] as Map<String, dynamic>
          : null,
      notes: json['notes']?.toString(),
      planName: plan is Map<String, dynamic>
          ? (plan['name']?.toString())
          : json['plan_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'package_subscription_plan_id': packageSubscriptionPlanId,
      'transaction_id': transactionId,
      'platform': platform,
      'status': status,
      'amount': amount,
      'currency': currency,
      'purchased_at': purchasedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'purchase_token': purchaseToken,
      'receipt_data': receiptData,
      'platform_data': platformData,
      'notes': notes,
      'plan_name': planName,
    };
  }
}














































































