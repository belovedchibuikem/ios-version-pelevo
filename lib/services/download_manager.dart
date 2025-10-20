import 'package:flutter/material.dart';
import 'download_service.dart';
import 'offline_player_service.dart';
import 'hybrid_audio_player_service.dart';
import 'podcastindex_service.dart';
import '../core/utils/episode_utils.dart';
import '../core/services/permission_service.dart';

/// Comprehensive download manager that coordinates downloads and offline playback
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final DownloadService _downloadService = DownloadService();
  final OfflinePlayerService _offlinePlayerService = OfflinePlayerService();
  final HybridAudioPlayerService _hybridPlayerService =
      HybridAudioPlayerService();
  final PodcastIndexService _podcastIndexService = PodcastIndexService();

  /// Initialize the download manager
  Future<void> initialize() async {
    await _offlinePlayerService.initialize();
    await _hybridPlayerService.initialize(playerProvider: null);
  }

  /// Download episode with podcast and episode data validation
  Future<void> downloadEpisodeWithValidation({
    required String episodeId,
    required String episodeTitle,
    required String audioUrl,
    required BuildContext context,
    VoidCallback? onDownloadComplete,
    VoidCallback? onDownloadError,
  }) async {
    try {
      // Check storage permission first
      final hasPermission =
          await PermissionService.ensureStoragePermission(context);
      if (!hasPermission) {
        debugPrint('Download cancelled: Storage permission not granted');
        onDownloadError?.call();
        return;
      }

      // Skip podcast validation for now - focus on download functionality
      // await _ensurePodcastAndEpisodeExist(episodeId, context);

      // Start download
      await _downloadService.downloadEpisode(
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
        context: context,
        onRetry: () => downloadEpisodeWithValidation(
          episodeId: episodeId,
          episodeTitle: episodeTitle,
          audioUrl: audioUrl,
          context: context,
          onDownloadComplete: onDownloadComplete,
          onDownloadError: onDownloadError,
        ),
      );

      onDownloadComplete?.call();
    } catch (e) {
      debugPrint('Download manager error: $e');
      onDownloadError?.call();
    }
  }

  /// Download episode from episode data map
  Future<void> downloadEpisodeFromData({
    required Map<String, dynamic> episodeData,
    required BuildContext context,
    VoidCallback? onDownloadComplete,
    VoidCallback? onDownloadError,
  }) async {
    final episodeInfo = EpisodeUtils.getEpisodeDownloadInfo(episodeData);
    final episodeId = episodeInfo['episodeId'];
    final episodeTitle = episodeInfo['episodeTitle'];
    final audioUrl = episodeInfo['audioUrl'];

    if (episodeId == null || episodeTitle == null || audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid episode data for download.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await downloadEpisodeWithValidation(
      episodeId: episodeId,
      episodeTitle: episodeTitle,
      audioUrl: audioUrl,
      context: context,
      onDownloadComplete: onDownloadComplete,
      onDownloadError: onDownloadError,
    );
  }

  /// Play episode with offline detection
  Future<void> playEpisodeWithOfflineDetection({
    required String episodeId,
    required String episodeTitle,
    required String audioUrl,
    required BuildContext context,
  }) async {
    try {
      // Check if episode is available offline
      final isOffline =
          await _offlinePlayerService.isEpisodeAvailableOffline(episodeId);

      if (isOffline) {
        // Play from offline storage
        await _offlinePlayerService.playOfflineEpisode(
          episodeId: episodeId,
          episodeTitle: episodeTitle,
          context: context,
        );

        // Show offline mode indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing offline: $episodeTitle'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Play from online source using hybrid player
        final episodeData = {
          'id': episodeId,
          'title': episodeTitle,
          'audioUrl': audioUrl,
        };

        await _hybridPlayerService.loadAndPlayEpisode(episodeData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing online: $episodeTitle'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error playing episode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing episode: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get episode playback info (online/offline status)
  Future<Map<String, dynamic>> getEpisodePlaybackInfo(String episodeId) async {
    final isOffline =
        await _offlinePlayerService.isEpisodeAvailableOffline(episodeId);
    final downloadInfo = _downloadService.getDownloadInfo(episodeId);
    final isDownloading = downloadInfo?.status == DownloadStatus.downloading;

    return {
      'isOffline': isOffline,
      'isDownloading': isDownloading,
      'downloadProgress': downloadInfo?.progress ?? 0.0,
      'downloadStatus': downloadInfo?.status,
      'canPlayOffline': isOffline,
    };
  }

  /// Check if episode is downloaded
  Future<bool> isEpisodeDownloaded(String episodeId) async {
    return await _downloadService.isEpisodeDownloaded(episodeId);
  }

  /// Get download progress
  DownloadInfo? getDownloadInfo(String episodeId) {
    return _downloadService.getDownloadInfo(episodeId);
  }

  /// Cancel download
  Future<void> cancelDownload(String episodeId) async {
    await _downloadService.cancelDownload(episodeId);
  }

  /// Delete downloaded episode
  Future<void> deleteDownloadedEpisode(
      String episodeId, BuildContext context) async {
    await _downloadService.deleteDownloadedEpisode(episodeId, context);
  }

  /// Get active downloads
  Map<String, DownloadInfo> get activeDownloads =>
      _downloadService.activeDownloads;

  /// Check if download is active
  bool isDownloadActive(String episodeId) =>
      _downloadService.isDownloadActive(episodeId);

  /// Get offline player service
  OfflinePlayerService get offlinePlayer => _offlinePlayerService;

  /// Get hybrid player service
  HybridAudioPlayerService get hybridPlayer => _hybridPlayerService;

  /// Dispose resources
  void dispose() {
    _offlinePlayerService.dispose();
  }
}
