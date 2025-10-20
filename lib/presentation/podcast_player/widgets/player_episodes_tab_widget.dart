import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../data/models/podcast.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../services/podcastindex_service.dart';
import '../../../data/repositories/podcast_repository.dart';
import '../../../services/library_api_service.dart';
import '../../home_screen/widgets/subscribe_button.dart';
import '../../../services/subscription_helper.dart';
import 'package:provider/provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../core/utils/duration_utils.dart';
import '../../library_screen/widgets/search_bar_widget.dart';

class PlayerEpisodesTabWidget extends StatefulWidget {
  final String? feedId;
  final String? currentEpisodeId;
  final Function(Map<String, dynamic>) onPlayEpisode;
  final Function(Map<String, dynamic>) onDownloadEpisode;
  final Function(Map<String, dynamic>) onShareEpisode;
  final Map<String, dynamic>? currentPodcast;
  final bool isEarningEnabled;
  final bool isPlaylistMode;
  final List<Map<String, dynamic>>? playlistEpisodes;

  const PlayerEpisodesTabWidget({
    super.key,
    required this.feedId,
    required this.currentEpisodeId,
    required this.onPlayEpisode,
    required this.onDownloadEpisode,
    required this.onShareEpisode,
    required this.currentPodcast,
    required this.isEarningEnabled,
    this.isPlaylistMode = false,
    this.playlistEpisodes,
  });

  @override
  State<PlayerEpisodesTabWidget> createState() =>
      _PlayerEpisodesTabWidgetState();
}

class _PlayerEpisodesTabWidgetState extends State<PlayerEpisodesTabWidget> {
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
    if (!widget.isPlaylistMode) {
      _fetchEpisodes();
    }
  }

  Future<void> _fetchEpisodes({bool loadMore = false}) async {
    if (_isLoading || widget.feedId == null) return;
    setState(() => _isLoading = true);

    if (loadMore) _currentPage++;
    final podcastIndexService = PodcastIndexService();
    final data = await podcastIndexService.getPaginatedEpisodes(
        widget.feedId!.toString(), _currentPage, _perPage,
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

  @override
  Widget build(BuildContext context) {
    // Use playlist episodes if in playlist mode, otherwise use fetched episodes
    final List<Map<String, dynamic>> episodesToShow =
        widget.isPlaylistMode ? (widget.playlistEpisodes ?? []) : _episodes;

    final filteredEpisodes = _searchQuery.isEmpty
        ? episodesToShow
        : episodesToShow.where((episode) {
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
          // Show playlist header in playlist mode
          if (widget.isPlaylistMode)
            Container(
              padding: EdgeInsets.all(4.w),
              margin: EdgeInsets.only(top: 2.h, left: 4.w, right: 4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'playlist_play',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Playlist Episodes',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.playlistEpisodes?.length ?? 0} episodes',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
                top: widget.isPlaylistMode ? 1.h : 2.h, left: 4.w, right: 4.w),
            child: SearchBarWidget(
              hintText: widget.isPlaylistMode
                  ? 'Search playlist episodes...'
                  : 'Search episodes...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          Expanded(
            child: _buildEpisodesList(filteredEpisodes),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList(List<Map<String, dynamic>> filteredEpisodes) {
    if (widget.isPlaylistMode) {
      if (filteredEpisodes.isEmpty) {
        return _buildPlaylistEmptyState();
      }
      return ListView.separated(
        padding: EdgeInsets.all(4.w),
        itemCount: filteredEpisodes.length,
        separatorBuilder: (context, index) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          final episode = filteredEpisodes[index];
          final isCurrentEpisode = episode['id'].toString() ==
              (widget.currentEpisodeId?.toString() ?? '');

          return Container(
            decoration: BoxDecoration(
              color: isCurrentEpisode
                  ? AppTheme.lightTheme.colorScheme.primaryContainer
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: isCurrentEpisode
                  ? Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.3),
                      width: 1)
                  : null,
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(4.w),
              leading: Stack(
                children: [
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(8)),
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
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => widget.onPlayEpisode(episode),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'play_arrow',
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                episode['title'] ?? 'Unknown Episode',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (episode['description'] != null &&
                      episode['description'].toString().isNotEmpty)
                    Text(
                      episode['description']
                          .toString()
                          .replaceAll(RegExp(r'<[^>]*>'), ''),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _formatDuration(episode['duration'] ?? 0),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: CustomIconWidget(
                  iconName: 'more_vert',
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'play':
                      widget.onPlayEpisode(episode);
                      break;
                    case 'download':
                      widget.onDownloadEpisode(episode);
                      break;
                    case 'share':
                      widget.onShareEpisode(episode);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'play',
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'play_arrow',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Text('Play'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'download',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Text('Download'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'share',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Text('Share'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      if (_isLoading && _episodes.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      if (filteredEpisodes.isEmpty) {
        return _buildEmptyState();
      }
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: filteredEpisodes.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final episode = filteredEpisodes[index];
                final isCurrentEpisode = episode['id'].toString() ==
                    (widget.currentEpisodeId?.toString() ?? '');
                final isDownloaded = episode['isDownloaded'] == true;
                final double? progress = episode['progress'] != null
                    ? (episode['progress'] as num).toDouble()
                    : null;

                return Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isCurrentEpisode
                                ? AppTheme
                                    .lightTheme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.1)
                                : AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: isCurrentEpisode
                                ? Border.all(
                                    color: AppTheme
                                        .lightTheme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 1)
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(4.w),
                            leading: Stack(
                              children: [
                                Container(
                                  width: 15.w,
                                  height: 15.w,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8)),
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
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () => widget.onPlayEpisode(episode),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: CustomIconWidget(
                                          iconName: 'play_arrow',
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isDownloaded)
                                  Positioned(
                                    top: 1.w,
                                    right: 1.w,
                                    child: Container(
                                      padding: EdgeInsets.all(1.w),
                                      decoration: BoxDecoration(
                                        color: AppTheme
                                            .lightTheme.colorScheme.tertiary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CustomIconWidget(
                                        iconName: 'download_done',
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        episode['title'] ?? '',
                                        style: AppTheme
                                            .lightTheme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme
                                              .lightTheme.colorScheme.onSurface,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (progress != null && progress > 0)
                                      Container(
                                        margin: EdgeInsets.only(left: 2.w),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 2.w, vertical: 0.5.w),
                                        decoration: BoxDecoration(
                                          color: isCurrentEpisode
                                              ? AppTheme.lightTheme.colorScheme
                                                  .primary
                                              : AppTheme.lightTheme.colorScheme
                                                  .surfaceVariant,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${(progress * 100).toInt()}%',
                                          style: AppTheme
                                              .lightTheme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: isCurrentEpisode
                                                ? Colors.white
                                                : AppTheme
                                                    .lightTheme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  _stripHtmlTags(episode['description'] ?? ''),
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 2.w, vertical: 0.5.w),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightTheme.colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _formatDuration(
                                            episode['duration'] ?? 0),
                                        style: AppTheme
                                            .lightTheme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    if (episode['isEarningEpisode'] == true &&
                                        widget.isEarningEnabled)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 2.w, vertical: 0.5.w),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successLight
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomIconWidget(
                                              iconName: 'monetization_on',
                                              color: AppTheme.successLight,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Earning',
                                              style: AppTheme.lightTheme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppTheme.successLight,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            subtitle: Text(
                              episode['publishDate'] ?? '',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: CustomIconWidget(
                                iconName: 'more_vert',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onSelected: (value) {
                                switch (value) {
                                  case 'download':
                                    widget.onDownloadEpisode(episode);
                                    break;
                                  case 'share':
                                    widget.onShareEpisode(episode);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'download',
                                  child: Row(children: [
                                    CustomIconWidget(
                                      iconName: episode['isDownloaded'] == true
                                          ? 'download_done'
                                          : 'download',
                                      size: 18,
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      episode['isDownloaded'] == true
                                          ? 'Remove Download'
                                          : 'Download',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium,
                                    ),
                                  ]),
                                ),
                                PopupMenuItem<String>(
                                  value: 'share',
                                  child: Row(children: [
                                    CustomIconWidget(
                                      iconName: 'share',
                                      size: 18,
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text('Share',
                                        style: AppTheme
                                            .lightTheme.textTheme.bodyMedium),
                                  ]),
                                ),
                              ],
                            ),
                            onTap: () => widget.onPlayEpisode(episode),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (_hasMore)
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _fetchEpisodes(loadMore: true),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Load More'),
              ),
            ),
        ],
      );
    }
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

  Widget _buildPlaylistEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'playlist_play',
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'No playlist episodes found',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'This playlist appears to be empty',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '0m';

    // Convert to double
    double seconds;
    if (duration is int) {
      seconds = duration.toDouble();
    } else if (duration is double) {
      seconds = duration;
    } else if (duration is String) {
      // Try to parse as seconds first
      seconds = double.tryParse(duration) ?? 0.0;
      // If that fails, try to parse duration string like "47m 27s"
      if (seconds == 0.0) {
        seconds = DurationUtils.parseDurationToSeconds(duration);
      }
    } else {
      seconds = 0.0;
    }

    // Use DurationUtils to format
    return DurationUtils.formatSecondsToString(seconds);
  }
}

String _stripHtmlTags(String htmlText) {
  final RegExp exp = RegExp(r'<[^>]+>', multiLine: true, caseSensitive: false);
  return htmlText
      .replaceAll(exp, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}
