import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/navigation_service.dart';
import '../../widgets/custom_icon_widget.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final NavigationService _navigationService = NavigationService();

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: currentTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Privacy Policy',
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
                    'Privacy Policy',
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
              'Pod Emeralds Limited ("we", "our", or "us") values your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the Pelevo mobile application and associated services (the "App").\n\nBy using the App, you consent to the data practices described in this policy.',
            ),

            // Information We Collect
            _buildSection(
              currentTheme,
              '1. Information We Collect',
              'We may collect the following information from users:\n\n• Personal Information (e.g., email address, location)\n• Listening Activity and Engagement\n• Device Information (e.g., device model, OS version)\n• App Usage Data (e.g., time spent, clicks, sessions)',
            ),

            // How We Use Your Information
            _buildSection(
              currentTheme,
              '2. How We Use Your Information',
              '• Provide and operate the App\n• Track listening activity for rewards\n• Improve user experience\n• Ensure security and detect fraud\n• Comply with legal obligations',
            ),

            // Sharing of Information
            _buildSection(
              currentTheme,
              '3. Sharing of Information',
              'We do not sell your personal information. We may share data with:\n\n• Payment processors (for reward withdrawals)\n• Analytics providers\n• Legal authorities if required by law',
            ),

            // Data Retention
            _buildSection(
              currentTheme,
              '4. Data Retention',
              'We retain your data as long as your account is active or as needed to provide services, comply with our legal obligations, or resolve disputes.',
            ),

            // Your Rights and Choices
            _buildSection(
              currentTheme,
              '5. Your Rights and Choices',
              'Depending on your location, you may have rights to access, update, or delete your personal data. Please contact us at support@podemeralds.com to make a request.',
            ),

            // Data Security
            _buildSection(
              currentTheme,
              '6. Data Security',
              'We implement industry-standard measures to protect your data, but no system is 100% secure. You use the App at your own risk.',
            ),

            // Children's Privacy
            _buildSection(
              currentTheme,
              '7. Children\'s Privacy',
              'Pelevo is not intended for users under the age of 13. We do not knowingly collect personal data from children.',
            ),

            // Changes to This Policy
            _buildSection(
              currentTheme,
              '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. Continued use of the App indicates your acceptance of the revised policy.',
            ),

            // Contact Us
            _buildSection(
              currentTheme,
              '9. Contact Us',
              'Pod Emeralds Limited\n\nEmail: info@podemeralds.com\n\nWebsite: www.pelevo.com',
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
