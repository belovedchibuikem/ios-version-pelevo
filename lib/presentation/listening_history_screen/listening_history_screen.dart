import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/history_provider.dart';
import '../../models/play_history.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/history_filter_widget.dart';
import './widgets/history_statistics_widget.dart';
import './widgets/history_list_widget.dart';
import '../../core/routes/app_routes.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen>
    with TickerProviderStateMixin {
  final NavigationService _navigationService = NavigationService();
  int _selectedTabIndex = 2; // Library tab
  late TabController _tabController;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterOptions = [
    'All',
    'In Progress',
    'Completed',
    'Recent',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _navigationService.trackNavigation(AppRoutes.listeningHistoryScreen);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyProvider =
          Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.loadPlayHistory(refresh: true);
      historyProvider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

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
        _navigationService.navigateTo(AppRoutes.profileScreen);
        break;
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);

    switch (filter) {
      case 'All':
        historyProvider.loadPlayHistory(refresh: true);
        break;
      case 'In Progress':
        historyProvider.loadInProgressEpisodes();
        break;
      case 'Completed':
        historyProvider.loadCompletedEpisodes();
        break;
      case 'Recent':
        historyProvider.loadRecentHistory();
        break;
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    if (query.isNotEmpty) {
      final historyProvider =
          Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.searchHistory(query);
    } else {
      _onFilterChanged(_selectedFilter);
    }
  }

  void _onRefresh() async {
    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);
    await historyProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: currentTheme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Listening History',
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
        actions: [
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: currentTheme.colorScheme.onSurface,
              size: 24,
            ),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear All History'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export History'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(currentTheme),
          _buildStatisticsTab(currentTheme),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData currentTheme) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        return Column(
          children: [
            // Filter and Search Section
            HistoryFilterWidget(
              selectedFilter: _selectedFilter,
              searchQuery: _searchQuery,
              filterOptions: _filterOptions,
              onFilterChanged: _onFilterChanged,
              onSearchChanged: _onSearchChanged,
            ),

            // History List
            Expanded(
              child: HistoryListWidget(
                historyProvider: historyProvider,
                onRefresh: _onRefresh,
                onHistoryTap: (history) {
                  Navigator.pushNamed(context, '/podcast-player', arguments: {
                    'episode': history.episode,
                    'playHistory': history,
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatisticsTab(ThemeData currentTheme) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        return HistoryStatisticsWidget(
          statistics: historyProvider.statistics,
          isLoading: historyProvider.isLoading,
          onRefresh: _onRefresh,
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'export':
        _exportHistory();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All History'),
        content: Text(
            'Are you sure you want to clear all your listening history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<HistoryProvider>(context, listen: false)
                  .clearAllPlayHistory();
              Navigator.pop(context);
            },
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportHistory() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
