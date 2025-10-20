import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../models/episode_bookmark.dart';
import '../services/episode_progress_service.dart';

/// Enhanced bookmark creator with advanced features
class EnhancedBookmarkCreator extends StatefulWidget {
  final String episodeId;
  final String podcastId;
  final int currentPosition;
  final int totalDuration;
  final VoidCallback? onBookmarkCreated;
  final EpisodeBookmark? existingBookmark;

  const EnhancedBookmarkCreator({
    super.key,
    required this.episodeId,
    required this.podcastId,
    required this.currentPosition,
    required this.totalDuration,
    this.onBookmarkCreated,
    this.existingBookmark,
  });

  @override
  State<EnhancedBookmarkCreator> createState() =>
      _EnhancedBookmarkCreatorState();
}

class _EnhancedBookmarkCreatorState extends State<EnhancedBookmarkCreator> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedColor = '#2196F3';
  bool _isPublic = false;
  bool _isCreating = false;

  // Predefined categories and colors
  final List<String> _predefinedCategories = [
    'Key Point',
    'Interesting Fact',
    'Quote',
    'Action Item',
    'Question',
    'Reference',
    'Personal Note',
    'Other'
  ];

  final List<String> _predefinedColors = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FF5722', // Deep Orange
    '#795548', // Brown
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.existingBookmark != null) {
      final bookmark = widget.existingBookmark!;
      _titleController.text = bookmark.title;
      _notesController.text = bookmark.notes ?? '';
      _categoryController.text = bookmark.category ?? '';
      _tagsController.text = bookmark.tags?.join(', ') ?? '';
      _selectedColor = bookmark.color;
      _isPublic = bookmark.isPublic;
    } else {
      _titleController.text =
          'Bookmark at ${_formatPosition(widget.currentPosition)}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createBookmark() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final progressService = EpisodeProgressService();
      await progressService.initialize();

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final success = await progressService.addBookmark(
        episodeId: widget.episodeId,
        podcastId: widget.podcastId,
        position: widget.currentPosition,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        color: _selectedColor,
        isPublic: _isPublic,
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        tags: tags.isNotEmpty ? tags : null,
        metadata: {
          'total_duration': widget.totalDuration,
          'created_from': 'enhanced_creator',
          'device_info': 'mobile_app',
        },
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingBookmark != null
                  ? 'Bookmark updated successfully'
                  : 'Bookmark created successfully'),
              backgroundColor: Colors.green,
            ),
          );

          widget.onBookmarkCreated?.call();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create bookmark. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  String _formatPosition(int position) {
    final minutes = position ~/ 60;
    final seconds = position % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 90.w,
        constraints: BoxConstraints(maxHeight: 80.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_add,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      widget.existingBookmark != null
                          ? 'Edit Bookmark'
                          : 'Create Bookmark',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Position indicator
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.lightTheme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Position: ${_formatPosition(widget.currentPosition)} of ${_formatPosition(widget.totalDuration)}',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Bookmark Title *',
                          hintText: 'Enter a descriptive title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 2.h),

                      // Category field with suggestions
                      Autocomplete<String>(
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              hintText: 'Choose or enter a category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.category),
                            ),
                          );
                        },
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _predefinedCategories;
                          }
                          return _predefinedCategories.where((category) =>
                              category.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) {
                          _categoryController.text = selection;
                        },
                      ),

                      SizedBox(height: 2.h),

                      // Tags field
                      TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: 'Tags',
                          hintText: 'Enter tags separated by commas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Notes field
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Add detailed notes about this bookmark',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),

                      SizedBox(height: 3.h),

                      // Color selection
                      Text(
                        'Choose Color:',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Wrap(
                        spacing: 2.w,
                        children: _predefinedColors.map((color) {
                          final isSelected = color == _selectedColor;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(
                                    int.parse(color.replaceAll('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 3.h),

                      // Public toggle
                      SwitchListTile(
                        title: Text(
                          'Make Public',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Other users can see this bookmark',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                        secondary: Icon(
                          _isPublic ? Icons.public : Icons.lock,
                          color: _isPublic
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 3.h),
                              ),
                              child: Text('Cancel'),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isCreating ? null : _createBookmark,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppTheme.lightTheme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 3.h),
                              ),
                              child: _isCreating
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(widget.existingBookmark != null
                                      ? 'Update'
                                      : 'Create'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

