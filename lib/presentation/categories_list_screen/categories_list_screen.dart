import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/category_grid_widget.dart';
import './widgets/category_search_widget.dart';
import '../../data/models/category.dart';
import '../../data/repositories/podcast_repository.dart';
import '../../core/routes/app_routes.dart';

// lib/presentation/categories_list_screen/categories_list_screen.dart

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PodcastRepository _podcastRepository = PodcastRepository();

  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  bool _isSearchActive = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _navigationService.trackNavigation(AppRoutes.categoriesListScreen);
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await _podcastRepository.initialize();
      final categories = await _podcastRepository.getCategories();
      setState(() {
        _allCategories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _allCategories;
        _isSearchActive = false;
      } else {
        _filteredCategories = _allCategories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _isSearchActive = true;
      }
    });
  }

  void _onCategoryTap(Category category) {
    debugPrint(
        'CategoriesListScreen: onCategoryTap id=${category.id}, name=${category.name}');
    _navigationService.navigateTo(AppRoutes.categoryPodcasts, arguments: {
      'id': category.id,
      'name': category.name,
      'icon': category.icon,
      'count': category.count,
      'gradientStart': category.gradientStart,
      'gradientEnd': category.gradientEnd,
    });
  }

  Future<void> _onRefresh() async {
    await _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          CategorySearchWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            isActive: _isSearchActive,
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        child: CategoryGridWidget(
                          categories: _filteredCategories
                              .map((cat) => {
                                    'id': cat.id,
                                    'name': cat.name,
                                    'icon': cat.icon,
                                    'count': cat.count,
                                    'gradientStart': cat.gradientStart,
                                    'gradientEnd': cat.gradientEnd,
                                  })
                              .toList(),
                          onCategoryTap: (cat) => _onCategoryTap(_allCategories
                              .firstWhere((c) => c.id == cat['id'])),
                          scrollController: _scrollController,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2.h,
        left: 4.w,
        right: 4.w,
        bottom: 2.h,
      ),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigationService.goBack(),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
                ),
              ),
              child: CustomIconWidget(
                iconName: 'arrow_back_ios',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse Categories',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${_filteredCategories.length} categories',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
