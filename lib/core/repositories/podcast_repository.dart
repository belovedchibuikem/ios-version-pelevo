import 'package:sqflite/sqflite.dart';
import '../../data/models/database_models.dart';
import '../database/database_helper.dart';

class PodcastRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Insert or update a podcast
  Future<int> insertOrUpdatePodcast(PodcastDatabaseModel podcast) async {
    if (podcast.id != null) {
      // Update existing podcast
      return await _dbHelper.update(
        DatabaseHelper.tablePodcasts,
        podcast.toMap(),
        'id = ?',
        [podcast.id],
      );
    } else {
      // Insert new podcast
      return await _dbHelper.insert(
        DatabaseHelper.tablePodcasts,
        podcast.toMap(),
      );
    }
  }

  // Get podcast by ID
  Future<PodcastDatabaseModel?> getPodcastById(int id) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return PodcastDatabaseModel.fromMap(results.first);
    }
    return null;
  }

  // Get podcast by feed URL
  Future<PodcastDatabaseModel?> getPodcastByFeedUrl(String feedUrl) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      where: 'feedUrl = ?',
      whereArgs: [feedUrl],
    );

    if (results.isNotEmpty) {
      return PodcastDatabaseModel.fromMap(results.first);
    }
    return null;
  }

  // Get all podcasts
  Future<List<PodcastDatabaseModel>> getAllPodcasts() async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      orderBy: 'title ASC',
    );

    return results.map((map) => PodcastDatabaseModel.fromMap(map)).toList();
  }

  // Get subscribed podcasts
  Future<List<PodcastDatabaseModel>> getSubscribedPodcasts() async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      where: 'isSubscribed = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );

    return results.map((map) => PodcastDatabaseModel.fromMap(map)).toList();
  }

  // Search podcasts by title or description
  Future<List<PodcastDatabaseModel>> searchPodcasts(String query) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      where: 'title LIKE ? OR description LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'title ASC',
    );

    return results.map((map) => PodcastDatabaseModel.fromMap(map)).toList();
  }

  // Get podcasts by category
  Future<List<PodcastDatabaseModel>> getPodcastsByCategory(
      String category) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'title ASC',
    );

    return results.map((map) => PodcastDatabaseModel.fromMap(map)).toList();
  }

  // Update podcast subscription status
  Future<int> updateSubscriptionStatus(int podcastId, bool isSubscribed) async {
    return await _dbHelper.update(
      DatabaseHelper.tablePodcasts,
      {'isSubscribed': isSubscribed ? 1 : 0},
      'id = ?',
      [podcastId],
    );
  }

  // Update podcast episode count
  Future<int> updateEpisodeCount(int podcastId, int episodeCount) async {
    return await _dbHelper.update(
      DatabaseHelper.tablePodcasts,
      {'episodeCount': episodeCount},
      'id = ?',
      [podcastId],
    );
  }

  // Update podcast last updated timestamp
  Future<int> updateLastUpdated(int podcastId, DateTime lastUpdated) async {
    return await _dbHelper.update(
      DatabaseHelper.tablePodcasts,
      {'lastUpdated': lastUpdated.millisecondsSinceEpoch},
      'id = ?',
      [podcastId],
    );
  }

  // Delete podcast and all related data
  Future<void> deletePodcast(int podcastId) async {
    await _dbHelper.transaction((txn) async {
      // Delete related episodes first (foreign key constraint)
      await txn.delete(
        DatabaseHelper.tableEpisodes,
        where: 'podcastId = ?',
        whereArgs: [podcastId],
      );

      // Delete related subscriptions
      await txn.delete(
        DatabaseHelper.tableSubscriptions,
        where: 'podcastId = ?',
        whereArgs: [podcastId],
      );

      // Delete the podcast
      await txn.delete(
        DatabaseHelper.tablePodcasts,
        where: 'id = ?',
        whereArgs: [podcastId],
      );
    });
  }

  // Get podcast statistics
  Future<Map<String, dynamic>> getPodcastStats(int podcastId) async {
    final episodeCount = Sqflite.firstIntValue(await _dbHelper.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableEpisodes} WHERE podcastId = ?',
          [podcastId],
        )) ??
        0;

    final downloadedCount = Sqflite.firstIntValue(await _dbHelper.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableEpisodes} WHERE podcastId = ? AND isDownloaded = 1',
          [podcastId],
        )) ??
        0;

    final playedCount = Sqflite.firstIntValue(await _dbHelper.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableEpisodes} WHERE podcastId = ? AND isPlayed = 1',
          [podcastId],
        )) ??
        0;

    final totalDuration = Sqflite.firstIntValue(await _dbHelper.rawQuery(
          'SELECT SUM(duration) FROM ${DatabaseHelper.tableEpisodes} WHERE podcastId = ?',
          [podcastId],
        )) ??
        0;

    return {
      'episodeCount': episodeCount,
      'downloadedCount': downloadedCount,
      'playedCount': playedCount,
      'totalDuration': totalDuration,
    };
  }

  // Bulk insert podcasts (for initial sync)
  Future<void> bulkInsertPodcasts(List<PodcastDatabaseModel> podcasts) async {
    await _dbHelper.transaction((txn) async {
      for (final podcast in podcasts) {
        await txn.insert(
          DatabaseHelper.tablePodcasts,
          podcast.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get podcasts that need updating (older than specified hours)
  Future<List<PodcastDatabaseModel>> getPodcastsNeedingUpdate(
      int hoursOld) async {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hoursOld));

    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      where: 'lastUpdated < ?',
      whereArgs: [cutoffTime.millisecondsSinceEpoch],
      orderBy: 'lastUpdated ASC',
    );

    return results.map((map) => PodcastDatabaseModel.fromMap(map)).toList();
  }

  // Get recently added podcasts
  Future<List<PodcastDatabaseModel>> getRecentlyAddedPodcasts(
      {int limit = 10}) async {
    final results = await _dbHelper.query(
      DatabaseHelper.tablePodcasts,
      orderBy: 'id DESC',
      limit: limit,
    );

    return results.map((map) => PodcastDatabaseModel.fromMap(map)).toList();
  }

  // Get trending podcasts (by episode count and subscription count)
  Future<List<PodcastDatabaseModel>> getTrendingPodcasts(
      {int limit = 20}) async {
    final results = await _dbHelper.rawQuery('''
      SELECT p.*, 
             COUNT(e.id) as episodeCount,
             COUNT(s.id) as subscriptionCount
      FROM ${DatabaseHelper.tablePodcasts} p
      LEFT JOIN ${DatabaseHelper.tableEpisodes} e ON p.id = e.podcastId
      LEFT JOIN ${DatabaseHelper.tableSubscriptions} s ON p.id = s.podcastId AND s.isActive = 1
      GROUP BY p.id
      ORDER BY episodeCount DESC, subscriptionCount DESC
      LIMIT ?
    ''', [limit]);

    return results.map((map) => PodcastDatabaseModel.fromMap(map)).toList();
  }
}
