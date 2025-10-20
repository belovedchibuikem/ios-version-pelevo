import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../core/app_export.dart';
import '../providers/playlist_provider.dart';

class AddToPlaylistWidget extends StatefulWidget {
  final int episodeId;
  final VoidCallback? onSuccess;

  const AddToPlaylistWidget({
    super.key,
    required this.episodeId,
    this.onSuccess,
  });

  @override
  State<AddToPlaylistWidget> createState() => _AddToPlaylistWidgetState();
}

class _AddToPlaylistWidgetState extends State<AddToPlaylistWidget> {
  final TextEditingController _playlistNameController = TextEditingController();
  bool _isCreatingPlaylist = false;

  @override
  void initState() {
    super.initState();
    // Load playlists using provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlistProvider =
          Provider.of<PlaylistProvider>(context, listen: false);
      playlistProvider.loadPlaylists();
    });
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  Future<void> _addToPlaylist(int playlistId) async {
    if (!mounted) return;

    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    // Show loading notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Adding Episode to playlist...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final success = await playlistProvider.addEpisodeToPlaylist(
        playlistId, widget.episodeId);

    if (mounted) {
      if (success) {
        final playlist = playlistProvider.getPlaylistById(playlistId);
        final playlistName = playlist?.name ?? 'Playlist';

        final message = playlistProvider.lastAddMessage ??
            (playlistProvider.lastAddWasDuplicate
                ? 'Episode is already in "$playlistName"'
                : 'Episode added to "$playlistName" successfully');
        final isDuplicate = playlistProvider.lastAddWasDuplicate;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isDuplicate ? Colors.blueGrey : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }

        // Close the modal after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error adding to playlist: ${playlistProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPlaylist() async {
    if (_playlistNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCreatingPlaylist = true;
    });

    try {
      // Show loading notification for creating playlist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Creating playlist and adding episode...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      final playlistProvider =
          Provider.of<PlaylistProvider>(context, listen: false);
      // Create playlist only and keep modal open
      final newPlaylist = await playlistProvider.createPlaylistOnly(
        _playlistNameController.text.trim(),
      );

      if (newPlaylist != null) {
        // Clear the text field
        _playlistNameController.clear();

        // Success message and keep modal open so user can add episode next
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Playlist "${newPlaylist.name}" created successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error creating playlist: ${playlistProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isCreatingPlaylist = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Add to Playlist',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Create new playlist section
              Text(
                'Create New Playlist',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _playlistNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter playlist name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 2.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  ElevatedButton(
                    onPressed: _isCreatingPlaylist ? null : _createPlaylist,
                    child: _isCreatingPlaylist
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Existing playlists section
              Text(
                'Add to Existing Playlist',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),

              if (playlistProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (playlistProvider.error != null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.lightTheme.colorScheme.error,
                          size: 48,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Error loading playlists',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          playlistProvider.error!,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => playlistProvider.loadPlaylists(
                                  forceRefresh: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                            SizedBox(width: 2.w),
                            OutlinedButton.icon(
                              onPressed: () {
                                playlistProvider.clearError();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (playlistProvider.playlists.isEmpty)
                Center(
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: 'playlist_play',
                        size: 48,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No playlists yet',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Create your first playlist above',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  constraints: BoxConstraints(maxHeight: 40.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: playlistProvider.playlists.length,
                    separatorBuilder: (context, index) => SizedBox(height: 1.h),
                    itemBuilder: (context, index) {
                      final playlist = playlistProvider.playlists[index];
                      final isAdding =
                          playlistProvider.isAddingToPlaylist(playlist.id);
                      final itemCount =
                          playlistProvider.getPlaylistItemCount(playlist.id);
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.playlist_play,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            playlist.name,
                            style: AppTheme.lightTheme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (playlist.description != null)
                                Text(
                                  playlist.description!,
                                  style:
                                      AppTheme.lightTheme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                '$itemCount episodes',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: isAdding
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                  ),
                                )
                              : IconButton(
                                  icon: CustomIconWidget(
                                    iconName: 'add',
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    size: 24,
                                  ),
                                  onPressed: isAdding
                                      ? null
                                      : () => _addToPlaylist(playlist.id),
                                ),
                          onTap: isAdding
                              ? null
                              : () => _addToPlaylist(playlist.id),
                        ),
                      );
                    },
                  ),
                ),

              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }
}
