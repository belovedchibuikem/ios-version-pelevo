import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_player_provider.dart';
import '../services/bookmark_service.dart';

class AddBookmarkModal extends StatefulWidget {
  final Map<String, dynamic> episode;
  final VoidCallback? onBookmarkAdded;

  const AddBookmarkModal({
    Key? key,
    required this.episode,
    this.onBookmarkAdded,
  }) : super(key: key);

  @override
  State<AddBookmarkModal> createState() => _AddBookmarkModalState();
}

class _AddBookmarkModalState extends State<AddBookmarkModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  String? _selectedBookmarkType;
  int _selectedPriority = 2;
  bool _isLoading = false;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    final currentPosition = playerProvider.position.inSeconds;

    _titleController.text = 'Bookmark at ${_formatTime(currentPosition)}';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _createBookmark() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      final currentPosition = playerProvider.position.inSeconds;
      final duration = playerProvider.duration?.inSeconds ?? 0;

      final bookmarkService = BookmarkService();
      await bookmarkService.createTimestampBookmark(
        episodeId: widget.episode['id'] ?? widget.episode['episode_id'] ?? '',
        podcastId: widget.episode['podcast_id'] ??
            widget.episode['podcast']?['id'] ??
            '',
        position: currentPosition,
        duration: duration,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        category: _selectedCategory,
        bookmarkType: _selectedBookmarkType,
        priority: _selectedPriority,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onBookmarkAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bookmark: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bookmark_add,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Add Bookmark',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Add your thoughts...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBookmarkType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'note', child: Text('Note')),
                  DropdownMenuItem(
                      value: 'highlight', child: Text('Highlight')),
                  DropdownMenuItem(value: 'quote', child: Text('Quote')),
                ],
                onChanged: (value) {
                  setState(() => _selectedBookmarkType = value);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Make public'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createBookmark,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Bookmark'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
