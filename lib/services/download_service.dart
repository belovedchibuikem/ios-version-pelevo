import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../core/services/permission_service.dart';
import 'library_api_service.dart';

/// Download progress callback
typedef DownloadProgressCallback = void Function(int received, int total);

/// Download status enum
enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

/// Download info model
class DownloadInfo {
  final String episodeId;
  final String episodeTitle;
  final String audioUrl;
  final String fileName;
  final String filePath;
  final int fileSize;
  final DownloadStatus status;
  final double progress;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;

  DownloadInfo({
    required this.episodeId,
    required this.episodeTitle,
    required this.audioUrl,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.status,
    required this.progress,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  DownloadInfo copyWith({
    String? episodeId,
    String? episodeTitle,
    String? audioUrl,
    String? fileName,
    String? filePath,
    int? fileSize,
    DownloadStatus? status,
    double? progress,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return DownloadInfo(
      episodeId: episodeId ?? this.episodeId,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      audioUrl: audioUrl ?? this.audioUrl,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Comprehensive download service for podcast episodes
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final LibraryApiService _apiService = LibraryApiService();
  final Dio _dio = Dio();

  // Active downloads tracking
  final Map<String, DownloadInfo> _activeDownloads = {};
  final Map<String, CancelToken> _cancelTokens = {};

  /// Get download directory
  Future<Directory> get _downloadDirectory async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');

      // Check if directory exists, if not create it
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
        debugPrint('Created download directory: ${downloadDir.path}');
      }

      // Verify we can write to the directory
      final testFile = File('${downloadDir.path}/test.txt');
      await testFile.writeAsString('test');
      await testFile.delete();

      debugPrint('Download directory is writable: ${downloadDir.path}');
      return downloadDir;
    } catch (e) {
      debugPrint('Error creating download directory: $e');
      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      debugPrint('Using fallback directory: ${appDir.path}');
      return appDir;
    }
  }

  /// Check if episode is downloaded
  Future<bool> isEpisodeDownloaded(String episodeId) async {
    try {
      final downloadDir = await _downloadDirectory;
      final file = File('${downloadDir.path}/$episodeId.mp3');
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking if episode is downloaded: $e');
      return false;
    }
  }

  /// Get downloaded episode file path
  Future<String?> getDownloadedFilePath(String episodeId) async {
    try {
      final downloadDir = await _downloadDirectory;
      final file = File('${downloadDir.path}/$episodeId.mp3');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting downloaded file path: $e');
      return null;
    }
  }

  /// Download episode with progress tracking
  Future<void> downloadEpisode({
    required String episodeId,
    required String episodeTitle,
    required String audioUrl,
    required BuildContext context,
    VoidCallback? onRetry,
  }) async {
    try {
      // Check if already downloaded
      if (await isEpisodeDownloaded(episodeId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Episode already downloaded'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if already downloading
      if (_activeDownloads.containsKey(episodeId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Episode is already being downloaded'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check and request storage permission using our permission service
      final hasPermission =
          await PermissionService.ensureStoragePermission(context);

      if (!hasPermission) {
        debugPrint('Storage permission not granted. Download cancelled.');
        return;
      }

      debugPrint('Storage permission granted successfully');

      // Create download info
      final downloadInfo = DownloadInfo(
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
        fileName: '$episodeId.mp3',
        filePath: '',
        fileSize: 0,
        status: DownloadStatus.downloading,
        progress: 0.0,
        startedAt: DateTime.now(),
      );

      _activeDownloads[episodeId] = downloadInfo;
      _cancelTokens[episodeId] = CancelToken();

      // Show download started notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting download: $episodeTitle'),
          backgroundColor: Colors.blue,
        ),
      );

      // Get download directory
      final downloadDir = await _downloadDirectory;
      final filePath = '${downloadDir.path}/$episodeId.mp3';
      final file = File(filePath);

      // Start download
      await _dio.download(
        audioUrl,
        filePath,
        cancelToken: _cancelTokens[episodeId],
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _activeDownloads[episodeId] = downloadInfo.copyWith(
              fileSize: total,
              progress: progress,
            );
          }
        },
      );

      // Download completed
      final finalFileSize = await file.length();
      final completedInfo = downloadInfo.copyWith(
        filePath: filePath,
        fileSize: finalFileSize,
        status: DownloadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );

      _activeDownloads[episodeId] = completedInfo;

      // Save to backend
      await _saveDownloadToBackend(
          episodeId, filePath, finalFileSize, context, onRetry);

      // Show completion notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download completed: $episodeTitle'),
          backgroundColor: Colors.green,
        ),
      );

      // Cleanup
      _cleanupDownload(episodeId);
    } catch (e) {
      debugPrint('Download error: $e');

      final errorInfo = _activeDownloads[episodeId]?.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      );

      if (errorInfo != null) {
        _activeDownloads[episodeId] = errorInfo;
      }

      // Show error notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Cleanup
      _cleanupDownload(episodeId);
    }
  }

  /// Cancel download
  Future<void> cancelDownload(String episodeId) async {
    final cancelToken = _cancelTokens[episodeId];
    if (cancelToken != null) {
      cancelToken.cancel('Download cancelled by user');

      final cancelledInfo = _activeDownloads[episodeId]?.copyWith(
        status: DownloadStatus.cancelled,
      );

      if (cancelledInfo != null) {
        _activeDownloads[episodeId] = cancelledInfo;
      }

      _cleanupDownload(episodeId);
    }
  }

  /// Delete downloaded episode
  Future<void> deleteDownloadedEpisode(
      String episodeId, BuildContext context) async {
    try {
      // Delete local file
      final filePath = await getDownloadedFilePath(episodeId);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from backend
      await _apiService.removeDownload(
        episodeId: episodeId,
        context: context,
        onRetry: () => deleteDownloadedEpisode(episodeId, context),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting download: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing download: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Save download to backend
  Future<void> _saveDownloadToBackend(
    String episodeId,
    String filePath,
    int fileSize,
    BuildContext context,
    VoidCallback? onRetry,
  ) async {
    try {
      await _apiService.addDownload(
        episodeId: episodeId,
        filePath: filePath,
        fileSize: fileSize,
        context: context,
        onRetry: onRetry,
      );
    } catch (e) {
      debugPrint('Error saving download to backend: $e');
      // Don't throw here as the file is already downloaded locally
    }
  }

  /// Cleanup download resources
  void _cleanupDownload(String episodeId) {
    _activeDownloads.remove(episodeId);
    _cancelTokens.remove(episodeId);
  }

  /// Get active downloads
  Map<String, DownloadInfo> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);

  /// Check if download is active
  bool isDownloadActive(String episodeId) =>
      _activeDownloads.containsKey(episodeId);

  /// Get download info
  DownloadInfo? getDownloadInfo(String episodeId) =>
      _activeDownloads[episodeId];
}
