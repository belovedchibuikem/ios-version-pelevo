import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/navigation_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_icon_widget.dart';
//import '../../widgets/custom_app_bar.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I download episodes for offline listening?',
      'answer':
          'To download episodes, tap the download icon next to any episode. Downloaded episodes will appear in your "Downloaded Episodes" section and can be played offline.',
      'category': 'Downloads',
    },
    {
      'question': 'How do I subscribe to a podcast?',
      'answer':
          'Navigate to any podcast and tap the "Subscribe" button. You\'ll receive notifications when new episodes are available.',
      'category': 'Subscriptions',
    },
    {
      'question': 'How do I adjust audio quality?',
      'answer':
          'Go to Profile > Settings > Audio Quality and select your preferred quality level. Higher quality uses more data but provides better sound.',
      'category': 'Audio',
    },
    {
      'question': 'How do I create a playlist?',
      'answer':
          'Currently, playlist creation is not available. You can use the "Downloaded Episodes" section to organize your favorite content.',
      'category': 'Playlists',
    },
    {
      'question': 'How do I report a bug or issue?',
      'answer':
          'Use the "Send Feedback" option in your profile settings to report bugs or suggest improvements.',
      'category': 'Support',
    },
    {
      'question': 'How do I manage my listening statistics?',
      'answer':
          'View your listening statistics in the Profile section. You can see your listening time, favorite podcasts, and activity patterns.',
      'category': 'Statistics',
    },
    {
      'question': 'How do I change my notification settings?',
      'answer':
          'Go to Profile > Settings > Notifications to customize which notifications you receive.',
      'category': 'Notifications',
    },
    {
      'question': 'How do I delete my account?',
      'answer':
          'Go to Profile > Account Actions > Delete Account. This action is permanent and cannot be undone.',
      'category': 'Account',
    },
  ];

  final List<Map<String, dynamic>> _supportOptions = [
    {
      'title': 'Contact Support',
      'subtitle': 'Get help from our support team',
      'icon': 'support_agent',
      'iconColor': 'primary',
      'action': 'contact_support',
    },
    {
      'title': 'Send Feedback',
      'subtitle': 'Help us improve the app',
      'icon': 'feedback',
      'iconColor': 'secondary',
      'action': 'send_feedback',
    },
    {
      'title': 'Report a Bug',
      'subtitle': 'Let us know about any issues',
      'icon': 'bug_report',
      'iconColor': 'error',
      'action': 'report_bug',
    },
    {
      'title': 'Feature Request',
      'subtitle': 'Suggest new features',
      'icon': 'lightbulb',
      'iconColor': 'tertiary',
      'action': 'feature_request',
    },
  ];

  List<Map<String, dynamic>> get filteredFaqs {
    if (_searchQuery.isEmpty) {
      return _faqs;
    }
    return _faqs.where((faq) {
      return faq['question']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['category'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: currentTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Help Center',
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
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search help topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: currentTheme.colorScheme.surface,
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Support Options
                  if (_searchQuery.isEmpty) ...[
                    Text(
                      'Get Help',
                      style: currentTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildSupportOptions(currentTheme),
                    SizedBox(height: 4.h),
                  ],

                  // FAQs
                  Text(
                    _searchQuery.isEmpty
                        ? 'Frequently Asked Questions'
                        : 'Search Results',
                    style: currentTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  if (filteredFaqs.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: currentTheme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No results found for "$_searchQuery"',
                            style: currentTheme.textTheme.bodyLarge?.copyWith(
                              color: currentTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildFaqList(currentTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOptions(ThemeData currentTheme) {
    return Column(
      children: _supportOptions.map((option) {
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: currentTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: currentTheme.colorScheme.shadow.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _getIconColor(option['iconColor'], currentTheme)
                    .withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: option['icon'],
                color: _getIconColor(option['iconColor'], currentTheme),
                size: 24,
              ),
            ),
            title: Text(
              option['title'],
              style: currentTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              option['subtitle'],
              style: currentTheme.textTheme.bodyMedium?.copyWith(
                color: currentTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _onSupportOptionTap(option['action']),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFaqList(ThemeData currentTheme) {
    return Column(
      children: filteredFaqs.map((faq) {
        return ExpansionTile(
          title: Text(
            faq['question'],
            style: currentTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            faq['category'],
            style: currentTheme.textTheme.bodySmall?.copyWith(
              color: currentTheme.colorScheme.primary,
            ),
          ),
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              child: Text(
                faq['answer'],
                style: currentTheme.textTheme.bodyMedium,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getIconColor(String colorType, ThemeData theme) {
    switch (colorType) {
      case 'primary':
        return theme.colorScheme.primary;
      case 'secondary':
        return theme.colorScheme.secondary;
      case 'tertiary':
        return theme.colorScheme.tertiary;
      case 'error':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }

  void _onSupportOptionTap(String action) {
    switch (action) {
      case 'contact_support':
        _showContactSupportDialog();
        break;
      case 'send_feedback':
        _navigationService.navigateTo(AppRoutes.feedbackScreen);
        break;
      case 'report_bug':
        _showReportBugDialog();
        break;
      case 'feature_request':
        _showFeatureRequestDialog();
        break;
    }
  }

  void _showContactSupportDialog() {
    final currentTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Contact Support',
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get help from our support team:',
                style: currentTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              _buildContactOption(
                'Email Support',
                'support@pelevo.com',
                Icons.email,
                () => _launchEmail('support@pelevo.com'),
              ),
              SizedBox(height: 1.h),
              _buildContactOption(
                'Live Chat',
                'Available 24/7',
                Icons.chat,
                () => _launchLiveChat(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    final currentTheme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: currentTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: currentTheme.colorScheme.outline.withAlpha(50),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: currentTheme.colorScheme.primary),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: currentTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportBugDialog() {
    final currentTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Report a Bug',
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Please use the "Send Feedback" option to report bugs. Include as much detail as possible about the issue you encountered.',
            style: currentTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigationService.navigateTo(AppRoutes.feedbackScreen);
              },
              child: Text('Send Feedback'),
            ),
          ],
        );
      },
    );
  }

  void _showFeatureRequestDialog() {
    final currentTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Feature Request',
            style: currentTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'We\'d love to hear your ideas! Use the "Send Feedback" option to suggest new features for Pelevo.',
            style: currentTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigationService.navigateTo(AppRoutes.feedbackScreen);
              },
              child: Text('Send Feedback'),
            ),
          ],
        );
      },
    );
  }

  void _launchEmail(String email) {
    // In a real app, you would use url_launcher to open email client
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email client for $email'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _launchLiveChat() {
    // In a real app, you would integrate with a live chat service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening live chat...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
