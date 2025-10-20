import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

// lib/presentation/profile_screen/widgets/settings_section_widget.dart

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Function(String)? onItemTap;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: currentTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              title,
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentTheme.colorScheme.primary,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: currentTheme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildSettingsItem(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, Map<String, dynamic> item) {
    final String type = item['type'] ?? 'navigation';

    switch (type) {
      case 'switch':
        return _buildSwitchItem(context, item);
      case 'selection':
        return _buildSelectionItem(context, item);
      case 'navigation':
      default:
        return _buildNavigationItem(context, item);
    }
  }

  Widget _buildNavigationItem(BuildContext context, Map<String, dynamic> item) {
    final currentTheme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              _getIconColor(context, item['iconColor']).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: item['icon'] ?? 'settings',
          size: 20,
          color: _getIconColor(context, item['iconColor']),
        ),
      ),
      title: Text(
        item['title'] ?? '',
        style: currentTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: item['subtitle'] != null
          ? Text(
              item['subtitle'],
              style: currentTheme.textTheme.bodySmall?.copyWith(
                color: currentTheme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: CustomIconWidget(
        iconName: 'chevron_right',
        size: 20,
        color: currentTheme.colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        if (item['key'] != null) {
          onItemTap?.call(item['key']);
        }
      },
    );
  }

  Widget _buildSwitchItem(BuildContext context, Map<String, dynamic> item) {
    final currentTheme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              _getIconColor(context, item['iconColor']).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: item['icon'] ?? 'settings',
          size: 20,
          color: _getIconColor(context, item['iconColor']),
        ),
      ),
      title: Text(
        item['title'] ?? '',
        style: currentTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: item['subtitle'] != null
          ? Text(
              item['subtitle'],
              style: currentTheme.textTheme.bodySmall?.copyWith(
                color: currentTheme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Switch(
        value: item['value'] ?? false,
        onChanged: (value) {
          if (item['key'] != null) {
            onItemTap?.call(item['key']);
          }
        },
      ),
    );
  }

  Widget _buildSelectionItem(BuildContext context, Map<String, dynamic> item) {
    final currentTheme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              _getIconColor(context, item['iconColor']).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: item['icon'] ?? 'settings',
          size: 20,
          color: _getIconColor(context, item['iconColor']),
        ),
      ),
      title: Text(
        item['title'] ?? '',
        style: currentTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        item['currentValue'] ?? item['subtitle'] ?? '',
        style: currentTheme.textTheme.bodySmall?.copyWith(
          color: currentTheme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: CustomIconWidget(
        iconName: 'chevron_right',
        size: 20,
        color: currentTheme.colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        if (item['key'] != null) {
          onItemTap?.call(item['key']);
        }
      },
    );
  }

  Color _getIconColor(BuildContext context, String? colorName) {
    final currentTheme = Theme.of(context);

    switch (colorName) {
      case 'primary':
        return currentTheme.colorScheme.primary;
      case 'secondary':
        return currentTheme.colorScheme.secondary;
      case 'tertiary':
        return currentTheme.colorScheme.tertiary;
      case 'error':
        return currentTheme.colorScheme.error;
      default:
        return currentTheme.colorScheme.primary;
    }
  }
}
