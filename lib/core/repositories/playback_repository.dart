import 'package:sqflite/sqflite.dart';
import '../../data/models/database_models.dart';
import '../database/database_helper.dart';

class PlaybackRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Insert or update playback history
  Future<int> insertOrUpdatePlaybackHistory(
      PlaybackHistoryModel history) async {
    if (history.id != null) {
      // Update existing history
      return await _dbHelper.update(
        DatabaseHelper.tablePlaybackHistory,
        history.toMap(),
        'id = ?',
        [history.id],
      );
    } else {
      // Insert new history
      return await _dbHelper.insert(
        DatabaseHelper.tablePlaybackHistory,
        history.toMap(),
      );
    }
  }

  // Get playback history by episode ID
  Future<PlaybackHistoryModel?> getPlaybackHistoryByEpisodeId(
      int episodeId) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePlaybackHistory,
      where: 'episodeId = ?',
      whereArgs: [episodeId],
      orderBy: 'playedAt DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return PlaybackHistoryModel.fromMap(results.first);
    }
    return null;
  }

  // Get all playback history
  Future<List<PlaybackHistoryModel>> getAllPlaybackHistory({
    int? limit,
    int? offset,
    String orderBy = 'playedAt DESC',
  }) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePlaybackHistory,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return results.map((map) => PlaybackHistoryModel.fromMap(map)).toList();
  }

  // Get playback history by date range
  Future<List<PlaybackHistoryModel>> getPlaybackHistoryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
  }) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePlaybackHistory,
      where: 'playedAt BETWEEN ? AND ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'playedAt DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => PlaybackHistoryModel.fromMap(map)).toList();
  }

  // Get recent playback history
  Future<List<PlaybackHistoryModel>> getRecentPlaybackHistory({
    int days = 30,
    int? limit,
    int? offset,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final results = await _dbHelper.query(
      DatabaseHelper.tablePlaybackHistory,
      where: 'playedAt >= ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
      orderBy: 'playedAt DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => PlaybackHistoryModel.fromMap(map)).toList();
  }

  // Update playback position
  Future<int> updatePlaybackPosition(
      int episodeId, int position, int duration) async {
    final existingHistory = await getPlaybackHistoryByEpisodeId(episodeId);

    if (existingHistory != null) {
      // Update existing history
      return await _dbHelper.update(
        DatabaseHelper.tablePlaybackHistory,
        {
          'position': position,
          'duration': duration,
          'playedAt': DateTime.now().millisecondsSinceEpoch,
        },
        'id = ?',
        [existingHistory.id],
      );
    } else {
      // Create new history
      final newHistory = PlaybackHistoryModel(
        episodeId: episodeId,
        position: position,
        duration: duration,
        playedAt: DateTime.now(),
        completed: false,
      );

      return await _dbHelper.insert(
        DatabaseHelper.tablePlaybackHistory,
        newHistory.toMap(),
      );
    }
  }

  // Mark episode as completed
  Future<int> markEpisodeCompleted(int episodeId) async {
    final existingHistory = await getPlaybackHistoryByEpisodeId(episodeId);

    if (existingHistory != null) {
      return await _dbHelper.update(
        DatabaseHelper.tablePlaybackHistory,
        {
          'completed': 1,
          'playedAt': DateTime.now().millisecondsSinceEpoch,
        },
        'id = ?',
        [existingHistory.id],
      );
    }
    return 0;
  }

  // Get playback progress for an episode
  Future<Map<String, dynamic>?> getPlaybackProgress(int episodeId) async {
    final history = await getPlaybackHistoryByEpisodeId(episodeId);

    if (history != null) {
      return {
        'position': history.position,
        'duration': history.duration,
        'progress':
            history.duration > 0 ? history.position / history.duration : 0.0,
        'completed': history.completed,
        'lastPlayed': history.playedAt,
      };
    }
    return null;
  }

  // Get episodes in progress (not completed)
  Future<List<Map<String, dynamic>>> getEpisodesInProgress({
    int? limit,
    int? offset,
  }) async {
    final results = await _dbHelper.rawQuery('''
      SELECT ph.*, e.title as episodeTitle, e.coverImage as episodeCoverImage,
             p.title as podcastTitle, p.coverImage as podcastCoverImage
      FROM ${DatabaseHelper.tablePlaybackHistory} ph
      INNER JOIN ${DatabaseHelper.tableEpisodes} e ON ph.episodeId = e.id
      INNER JOIN ${DatabaseHelper.tablePodcasts} p ON e.podcastId = p.id
      WHERE ph.completed = 0
      ORDER BY ph.playedAt DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''');

    return results;
  }

  // Get completed episodes
  Future<List<Map<String, dynamic>>> getCompletedEpisodes({
    int? limit,
    int? offset,
  }) async {
    final results = await _dbHelper.rawQuery('''
      SELECT ph.*, e.title as episodeTitle, e.coverImage as episodeCoverImage,
             p.title as podcastTitle, p.coverImage as podcastCoverImage
      FROM ${DatabaseHelper.tablePlaybackHistory} ph
      INNER JOIN ${DatabaseHelper.tableEpisodes} e ON ph.episodeId = e.id
      INNER JOIN ${DatabaseHelper.tablePodcasts} p ON e.podcastId = p.id
      WHERE ph.completed = 1
      ORDER BY ph.playedAt DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''');

    return results;
  }

  // Get listening statistics
  Future<Map<String, dynamic>> getListeningStats({
    int days = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final totalListeningTime =
        Sqflite.firstIntValue(await _dbHelper.rawQuery('''
        SELECT SUM(position) FROM ${DatabaseHelper.tablePlaybackHistory}
        WHERE playedAt >= ?
      ''', [cutoffDate.millisecondsSinceEpoch])) ?? 0;

    final completedEpisodes = Sqflite.firstIntValue(await _dbHelper.rawQuery('''
        SELECT COUNT(*) FROM ${DatabaseHelper.tablePlaybackHistory}
        WHERE completed = 1 AND playedAt >= ?
      ''', [cutoffDate.millisecondsSinceEpoch])) ?? 0;

    final inProgressEpisodes =
        Sqflite.firstIntValue(await _dbHelper.rawQuery('''
        SELECT COUNT(DISTINCT episodeId) FROM ${DatabaseHelper.tablePlaybackHistory}
        WHERE completed = 0 AND playedAt >= ?
      ''', [cutoffDate.millisecondsSinceEpoch])) ?? 0;

    final averageSessionLength =
        Sqflite.firstIntValue(await _dbHelper.rawQuery('''
        SELECT AVG(position) FROM ${DatabaseHelper.tablePlaybackHistory}
        WHERE playedAt >= ?
      ''', [cutoffDate.millisecondsSinceEpoch])) ?? 0;

    return {
      'totalListeningTime': totalListeningTime,
      'completedEpisodes': completedEpisodes,
      'inProgressEpisodes': inProgressEpisodes,
      'averageSessionLength': averageSessionLength,
      'period': days,
    };
  }

  // Get listening history by day
  Future<List<Map<String, dynamic>>> getListeningHistoryByDay({
    int days = 7,
  }) async {
    final results = await _dbHelper.rawQuery('''
      SELECT 
        DATE(playedAt/1000, 'unixepoch') as date,
        SUM(position) as totalListeningTime,
        COUNT(*) as sessions,
        COUNT(DISTINCT episodeId) as uniqueEpisodes
      FROM ${DatabaseHelper.tablePlaybackHistory}
      WHERE playedAt >= ?
      GROUP BY DATE(playedAt/1000, 'unixepoch')
      ORDER BY date DESC
      LIMIT ?
    ''', [
      DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch,
      days,
    ]);

    return results;
  }

  // Delete old playback history
  Future<int> deleteOldPlaybackHistory(int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    return await _dbHelper.delete(
      DatabaseHelper.tablePlaybackHistory,
      'playedAt < ?',
      [cutoffDate.millisecondsSinceEpoch],
    );
  }

  // Clear all playback history
  Future<int> clearAllPlaybackHistory() async {
    return await _dbHelper.delete(
      DatabaseHelper.tablePlaybackHistory,
      '1=1',
      [],
    );
  }

  // Get episodes that can be resumed
  Future<List<Map<String, dynamic>>> getResumableEpisodes({
    int? limit,
    int? offset,
  }) async {
    final results = await _dbHelper.rawQuery('''
      SELECT ph.*, e.title as episodeTitle, e.coverImage as episodeCoverImage,
             p.title as podcastTitle, p.coverImage as podcastCoverImage,
             (ph.duration - ph.position) as remainingTime
      FROM ${DatabaseHelper.tablePlaybackHistory} ph
      INNER JOIN ${DatabaseHelper.tableEpisodes} e ON ph.episodeId = e.id
      INNER JOIN ${DatabaseHelper.tablePodcasts} p ON e.podcastId = p.id
      WHERE ph.completed = 0 AND ph.position > 0
      ORDER BY ph.playedAt DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''');

    return results;
  }

  // Get listening streak
  Future<int> getListeningStreak() async {
    final results = await _dbHelper.rawQuery('''
      WITH RECURSIVE dates AS (
        SELECT DATE('now') as date, 0 as streak
        UNION ALL
        SELECT DATE(date, '-1 day'), 
               CASE 
                 WHEN EXISTS (
                   SELECT 1 FROM ${DatabaseHelper.tablePlaybackHistory} 
                   WHERE DATE(playedAt/1000, 'unixepoch') = date
                 ) THEN streak + 1
                 ELSE 0
               END
        FROM dates 
        WHERE streak > 0
      )
      SELECT MAX(streak) as maxStreak FROM dates
    ''');

    return Sqflite.firstIntValue(results) ?? 0;
  }
}
