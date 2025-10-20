import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../../providers/episode_progress_provider.dart';
import '../../../providers/podcast_player_provider.dart';

// lib/presentation/podcast_detail_screen/widgets/episode_card_widget.dart

class EpisodeCardWidget extends StatelessWidget {
  final Map<String, dynamic> episode;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowDetails;

  const EpisodeCardWidget({
    super.key,
    required this.episode,
    required this.onPlay,
    required this.onDownload,
    required this.onShare,
    this.onLongPress,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEarningEpisode = episode['isEarningEpisode'] ?? false;
    final bool isDownloaded = episode['isDownloaded'] ?? false;
    final bool isPlayed = episode['isPlayed'] ?? false;
    final double progress = episode['progress'] ?? 0.0;
    final String episodeId = episode['id']?.toString() ?? '';

    return RepaintBoundary(
      child: GestureDetector(
          onTap: onPlay,
          onLongPress: onLongPress,
          onDoubleTap: onShowDetails,
          child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ]),
              child: Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Episode cover with play button
                  Stack(children: [
                    Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CustomImageWidget(
                                imageUrl: episode['coverImage'] ?? '',
                                width: 20.w,
                                height: 20.w,
                                fit: BoxFit.cover))),

                    // Play button overlay with real-time status
                    Positioned.fill(
                        child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: _buildPlayButtonWithStatus(
                                    context, episodeId)))),

                    // Download status
                    if (isDownloaded)
                      Positioned(
                          top: 1.w,
                          right: 1.w,
                          child: Container(
                              padding: EdgeInsets.all(1.w),
                              decoration: BoxDecoration(
                                  color:
                                      AppTheme.lightTheme.colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(8)),
                              child: CustomIconWidget(
                                  iconName: 'download_done',
                                  color: Colors.white,
                                  size: 12))),
                  ]),

                  SizedBox(width: 3.w),

                  // Episode info
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Title and earning badge
                        Row(children: [
                          Expanded(
                              child: Text(episode['title'] ?? '',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.lightTheme.colorScheme
                                              .onSurface),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)),
                          if (isEarningEpisode) ...[
                            SizedBox(width: 2.w),
                            Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 0.5.w),
                                decoration: BoxDecoration(
                                    color: AppTheme.earningActiveLight,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomIconWidget(
                                          iconName: 'monetization_on',
                                          color: Colors.white,
                                          size: 12),
                                      SizedBox(width: 1.w),
                                      Text('${episode['coinsPerMinute']}',
                                          style: AppTheme
                                              .lightTheme.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600)),
                                    ])),
                          ],
                        ]),

                        SizedBox(height: 1.h),

                        // Description
                        Text(_stripHtmlTags(episode['description'] ?? ''),
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),

                        SizedBox(height: 2.h),

                        // Duration, publish date, and actions
                        Row(children: [
                          // Duration
                          Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.w),
                              decoration: BoxDecoration(
                                  color: AppTheme
                                      .lightTheme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(formatDuration(episode['duration']),
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                          color: AppTheme.lightTheme.colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.w500))),

                          SizedBox(width: 2.w),

                          // Publish date
                          Text(episode['publishDate'] ?? '',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant)),

                          const Spacer(),

                          // Actions
                          Row(children: [
                            GestureDetector(
                                onTap: onDownload,
                                child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    child: CustomIconWidget(
                                        iconName: isDownloaded
                                            ? 'download_done'
                                            : 'download',
                                        color: isDownloaded
                                            ? AppTheme
                                                .lightTheme.colorScheme.tertiary
                                            : AppTheme.lightTheme.colorScheme
                                                .onSurfaceVariant,
                                        size: 20))),
                            GestureDetector(
                                onTap: onShare,
                                child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    child: CustomIconWidget(
                                        iconName: 'share',
                                        color: AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                        size: 20))),
                            GestureDetector(
                                onTap: onLongPress,
                                child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    child: CustomIconWidget(
                                        iconName: 'more_vert',
                                        color: AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                        size: 20))),
                          ]),
                        ]),
                      ])),
                ]),

                // Progress bar for played episodes
                if (isPlayed && progress > 0)
                  Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Column(children: [
                        LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme
                                .lightTheme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.primary)),
                        SizedBox(height: 1.h),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  progress == 1.0
                                      ? 'Completed'
                                      : '${(progress * 100).toInt()}% completed',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                          color: AppTheme.lightTheme.colorScheme
                                              .onSurfaceVariant)),
                              if (progress == 1.0 && isEarningEpisode)
                                Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 1.5.w, vertical: 0.5.w),
                                    decoration: BoxDecoration(
                                        color: AppTheme.earningActiveLight
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CustomIconWidget(
                                              iconName: 'monetization_on',
                                              color:
                                                  AppTheme.earningActiveLight,
                                              size: 12),
                                          SizedBox(width: 1.w),
                                          Text('Earning Active',
                                              style: AppTheme.lightTheme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                      color: AppTheme
                                                          .earningActiveLight,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        ])),
                            ]),
                      ])),

                // Real-time playback status display
                _buildRealTimeStatusDisplay(context, episodeId),
              ]))),
    );
  }

  Widget _buildPlayButtonWithStatus(BuildContext context, String episodeId) {
    final EpisodeProgressProvider episodeProgressProvider =
        Provider.of<EpisodeProgressProvider>(context, listen: false);
    final PodcastPlayerProvider podcastPlayerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);

    final bool isPlaying = podcastPlayerProvider.isPlaying &&
        podcastPlayerProvider.currentEpisode?.id.toString() == episodeId;
    final bool isBuffering = podcastPlayerProvider.isBuffering &&
        podcastPlayerProvider.currentEpisode?.id.toString() == episodeId;
    final double currentProgress =
        episodeProgressProvider.getProgressPercentage(episodeId);

    return Stack(
      children: [
        Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20)),
            child: CustomIconWidget(
                iconName: 'play_arrow', color: Colors.white, size: 20)),
        if (isPlaying)
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20)),
                  child: Center(
                      child: CustomIconWidget(
                          iconName: 'pause', color: Colors.white, size: 20)))),
        if (isBuffering)
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20)),
                  child: Center(
                      child: CustomIconWidget(
                          iconName: 'refresh',
                          color: Colors.white,
                          size: 20)))),
        if (currentProgress > 0)
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20)),
                  child: Center(
                      child: Text('${(currentProgress * 100).toInt()}%',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white))))),
      ],
    );
  }

  Widget _buildRealTimeStatusDisplay(BuildContext context, String episodeId) {
    final PodcastPlayerProvider podcastPlayerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);

    final bool isPlaying = podcastPlayerProvider.isPlaying &&
        podcastPlayerProvider.currentEpisode?.id.toString() == episodeId;
    final bool isBuffering = podcastPlayerProvider.isBuffering &&
        podcastPlayerProvider.currentEpisode?.id.toString() == episodeId;
    final double currentProgress =
        Provider.of<EpisodeProgressProvider>(context, listen: false)
            .getProgressPercentage(episodeId);

    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPlaying
                ? 'Playing'
                : isBuffering
                    ? 'Buffering'
                    : 'Paused',
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: currentProgress,
            backgroundColor:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary),
          ),
        ],
      ),
    );
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
