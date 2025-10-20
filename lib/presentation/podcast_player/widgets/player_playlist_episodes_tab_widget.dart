import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/duration_utils.dart';

class PlayerPlaylistEpisodesTabWidget extends StatefulWidget {
  final String? currentEpisodeId;
  final Function(Map<String, dynamic>) onPlayEpisode;
  final Function(Map<String, dynamic>) onDownloadEpisode;
  final Function(Map<String, dynamic>) onShareEpisode;
  final List<Map<String, dynamic>> playlistEpisodes;
  final String playlistName;

  const PlayerPlaylistEpisodesTabWidget({
    super.key,
    required this.currentEpisodeId,
    required this.onPlayEpisode,
    required this.onDownloadEpisode,
    required this.onShareEpisode,
    required this.playlistEpisodes,
    required this.playlistName,
  });

  @override
  State<PlayerPlaylistEpisodesTabWidget> createState() =>
      _PlayerPlaylistEpisodesTabWidgetState();
}

class _PlayerPlaylistEpisodesTabWidgetState
    extends State<PlayerPlaylistEpisodesTabWidget> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredEpisodes = _searchQuery.isEmpty
        ? widget.playlistEpisodes
        : widget.playlistEpisodes.where((episode) {
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
          // Playlist header
          Container(
            padding: EdgeInsets.all(4.w),
            margin: EdgeInsets.only(top: 2.h, left: 4.w, right: 4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: 'playlist_play',
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playlist',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.playlistName,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredEpisodes.length} episodes',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.only(top: 2.h, left: 4.w, right: 4.w),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search playlist episodes...',
                  hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                  prefixIcon: CustomIconWidget(
                    iconName: 'search',
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                ),
              ),
            ),
          ),

          // Episodes list
          Expanded(
            child: filteredEpisodes.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
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
                                  width: 2,
                                )
                              : Border.all(
                                  color: AppTheme.lightTheme.colorScheme.outline
                                      .withValues(alpha: 0.1),
                                ),
                          boxShadow: isCurrentEpisode
                              ? [
                                  BoxShadow(
                                    color: AppTheme
                                        .lightTheme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
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
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
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
                                          Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: CustomIconWidget(
                                        iconName: 'play_arrow',
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            episode['title'] ?? 'Unknown Episode',
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(
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
                                Padding(
                                  padding: EdgeInsets.only(top: 1.h),
                                  child: Text(
                                    _stripHtmlTags(
                                        episode['description'].toString()),
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              SizedBox(height: 1.h),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 2.w, vertical: 0.5.h),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightTheme.colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'schedule',
                                          color: AppTheme
                                              .lightTheme.colorScheme.primary,
                                          size: 12,
                                        ),
                                        SizedBox(width: 1.w),
                                        Text(
                                          _formatDuration(
                                              episode['duration'] ?? 0),
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme
                                                .lightTheme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCurrentEpisode) ...[
                                    SizedBox(width: 2.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 2.w, vertical: 0.5.h),
                                      decoration: BoxDecoration(
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CustomIconWidget(
                                            iconName: 'play_arrow',
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 1.w),
                                          Text(
                                            'NOW PLAYING',
                                            style: AppTheme
                                                .lightTheme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
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
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
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
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
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
                  ),
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
            iconName: 'playlist_play',
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'No episodes found',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isEmpty
                ? 'This playlist appears to be empty'
                : 'No episodes match your search',
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

    // Format back to a readable string
    final int hours = (seconds / 3600).floor();
    final int minutes = ((seconds % 3600) / 60).floor();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _stripHtmlTags(String htmlText) {
    final RegExp exp =
        RegExp(r'<[^>]+>', multiLine: true, caseSensitive: false);
    return htmlText
        .replaceAll(exp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
