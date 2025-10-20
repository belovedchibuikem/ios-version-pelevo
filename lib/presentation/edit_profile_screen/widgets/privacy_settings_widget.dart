import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

// lib/presentation/edit_profile_screen/widgets/privacy_settings_widget.dart

class PrivacySettingsWidget extends StatelessWidget {
  final Map<String, bool> settings;
  final Function(String, bool) onSettingChanged;

  const PrivacySettingsWidget({
    super.key,
    required this.settings,
    required this.onSettingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    final List<Map<String, dynamic>> privacyOptions = [
      {
        'key': 'profileVisibility',
        'title': 'Public Profile',
        'subtitle': 'Make your profile visible to other users',
        'icon': 'visibility',
      },
      {
        'key': 'showListeningActivity',
        'title': 'Show Listening Activity',
        'subtitle': 'Display your recent listening history',
        'icon': 'history',
      },
      {
        'key': 'allowRecommendations',
        'title': 'Personalized Recommendations',
        'subtitle': 'Use listening data for better suggestions',
        'icon': 'auto_awesome',
      },
      {
        'key': 'shareEarnings',
        'title': 'Share Earnings Stats',
        'subtitle': 'Show your earning achievements publicly',
        'icon': 'leaderboard',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.colorScheme.outline.withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'privacy_tip',
                size: 24,
                color: currentTheme.colorScheme.tertiary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Privacy Controls',
                style: currentTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...privacyOptions.map((option) => _buildPrivacyOption(
                context,
                option['key'],
                option['title'],
                option['subtitle'],
                option['icon'],
                settings[option['key']] ?? true,
              )),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context,
    String key,
    String title,
    String subtitle,
    String iconName,
    bool value,
  ) {
    final currentTheme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? currentTheme.colorScheme.tertiary.withAlpha(26)
                  : currentTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              size: 20,
              color: value
                  ? currentTheme.colorScheme.tertiary
                  : currentTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: currentTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) => onSettingChanged(key, newValue),
            activeColor: currentTheme.colorScheme.tertiary,
            inactiveThumbColor: currentTheme.colorScheme.outline,
            inactiveTrackColor:
                currentTheme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
