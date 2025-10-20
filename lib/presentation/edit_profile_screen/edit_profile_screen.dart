import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart';

import '../../core/app_export.dart';
import '../../core/theme_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/validation_utils.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/custom_text_input_widget.dart';
import './widgets/profile_avatar_widget.dart';
import 'package:flutter/foundation.dart';

// lib/presentation/edit_profile_screen/edit_profile_screen.dart

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final NavigationService _navigationService = NavigationService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;

  // Focus nodes
  late FocusNode _displayNameFocus;
  late FocusNode _emailFocus;
  late FocusNode _bioFocus;
  late FocusNode _locationFocus;

  // Tab controller for expandable sections
  late TabController _tabController;

  // State variables
  int _selectedTabIndex = 4; // Profile tab
  String? _profileImageUrl;
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;

  // Form validation errors
  String? _displayNameError;
  String? _emailError;
  String? _bioError;

  // Settings
  final Map<String, bool> _notificationSettings = {
    'newEpisodes': true,
    'recommendations': true,
    'earnings': true,
    'social': false,
    'marketing': false,
  };

  final Map<String, bool> _privacySettings = {
    'profileVisibility': true,
    'showListeningActivity': true,
    'allowRecommendations': true,
    'shareEarnings': false,
  };

  // Original data for change detection
  late Map<String, dynamic> _originalData;

  User? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _navigationService.trackNavigation(AppRoutes.editProfileScreen);
    _fetchUser();
    // Initialize focus nodes
    _displayNameFocus = FocusNode();
    _emailFocus = FocusNode();
    _bioFocus = FocusNode();
    _locationFocus = FocusNode();

    // Initialize tab controller
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoadingUser = true;
    });
    final user = await UserRepository().getCurrentUser();
    if (user != null) {
      _user = user;
      _displayNameController = TextEditingController(text: user.name ?? '');
      _emailController = TextEditingController(text: user.email);
      _bioController = TextEditingController(); // Add if backend supports
      _locationController = TextEditingController(); // Add if backend supports

      _profileImageUrl = user.profileImageUrl;
      _originalData = {
        'name': user.name ?? '',
        'email': user.email,
        'bio': '',
        'location': '',
        'website': '',
        'profileImageUrl': user.profileImageUrl,
        'notificationSettings': Map.from(_notificationSettings),
        'privacySettings': Map.from(_privacySettings),
      };
      _addChangeListeners();
    }
    setState(() {
      _isLoadingUser = false;
    });
  }

  void _addChangeListeners() {
    _displayNameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
    _locationController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = _displayNameController.text != _originalData['name'] ||
        _emailController.text != _originalData['email'] ||
        _bioController.text != _originalData['bio'] ||
        _locationController.text != _originalData['location'] ||
        _profileImageUrl != _originalData['profileImageUrl'];
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();

    _displayNameFocus.dispose();
    _emailFocus.dispose();
    _bioFocus.dispose();
    _locationFocus.dispose();

    _tabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog(() {
        setState(() {
          _selectedTabIndex = index;
        });
        _navigateToTab(index);
      });
    } else {
      setState(() {
        _selectedTabIndex = index;
      });
      _navigateToTab(index);
    }
  }

  void _navigateToTab(int index) {
    switch (index) {
      case 0:
        _navigationService.navigateTo(AppRoutes.homeScreen);
        break;
      case 1:
        _navigationService.navigateTo(AppRoutes.earnScreen);
        break;
      case 2:
        _navigationService.navigateTo(AppRoutes.libraryScreen);
        break;
      case 3:
        _navigationService.navigateTo(AppRoutes.walletScreen);
        break;
      case 4:
        // Stay on current screen
        break;
    }
  }

  void _onBackPressed() {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog(() {
        _navigationService.goBack();
      });
    } else {
      _navigationService.goBack();
    }
  }

  void _showUnsavedChangesDialog(VoidCallback onConfirm) {
    final currentTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Unsaved Changes',
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'You have unsaved changes. Are you sure you want to leave without saving?',
            style: currentTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: currentTheme.textTheme.labelLarge?.copyWith(
                  color: currentTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                'Leave',
                style: currentTheme.textTheme.labelLarge?.copyWith(
                  color: currentTheme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _validateForm() {
    setState(() {
      _displayNameError = null;
      _emailError = null;
      _bioError = null;
    });

    bool isValid = true;

    // Validate display name
    if (_displayNameController.text.trim().isEmpty) {
      setState(() {
        _displayNameError = 'Display name is required';
      });
      isValid = false;
    } else if (!ValidationUtils.isValidName(
        _displayNameController.text.trim())) {
      setState(() {
        _displayNameError =
            'Display name must be at least 2 characters and contain only letters and spaces';
      });
      isValid = false;
    }

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = 'Email address is required';
      });
      isValid = false;
    } else if (!ValidationUtils.isValidEmail(_emailController.text.trim())) {
      // Debug logging for email validation
      if (kDebugMode) {
        ValidationUtils.debugEmailValidation(_emailController.text.trim());
      }
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      isValid = false;
    }

    // Validate bio length
    if (_bioController.text.length > 500) {
      setState(() {
        _bioError = 'Bio must be less than 500 characters';
      });
      isValid = false;
    }

    return isValid;
  }

  void _onImageChanged(String? newImagePath) async {
    if (newImagePath == null) {
      setState(() {
        _profileImageUrl = null;
      });
      _checkForChanges();
      return;
    }

    // Handle file path from image picker
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload the image to backend
      final url = await UserRepository().uploadAvatar(newImagePath);
      setState(() {
        _profileImageUrl = url;
        _isLoading = false;
      });
      _checkForChanges();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text('Profile photo updated successfully'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'error',
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text('Failed to upload image: $e'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Temporarily disabled - will be restored when advanced settings are re-enabled
  // void _onNotificationSettingChanged(String key, bool value) {
  //   setState(() {
  //     _notificationSettings[key] = value;
  //     _hasUnsavedChanges = true;
  //   });
  // }

  // void _onPrivacySettingChanged(String key, bool value) {
  //   setState(() {
  //     _privacySettings[key] = value;
  //     _hasUnsavedChanges = true;
  //   });
  // }

  // Temporarily disabled - will be restored when advanced settings are re-enabled
  // Widget _buildAdvancedOption(
  //   BuildContext context,
  //   String title,
  //   String subtitle,
  //   String iconName,
  //   VoidCallback onTap,
  // ) {
  //   final currentTheme = Theme.of(context);

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(12),
  //       child: Container(
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: currentTheme.colorScheme.surfaceContainerHighest,
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: currentTheme.colorScheme.outline.withAlpha(50),
  //             width: 1,
  //           ),
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               width: 40,
  //               height: 40,
  //               decoration: BoxDecoration(
  //                 color: currentTheme.colorScheme.secondary.withAlpha(26),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: CustomIconWidget(
  //                 iconName: iconName,
  //                 size: 20,
  //                 color: currentTheme.colorScheme.secondary,
  //               ),
  //             ),
  //             SizedBox(width: 3.w),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title,
  //                     style: currentTheme.textTheme.bodyLarge?.copyWith(
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   Text(
  //                     subtitle,
  //                     style: currentTheme.textTheme.bodySmall?.copyWith(
  //                       color: currentTheme.colorScheme.onSurfaceVariant,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             CustomIconWidget(
  //               iconName: 'arrow_forward_ios',
  //               size: 16,
  //               color: currentTheme.colorScheme.onSurfaceVariant,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_validateForm()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final success = await UserRepository().updateUserProfile({
      'name': _displayNameController.text.trim(),
      'email': _emailController.text.trim(),
      // Add other fields if supported by backend
      'profileImage': _profileImageUrl,
      'subscribedCategories': _user?.subscribedCategories ?? [],
    });
    setState(() {
      _isLoading = false;
    });
    if (success) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text('Profile updated successfully'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      _navigationService.goBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'error',
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text('Failed to update profile. Please try again.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final currentTheme = Theme.of(context);
        if (_isLoadingUser) {
          return const Center(child: CircularProgressIndicator());
        }
        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvoked: (didPop) {
            if (!didPop && _hasUnsavedChanges) {
              _onBackPressed();
            }
          },
          child: Scaffold(
            backgroundColor: currentTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: currentTheme.colorScheme.surface,
              elevation: 0,
              title: Text(
                'Edit Profile',
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
                onPressed: _onBackPressed,
              ),
              actions: [
                if (_hasUnsavedChanges)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  currentTheme.colorScheme.primary,
                                ),
                              ),
                            )
                          : CustomIconWidget(
                              iconName: 'save',
                              color: currentTheme.colorScheme.primary,
                              size: 24,
                            ),
                      onPressed: _isLoading ? null : _saveProfile,
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                // Main content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16, 2.h, 16, 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar section
                          ProfileAvatarWidget(
                            currentImageUrl: _profileImageUrl,
                            onImageChanged: _onImageChanged,
                            isEditing: true,
                          ),

                          SizedBox(height: 4.h),

                          // Basic Information
                          Text(
                            'Basic Information',
                            style: currentTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: currentTheme.colorScheme.primary,
                            ),
                          ),

                          SizedBox(height: 2.h),

                          CustomTextInputWidget(
                            controller: _displayNameController,
                            focusNode: _displayNameFocus,
                            labelText: 'Display Name',
                            hintText: 'Enter your display name',
                            iconName: 'person',
                            textInputAction: TextInputAction.next,
                            maxLength: 50,
                            errorText: _displayNameError,
                            onChanged: (value) => _checkForChanges(),
                            onSubmitted: (value) => _emailFocus.requestFocus(),
                          ),

                          SizedBox(height: 2.h),

                          CustomTextInputWidget(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            labelText: 'Email Address',
                            hintText: 'Enter your email address',
                            iconName: 'email',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            errorText: _emailError,
                            onChanged: (value) => _checkForChanges(),
                            onSubmitted: (value) => _bioFocus.requestFocus(),
                          ),

                          SizedBox(height: 2.h),

                          CustomTextInputWidget(
                            controller: _bioController,
                            focusNode: _bioFocus,
                            labelText: 'Bio',
                            hintText: 'Tell us about yourself...',
                            iconName: 'description',
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            maxLines: 4,
                            maxLength: 500,
                            errorText: _bioError,
                            onChanged: (value) => _checkForChanges(),
                          ),

                          SizedBox(height: 2.h),

                          CustomTextInputWidget(
                            controller: _locationController,
                            focusNode: _locationFocus,
                            labelText: 'Location',
                            hintText: 'City, Country',
                            iconName: 'location_on',
                            textInputAction: TextInputAction.done,
                            maxLength: 100,
                            onChanged: (value) => _checkForChanges(),
                            onSubmitted: (value) => _checkForChanges(),
                          ),

                          SizedBox(height: 4.h),

                          // Advanced Settings with Tabs - Temporarily disabled
                          // Container(
                          // decoration: BoxDecoration(
                          //   color: currentTheme.cardColor,
                          //   borderRadius: BorderRadius.circular(12),
                          //   border: Border.all(
                          //     color: currentTheme.colorScheme.outline
                          //         .withAlpha(77),
                          //     width: 1,
                          //   ),
                          //   boxShadow: [
                          //     BoxShadow(
                          //       color: currentTheme.colorScheme.shadow
                          //           .withAlpha(26),
                          //       blurRadius: 8,
                          //       offset: const Offset(0, 2),
                          //     ),
                          //   ],
                          // ),
                          // child: Column(
                          //   children: [
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: currentTheme.colorScheme.surface,
                          //     borderRadius: const BorderRadius.only(
                          //       topLeft: Radius.circular(12),
                          //       topRight: Radius.circular(12),
                          //     ),
                          //   ),
                          //   child: TabBar(
                          //     controller: _tabController,
                          //     labelColor:
                          //         currentTheme.colorScheme.primary,
                          //     unselectedLabelColor: currentTheme
                          //         .colorScheme.onSurfaceVariant,
                          //     indicatorColor:
                          //         currentTheme.colorScheme.primary,
                          //     indicatorWeight: 3,
                          //     labelStyle: currentTheme
                          //         .textTheme.labelLarge
                          //         ?.copyWith(
                          //       fontWeight: FontWeight.w600,
                          //     ),
                          //     unselectedLabelStyle: currentTheme
                          //         .textTheme.labelLarge
                          //         ?.copyWith(
                          //       fontWeight: FontWeight.w500,
                          //     ),
                          //     tabs: const [
                          //       Tab(text: 'Notifications'),
                          //       Tab(text: 'Privacy'),
                          //       Tab(text: 'Advanced'),
                          //     ],
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 350, // Reduced height for better fit
                          //   child: TabBarView(
                          //     controller: _tabController,
                          //     children: [
                          //       // Notifications Tab
                          //       Padding(
                          //         padding: const EdgeInsets.all(16),
                          //         child: NotificationSettingsWidget(
                          //           settings: _notificationSettings,
                          //           onSettingChanged:
                          //               _onNotificationSettingChanged,
                          //         ),
                          //       ),

                          //       // Privacy Tab
                          //       Padding(
                          //         padding: const EdgeInsets.all(16),
                          //         child: PrivacySettingsWidget(
                          //           settings: _privacySettings,
                          //           onSettingChanged:
                          //               _onPrivacySettingChanged,
                          //         ),
                          //       ),

                          //       // Advanced Tab
                          //       Padding(
                          //         padding: const EdgeInsets.all(16),
                          //         child: Column(
                          //           crossAxisAlignment:
                          //               CrossAxisAlignment.start,
                          //           children: [
                          //             Row(
                          //               children: [
                          //                 CustomIconWidget(
                          //                   iconName: 'settings',
                          //                   size: 24,
                          //                   color: currentTheme
                          //                       .colorScheme.secondary,
                          //                 ),
                          //                 SizedBox(width: 2.w),
                          //                 Text(
                          //                   'Advanced Settings',
                          //                   style: currentTheme
                          //                       .textTheme.titleMedium
                          //                       ?.copyWith(
                          //                     fontWeight: FontWeight.w600,
                          //                   ),
                          //                 ),
                          //               ],
                          //             ),
                          //             SizedBox(height: 2.h),
                          //             _buildAdvancedOption(
                          //               context,
                          //               'Account Management',
                          //               'Manage your account settings and preferences',
                          //               'account_circle',
                          //               () {},
                          //             ),
                          //             _buildAdvancedOption(
                          //               context,
                          //               'Data & Storage',
                          //               'Control your data usage and storage settings',
                          //               'storage',
                          //               () {},
                          //             ),
                          //             _buildAdvancedOption(
                          //               context,
                          //               'Security',
                          //               'Manage your security settings and passwords',
                          //               'security',
                          //               () {},
                          //             ),
                          //             _buildAdvancedOption(
                          //               context,
                          //               'Help & Support',
                          //               'Get help and contact support',
                          //               'help_outline',
                          //               () {},
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // ],
                          // ),
                          // ),

                          // SizedBox(height: 2.h), // Minimal space
                        ],
                      ),
                    ),
                  ),
                ),

                // Save button
                if (_hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentTheme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: currentTheme.colorScheme.outline.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.colorScheme.shadow.withAlpha(26),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: currentTheme.colorScheme.primary,
                            foregroundColor: currentTheme.colorScheme.onPrimary,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      currentTheme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: currentTheme.textTheme.labelLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: currentTheme.colorScheme.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                // Bottom navigation
                Container(
                  decoration: BoxDecoration(
                    color: currentTheme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: currentTheme.colorScheme.shadow.withAlpha(26),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: CommonBottomNavigationWidget(
                      currentIndex: _selectedTabIndex,
                      onTabSelected: _onTabSelected,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
