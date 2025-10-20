import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../data/models/podcast.dart';
import '../../data/repositories/podcast_repository.dart';
import '../home_screen/widgets/podcast_card_widget.dart';
import '../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core/error_handling/global_error_handler.dart';
import '../../core/utils/smooth_scroll_utils.dart';
import '../../core/utils/mini_player_positioning.dart';
import '../../widgets/episode_detail_modal.dart';

// lib/presentation/category_podcasts_screen/category_podcasts_screen.dart

class CategoryPodcastsScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryPodcastsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryPodcastsScreen> createState() => _CategoryPodcastsScreenState();
}

class _CategoryPodcastsScreenState extends State<CategoryPodcastsScreen> {
  final PodcastRepository _podcastRepository = PodcastRepository();
  bool _isLoading = true;
  List<Podcast> _podcasts = [];
  String _sortBy = 'Popular';
  final List<String> _sortOptions = ['Popular', 'Recent', 'A-Z', 'Duration'];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    debugPrint('CategoryPodcastsScreen:initState -> category: '
        'id=${widget.category['id']}, name=${widget.category['name']}');
    _loadCategoryPodcasts();
  }

  Future<void> _loadCategoryPodcasts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final String catId = widget.category['id'].toString();
    final String catName = widget.category['name'].toString();
    final Stopwatch sw = Stopwatch()..start();
    debugPrint('CategoryPodcastsScreen: Loading podcasts for '
        'category id=$catId name=$catName');

    try {
      debugPrint('CategoryPodcastsScreen: Initializing repository...');
      await _podcastRepository
          .initialize()
          .timeout(const Duration(seconds: 10));
      debugPrint('CategoryPodcastsScreen: Repository initialized');
      final podcasts = await _podcastRepository
          .getPodcastsByCategory(catId, catName)
          .timeout(const Duration(seconds: 15));

      debugPrint('CategoryPodcastsScreen: Fetched ${podcasts.length} podcasts '
          'in ${sw.elapsedMilliseconds} ms');

      if (mounted) {
        setState(() {
          _podcasts = podcasts;
          _isLoading = false;
        });
      }
    } on TimeoutException catch (_) {
      debugPrint('CategoryPodcastsScreen: Timeout while loading category');
      if (mounted) {
        setState(() {
          _errorMessage = 'Request timed out. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('CategoryPodcastsScreen: Error loading category: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load podcasts for this category.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSortChanged(String sortOption) {
    setState(() {
      _sortBy = sortOption;
      _podcasts = List.from(_podcasts);
      // Apply sorting logic here based on sortOption
      switch (sortOption) {
        case 'A-Z':
          _podcasts.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'Recent':
          // Sort by ID as a proxy for recent (higher ID = more recent)
          _podcasts.sort((a, b) =>
              int.parse(a.id.toString()).compareTo(int.parse(b.id.toString())));
          break;
        case 'Duration':
          _podcasts.sort((a, b) => a.duration.compareTo(b.duration));
          break;
        default: // Popular
          // Sort by ID as a proxy for popularity
          _podcasts.sort((a, b) =>
              int.parse(a.id.toString()).compareTo(int.parse(b.id.toString())));
      }
    });
  }

  void _onPodcastTap(Podcast podcast) {
    Navigator.pushNamed(context, '/podcast-detail-screen',
        arguments: podcast.toMap());
  }

  void _onSubscribe(Podcast podcast, int index) async {
    await handleSubscribeAction(
      context: context,
      podcastId: podcast.id.toString(),
      isCurrentlySubscribed: _podcasts[index].isSubscribed,
      onStateChanged: (bool subscribed) {
        if (mounted) {
          setState(() {
            _podcasts[index] = podcast.copyWith(isSubscribed: subscribed);
          });
        }
      },
    );
  }

  /// Handle long press on podcast card to show episode details
  void _onPodcastLongPress(Podcast podcast) async {
    try {
      // Fetch episodes for this podcast
      final podcastId =
          podcast.id is int ? podcast.id as int : int.tryParse(podcast.id) ?? 0;
      final episodes = await _podcastRepository.getPodcastEpisodes(podcastId);

      if (episodes.isNotEmpty) {
        final episode = episodes.first;

        // Convert episodes to map format for the modal
        final episodeMaps = episodes.map((e) => e.toJson()).toList();
        final episodeIndex = 0; // First episode

        // Show episode detail modal
        _showEpisodeDetailModal(
            context, episode.toJson(), episodeMaps, episodeIndex);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No episodes available for this podcast.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading episodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show episode detail modal for a specific episode
  void _showEpisodeDetailModal(
      BuildContext context,
      Map<String, dynamic> episode,
      List<Map<String, dynamic>> episodes,
      int episodeIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        Container(
          width: double.infinity,
          height: double.infinity,
          child: EpisodeDetailModal(
            episode: episode,
            episodes: episodes,
            episodeIndex: episodeIndex,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        if (subscriptionProvider.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: Text('Category Podcasts')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subscriptionProvider.errorMessage!),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      subscriptionProvider
                          .fetchAndSetSubscriptionsFromBackend();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            appBar: AppBar(
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                elevation: 0,
                leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        margin: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.lightTheme.colorScheme.shadow,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2)),
                            ]),
                        child: CustomIconWidget(
                            iconName: 'arrow_back_ios_new',
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            size: 20))),
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.category['name'] ?? '',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurface)),
                      Text('${_podcasts.length} podcasts',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme
                                      .onSurfaceVariant)),
                    ]),
                actions: [
                  PopupMenuButton<String>(
                      onSelected: _onSortChanged,
                      icon: CustomIconWidget(
                          iconName: 'sort',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 24),
                      itemBuilder: (BuildContext context) {
                        return _sortOptions.map((String option) {
                          return PopupMenuItem<String>(
                              value: option,
                              child: Row(children: [
                                Text(option),
                                if (_sortBy == option) ...[
                                  const Spacer(),
                                  CustomIconWidget(
                                      iconName: 'check',
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      size: 16),
                                ],
                              ]));
                        }).toList();
                      }),
                  SizedBox(width: 2.w),
                ]),
            body: (() {
              debugPrint('CategoryPodcastsScreen: UI -> isLoading='
                  '$_isLoading, error="$_errorMessage", count=${_podcasts.length}');
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_errorMessage.isNotEmpty) {
                debugPrint(
                    'CategoryPodcastsScreen: UI -> error: _errorMessage=$_errorMessage');
                return _buildErrorState();
              }
              if (_podcasts.isEmpty) {
                debugPrint('CategoryPodcastsScreen: UI -> empty state');
                return _buildEmptyState();
              }
              // Use grid layout which provides bounded height to card children
              // to avoid Expanded-in-unbounded errors inside ListView items.
              return _buildPodcastsList();
            })());
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CustomIconWidget(
          iconName: 'podcasts',
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 64),
      SizedBox(height: 3.h),
      Text('No Podcasts Found',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface)),
      SizedBox(height: 1.h),
      Text('There are no podcasts in this category yet.\nCheck back later!',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center),
    ]));
  }

  Widget _buildPodcastsList() {
    return Padding(
        padding: EdgeInsets.only(
          left: 4.w,
          right: 4.w,
          top: 4.w,
          bottom: MiniPlayerPositioning.bottomPaddingForScrollables(),
        ),
        child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4.w,
                mainAxisSpacing: 3.h,
                childAspectRatio: 0.75),
            itemCount: _podcasts.length,
            itemBuilder: (context, index) {
              return PodcastCardWidget(
                podcast: _podcasts[index],
                onTap: () => _onPodcastTap(_podcasts[index]),
                onSubscribe: (podcast) async =>
                    _onSubscribe(_podcasts[index], index),
                onLongPress: () => _onPodcastLongPress(_podcasts[index]),
              );
            }));
  }

  Widget _buildErrorState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CustomIconWidget(
          iconName: 'error',
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 64),
      SizedBox(height: 3.h),
      Text('Error Loading Podcasts',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface)),
      SizedBox(height: 1.h),
      Text(_errorMessage,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center),
    ]));
  }
}
