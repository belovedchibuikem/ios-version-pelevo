import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/profile_screen/widgets/profile_header_widget.dart

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback onEditTap;

  const ProfileHeaderWidget({
    super.key,
    required this.userProfile,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.lightTheme.colorScheme.primary,
                  AppTheme.lightTheme.colorScheme.primaryContainer,
                ]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]),
        child: Column(children: [
          // Profile Picture and Edit Button
          Center(
            child: Stack(alignment: Alignment.center, children: [
              Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]),
                  child: ClipOval(
                    child: userProfile['profileImage'] != null
                        ? CustomImageWidget(
                            imageUrl: userProfile['profileImage'],
                            width: 24.w - 8,
                            height: 24.w - 8,
                            fit: BoxFit.cover)
                        : Center(
                            child: CustomIconWidget(
                                iconName: 'person',
                                size: 12.w,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant)),
                  )),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      AppTheme.lightTheme.colorScheme.onPrimary,
                                  width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]),
                          child: CustomIconWidget(
                              iconName: 'edit',
                              size: 18,
                              color: AppTheme
                                  .lightTheme.colorScheme.onSecondary)))),
            ]),
          ),

          SizedBox(height: 3.h),

          // User Name and Email
          Text(userProfile['name'] ?? 'User Name',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 1.h),
          Text(userProfile['email'] ?? 'user@example.com',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary
                      .withValues(alpha: 0.9))),

          SizedBox(height: 0.5.h),

          // Member Since
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onPrimary
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              'Member Since: ${userProfile['memberSince'] ?? 'Registration'}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary
                      .withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(height: 4.h),

          // Statistics Row
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildStatItem(
                'Subscriptions',
                userProfile['subscriptionsCount']?.toString() ?? '0',
                'rss_feed'),
            _buildDivider(),
            _buildStatItem('Hours Listened',
                userProfile['listeningHours']?.toString() ?? '0', 'headphones'),
            _buildDivider(),
            _buildStatItem(
                'Coins Earned',
                userProfile['totalCoins']?.toString() ?? '0',
                'monetization_on'),
          ]),

          SizedBox(height: 3.h),

          // Level Progress
          if (userProfile['level'] != null) ...[_buildLevelProgress()],
        ]));
  }

  Widget _buildStatItem(String label, String value, String iconName) {
    return Expanded(
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]),
            child: CustomIconWidget(
                iconName: iconName,
                size: 24,
                color: AppTheme.lightTheme.colorScheme.onPrimary)),
        SizedBox(height: 1.h),
        Text(value,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold)),
        Text(label,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.8),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 8.h,
      color: AppTheme.lightTheme.colorScheme.onPrimary.withValues(alpha: 0.3),
    );
  }

  Widget _buildLevelProgress() {
    return Column(
      children: [
        // Level Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.colorScheme.secondary,
                AppTheme.lightTheme.colorScheme.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'star',
                size: 20,
                color: AppTheme.lightTheme.colorScheme.onSecondary,
              ),
              SizedBox(width: 2.w),
              Text(
                userProfile['level'] ?? 'Member',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Progress Bar
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to next level',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary
                        .withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '${((userProfile['nextLevelProgress'] ?? 0.0) * 100).toInt()}%',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: userProfile['nextLevelProgress'] ?? 0.0,
                backgroundColor: AppTheme.lightTheme.colorScheme.onPrimary
                    .withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.secondary,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
