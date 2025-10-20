import 'package:sqflite/sqflite.dart';
import '../../data/models/database_models.dart';
import '../database/database_helper.dart';

class EpisodeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Insert or update an episode
  Future<int> insertOrUpdateEpisode(EpisodeDatabaseModel episode) async {
    if (episode.id != null) {
      // Update existing episode
      return await _dbHelper.update(
        DatabaseHelper.tableEpisodes,
        episode.toMap(),
        'id = ?',
        [episode.id],
      );
    } else {
      // Insert new episode
      return await _dbHelper.insert(
        DatabaseHelper.tableEpisodes,
        episode.toMap(),
      );
    }
  }

  // Get episode by ID
  Future<EpisodeDatabaseModel?> getEpisodeById(int id) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return EpisodeDatabaseModel.fromMap(results.first);
    }
    return null;
  }

  // Get episode by GUID
  Future<EpisodeDatabaseModel?> getEpisodeByGuid(String guid) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'guid = ?',
      whereArgs: [guid],
    );

    if (results.isNotEmpty) {
      return EpisodeDatabaseModel.fromMap(results.first);
    }
    return null;
  }

  // Get episodes by podcast ID
  Future<List<EpisodeDatabaseModel>> getEpisodesByPodcastId(
    int podcastId, {
    int? limit,
    int? offset,
    String orderBy = 'releaseDate DESC',
  }) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'podcastId = ?',
      whereArgs: [podcastId],
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Get all episodes
  Future<List<EpisodeDatabaseModel>> getAllEpisodes({
    int? limit,
    int? offset,
    String orderBy = 'releaseDate DESC',
  }) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Get downloaded episodes
  Future<List<EpisodeDatabaseModel>> getDownloadedEpisodes({
    int? limit,
    int? offset,
    String orderBy = 'releaseDate DESC',
  }) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'isDownloaded = ?',
      whereArgs: [1],
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Get played episodes
  Future<List<EpisodeDatabaseModel>> getPlayedEpisodes({
    int? limit,
    int? offset,
    String orderBy = 'lastPlayed DESC',
  }) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'isPlayed = ?',
      whereArgs: [1],
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Search episodes by title or description
  Future<List<EpisodeDatabaseModel>> searchEpisodes(
    String query, {
    int? limit,
    int? offset,
  }) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'releaseDate DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Get episodes by category
  Future<List<EpisodeDatabaseModel>> getEpisodesByCategory(
    String category, {
    int? limit,
    int? offset,
  }) async {
    final results = await _dbHelper.rawQuery('''
      SELECT e.* FROM ${DatabaseHelper.tableEpisodes} e
      INNER JOIN ${DatabaseHelper.tablePodcasts} p ON e.podcastId = p.id
      WHERE p.category = ?
      ORDER BY e.releaseDate DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''', [category]);

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Get recent episodes
  Future<List<EpisodeDatabaseModel>> getRecentEpisodes({
    int days = 7,
    int? limit,
    int? offset,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'releaseDate >= ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
      orderBy: 'releaseDate DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Update episode download status
  Future<int> updateDownloadStatus(
      int episodeId, bool isDownloaded, String? localPath) async {
    return await _dbHelper.update(
      DatabaseHelper.tableEpisodes,
      {
        'isDownloaded': isDownloaded ? 1 : 0,
        'localPath': localPath,
      },
      'id = ?',
      [episodeId],
    );
  }

  // Update episode played status
  Future<int> updatePlayedStatus(int episodeId, bool isPlayed) async {
    return await _dbHelper.update(
      DatabaseHelper.tableEpisodes,
      {
        'isPlayed': isPlayed ? 1 : 0,
        'lastPlayed': DateTime.now().millisecondsSinceEpoch,
      },
      'id = ?',
      [episodeId],
    );
  }

  // Update episode play count
  Future<int> incrementPlayCount(int episodeId) async {
    final episode = await getEpisodeById(episodeId);
    if (episode != null) {
      return await _dbHelper.update(
        DatabaseHelper.tableEpisodes,
        {
          'playCount': episode.playCount + 1,
          'lastPlayed': DateTime.now().millisecondsSinceEpoch,
        },
        'id = ?',
        [episodeId],
      );
    }
    return 0;
  }

  // Update episode rating
  Future<int> updateRating(int episodeId, double rating) async {
    return await _dbHelper.update(
      DatabaseHelper.tableEpisodes,
      {'rating': rating},
      'id = ?',
      [episodeId],
    );
  }

  // Update episode notes
  Future<int> updateNotes(int episodeId, String notes) async {
    return await _dbHelper.update(
      DatabaseHelper.tableEpisodes,
      {'notes': notes},
      'id = ?',
      [episodeId],
    );
  }

  // Delete episode
  Future<int> deleteEpisode(int episodeId) async {
    return await _dbHelper.delete(
      DatabaseHelper.tableEpisodes,
      'id = ?',
      [episodeId],
    );
  }

  // Delete episodes by podcast ID
  Future<int> deleteEpisodesByPodcastId(int podcastId) async {
    return await _dbHelper.delete(
      DatabaseHelper.tableEpisodes,
      'podcastId = ?',
      [podcastId],
    );
  }

  // Get episode statistics
  Future<Map<String, dynamic>> getEpisodeStats() async {
    final totalEpisodes = Sqflite.firstIntValue(await _dbHelper.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.tableEpisodes}')) ??
        0;

    final downloadedEpisodes = Sqflite.firstIntValue(await _dbHelper.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.tableEpisodes} WHERE isDownloaded = 1')) ??
        0;

    final playedEpisodes = Sqflite.firstIntValue(await _dbHelper.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseHelper.tableEpisodes} WHERE isPlayed = 1')) ??
        0;

    final totalDuration = Sqflite.firstIntValue(await _dbHelper.rawQuery(
            'SELECT SUM(duration) FROM ${DatabaseHelper.tableEpisodes}')) ??
        0;

    final totalPlayCount = Sqflite.firstIntValue(await _dbHelper.rawQuery(
            'SELECT SUM(playCount) FROM ${DatabaseHelper.tableEpisodes}')) ??
        0;

    return {
      'totalEpisodes': totalEpisodes,
      'downloadedEpisodes': downloadedEpisodes,
      'playedEpisodes': playedEpisodes,
      'totalDuration': totalDuration,
      'totalPlayCount': totalPlayCount,
    };
  }

  // Get episodes that need updating
  Future<List<EpisodeDatabaseModel>> getEpisodesNeedingUpdate(
      int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    final results = await _dbHelper.query(
      DatabaseHelper.tableEpisodes,
      where: 'releaseDate < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
      orderBy: 'releaseDate ASC',
    );

    return results.map((map) => EpisodeDatabaseModel.fromMap(map)).toList();
  }

  // Bulk insert episodes (for initial sync)
  Future<void> bulkInsertEpisodes(List<EpisodeDatabaseModel> episodes) async {
    await _dbHelper.transaction((txn) async {
      for (final episode in episodes) {
        await txn.insert(
          DatabaseHelper.tableEpisodes,
          episode.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get episodes with podcast information (for display)
  Future<List<Map<String, dynamic>>> getEpisodesWithPodcastInfo({
    int? limit,
    int? offset,
    String orderBy = 'e.releaseDate DESC',
  }) async {
    final results = await _dbHelper.rawQuery('''
      SELECT e.*, p.title as podcastTitle, p.coverImage as podcastCoverImage
      FROM ${DatabaseHelper.tableEpisodes} e
      INNER JOIN ${DatabaseHelper.tablePodcasts} p ON e.podcastId = p.id
      ORDER BY $orderBy
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''');

    return results;
  }

  // Get episodes by podcast with full information
  Future<List<Map<String, dynamic>>> getEpisodesByPodcastWithInfo(
    int podcastId, {
    int? limit,
    int? offset,
    String orderBy = 'e.releaseDate DESC',
  }) async {
    final results = await _dbHelper.rawQuery('''
      SELECT e.*, p.title as podcastTitle, p.coverImage as podcastCoverImage
      FROM ${DatabaseHelper.tableEpisodes} e
      INNER JOIN ${DatabaseHelper.tablePodcasts} p ON e.podcastId = p.id
      WHERE e.podcastId = ?
      ORDER BY $orderBy
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''', [podcastId]);

    return results;
  }
}
