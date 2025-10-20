import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';

class EpisodeSeekBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final int currentPosition; // Current position in seconds
  final int totalDuration; // Total duration in seconds
  final List<Map<String, dynamic>>? bookmarks; // Episode bookmarks
  final Function(double) onSeek; // Callback when seeking
  final Function(int, String) onBookmarkTap; // Callback when bookmark is tapped
  final Function(int, String, String) onBookmarkAdd; // Callback to add bookmark
  final bool isPlaying;
  final bool showBookmarks;

  const EpisodeSeekBar({
    super.key,
    required this.progress,
    required this.currentPosition,
    required this.totalDuration,
    this.bookmarks,
    required this.onSeek,
    required this.onBookmarkTap,
    required this.onBookmarkAdd,
    this.isPlaying = false,
    this.showBookmarks = true,
  });

  @override
  State<EpisodeSeekBar> createState() => _EpisodeSeekBarState();
}

class _EpisodeSeekBarState extends State<EpisodeSeekBar> {
  double _dragProgress = 0.0;
  bool _isDragging = false;
  bool _showBookmarkDialog = false;

  @override
  void initState() {
    super.initState();
    _dragProgress = widget.progress;
  }

  @override
  void didUpdateWidget(EpisodeSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _dragProgress = widget.progress;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  void _onSeekStart(double progress) {
    setState(() {
      _isDragging = true;
      _dragProgress = progress;
    });
  }

  void _onSeekUpdate(double progress) {
    setState(() {
      _dragProgress = progress;
    });
  }

  void _onSeekEnd(double progress) {
    setState(() {
      _isDragging = false;
      _dragProgress = progress;
    });
    widget.onSeek(progress);
  }

  void _showAddBookmarkDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedColor = '#2196F3';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Position: ${_formatDuration(widget.currentPosition)}'),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Bookmark Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Color: '),
                ...['#2196F3', '#FF5722', '#4CAF50', '#9C27B0', '#FF9800']
                    .map((color) => GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Color(
                                  int.parse(color.replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                widget.onBookmarkAdd(
                  widget.currentPosition,
                  titleController.text,
                  notesController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProgress = _isDragging ? _dragProgress : widget.progress;
    final currentTime = _formatDuration(widget.currentPosition);
    final totalTime = _formatDuration(widget.totalDuration);
    final remainingTime =
        _formatDuration(widget.totalDuration - widget.currentPosition);

    return Column(
      children: [
        // Time display
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTime,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '-$remainingTime',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                totalTime,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 1.h),

        // Seek bar
        Stack(
          children: [
            // Background track
            Container(
              height: 4.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.h,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
                  inactiveTrackColor: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  thumbColor: AppTheme.lightTheme.colorScheme.primary,
                  overlayColor: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: currentProgress.clamp(0.0, 1.0),
                  onChanged: _onSeekUpdate,
                  onChangeStart: _onSeekStart,
                  onChangeEnd: _onSeekEnd,
                ),
              ),
            ),

            // Bookmark indicators
            if (widget.showBookmarks && widget.bookmarks != null)
              ...widget.bookmarks!.map((bookmark) {
                final bookmarkProgress =
                    bookmark['position'] / widget.totalDuration;
                return Positioned(
                  left: 4.w +
                      (bookmarkProgress *
                          (MediaQuery.of(context).size.width - 8.w)),
                  top: 0,
                  child: GestureDetector(
                    onTap: () => widget.onBookmarkTap(
                      bookmark['position'],
                      bookmark['title'],
                    ),
                    child: Container(
                      width: 2.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                            bookmark['color'].replaceAll('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(1.w),
                      ),
                      child: Tooltip(
                        message:
                            '${bookmark['title']}\n${_formatDuration(bookmark['position'])}',
                        child: Container(),
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),

        SizedBox(height: 1.h),

        // Bookmark controls
        if (widget.showBookmarks)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bookmarks: ${widget.bookmarks?.length ?? 0}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _showAddBookmarkDialog,
                      icon: Icon(
                        Icons.bookmark_add,
                        size: 20,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      tooltip: 'Add Bookmark',
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Show bookmarks list
                      },
                      icon: Icon(
                        Icons.bookmark,
                        size: 20,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      tooltip: 'View Bookmarks',
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
