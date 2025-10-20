import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './episode_card_widget.dart';
import '../../library_screen/widgets/search_bar_widget.dart';
import '../../../services/podcastindex_service.dart';
import '../../../widgets/episode_detail_modal.dart';

// lib/presentation/podcast_detail_screen/widgets/episodes_tab_widget.dart

class EpisodesTabWidget extends StatefulWidget {
  final String feedId;
  final Function(Map<String, dynamic>) onPlayEpisode;
  final Function(Map<String, dynamic>) onDownloadEpisode;
  final Function(Map<String, dynamic>) onShareEpisode;

  const EpisodesTabWidget({
    super.key,
    required this.feedId,
    required this.onPlayEpisode,
    required this.onDownloadEpisode,
    required this.onShareEpisode,
  });

  @override
  State<EpisodesTabWidget> createState() => _EpisodesTabWidgetState();
}

class _EpisodesTabWidgetState extends State<EpisodesTabWidget> {
  String _searchQuery = '';
  int _currentPage = 1;
  final int _perPage = 100;
  bool _hasMore = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _episodes = [];
  Map<String, dynamic>? _meta;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (loadMore) _currentPage++;
    final podcastIndexService = PodcastIndexService();
    final data = await podcastIndexService.getPaginatedEpisodes(
        widget.feedId, _currentPage, _perPage,
        context: context);
    final newEpisodes =
        (data['episodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final meta = data['meta'] ?? {};

    if (loadMore) {
      _episodes.addAll(newEpisodes);
    } else {
      _episodes = newEpisodes;
    }
    _meta = meta;
    _hasMore = meta['has_more'] ?? false;
    _isLoading = false;
    if (!mounted) return;
    setState(() {});
  }

  String formatDuration(dynamic duration) {
    if (duration == null) return '';
    if (duration is String) return duration;
    if (duration is int) {
      final seconds = duration;
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }
    return duration.toString();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEpisodes = _searchQuery.isEmpty
        ? _episodes
        : _episodes.where((episode) {
            final title = (episode['title'] ?? '').toString().toLowerCase();
            final desc =
                (episode['description'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || desc.contains(query);
          }).toList();

    return Container(
      color: AppTheme.lightTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h, left: 4.w, right: 4.w),
            child: SearchBarWidget(
              hintText: 'Search episodes...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : (filteredEpisodes.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.all(4.w),
                              itemCount: filteredEpisodes.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 2.h),
                              itemBuilder: (context, index) {
                                final episode = filteredEpisodes[index];
                                return EpisodeCardWidget(
                                  episode: episode,
                                  onPlay: () => widget.onPlayEpisode(episode),
                                  onDownload: () =>
                                      widget.onDownloadEpisode(episode),
                                  onShare: () => widget.onShareEpisode(episode),
                                  onLongPress: () =>
                                      _showEpisodeOptions(context, episode),
                                  onShowDetails: () =>
                                      _showEpisodeDetailModal(context, episode),
                                );
                              },
                            ),
                          ),
                          if (_hasMore)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _fetchEpisodes(loadMore: true),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Text('Load More'),
                              ),
                            ),
                        ],
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'podcasts',
            size: 64,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Episodes Available',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Check back later for new episodes',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEpisodeOptions(BuildContext context, Map<String, dynamic> episode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Episode info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomImageWidget(
                        imageUrl: episode['coverImage'] ?? '',
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode['title'] ?? '',
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          formatDuration(episode['duration']),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Options
            _buildOptionItem(
              context,
              'Play Episode',
              'play_arrow',
              () {
                Navigator.pop(context);
                widget.onPlayEpisode(episode);
              },
            ),
            _buildOptionItem(
              context,
              episode['isDownloaded'] ? 'Remove Download' : 'Download',
              episode['isDownloaded'] ? 'download_done' : 'download',
              () {
                Navigator.pop(context);
                widget.onDownloadEpisode(episode);
              },
            ),
            _buildOptionItem(
              context,
              'Add to Queue',
              'queue_music',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to queue'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildOptionItem(
              context,
              'Share Episode',
              'share',
              () {
                Navigator.pop(context);
                widget.onShareEpisode(episode);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Show episode detail modal for a specific episode
  void _showEpisodeDetailModal(
      BuildContext context, Map<String, dynamic> episode) {
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
            episodes: _episodes,
            episodeIndex: _episodes.indexWhere(
                (e) => e['id'].toString() == episode['id'].toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.lightTheme.colorScheme.onSurface,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge,
      ),
      onTap: onTap,
    );
  }
}
