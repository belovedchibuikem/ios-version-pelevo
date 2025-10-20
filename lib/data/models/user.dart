// lib/data/models/user.dart

import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String email;
  final String? name;
  final String? profileImageUrl;
  final double balance;
  final List<String> subscribedCategories;
  final DateTime? createdAt;
  final String? memberSince; // Add this field to store the formatted string

  User({
    required this.id,
    required this.email,
    this.name,
    this.profileImageUrl,
    this.balance = 0.0,
    this.subscribedCategories = const [],
    this.createdAt,
    this.memberSince, // Add this parameter
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Debug: Print all received fields
    debugPrint('DEBUG: User.fromJson - received data: $json');

    // Check for registered_at first, then created_at, then memberSince
    DateTime? createdAt;
    String? memberSince;

    if (json['registered_at'] != null) {
      debugPrint('DEBUG: Found registered_at field');
      createdAt = DateTime.parse(json['registered_at'] as String);
    } else if (json['created_at'] != null) {
      debugPrint('DEBUG: Found created_at field');
      createdAt = DateTime.parse(json['created_at'] as String);
    } else if (json['memberSince'] != null) {
      debugPrint('DEBUG: Found memberSince field, parsing formatted date');
      memberSince = json['memberSince'] as String;
      // Try to parse the formatted date like "June 2025"
      try {
        final memberSinceStr = json['memberSince'] as String;
        final parts = memberSinceStr.split(' ');
        if (parts.length == 2) {
          final month = parts[0];
          final year = int.parse(parts[1]);
          final monthMap = {
            'January': 1,
            'February': 2,
            'March': 3,
            'April': 4,
            'May': 5,
            'June': 6,
            'July': 7,
            'August': 8,
            'September': 9,
            'October': 10,
            'November': 11,
            'December': 12
          };
          if (monthMap.containsKey(month)) {
            createdAt = DateTime(year, monthMap[month]!, 1);
            debugPrint('DEBUG: Successfully parsed memberSince: $createdAt');
          }
        }
      } catch (e) {
        debugPrint('DEBUG: Failed to parse memberSince: $e');
      }
    } else {
      debugPrint('DEBUG: No registered_at or created_at found');
    }

    debugPrint('DEBUG: User createdAt is $createdAt');
    debugPrint('DEBUG: User memberSince is $memberSince');

    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String?,
      profileImageUrl: json['profile_image_url'] ?? json['profileImage'],
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      subscribedCategories: (json['subscribed_categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: createdAt,
      memberSince: memberSince, // Add this field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image_url': profileImageUrl,
      'balance': balance,
      'subscribed_categories': subscribedCategories,
      'created_at': createdAt?.toIso8601String(),
      'member_since': memberSince, // Add this field
    };
  }
}
