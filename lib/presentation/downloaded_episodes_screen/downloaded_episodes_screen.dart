import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import '../../services/library_api_service.dart';
import '../../models/download.dart';
import '../../core/routes/app_routes.dart';
import '../../core/error_handling/global_error_handler.dart';
import '../../core/utils/smooth_scroll_utils.dart';
import '../../core/utils/mini_player_positioning.dart';

// lib/presentation/downloaded_episodes_screen/downloaded_episodes_screen.dart

class DownloadedEpisodesScreen extends StatefulWidget {
  const DownloadedEpisodesScreen({super.key});

  @override
  State<DownloadedEpisodesScreen> createState() =>
      _DownloadedEpisodesScreenState();
}

class _DownloadedEpisodesScreenState extends State<DownloadedEpisodesScreen>
    with SafeStateMixin, SmoothScrollMixin {
  final NavigationService _navigationService = NavigationService();
  final LibraryApiService _libraryApiService = LibraryApiService();
  int _selectedTabIndex = 4;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedEpisodes = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<Download> _downloads = [];
  bool _hasMore = false;
  int _currentPage = 1;

  final List<String> _filterOptions = [
    'All',
    'Recently Downloaded',
    'Oldest First',
    'By Podcast'
  ];

  /// Load downloads from API
  Future<void> _loadDownloads({bool refresh = false}) async {
    if (refresh) {
      safeSetState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _downloads.clear();
      });
    } else if (_isLoadingMore) {
      return;
    }

    try {
      safeSetState(() {
        if (!refresh) _isLoadingMore = true;
      });

      final result = await _libraryApiService.getDownloads(
        page: _currentPage,
        context: context,
        onRetry: () => _loadDownloads(refresh: true),
      );

      if (mounted) {
        safeSetState(() {
          if (refresh) {
            _downloads = result['data'] as List<Download>;
          } else {
            _downloads.addAll(result['data'] as List<Download>);
          }
          _hasMore = result['hasMore'] as bool? ?? false;
          _currentPage = _currentPage + 1;
          _isLoading = false;
          _isLoadingMore = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        safeSetState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = e.toString();
        });
      }
    }
  }

  /// Load more downloads
  Future<void> _loadMoreDownloads() async {
    if (_hasMore && !_isLoadingMore) {
      await _loadDownloads();
    }
  }

  /// Build error state widget
  Widget _buildErrorState(ThemeData currentTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: currentTheme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Error loading downloads',
            style: currentTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: currentTheme.colorScheme.error,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _error ?? 'An error occurred while loading downloads',
            style: currentTheme.textTheme.bodyMedium?.copyWith(
              color: currentTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: () => _loadDownloads(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _navigationService.trackNavigation('/downloaded-episodes-screen');
    _loadDownloads(refresh: true);
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

  List<Download> get filteredDownloads {
    List<Download> filtered = _downloads.where((download) {
      final titleMatch = download.episode?.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ??
          false;
      final podcastMatch = download.episode?.podcast?.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ??
          false;
      return titleMatch || podcastMatch;
    }).toList();

    switch (_selectedFilter) {
      case 'Recently Downloaded':
        filtered.sort((a, b) => (b.downloadedAt ?? DateTime.now())
            .compareTo(a.downloadedAt ?? DateTime.now()));
        break;
      case 'Oldest First':
        filtered.sort((a, b) => (a.downloadedAt ?? DateTime.now())
            .compareTo(b.downloadedAt ?? DateTime.now()));
        break;
      case 'By Podcast':
        filtered.sort((a, b) => (a.episode?.podcast?.title ?? '')
            .compareTo(b.episode?.podcast?.title ?? ''));
        break;
      default:
        break;
    }

    return filtered;
  }

  void _playDownload(Download download) {
    if (download.episode == null) {
      Fluttertoast.showToast(
          msg: 'Episode data not available',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM);
      return;
    }

    // Convert Download to episode format for the player
    final episodeData = {
      'id': download.episode!.id,
      'title': download.episode!.title,
      'description': download.episode!.description ?? '',
      'duration': download.episode!.durationFormatted,
      'image': download.episode!.image ?? '',
      'audioUrl':
          download.filePath, // Use file path as audio URL for offline playback
      'podcast': {
        'id': download.episode!.podcast?.id,
        'title': download.episode!.podcast?.title ?? '',
        'author': download.episode!.podcast?.author ?? '',
        'image': download.episode!.podcast?.image ?? '',
      },
      'isDownloaded': true,
      'isOffline': true, // Mark as offline for indicator
      'filePath': download.filePath, // Include file path for offline playback
    };

    // Navigate to player with downloaded episode
    Navigator.pushNamed(
      context,
      AppRoutes.podcastPlayer,
      arguments: {
        'episode': episodeData,
        'isOffline': true,
        'source': 'downloads',
      },
    );
  }

  void _deleteDownload(String downloadId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final currentTheme = Theme.of(context);
          return AlertDialog(
              title: Text('Delete Download',
                  style: currentTheme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              content: Text(
                  'Are you sure you want to delete this downloaded episode? This action cannot be undone.',
                  style: currentTheme.textTheme.bodyMedium),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.onSurfaceVariant))),
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        await _libraryApiService.removeDownload(
                          episodeId: downloadId,
                          context: context,
                        );
                        setState(() {
                          _downloads.removeWhere((download) =>
                              download.id.toString() == downloadId);
                        });
                        Fluttertoast.showToast(
                            msg: 'Download deleted successfully',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM);
                      } catch (e) {
                        Fluttertoast.showToast(
                            msg: 'Failed to delete download',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM);
                      }
                    },
                    child: Text('Delete',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.error,
                            fontWeight: FontWeight.w600))),
              ]);
        });
  }

  void _deleteSelectedEpisodes() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final currentTheme = Theme.of(context);
          return AlertDialog(
              title: Text('Delete Downloads',
                  style: currentTheme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              content: Text(
                  'Are you sure you want to delete ${_selectedEpisodes.length} selected downloads? This action cannot be undone.',
                  style: currentTheme.textTheme.bodyMedium),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.onSurfaceVariant))),
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        // Delete selected downloads
                        for (final downloadId in _selectedEpisodes) {
                          await _libraryApiService.removeDownload(
                            episodeId: downloadId,
                            context: context,
                          );
                        }
                        setState(() {
                          _downloads.removeWhere((download) => _selectedEpisodes
                              .contains(download.id.toString()));
                          _selectedEpisodes.clear();
                          _isSelectionMode = false;
                        });
                        Fluttertoast.showToast(
                            msg: 'Selected downloads deleted successfully',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM);
                      } catch (e) {
                        Fluttertoast.showToast(
                            msg: 'Failed to delete some downloads',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM);
                      }
                    },
                    child: Text('Delete',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.error,
                            fontWeight: FontWeight.w600))),
              ]);
        });
  }

  double _calculateTotalSize() {
    return _downloads.fold(
        0.0,
        (sum, download) =>
            sum +
            (download.fileSize?.toDouble() ?? 0.0) /
                (1024 * 1024)); // Convert bytes to MB
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final downloads = filteredDownloads;

    return Scaffold(
        backgroundColor: currentTheme.scaffoldBackgroundColor,
        appBar: AppBar(
            backgroundColor: currentTheme.colorScheme.surface,
            elevation: 0,
            title: Text(
                _isSelectionMode
                    ? '${_selectedEpisodes.length} selected'
                    : 'Downloaded Episodes',
                style: currentTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: currentTheme.colorScheme.onSurface)),
            centerTitle: true,
            leading: IconButton(
                icon: CustomIconWidget(
                    iconName: _isSelectionMode ? 'close' : 'arrow_back',
                    color: currentTheme.colorScheme.onSurface,
                    size: 24),
                onPressed: () {
                  if (_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedEpisodes.clear();
                    });
                  } else {
                    _navigationService.goBack();
                  }
                }),
            actions: [
              if (_isSelectionMode) ...[
                IconButton(
                    icon: CustomIconWidget(
                        iconName: 'delete',
                        color: currentTheme.colorScheme.error,
                        size: 24),
                    onPressed: _selectedEpisodes.isNotEmpty
                        ? _deleteSelectedEpisodes
                        : null),
              ] else ...[
                IconButton(
                    icon: CustomIconWidget(
                        iconName: 'more_vert',
                        color: currentTheme.colorScheme.onSurface,
                        size: 24),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = true;
                      });
                    }),
              ],
            ]),
        body: Stack(children: [
          Column(children: [
            // Storage Info Card
            if (!_isSelectionMode) _buildStorageInfoCard(currentTheme),

            // Search and Filter
            if (!_isSelectionMode) _buildSearchAndFilter(currentTheme),

            // Downloads List
            Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState(currentTheme)
                        : downloads.isEmpty
                            ? _buildEmptyState(currentTheme)
                            : ListView.builder(
                                controller: scrollController,
                                physics: SmoothScrollUtils.defaultPhysics,
                                padding: EdgeInsets.only(
                                  bottom: MiniPlayerPositioning
                                      .bottomPaddingForScrollables(),
                                ),
                                itemCount:
                                    downloads.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == downloads.length && _hasMore) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: _isLoadingMore
                                            ? const CircularProgressIndicator()
                                            : ElevatedButton(
                                                onPressed: _loadMoreDownloads,
                                                child: const Text('Load More'),
                                              ),
                                      ),
                                    );
                                  }
                                  final download = downloads[index];
                                  return _buildDownloadCard(
                                      currentTheme, download, index);
                                })),
          ]),
          // Floating Action Button for Scroll to Top
          if (_downloads.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 80,
              child: FloatingActionButton(
                mini: true,
                onPressed: scrollToTop,
                backgroundColor: currentTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigationWidget(
                  currentIndex: _selectedTabIndex,
                  onTabSelected: _onTabSelected)),
        ]));
  }

  Widget _buildStorageInfoCard(ThemeData currentTheme) {
    final totalSize = _calculateTotalSize();
    final totalEpisodes = _downloads.length;

    return Container(
        margin: EdgeInsets.all(4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  currentTheme.colorScheme.primary.withValues(alpha: 0.1),
                  currentTheme.colorScheme.secondary.withValues(alpha: 0.05),
                ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    currentTheme.colorScheme.primary.withValues(alpha: 0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [
            CustomIconWidget(
                iconName: 'download',
                color: currentTheme.colorScheme.primary,
                size: 28),
            SizedBox(height: 1.h),
            Text('$totalEpisodes',
                style: currentTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: currentTheme.colorScheme.primary)),
            Text('Episodes',
                style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant)),
          ]),
          Container(
              height: 6.h,
              width: 1,
              color: currentTheme.colorScheme.outline.withValues(alpha: 0.3)),
          Column(children: [
            CustomIconWidget(
                iconName: 'storage',
                color: currentTheme.colorScheme.secondary,
                size: 28),
            SizedBox(height: 1.h),
            Text('${totalSize.toStringAsFixed(1)} MB',
                style: currentTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: currentTheme.colorScheme.secondary)),
            Text('Total Size',
                style: currentTheme.textTheme.bodySmall?.copyWith(
                    color: currentTheme.colorScheme.onSurfaceVariant)),
          ]),
        ]));
  }

  Widget _buildSearchAndFilter(ThemeData currentTheme) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(children: [
          // Search Bar
          TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                  hintText: 'Search episodes...',
                  prefixIcon: CustomIconWidget(
                      iconName: 'search',
                      color: currentTheme.colorScheme.onSurfaceVariant,
                      size: 20),
                  filled: true,
                  fillColor: currentTheme.colorScheme.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none))),
          SizedBox(height: 2.h),

          // Filter Chips
          SizedBox(
              height: 5.h,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterOptions.length,
                  itemBuilder: (context, index) {
                    final filter = _filterOptions[index];
                    final isSelected = filter == _selectedFilter;

                    return Container(
                        margin: EdgeInsets.only(right: 2.w),
                        child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: currentTheme.colorScheme.surface,
                            selectedColor: currentTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            labelStyle: currentTheme.textTheme.bodySmall
                                ?.copyWith(
                                    color: isSelected
                                        ? currentTheme.colorScheme.primary
                                        : currentTheme
                                            .colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400)));
                  })),
          SizedBox(height: 2.h),
        ]));
  }

  Widget _buildDownloadCard(
      ThemeData currentTheme, Download download, int index) {
    final isSelected = _selectedEpisodes.contains(download.id.toString());

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
            color: currentTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: _isSelectionMode && isSelected
                ? Border.all(color: currentTheme.colorScheme.primary, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                  color: currentTheme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ]),
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedEpisodes.remove(download.id.toString());
                  } else {
                    _selectedEpisodes.add(download.id.toString());
                  }
                });
              } else {
                _playDownload(download);
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedEpisodes.add(download.id.toString());
                });
              }
            },
            child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(children: [
                  // Selection Indicator
                  if (_isSelectionMode) ...[
                    Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected
                                    ? currentTheme.colorScheme.primary
                                    : currentTheme.colorScheme.outline,
                                width: 2),
                            color: isSelected
                                ? currentTheme.colorScheme.primary
                                : Colors.transparent),
                        child: isSelected
                            ? CustomIconWidget(
                                iconName: 'check',
                                color: currentTheme.colorScheme.onPrimary,
                                size: 16)
                            : null),
                    SizedBox(width: 3.w),
                  ],

                  // Episode Thumbnail
                  Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: currentTheme.colorScheme.shadow
                                    .withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2)),
                          ]),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomImageWidget(
                              imageUrl: download.episode?.image ?? '',
                              width: 16.w,
                              height: 16.w,
                              fit: BoxFit.cover))),
                  SizedBox(width: 3.w),

                  // Episode Info
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(download.episode?.title ?? 'Unknown Episode',
                            style: currentTheme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 0.5.h),
                        Text(
                            download.episode?.podcast?.title ??
                                'Unknown Podcast',
                            style: currentTheme.textTheme.bodySmall?.copyWith(
                                color: currentTheme.colorScheme.primary,
                                fontWeight: FontWeight.w500)),
                        SizedBox(height: 1.h),
                        Row(children: [
                          CustomIconWidget(
                              iconName: 'access_time',
                              color: currentTheme.colorScheme.onSurfaceVariant,
                              size: 14),
                          SizedBox(width: 1.w),
                          Text(download.episode?.durationFormatted ?? 'Unknown',
                              style: currentTheme.textTheme.bodySmall?.copyWith(
                                  color: currentTheme
                                      .colorScheme.onSurfaceVariant)),
                          SizedBox(width: 3.w),
                          CustomIconWidget(
                              iconName: 'storage',
                              color: currentTheme.colorScheme.onSurfaceVariant,
                              size: 14),
                          SizedBox(width: 1.w),
                          Text(download.formattedFileSize,
                              style: currentTheme.textTheme.bodySmall?.copyWith(
                                  color: currentTheme
                                      .colorScheme.onSurfaceVariant)),
                        ]),
                        // Progress indicator removed as it's not available in Download model
                      ])),

                  // Actions
                  if (!_isSelectionMode)
                    PopupMenuButton<String>(
                        icon: CustomIconWidget(
                            iconName: 'more_vert',
                            color: currentTheme.colorScheme.onSurfaceVariant,
                            size: 20),
                        onSelected: (value) {
                          switch (value) {
                            case 'play':
                              _playDownload(download);
                              break;
                            case 'delete':
                              _deleteDownload(download.id.toString());
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                  value: 'play',
                                  child: Row(children: [
                                    CustomIconWidget(
                                        iconName: 'play_arrow',
                                        color: currentTheme.colorScheme.primary,
                                        size: 20),
                                    SizedBox(width: 2.w),
                                    Text('Play'),
                                  ])),
                              PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(children: [
                                    CustomIconWidget(
                                        iconName: 'delete',
                                        color: currentTheme.colorScheme.error,
                                        size: 20),
                                    SizedBox(width: 2.w),
                                    Text('Delete'),
                                  ])),
                            ]),
                ]))));
  }

  Widget _buildEmptyState(ThemeData currentTheme) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CustomIconWidget(
          iconName: 'download',
          color: currentTheme.colorScheme.onSurfaceVariant,
          size: 64),
      SizedBox(height: 2.h),
      Text('No Downloaded Episodes',
          style: currentTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: currentTheme.colorScheme.onSurfaceVariant)),
      SizedBox(height: 1.h),
      Text('Start downloading episodes to listen offline',
          style: currentTheme.textTheme.bodyMedium
              ?.copyWith(color: currentTheme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center),
    ]));
  }
}
