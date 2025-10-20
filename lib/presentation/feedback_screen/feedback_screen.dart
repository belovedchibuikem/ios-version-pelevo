import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/navigation_service.dart';
import '../../services/feedback_service.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../core/app_export.dart';
import '../../core/utils/validation_utils.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final NavigationService _navigationService = NavigationService();
  final FeedbackService _feedbackService = FeedbackService();
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCategory = 'General Feedback';
  String _selectedPriority = 'Medium';
  bool _includeSystemInfo = true;
  bool _isSubmitting = false;
  List<String> _categories = [];
  List<String> _priorities = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndPriorities();
  }

  Future<void> _loadCategoriesAndPriorities() async {
    try {
      final categories = await _feedbackService.getCategories(context: context);
      final priorities = await _feedbackService.getPriorities(context: context);

      if (mounted) {
        setState(() {
          _categories = categories;
          _priorities = priorities;

          // Set default values if available
          if (_categories.isNotEmpty &&
              !_categories.contains(_selectedCategory)) {
            _selectedCategory = _categories.first;
          }
          if (_priorities.isNotEmpty &&
              !_priorities.contains(_selectedPriority)) {
            _selectedPriority = _priorities.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading categories and priorities: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigationService.goBack(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 48,
                    color: currentTheme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Help us improve Pelevo',
                    style: currentTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Your feedback helps us make Pelevo better for everyone',
                    style: currentTheme.textTheme.bodyMedium?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    Text(
                      'Category',
                      style: currentTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildCategorySelector(currentTheme),
                    SizedBox(height: 3.h),

                    // Priority Selection
                    Text(
                      'Priority',
                      style: currentTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildPrioritySelector(currentTheme),
                    SizedBox(height: 3.h),

                    // Subject
                    Text(
                      'Subject',
                      style: currentTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: 'Brief description of your feedback',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: currentTheme.colorScheme.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 3.h),

                    // Message
                    Text(
                      'Message',
                      style: currentTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'Please provide detailed information about your feedback, bug report, or feature request...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: currentTheme.colorScheme.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a message';
                        }
                        if (value.trim().length < 10) {
                          return 'Please provide more details (at least 10 characters)';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 3.h),

                    // Email (Optional)
                    Text(
                      'Email (Optional)',
                      style: currentTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'your.email@example.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: currentTheme.colorScheme.surface,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return ValidationUtils.validateEmail(value);
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 3.h),

                    // Include System Info
                    Container(
                      decoration: BoxDecoration(
                        color: currentTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentTheme.colorScheme.outline.withAlpha(50),
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Include System Information',
                          style: currentTheme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Include device info, app version, and system details to help us better understand your issue',
                          style: currentTheme.textTheme.bodySmall?.copyWith(
                            color: currentTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: _includeSystemInfo,
                        onChanged: (value) {
                          setState(() {
                            _includeSystemInfo = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 12.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentTheme.colorScheme.primary,
                          foregroundColor: currentTheme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 4.w,
                                    height: 4.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        currentTheme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Submitting...',
                                    style: currentTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'send',
                                    color: currentTheme.colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Submit Feedback',
                                    style: currentTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData currentTheme) {
    return Container(
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.colorScheme.outline.withAlpha(50),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
          });
        },
      ),
    );
  }

  Widget _buildPrioritySelector(ThemeData currentTheme) {
    return Container(
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.colorScheme.outline.withAlpha(50),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPriority,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        ),
        items: _priorities.map((priority) {
          return DropdownMenuItem(
            value: priority,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(priority),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPriority = value!;
          });
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit feedback using the API service
      final result = await _feedbackService.submitFeedback(
        category: _selectedCategory,
        priority: _selectedPriority,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        includeSystemInfo: _includeSystemInfo,
        systemInfo: _includeSystemInfo ? _getSystemInfo() : null,
        context: context,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    result['message'] ??
                        'Thank you! Your feedback has been submitted successfully.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _navigationService.goBack();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Failed to submit feedback. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitFeedback,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic> _getSystemInfo() {
    // In a real app, you would collect actual system information
    return {
      'appVersion': '1.0.0',
      'platform': 'Android', // or iOS
      'deviceModel': 'Unknown Device',
      'osVersion': 'Android 12',
      'screenResolution': '1080x1920',
      'availableStorage': '2.5 GB',
      'networkType': 'WiFi',
    };
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
