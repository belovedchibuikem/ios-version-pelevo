import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/navigation_service.dart';
import '../../widgets/custom_icon_widget.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final NavigationService _navigationService = NavigationService();

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: currentTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Terms & Conditions',
          style: currentTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: currentTheme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: currentTheme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => _navigationService.goBack(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: currentTheme.colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms & Conditions of Service',
                    style: currentTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: currentTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Effective Date: 01-07-2025',
                    style: currentTheme.textTheme.bodyMedium?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Last Updated: 01-07-2025',
                    style: currentTheme.textTheme.bodyMedium?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Introduction
            _buildSection(
              currentTheme,
              'Introduction',
              'Welcome to Pelevo, a podcast listening and rewards platform operated by Pod Emeralds Limited ("we," "us," "our"). These Terms & Conditions of Service ("Terms") govern your use of our application, services, and features available through the Pelevo mobile and web platforms (collectively, the "App").\n\nBy downloading, accessing, or using the Pelevo App, you ("you," "user") agree to be bound by these Terms. If you do not agree with any part of these Terms, please do not use the App.',
            ),

            // Eligibility
            _buildSection(
              currentTheme,
              '1. Eligibility',
              '• Be at least 13 years old.\n• Agree to and abide by these Terms.\n• Reside in a country where our services, including the rewards system, are legally permitted.\n\nNote: The earning and withdrawal features are currently only available to users located in the United States.',
            ),

            // User Accounts
            _buildSection(
              currentTheme,
              '1.1. User Accounts',
              '• Maintaining the security of your account and password\n• All activities that occur under your account\n• Notifying us immediately of any unauthorized use\n• Ensuring you are at least 13 years old to use the service',
            ),

            // Service Overview
            _buildSection(
              currentTheme,
              '2. Service Overview',
              '• Access to a curated library of podcasts\n• Listen to curated and monetized podcasts.\n• Earn virtual rewards in the form of Pelevo Coins based on their listening activities.\n• Withdraw eligible coins as cash once a specified withdrawal threshold is reached.\n\nPodcasts available in the app may be:\n\n• Created by independent hosts.\n• Scripted and voiced using AI technology.\n• Sponsored and monetized, enabling revenue sharing between Pod Emeralds Limited and eligible users.',
            ),

            // Earning Rewards
            _buildSection(
              currentTheme,
              '3. Earning Rewards',
              '• Listening to monetized podcasts made available within the app.\n• Complying with listening engagement rules (e.g., minimum listen time, skipping restrictions).\n\nThe rate of earning coins may vary based on:\n\n• The specific podcast,\n• Current sponsorship agreements,\n• Listening behavior or engagement metrics.\n\nWe do not guarantee earnings, and we reserve the right to change reward structures at any time without prior notice.',
            ),

            // Withdrawals
            _buildSection(
              currentTheme,
              '4. Withdrawals',
              '• Coins earned can be converted into cash and withdrawn once the minimum withdrawal threshold is met.\n• The withdrawal feature is only available to users located in the United States.\n• All withdrawals are subject to review and verification, and may take several business days to process.\n• We reserve the right to deny withdrawal requests in cases of suspected fraud, terms violations, or if a podcast host cancels sponsorship or revenue-sharing arrangements.',
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
