import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/playlist.dart';
import '../../services/library_api_service.dart';
import 'widgets/episode_browser_widget.dart';

class AddEpisodesToPlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback? onEpisodesAdded;

  const AddEpisodesToPlaylistScreen({
    super.key,
    required this.playlist,
    this.onEpisodesAdded,
  });

  @override
  State<AddEpisodesToPlaylistScreen> createState() =>
      _AddEpisodesToPlaylistScreenState();
}

class _AddEpisodesToPlaylistScreenState extends State<AddEpisodesToPlaylistScreen> {
  final LibraryApiService _libraryService = LibraryApiService();
  Set<int> _selectedEpisodes = {};
  bool _isAddingEpisodes = false;

  void _toggleEpisodeSelection(int episodeId) {
    setState(() {
      if (_selectedEpisodes.contains(episodeId)) {
        _selectedEpisodes.remove(episodeId);
      } else {
        _selectedEpisodes.add(episodeId);
      }
    });
  }

  Future<void> _addSelectedEpisodes() async {
    if (_selectedEpisodes.isEmpty) return;

    setState(() => _isAddingEpisodes = true);

    try {
      int successCount = 0;
      int errorCount = 0;

      for (final episodeId in _selectedEpisodes) {
        try {
          await _libraryService.addEpisodeToPlaylist(widget.playlist.id, episodeId);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Error adding episode $episodeId: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? 'Added $successCount episode${successCount > 1 ? 's' : ''} to playlist'
                  : 'Failed to add episodes to playlist',
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );

        if (successCount > 0) {
          widget.onEpisodesAdded?.call();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding episodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingEpisodes = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add to ${widget.playlist.name}'),
        actions: [
          if (_selectedEpisodes.isNotEmpty)
            TextButton(
              onPressed: _isAddingEpisodes ? null : _addSelectedEpisodes,
              child: _isAddingEpisodes
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Add (${_selectedEpisodes.length})',
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: EpisodeBrowserWidget(
        selectedEpisodes: _selectedEpisodes,
        onEpisodeToggle: _toggleEpisodeSelection,
        onEpisodesSelected: _addSelectedEpisodes,
      ),
    );
  }
}
