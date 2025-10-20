import 'package:flutter/foundation.dart';

class PackageSubscriptionPlan {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final String currency;
  final String billingPeriod;
  final String? googlePlayProductId;
  final String? appleProductId;
  final List<String> features;
  final bool isActive;
  final bool isPopular;
  final int sortOrder;

  PackageSubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    this.googlePlayProductId,
    this.appleProductId,
    required this.features,
    required this.isActive,
    required this.isPopular,
    required this.sortOrder,
  });

  factory PackageSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // Handle price which can be String or num
    double parsePrice(dynamic price) {
      if (price is num) {
        return price.toDouble();
      } else if (price is String) {
        return double.tryParse(price) ?? 0.0;
      }
      return 0.0;
    }

    return PackageSubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      price: parsePrice(json['price']),
      currency: json['currency'] as String,
      billingPeriod: json['billing_period'] as String,
      googlePlayProductId: json['google_play_product_id'] as String?,
      appleProductId: json['apple_product_id'] as String?,
      features: (json['features'] as List<dynamic>).cast<String>(),
      isActive: json['is_active'] as bool? ?? true,
      isPopular: json['is_popular'] as bool? ?? false,
      sortOrder: json['sort_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'price': price,
      'currency': currency,
      'billing_period': billingPeriod,
      'google_play_product_id': googlePlayProductId,
      'apple_product_id': appleProductId,
      'features': features,
      'is_active': isActive,
      'is_popular': isPopular,
      'sort_order': sortOrder,
    };
  }

  String get formattedPrice {
    if (price == 0) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }

  String get billingPeriodText {
    switch (billingPeriod) {
      case 'monthly':
        return '/month';
      case 'yearly':
        return '/year';
      case 'lifetime':
        return '';
      default:
        return '';
    }
  }

  String get fullPriceText {
    if (price == 0) return 'Free';
    return '$formattedPrice$billingPeriodText';
  }
}
