import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

// lib/presentation/edit_profile_screen/widgets/notification_settings_widget.dart

class NotificationSettingsWidget extends StatelessWidget {
  final Map<String, bool> settings;
  final Function(String, bool) onSettingChanged;

  const NotificationSettingsWidget({
    super.key,
    required this.settings,
    required this.onSettingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    final List<Map<String, dynamic>> notificationOptions = [
      {
        'key': 'newEpisodes',
        'title': 'New Episodes',
        'subtitle': 'Get notified when new episodes are available',
        'icon': 'notifications_active',
      },
      {
        'key': 'recommendations',
        'title': 'Recommendations',
        'subtitle': 'Receive personalized podcast suggestions',
        'icon': 'recommend',
      },
      {
        'key': 'earnings',
        'title': 'Earnings Updates',
        'subtitle': 'Get notified about your listening rewards',
        'icon': 'paid',
      },
      {
        'key': 'social',
        'title': 'Social Updates',
        'subtitle': 'Friends activity and community updates',
        'icon': 'people',
      },
      {
        'key': 'marketing',
        'title': 'Promotional Offers',
        'subtitle': 'Special deals and premium features',
        'icon': 'local_offer',
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
                iconName: 'notifications',
                size: 24,
                color: currentTheme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Notification Preferences',
                style: currentTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...notificationOptions.map((option) => _buildNotificationOption(
                context,
                option['key'],
                option['title'],
                option['subtitle'],
                option['icon'],
                settings[option['key']] ?? false,
              )),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(
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
                  ? currentTheme.colorScheme.primary.withAlpha(26)
                  : currentTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              size: 20,
              color: value
                  ? currentTheme.colorScheme.primary
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
            activeColor: currentTheme.colorScheme.primary,
            inactiveThumbColor: currentTheme.colorScheme.outline,
            inactiveTrackColor:
                currentTheme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
