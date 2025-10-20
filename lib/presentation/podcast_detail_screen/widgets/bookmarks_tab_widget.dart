import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/episode_bookmark.dart';
import '../../../services/episode_progress_service.dart';
import '../../../core/utils/mini_player_positioning.dart';
import '../../../widgets/episode_seek_bar.dart';

class BookmarksTabWidget extends StatefulWidget {
  final List<Map<String, dynamic>> episodes;
  final String podcastId;

  const BookmarksTabWidget({
    super.key,
    required this.episodes,
    required this.podcastId,
  });

  @override
  State<BookmarksTabWidget> createState() => _BookmarksTabWidgetState();
}

class _BookmarksTabWidgetState extends State<BookmarksTabWidget> {
  final EpisodeProgressService _progressService = EpisodeProgressService();
  List<EpisodeBookmark> _allBookmarks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _progressService.initialize();

      // Get bookmarks for all episodes in this podcast
      final allBookmarks = <EpisodeBookmark>[];
      for (final episode in widget.episodes) {
        final episodeId = episode['id'].toString();
        final bookmarks = await _progressService.getBookmarks(episodeId);
        allBookmarks.addAll(bookmarks);
      }

      // Sort bookmarks by creation date (newest first)
      allBookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _allBookmarks = allBookmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onBookmarkTap(EpisodeBookmark bookmark) {
    // Find the episode for this bookmark
    final episode = widget.episodes.firstWhere(
      (e) => e['id'].toString() == bookmark.episodeId,
      orElse: () => widget.episodes.first,
    );

    // Navigate to player at bookmark position
    Navigator.pushNamed(
      context,
      AppRoutes.podcastPlayer,
      arguments: {
        'podcast': {'id': widget.podcastId},
        'episodes': widget.episodes,
        'currentEpisode': episode,
        'startPosition': bookmark.position,
      },
    );
  }

  void _onBookmarkDelete(EpisodeBookmark bookmark) async {
    try {
      await _progressService.removeBookmark(
          bookmark.episodeId, bookmark.position);
      await _loadBookmarks(); // Reload bookmarks

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmark "${bookmark.title}" deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting bookmark: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.lightTheme.colorScheme.error,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading bookmarks',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookmarks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allBookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
            SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Bookmarks you create while listening to episodes will appear here',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Bookmarks list - Non-scrollable to allow main screen scrolling
        ..._allBookmarks.map((bookmark) {
          final episode = widget.episodes.firstWhere(
            (e) => e['id'].toString() == bookmark.episodeId,
            orElse: () => widget.episodes.first,
          );

          return Card(
            margin: EdgeInsets.only(
              left: 4.w,
              right: 4.w,
              bottom: 2.h,
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(4.w),
              leading: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color:
                      Color(int.parse(bookmark.color.replaceAll('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                bookmark.title,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 1.h),
                  Text(
                    episode['title'] ?? 'Unknown Episode',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  if (bookmark.notes?.isNotEmpty == true)
                    Text(
                      bookmark.notes!,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.lightTheme.colorScheme.outline,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        bookmark.formattedPosition,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.outline,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.lightTheme.colorScheme.outline,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _formatDate(bookmark.createdAt),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _onBookmarkDelete(bookmark);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _onBookmarkTap(bookmark),
            ),
          );
        }).toList(),

        // Bottom padding for mini-player
        SizedBox(
          height: MiniPlayerPositioning.bottomPaddingForScrollables(),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
