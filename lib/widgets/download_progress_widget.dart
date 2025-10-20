import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/download_service.dart';
import '../core/app_export.dart';

/// Widget for displaying download progress and controls
class DownloadProgressWidget extends StatefulWidget {
  final String episodeId;
  final String episodeTitle;
  final String audioUrl;
  final VoidCallback? onDownloadComplete;
  final VoidCallback? onDownloadError;

  const DownloadProgressWidget({
    super.key,
    required this.episodeId,
    required this.episodeTitle,
    required this.audioUrl,
    this.onDownloadComplete,
    this.onDownloadError,
  });

  @override
  State<DownloadProgressWidget> createState() => _DownloadProgressWidgetState();
}

class _DownloadProgressWidgetState extends State<DownloadProgressWidget> {
  final DownloadService _downloadService = DownloadService();
  DownloadInfo? _downloadInfo;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  void _checkDownloadStatus() {
    final downloadInfo = _downloadService.getDownloadInfo(widget.episodeId);
    if (downloadInfo != null) {
      setState(() {
        _downloadInfo = downloadInfo;
        _isDownloading = downloadInfo.status == DownloadStatus.downloading;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      await _downloadService.downloadEpisode(
        episodeId: widget.episodeId,
        episodeTitle: widget.episodeTitle,
        audioUrl: widget.audioUrl,
        context: context,
        onRetry: _startDownload,
      );

      setState(() {
        _isDownloading = false;
      });

      widget.onDownloadComplete?.call();
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      widget.onDownloadError?.call();
    }
  }

  Future<void> _cancelDownload() async {
    await _downloadService.cancelDownload(widget.episodeId);
    setState(() {
      _isDownloading = false;
    });
  }

  Future<void> _deleteDownload() async {
    await _downloadService.deleteDownloadedEpisode(widget.episodeId, context);
    setState(() {
      _downloadInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final downloadInfo = _downloadService.getDownloadInfo(widget.episodeId);
    final isDownloaded = downloadInfo?.status == DownloadStatus.completed;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: currentTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    widget.episodeTitle,
                    style: currentTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Download status and progress
            if (_isDownloading && downloadInfo != null) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: downloadInfo.progress,
                      backgroundColor: currentTheme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(
                        currentTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${(downloadInfo.progress * 100).toInt()}%',
                    style: currentTheme.textTheme.bodySmall?.copyWith(
                      color: currentTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Text(
                    'Downloading...',
                    style: currentTheme.textTheme.bodySmall?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _cancelDownload,
                    icon: Icon(
                      Icons.cancel,
                      size: 20,
                      color: currentTheme.colorScheme.error,
                    ),
                    tooltip: 'Cancel Download',
                  ),
                ],
              ),
            ] else if (isDownloaded) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Downloaded',
                    style: currentTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _deleteDownload,
                    icon: Icon(
                      Icons.delete,
                      size: 20,
                      color: currentTheme.colorScheme.error,
                    ),
                    tooltip: 'Delete Download',
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _startDownload,
                      icon: Icon(
                        _isDownloading ? Icons.downloading : Icons.download,
                        size: 18,
                      ),
                      label: Text(
                        _isDownloading ? 'Downloading...' : 'Download',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentTheme.colorScheme.primary,
                        foregroundColor: currentTheme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
