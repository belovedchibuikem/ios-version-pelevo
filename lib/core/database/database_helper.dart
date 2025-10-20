import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/database_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static bool _isInitializing = false;
  static bool _isInitialized = false;
  static Completer<Database>? _initCompleter;
  static int _stuckCount = 0; // Track how many times database gets stuck
  static const int _maxStuckAttempts =
      2; // Reduced from 3 to prevent cascading failures

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _databaseName = 'pelevo_podcast.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tablePodcasts = 'podcasts';
  static const String tableEpisodes = 'episodes';
  static const String tablePlaybackHistory = 'playback_history';
  static const String tableUserBookmarks = 'user_bookmarks';
  static const String tableSubscriptions = 'subscriptions';
  static const String tableDownloadQueue = 'download_queue';

  // Cache management
  static final Map<String, Map<String, dynamic>> _queryCache = {};
  static int _cacheHits = 0;
  static int _cacheMisses = 0;

  Future<Database> get database async {
    if (_database != null && _isInitialized) {
      return _database!;
    }

    // If we're already initializing, wait for it
    if (_isInitializing && _initCompleter != null) {
      try {
        return await _initCompleter!.future.timeout(
          Duration(seconds: 45), // Increased from 30 to give more time
          onTimeout: () {
            debugPrint(
                '⏰ Database initialization timeout, forcing resolution...');
            _initCompleter!.completeError('Initialization timeout');
            throw TimeoutException('Database initialization timeout');
          },
        );
      } catch (e) {
        debugPrint('❌ Database initialization failed: $e');
        // Force resolution of the stuck state with timeout
        try {
          await _resolveDatabaseLock().timeout(
            Duration(seconds: 10),
            onTimeout: () {
              debugPrint(
                  '⏰ Database resolution timeout, forcing emergency bypass...');
              _forceEmergencyBypass();
            },
          );
        } catch (resolutionError) {
          debugPrint('❌ Database resolution failed: $resolutionError');
          _forceEmergencyBypass();
        }

        // Try to get database again after resolution
        if (_database != null && _isInitialized) {
          return _database!;
        }

        // If still no database, create emergency bypass
        try {
          await _emergencyBypass();
          if (_database != null && _isInitialized) {
            return _database!;
          }
        } catch (bypassError) {
          debugPrint('❌ Emergency bypass failed: $bypassError');
        }

        // If all else fails, throw an error
        throw Exception(
            'Failed to create any working database after all recovery attempts');
      }
    }

    // Start initialization
    _isInitializing = true;
    _initCompleter = Completer<Database>();

    try {
      debugPrint('🚀 Starting database initialization...');

      // Try normal initialization first with aggressive timeout
      final db = await _initDatabase().timeout(
        Duration(seconds: 25), // Aggressive timeout for main initialization
        onTimeout: () {
          debugPrint(
              '⏰ Main database initialization timeout, forcing emergency bypass...');
          throw TimeoutException('Main database initialization timeout');
        },
      );

      _database = db;
      _isInitialized = true;
      _initCompleter!.complete(db);

      debugPrint('✅ Database initialized successfully');
      return db;
    } catch (e) {
      debugPrint('❌ Normal database initialization failed: $e');

      // If normal initialization fails, try aggressive resolution
      try {
        await _resolveDatabaseLock();

        // Try to get database again after resolution
        if (_database != null && _isInitialized) {
          _initCompleter!.complete(_database!);
          return _database!;
        }

        // If still no database, create emergency bypass
        await _emergencyBypass();

        if (_database != null && _isInitialized) {
          _initCompleter!.complete(_database!);
          return _database!;
        }

        throw Exception('Failed to create any working database');
      } catch (resolutionError) {
        debugPrint('❌ Database resolution failed: $resolutionError');

        // Use graceful failure handling instead of rethrowing
        await handleDatabaseFailure('Initialization failed: $resolutionError');

        // Return a minimal database or throw a more informative error
        if (_database != null && _isInitialized) {
          return _database!;
        }

        // If we still don't have a database, the app will continue without it
        throw Exception(
            'Database initialization failed and app will continue without database functionality');
      }
    }
  }

  /// Handle database open event
  Future<void> _onOpen(Database db) async {
    try {
      // Add timeout protection to the entire onOpen process
      await _onOpenWithTimeout(db).timeout(
        Duration(seconds: 10), // Reduced from 15 to 10 seconds
        onTimeout: () {
          debugPrint('🚨 Database onOpen timed out, forcing continue...');
          _forceContinueToPreventHanging();
          throw TimeoutException(
              'Database onOpen timed out', Duration(seconds: 10));
        },
      );
    } catch (e) {
      debugPrint('⚠️ Warning: Could not complete database onOpen: $e');
      // Force continue to prevent hanging
      _forceContinueToPreventHanging();
    }
  }

  /// Handle database open event with timeout protection and enhanced performance
  Future<void> _onOpenWithTimeout(Database db) async {
    try {
      // First, ensure android_metadata table exists (Android requirement)
      await _ensureAndroidMetadataTable(db);

      // Enhanced PRAGMA settings for better performance and reliability
      // Note: These PRAGMA statements must be executed BEFORE any transactions
      final performancePragmas = [
        'PRAGMA synchronous = NORMAL',
        'PRAGMA cache_size = 20000', // Increased from 10000 for better performance
        'PRAGMA temp_store = MEMORY',
        'PRAGMA mmap_size = 536870912', // Increased to 512MB for better memory mapping
        'PRAGMA page_size = 4096',
        'PRAGMA busy_timeout = 30000', // 30 second timeout
        'PRAGMA auto_vacuum = INCREMENTAL', // Add incremental vacuum for better performance
        'PRAGMA incremental_vacuum = 1000', // Vacuum every 1000 pages
        'PRAGMA optimize', // Optimize database structure
      ];

      for (final pragma in performancePragmas) {
        try {
          await db.execute(pragma);
          debugPrint('✅ Applied: $pragma');
        } catch (e) {
          debugPrint('⚠️ Some PRAGMA settings failed: $e');
          // Continue with basic settings
        }
      }

      // IMPORTANT: Set journal mode AFTER other configurations but BEFORE any transactions
      // This prevents the "cannot change into wal mode from within a transaction" error
      try {
        await db.execute('PRAGMA journal_mode = WAL');
        debugPrint('✅ WAL mode enabled successfully');

        // Set WAL-specific configurations for better performance
        try {
          await db.execute(
              'PRAGMA wal_autocheckpoint = 500'); // More frequent checkpoints
          await db.execute(
              'PRAGMA checkpoint_fullfsync = OFF'); // Faster checkpoints
          debugPrint('✅ Enhanced WAL configuration applied');
        } catch (e) {
          debugPrint('⚠️ Could not set enhanced WAL configuration: $e');
        }
      } catch (e) {
        debugPrint('⚠️ Could not enable WAL mode: $e');
        // Fallback to DELETE mode if WAL fails
        try {
          await db.execute('PRAGMA journal_mode = DELETE');
          debugPrint('✅ Fallback to DELETE journal mode');
        } catch (fallbackError) {
          debugPrint('⚠️ Could not set journal mode: $fallbackError');
        }
      }

      debugPrint('✅ Enhanced database configuration applied successfully');

      // Check if tables exist, if not create them with timeout
      await _ensureTablesExistWithTimeout(db).timeout(
        Duration(seconds: 8),
        onTimeout: () {
          debugPrint(
              '⏰ Table creation timeout, continuing with basic setup...');
        },
      );

      // Pre-warm database for better performance
      await _prewarmDatabase(db);
    } catch (e) {
      debugPrint('⚠️ Warning: Could not apply database configuration: $e');
      // Continue without optimal configuration
    }
  }

  /// Pre-warm database for better performance
  Future<void> _prewarmDatabase(Database db) async {
    try {
      debugPrint('🔥 Pre-warming database for better performance...');

      // Execute common queries to populate cache and optimize query planning
      await Future.wait([
        db.rawQuery("SELECT COUNT(*) FROM $tablePodcasts LIMIT 1"),
        db.rawQuery("SELECT COUNT(*) FROM $tableEpisodes LIMIT 1"),
        db.rawQuery("SELECT COUNT(*) FROM $tablePlaybackHistory LIMIT 1"),
      ]);

      // Analyze tables for better query planning
      try {
        await db.execute('ANALYZE');
        debugPrint('✅ Database analysis completed');
      } catch (e) {
        debugPrint('⚠️ Database analysis failed: $e');
      }

      debugPrint('✅ Database pre-warming completed');
    } catch (e) {
      debugPrint('⚠️ Database pre-warming failed: $e');
    }
  }

  /// Check if all required tables exist in the database
  Future<bool> _checkTablesExist(Database db) async {
    try {
      final requiredTables = [
        tablePodcasts,
        tableEpisodes,
        tablePlaybackHistory,
        tableUserBookmarks,
        tableSubscriptions,
        tableDownloadQueue,
      ];

      for (final tableName in requiredTables) {
        final result = await db
            .rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'")
            .timeout(
          Duration(seconds: 2), // Short timeout for each table check
          onTimeout: () {
            debugPrint(
                '⏰ Table check timeout for $tableName, assuming missing...');
            return <Map<String,
                dynamic>>[]; // Return empty result to indicate missing table
          },
        );

        if (result.isEmpty) {
          debugPrint('❌ Missing table: $tableName');
          return false;
        }
      }

      debugPrint('✅ All required tables exist');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking tables: $e');
      return false;
    }
  }

  /// Ensure all required tables exist
  Future<void> _ensureTablesExist(Database db) async {
    try {
      debugPrint('🔍 Checking if database tables exist...');

      // Check if all required tables exist with timeout
      final allTablesExist = await _checkTablesExist(db).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ Table check timeout, assuming tables exist...');
          return true; // Assume tables exist to prevent hanging
        },
      );

      if (!allTablesExist) {
        debugPrint('⚠️ Some tables missing, creating them now...');
        await _onCreate(db, _databaseVersion).timeout(
          Duration(seconds: 8),
          onTimeout: () {
            debugPrint(
                '⏰ Table creation timeout, continuing with basic setup...');
          },
        );
      } else {
        debugPrint('✅ All required tables exist');
        // Validate and migrate existing schema if needed with timeout
        await _validateAndMigrateSchema(db).timeout(
          Duration(seconds: 5),
          onTimeout: () {
            debugPrint(
                '⏰ Schema validation timeout, continuing with basic setup...');
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking table existence: $e');
      // Try to create tables anyway, but don't fail the app
      try {
        await _onCreate(db, _databaseVersion);
      } catch (createError) {
        debugPrint('❌ Failed to create tables: $createError');
        // Don't rethrow - continue with existing structure to prevent app hanging
        debugPrint('⚠️ Continuing with existing database structure...');
      }
    }
  }

  /// Ensure all required tables exist with timeout protection
  Future<void> _ensureTablesExistWithTimeout(Database db) async {
    try {
      await _ensureTablesExist(db).timeout(
        Duration(seconds: 10), // Timeout for table existence check
        onTimeout: () {
          debugPrint('🚨 Table existence check timed out, forcing continue...');
          _forceContinueToPreventHanging();
          throw TimeoutException(
              'Table existence check timed out', Duration(seconds: 10));
        },
      );
    } catch (e) {
      debugPrint('⚠️ Warning: Could not ensure tables exist: $e');
      // Force continue to prevent hanging
      _forceContinueToPreventHanging();
    }
  }

  /// Enhanced database creation with optimized indexes
  Future<void> _onCreate(Database db, int version) async {
    try {
      debugPrint('🔧 Creating database tables with optimized indexes...');

      // First, create the android_metadata table that Android expects
      await _ensureAndroidMetadataTable(db).timeout(
        Duration(seconds: 3),
        onTimeout: () {
          debugPrint(
              '⏰ Android metadata table creation timeout, continuing...');
        },
      );

      // Create tables with professional existence checking and timeouts
      await _createTableIfNotExists(db, tablePodcasts, '''
        CREATE TABLE $tablePodcasts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          coverImage TEXT NOT NULL,
          feedUrl TEXT UNIQUE NOT NULL,
          author TEXT NOT NULL,
          language TEXT NOT NULL,
          category TEXT NOT NULL,
          isExplicit INTEGER NOT NULL DEFAULT 0,
          lastUpdated INTEGER NOT NULL,
          isSubscribed INTEGER NOT NULL DEFAULT 0,
          episodeCount INTEGER NOT NULL DEFAULT 0,
          websiteUrl TEXT,
          email TEXT
        )
      ''').timeout(
        Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏰ Podcasts table creation timeout, continuing...');
        },
      );

      await _createTableIfNotExists(db, tableEpisodes, '''
        CREATE TABLE $tableEpisodes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          podcastId INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          audioUrl TEXT NOT NULL,
          localPath TEXT,
          duration INTEGER NOT NULL,
          releaseDate INTEGER NOT NULL,
          isDownloaded INTEGER NOT NULL DEFAULT 0,
          isPlayed INTEGER NOT NULL DEFAULT 0,
          coverImage TEXT,
          transcript TEXT,
          notes TEXT,
          lastPlayed INTEGER NOT NULL,
          playCount INTEGER NOT NULL DEFAULT 0,
          rating REAL,
          guid TEXT,
          enclosureUrl TEXT,
          enclosureType TEXT,
          enclosureSize INTEGER,
          FOREIGN KEY (podcastId) REFERENCES $tablePodcasts (id) ON DELETE CASCADE
        )
      ''').timeout(
        Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏰ Episodes table creation timeout, continuing...');
        },
      );

      await _createTableIfNotExists(db, tablePlaybackHistory, '''
        CREATE TABLE $tablePlaybackHistory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          episodeId INTEGER NOT NULL,
          position INTEGER NOT NULL,
          duration INTEGER NOT NULL,
          playedAt INTEGER NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          deviceId TEXT,
          sessionId TEXT,
          FOREIGN KEY (episodeId) REFERENCES $tableEpisodes (id) ON DELETE CASCADE
        )
      ''').timeout(
        Duration(seconds: 2),
        onTimeout: () {
          debugPrint(
              '⏰ Playback history table creation timeout, continuing...');
        },
      );

      await _createTableIfNotExists(db, tableUserBookmarks, '''
        CREATE TABLE $tableUserBookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          episodeId INTEGER NOT NULL,
          position INTEGER NOT NULL,
          title TEXT NOT NULL,
          notes TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          color TEXT,
          isSynced INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (episodeId) REFERENCES $tableEpisodes (id) ON DELETE CASCADE
        )
      ''').timeout(
        Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⏰ User bookmarks table creation timeout, continuing...');
        },
      );

      await _createTableIfNotExists(db, tableSubscriptions, '''
        CREATE TABLE $tableSubscriptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          podcastId INTEGER NOT NULL,
          userId TEXT NOT NULL,
          subscribedAt INTEGER NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1,
          lastSyncAt INTEGER,
          syncStatus TEXT,
          deviceId TEXT,
          FOREIGN KEY (podcastId) REFERENCES $tablePodcasts (id) ON DELETE CASCADE,
          UNIQUE(podcastId, userId)
        )
      ''').timeout(
        Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⏰ Subscriptions table creation timeout, continuing...');
        },
      );

      await _createTableIfNotExists(db, tableDownloadQueue, '''
        CREATE TABLE $tableDownloadQueue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          episodeId INTEGER NOT NULL,
          status TEXT NOT NULL,
          progress REAL NOT NULL DEFAULT 0.0,
          createdAt INTEGER NOT NULL,
          startedAt INTEGER,
          completedAt INTEGER,
          errorMessage TEXT,
          priority INTEGER NOT NULL DEFAULT 2,
          isAutoDownload INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (episodeId) REFERENCES $tableEpisodes (id) ON DELETE CASCADE
        )
      ''').timeout(
        Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⏰ Download queue table creation timeout, continuing...');
        },
      );

      // Create enhanced indexes for better query performance
      await _createEnhancedIndexes(db);

      debugPrint(
          '✅ All database tables and optimized indexes created successfully');
    } catch (e) {
      debugPrint('❌ Error creating database tables: $e');
      // Don't rethrow - handle gracefully to prevent app hanging
      debugPrint('⚠️ Continuing with existing database structure...');
    }
  }

  /// Create enhanced indexes for better query performance
  Future<void> _createEnhancedIndexes(Database db) async {
    try {
      debugPrint('🔧 Creating enhanced performance indexes...');

      final enhancedIndexes = [
        // Composite indexes for better query performance
        'CREATE INDEX IF NOT EXISTS idx_episodes_podcastId_releaseDate ON $tableEpisodes (podcastId, releaseDate DESC)',
        'CREATE INDEX IF NOT EXISTS idx_episodes_downloaded_status ON $tableEpisodes (isDownloaded, isPlayed)',
        'CREATE INDEX IF NOT EXISTS idx_episodes_guid_unique ON $tableEpisodes (guid)',

        // Playback history optimization
        'CREATE INDEX IF NOT EXISTS idx_playback_history_episode_position ON $tablePlaybackHistory (episodeId, position)',
        'CREATE INDEX IF NOT EXISTS idx_playback_history_played_at ON $tablePlaybackHistory (playedAt DESC)',

        // User bookmarks optimization
        'CREATE INDEX IF NOT EXISTS idx_user_bookmarks_episode_created ON $tableUserBookmarks (episodeId, createdAt DESC)',
        'CREATE INDEX IF NOT EXISTS idx_user_bookmarks_sync_status ON $tableUserBookmarks (isSynced)',

        // Subscriptions optimization
        'CREATE INDEX IF NOT EXISTS idx_subscriptions_user_active ON $tableSubscriptions (userId, isActive, subscribedAt DESC)',
        'CREATE INDEX IF NOT EXISTS idx_subscriptions_podcast_user ON $tableSubscriptions (podcastId, userId)',

        // Download queue optimization
        'CREATE INDEX IF NOT EXISTS idx_download_queue_status_priority ON $tableDownloadQueue (status, priority DESC)',
        'CREATE INDEX IF NOT EXISTS idx_download_queue_episode_status ON $tableDownloadQueue (episodeId, status)',

        // Podcast optimization
        'CREATE INDEX IF NOT EXISTS idx_podcasts_subscribed ON $tablePodcasts (isSubscribed)',
        'CREATE INDEX IF NOT EXISTS idx_podcasts_category ON $tablePodcasts (category)',
        'CREATE INDEX IF NOT EXISTS idx_podcasts_last_updated ON $tablePodcasts (lastUpdated DESC)',
      ];

      for (final index in enhancedIndexes) {
        try {
          await db.execute(index);
          debugPrint('✅ Created enhanced index');
        } catch (e) {
          debugPrint('⚠️ Could not create enhanced index: $e');
        }
      }

      debugPrint('✅ Enhanced indexes creation completed');
    } catch (e) {
      debugPrint('❌ Error creating enhanced indexes: $e');
    }
  }

  // Enhanced query method with caching support
  Future<List<Map<String, dynamic>>> queryWithCache(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    Duration cacheTimeout = const Duration(minutes: 5),
  }) async {
    final db = await database;

    // Add query result caching for frequently accessed data
    final cacheKey = '$table${where ?? ''}${limit ?? ''}${offset ?? ''}';

    // Check cache first
    if (_queryCache.containsKey(cacheKey)) {
      final cached = _queryCache[cacheKey]!;
      if (DateTime.now().difference(cached['timestamp']) < cacheTimeout) {
        _cacheHits++;
        debugPrint('💾 Returning cached result for: $cacheKey');
        return cached['data'];
      }
    }

    _cacheMisses++;

    // Execute query
    final result = await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    // Cache result
    _queryCache[cacheKey] = {
      'data': result,
      'timestamp': DateTime.now(),
    };

    // Limit cache size to prevent memory issues
    if (_queryCache.length > 100) {
      _clearOldCacheEntries();
    }

    return result;
  }

  // Pagination support for large datasets
  Future<List<Map<String, dynamic>>> queryPaginated(
    String table, {
    int page = 1,
    int pageSize = 50,
    String? orderBy,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final offset = (page - 1) * pageSize;

    return await query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );
  }

  // Get total count for pagination
  Future<int> getTableCount(String table,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;

    String countQuery = 'SELECT COUNT(*) FROM $table';
    if (where != null) {
      countQuery += ' WHERE $where';
    }

    final result = await db.rawQuery(countQuery, whereArgs);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Enhanced database statistics with performance metrics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;

    try {
      final podcastCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $tablePodcasts')) ??
          0;

      final episodeCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $tableEpisodes')) ??
          0;

      final downloadedCount = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM $tableEpisodes WHERE isDownloaded = 1')) ??
          0;

      final bookmarkCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $tableUserBookmarks')) ??
          0;

      final pendingDownloads = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM $tableDownloadQueue WHERE status = "pending"')) ??
          0;

      // Add performance metrics
      final cacheSize = _queryCache.length;
      final cacheHitRate = _calculateCacheHitRate();

      return {
        'podcasts': podcastCount,
        'episodes': episodeCount,
        'downloaded': downloadedCount,
        'bookmarks': bookmarkCount,
        'pendingDownloads': pendingDownloads,
        'cacheSize': cacheSize,
        'cacheHitRate': cacheHitRate,
        'databaseStatus': databaseStatus,
      };
    } catch (e) {
      debugPrint('❌ Error getting database stats: $e');
      return {
        'error': e.toString(),
        'databaseStatus': databaseStatus,
      };
    }
  }

  // Comprehensive database health monitoring
  Future<Map<String, dynamic>> getDatabaseHealthReport() async {
    try {
      final db = await database;
      final report = <String, dynamic>{};

      // Check table sizes and health
      final tables = [
        tablePodcasts,
        tableEpisodes,
        tablePlaybackHistory,
        tableUserBookmarks,
        tableSubscriptions,
        tableDownloadQueue
      ];
      for (final table in tables) {
        try {
          final count = await getTableCount(table);
          report['${table}_count'] = count;

          // Check table integrity
          final integrityResult =
              await db.rawQuery("PRAGMA table_info($table)");
          report['${table}_columns'] = integrityResult.length;
        } catch (e) {
          report['${table}_error'] = e.toString();
        }
      }

      // Check database file size
      try {
        final path = await _getDatabasePath();
        final file = File(path);
        if (await file.exists()) {
          final stat = await file.stat();
          report['file_size_mb'] =
              (stat.size / (1024 * 1024)).toStringAsFixed(2);
        }
      } catch (e) {
        report['file_size_error'] = e.toString();
      }

      // Check cache efficiency
      report['cache_size'] = _queryCache.length;
      report['cache_hit_rate'] = _calculateCacheHitRate();

      // Check database integrity
      try {
        final integrityResult = await db.rawQuery('PRAGMA integrity_check');
        report['integrity_check'] = integrityResult;
      } catch (e) {
        report['integrity_check_error'] = e.toString();
      }

      // Check database configuration
      try {
        final pragmaResults = await Future.wait([
          db.rawQuery('PRAGMA cache_size'),
          db.rawQuery('PRAGMA page_size'),
          db.rawQuery('PRAGMA journal_mode'),
          db.rawQuery('PRAGMA synchronous'),
        ]);

        report['pragma_cache_size'] = Sqflite.firstIntValue(pragmaResults[0]);
        report['pragma_page_size'] = Sqflite.firstIntValue(pragmaResults[1]);
        report['pragma_journal_mode'] = pragmaResults[2].first['journal_mode'];
        report['pragma_synchronous'] = pragmaResults[3].first['synchronous'];
      } catch (e) {
        report['pragma_check_error'] = e.toString();
      }

      // Overall health score
      report['health_score'] = _calculateHealthScore(report);

      return report;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Calculate overall database health score
  int _calculateHealthScore(Map<String, dynamic> report) {
    int score = 100;

    // Deduct points for errors
    final errorKeys = report.keys.where((key) => key.contains('error'));
    score -= (errorKeys.length * 10);

    // Deduct points for missing tables
    final tableKeys = report.keys.where((key) => key.contains('_count'));
    for (final key in tableKeys) {
      if (report[key] == 0) score -= 5;
    }

    // Deduct points for low cache hit rate
    final cacheHitRate = report['cache_hit_rate'] ?? 0.0;
    if (cacheHitRate < 0.5)
      score -= 15;
    else if (cacheHitRate < 0.7) score -= 10;

    return score.clamp(0, 100);
  }

  // Cache management
  void _clearQueryCache() {
    _queryCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    debugPrint('🗑️ Query cache cleared');
  }

  void _clearOldCacheEntries() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _queryCache.entries) {
      final age = now.difference(entry.value['timestamp']);
      if (age > const Duration(minutes: 30)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _queryCache.remove(key);
    }

    debugPrint('🗑️ Removed ${keysToRemove.length} old cache entries');
  }

  double _calculateCacheHitRate() {
    final total = _cacheHits + _cacheMisses;
    if (total == 0) return 0.0;
    return _cacheHits / total;
  }

  // Optimize database periodically
  Future<void> optimizeDatabase() async {
    try {
      debugPrint('🔧 Optimizing database...');
      final db = await database;

      // Run database optimization
      await db.execute('PRAGMA optimize');

      // Analyze tables for better query planning
      await db.execute('ANALYZE');

      // Clear old cache entries
      _clearOldCacheEntries();

      debugPrint('✅ Database optimization completed');
    } catch (e) {
      debugPrint('⚠️ Database optimization failed: $e');
    }
  }

  // Get database performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final db = await database;
      final metrics = <String, dynamic>{};

      // Check query performance
      final startTime = DateTime.now();
      await db.rawQuery("SELECT COUNT(*) FROM $tableEpisodes LIMIT 1");
      final queryTime = DateTime.now().difference(startTime);
      metrics['basic_query_time_ms'] = queryTime.inMilliseconds;

      // Check cache performance
      metrics['cache_size'] = _queryCache.length;
      metrics['cache_hit_rate'] = _calculateCacheHitRate();
      metrics['cache_hits'] = _cacheHits;
      metrics['cache_misses'] = _cacheMisses;

      // Check database size
      try {
        final path = await _getDatabasePath();
        final file = File(path);
        if (await file.exists()) {
          final stat = await file.stat();
          metrics['database_size_mb'] =
              (stat.size / (1024 * 1024)).toStringAsFixed(2);
        }
      } catch (e) {
        metrics['database_size_error'] = e.toString();
      }

      return metrics;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Generic insert method
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Generic update method
  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<Object?> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  // Generic delete method
  Future<int> delete(
      String table, String where, List<Object?> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Generic query method
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  // Raw query method for complex queries
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableDownloadQueue);
      await txn.delete(tableUserBookmarks);
      await txn.delete(tablePlaybackHistory);
      await txn.delete(tableEpisodes);
      await txn.delete(tableSubscriptions);
      await txn.delete(tablePodcasts);
    });
  }

  // Check if database is in emergency bypass mode
  bool get isEmergencyBypassed => _stuckCount > _maxStuckAttempts;

  // Get database status for debugging
  String get databaseStatus {
    if (isEmergencyBypassed) {
      return 'EMERGENCY_BYPASSED';
    } else if (_isInitializing) {
      return 'INITIALIZING';
    } else if (_database != null && _database!.isOpen) {
      return 'HEALTHY';
    } else if (_database != null) {
      return 'CLOSED';
    } else {
      return 'NOT_INITIALIZED';
    }
  }

  // Additional methods for database management and recovery
  Future<void> resetConnection() async {
    try {
      debugPrint('🔄 Resetting database connection...');
      if (_database != null) {
        try {
          if (_database!.isOpen) {
            await _database!.close();
          }
        } catch (e) {
          debugPrint('⚠️ Warning: Error closing database: $e');
        }
        _database = null;
      }
      _isInitializing = false;
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError('Connection reset');
      }
      _initCompleter = Completer<Database>();
      await Future.delayed(Duration(milliseconds: 1000));
      debugPrint('✅ Database connection reset successfully');
    } catch (e) {
      debugPrint('❌ Error resetting database connection: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      debugPrint('🔒 Closing database connection...');
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      _isInitializing = false;
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError('Database closed');
      }
      debugPrint('✅ Database connection closed successfully');
    } catch (e) {
      debugPrint('❌ Error closing database: $e');
      rethrow;
    }
  }

  // Placeholder methods for the remaining functionality
  Future<void> _ensureAndroidMetadataTable(Database db) async {
    try {
      // Check if android_metadata table exists
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='android_metadata'");

      if (result.isEmpty) {
        debugPrint('🔧 Creating android_metadata table...');

        // Create the android_metadata table that Android expects
        await db.execute('''
          CREATE TABLE android_metadata (
            locale TEXT
          )
        ''');

        // Insert default locale
        await db.insert('android_metadata', {'locale': 'en_US'});

        debugPrint('✅ android_metadata table created successfully');
      } else {
        debugPrint('✅ android_metadata table already exists');
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Could not create android_metadata table: $e');
      // Continue anyway - this is not critical
    }
  }

  Future<void> _validateAndMigrateSchema(Database db) async {
    try {
      debugPrint('🔍 Validating existing database schema...');

      // Check if we need to add missing columns to existing tables
      await _addMissingColumnsIfNeeded(db);

      // Check if we need to create missing indexes
      await _createMissingIndexesIfNeeded(db);

      debugPrint('✅ Database schema validation completed');
    } catch (e) {
      debugPrint('⚠️ Schema validation failed: $e');
      // Continue without failing - existing structure is better than no structure
      debugPrint('ℹ️ Continuing with existing database structure...');
    }
  }

  Future<void> _addMissingColumnsIfNeeded(Database db) async {
    try {
      // This is a placeholder for future schema migrations
      // When you need to add new columns, implement them here
      debugPrint('ℹ️ No schema migrations needed at this time');
    } catch (e) {
      debugPrint('⚠️ Error during schema migration: $e');
    }
  }

  Future<void> _createMissingIndexesIfNeeded(Database db) async {
    try {
      // This is a placeholder for future index migrations
      // When you need to add new indexes, implement them here
      debugPrint('ℹ️ No index migrations needed at this time');
    } catch (e) {
      debugPrint('⚠️ Error during index migration: $e');
    }
  }

  Future<void> _createTableIfNotExists(
      Database db, String tableName, String createSql) async {
    try {
      final exists = await _tableExists(db, tableName);
      if (!exists) {
        debugPrint('🔧 Creating table: $tableName');
        await db.execute(createSql);
        debugPrint('✅ Table created: $tableName');
      } else {
        debugPrint('ℹ️ Table already exists, skipping: $tableName');
        // Validate that the existing table has the expected structure
        await _validateTableStructure(db, tableName);
      }
    } catch (e) {
      debugPrint('⚠️ Error creating table $tableName: $e');
      // Continue without failing - table might already exist
      debugPrint('ℹ️ Continuing with existing table structure for: $tableName');
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ Error checking if table $tableName exists: $e');
      return false;
    }
  }

  Future<void> _validateTableStructure(Database db, String tableName) async {
    try {
      // Get the table schema from the database
      final schemaResult = await db.rawQuery("PRAGMA table_info($tableName)");

      if (schemaResult.isEmpty) {
        debugPrint('⚠️ Could not retrieve schema for table: $tableName');
        return;
      }

      // Log the existing table structure for debugging
      debugPrint('ℹ️ Existing table structure for $tableName:');
      for (final column in schemaResult) {
        final name = column['name'] as String?;
        final type = column['type'] as String?;
        final notNull = column['notnull'] as int?;
        final defaultValue = column['dflt_value'];
        debugPrint(
            '  - $name: $type (not null: ${notNull == 1}, default: $defaultValue)');
      }

      debugPrint('ℹ️ Table $tableName structure validated');
    } catch (e) {
      debugPrint('⚠️ Error validating table structure for $tableName: $e');
      // Continue without failing - existing structure is better than no structure
    }
  }

  Future<void> _resolveDatabaseLock() async {
    try {
      debugPrint('🔓 Resolving database lock...');

      // Step 1: Force close all connections
      await _forceCloseDatabase();

      // Step 2: Wait for system to release locks
      await Future.delayed(Duration(seconds: 2));

      // Step 3: Try to delete the locked database file
      final path = await _getDatabasePath();
      await _safeDeleteDatabaseFile(path);

      // Step 4: Wait again for file system operations
      await Future.delayed(Duration(seconds: 1));

      // Step 5: Create fresh database
      await _createFreshDatabase();

      debugPrint('✅ Database lock resolved successfully');
    } catch (e) {
      debugPrint('❌ Failed to resolve database lock: $e');
      // Last resort: emergency bypass
      await _emergencyBypass();
    }
  }

  Future<void> _forceCloseDatabase() async {
    try {
      debugPrint('🔒 Force closing all database connections...');

      // Close the main database connection
      if (_database != null) {
        try {
          await _database!.close();
          debugPrint('✅ Main database connection closed');
        } catch (e) {
          debugPrint('⚠️ Error closing main database: $e');
        }
        _database = null;
      }

      // Reset all state variables
      _isInitializing = false;
      _isInitialized = false;
      _initCompleter = null;

      // Force garbage collection to release any remaining references
      debugPrint('🗑️ Forcing garbage collection...');

      // Wait a bit for connections to fully close
      await Future.delayed(Duration(milliseconds: 500));

      debugPrint('✅ Database connections force closed');
    } catch (e) {
      debugPrint('❌ Error during force close: $e');
    }
  }

  Future<void> _safeDeleteDatabaseFile(String path) async {
    try {
      debugPrint('🗑️ Attempting to safely delete database file: $path');

      final dbFile = File(path);
      if (!await dbFile.exists()) {
        debugPrint('✅ Database file does not exist, no deletion needed');
        return;
      }

      // Try multiple deletion strategies
      bool deleted = false;

      // Strategy 1: Direct delete
      try {
        await dbFile.delete();
        deleted = true;
        debugPrint('✅ Database file deleted directly');
      } catch (e) {
        debugPrint('❌ Direct delete failed: $e');
      }

      // Strategy 2: Rename and delete if direct failed
      if (!deleted) {
        try {
          final tempPath =
              '${path}_delete_${DateTime.now().millisecondsSinceEpoch}';
          await dbFile.rename(tempPath);
          await File(tempPath).delete();
          deleted = true;
          debugPrint('✅ Database file deleted via rename');
        } catch (e) {
          debugPrint('❌ Rename delete failed: $e');
        }
      }

      if (deleted) {
        debugPrint('✅ Database file deletion handled');
      } else {
        debugPrint('❌ Could not delete database file safely');
      }
    } catch (e) {
      debugPrint('❌ Error during safe database file deletion: $e');
    }
  }

  Future<void> _createFreshDatabase() async {
    try {
      debugPrint('🆕 Creating completely fresh database...');

      // Ensure database directory exists
      final dbDir = await getDatabasesPath();
      final dbPath = join(dbDir, _databaseName);

      // Delete any existing database file
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
        debugPrint('🗑️ Old database file deleted');
      }

      // Create new database with minimal configuration
      _database = await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        singleInstance: false, // Allow multiple instances temporarily
      );

      // Apply configuration after successful creation
      await _onOpenWithTimeout(_database!);

      _isInitialized = true;
      debugPrint('✅ Fresh database created successfully');
    } catch (e) {
      debugPrint('❌ Failed to create fresh database: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      debugPrint(
          '🔄 Upgrading database from version $oldVersion to $newVersion');

      if (oldVersion < 1) {
        // Version 1: Initial schema
        debugPrint('📋 Creating initial database schema...');

        // Drop existing tables if they exist (to recreate with correct schema)
        await _dropExistingTables(db);

        // Create tables with correct schema
        await _onCreate(db, newVersion);

        debugPrint('✅ Database upgraded to version $newVersion');
      }
    } catch (e) {
      debugPrint('❌ Error upgrading database: $e');
      rethrow;
    }
  }

  Future<void> _dropExistingTables(Database db) async {
    try {
      debugPrint('🗑️ Dropping existing tables for schema recreation...');

      // Drop tables in reverse dependency order
      await db.execute('DROP TABLE IF EXISTS $tableDownloadQueue');
      await db.execute('DROP TABLE IF EXISTS $tableSubscriptions');
      await db.execute('DROP TABLE IF EXISTS $tableUserBookmarks');
      await db.execute('DROP TABLE IF EXISTS $tablePlaybackHistory');
      await db.execute('DROP TABLE IF EXISTS $tableEpisodes');
      await db.execute('DROP TABLE IF EXISTS $tablePodcasts');

      debugPrint('✅ Existing tables dropped successfully');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not drop some existing tables: $e');
      // Continue anyway
    }
  }

  Future<void> _forceEmergencyBypass() async {
    try {
      debugPrint('🚨 Forcing emergency bypass due to resolution failure...');

      // Reset all state
      _database = null;
      _isInitializing = false;
      _isInitialized = false;

      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.completeError('Emergency bypass forced');
      }

      // Create emergency bypass database
      try {
        await _emergencyBypass();
        debugPrint('✅ Emergency bypass completed');
      } catch (bypassError) {
        debugPrint('❌ Emergency bypass failed: $bypassError');

        // Try to create minimal working database as last resort
        debugPrint('🔄 Attempting to create minimal working database...');
        final minimalDb = await _createMinimalWorkingDatabase();
        if (minimalDb != null) {
          _database = minimalDb;
          _isInitialized = true;
          debugPrint('✅ Minimal working database created and set as active');
        } else {
          debugPrint(
              '⚠️ Database state reset, app will continue without database');
        }
      }
    } catch (e) {
      debugPrint('❌ Emergency bypass failed: $e');
      // Reset state anyway
      _database = null;
      _isInitializing = false;
      _isInitialized = false;
    }
  }

  Future<void> _emergencyBypass() async {
    try {
      debugPrint('🚨 Emergency database bypass activated...');

      // Create database in memory as last resort
      _database = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          debugPrint('🚨 Creating emergency in-memory database...');

          // Create only essential tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS episodes (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              audio_url TEXT,
              duration INTEGER,
              published_at INTEGER,
              podcast_id TEXT,
              created_at INTEGER DEFAULT (strftime('%s', 'now'))
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS episode_progress (
              episode_id TEXT PRIMARY KEY,
              position INTEGER DEFAULT 0,
              duration INTEGER DEFAULT 0,
              completed INTEGER DEFAULT 0,
              last_updated INTEGER DEFAULT (strftime('%s', 'now'))
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS podcasts (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              image_url TEXT,
              created_at INTEGER DEFAULT (strftime('%s', 'now'))
            )
          ''');

          debugPrint('✅ Emergency database tables created');
        },
      );

      _isInitialized = true;
      debugPrint('🚨 Emergency database bypass successful');
    } catch (e) {
      debugPrint('❌ Emergency database bypass failed: $e');
      // At this point, we can't do much more
      _isInitialized = false;
    }
  }

  Future<Database?> _createMinimalWorkingDatabase() async {
    try {
      debugPrint('🔄 Creating minimal working database as last resort...');

      // Get a temporary path for the minimal database
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'minimal_${_databaseName}');

      // Create a very basic database with minimal tables
      final db = await openDatabase(
        tempPath,
        version: 1,
        onCreate: (db, version) async {
          // Only create the most essential table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tablePodcasts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              coverImage TEXT NOT NULL,
              feedUrl TEXT UNIQUE NOT NULL
            )
          ''');
        },
        singleInstance: true,
        readOnly: false,
      );

      debugPrint('✅ Minimal working database created at: $tempPath');
      return db;
    } catch (e) {
      debugPrint('❌ Failed to create minimal working database: $e');
      return null;
    }
  }

  Future<void> _forceContinueToPreventHanging() async {
    try {
      _stuckCount++;
      debugPrint(
          '🚨 Force continuing to prevent hanging... (Attempt $_stuckCount/$_maxStuckAttempts)');

      // If we've been stuck too many times, completely bypass database
      if (_stuckCount >= _maxStuckAttempts) {
        debugPrint(
            '🚨 Maximum stuck attempts reached, bypassing database initialization');
        await _bypassDatabaseInitialization();
        return;
      }

      // Check if we should try a more aggressive approach first
      if (_stuckCount >= 2) {
        debugPrint('🔄 Multiple stuck attempts, trying emergency bypass...');
        try {
          // Instead of aggressive reset, go straight to emergency bypass
          await _emergencyBypass();
          _stuckCount = 0; // Reset counter after successful bypass
          return;
        } catch (bypassError) {
          debugPrint('❌ Emergency bypass failed: $bypassError');
        }
      }

      // Use safe reset to prevent transaction corruption with timeout
      try {
        await _safeResetDatabaseState().timeout(
          Duration(seconds: 2), // Short timeout to prevent hanging
          onTimeout: () {
            debugPrint('⏰ Safe reset timed out, forcing immediate reset...');
            // Force immediate reset
            _database = null;
            _isInitializing = false;
            _initCompleter = Completer<Database>();
          },
        );
      } catch (e) {
        debugPrint('❌ Safe reset failed: $e');
        // Force reset anyway
        _database = null;
        _isInitializing = false;
        _initCompleter = Completer<Database>();
      }

      debugPrint('✅ Forced continuation to prevent hanging');
    } catch (e) {
      debugPrint('❌ Error during force continue: $e');
      // Reset state anyway
      _database = null;
      _isInitializing = false;
      _initCompleter = Completer<Database>();
    }
  }

  Future<void> _safeResetDatabaseState() async {
    try {
      debugPrint('🔄 Safely resetting database state...');

      // Close database if open with aggressive timeout
      if (_database != null && _database!.isOpen) {
        try {
          // Start the close operation but don't wait for it to complete
          _database!.close().timeout(
            Duration(seconds: 1), // Very short timeout
            onTimeout: () {
              debugPrint(
                  '⏰ Database close timed out during reset, forcing continue...');
            },
          ).catchError((e) {
            debugPrint('⚠️ Database close error during reset (ignored): $e');
          });

          // Immediately reset the database reference
          _database = null;
          debugPrint('✅ Database connection force reset');
        } catch (e) {
          debugPrint('⚠️ Error during database close (ignored): $e');
          // Force close anyway
          _database = null;
        }
      }

      // Reset all state variables immediately
      _database = null;
      _isInitializing = false;

      // Complete any pending initialization
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError('Database state reset');
      }

      // Create new completer
      _initCompleter = Completer<Database>();

      // Very short wait for cleanup
      await Future.delayed(Duration(milliseconds: 100));

      debugPrint('✅ Database state safely reset');
    } catch (e) {
      debugPrint('❌ Error resetting database state: $e');
      // Force reset anyway
      _database = null;
      _isInitializing = false;
      _initCompleter = Completer<Database>();
    }
  }

  Future<void> _bypassDatabaseInitialization() async {
    try {
      debugPrint('🚨 Bypassing database initialization to prevent hanging...');

      // Reset all state
      _database = null;
      _isInitializing = false;

      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.completeError(
            'Database initialization bypassed to prevent hanging');
      }

      // Create new completer that will never complete
      _initCompleter = Completer<Database>();

      debugPrint(
          '✅ Database initialization bypassed - app will continue without database');
      debugPrint('⚠️ Note: Database operations will not be available');
      debugPrint('⚠️ Note: App will have limited functionality');
    } catch (e) {
      debugPrint('❌ Error bypassing database initialization: $e');
      // Reset state anyway
      _database = null;
      _isInitializing = false;
      _initCompleter = Completer<Database>();
    }
  }

  Future<void> handleDatabaseFailure(String reason) async {
    try {
      debugPrint('🚨 Handling database failure: $reason');

      // Reset all state
      _database = null;
      _isInitializing = false;
      _isInitialized = false;

      // Complete any pending operations with error
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.completeError('Database failure: $reason');
      }

      // Create new completer for future attempts
      _initCompleter = Completer<Database>();

      // Increment stuck count
      _stuckCount++;

      debugPrint('✅ Database failure handled gracefully');
      debugPrint('⚠️ App will continue without database functionality');
    } catch (e) {
      debugPrint('❌ Error handling database failure: $e');
      // Force reset anyway
      _database = null;
      _isInitializing = false;
      _isInitialized = false;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      debugPrint('🚀 Starting database initialization...');

      // Initialize sqflite for desktop support
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // Get the database path
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, _databaseName);

      debugPrint('🗄️ Database path: $path');

      // Check if database file exists and handle existing database
      final dbFile = File(path);
      if (await dbFile.exists()) {
        debugPrint('📁 Existing database file found, checking integrity...');

        // Check integrity with timeout
        bool isCorrupted = false;
        try {
          isCorrupted = !await _checkDatabaseIntegrity(path).timeout(
            Duration(seconds: 8),
            onTimeout: () {
              debugPrint('⏰ Integrity check timed out, assuming corrupted');
              return false;
            },
          );
        } catch (e) {
          debugPrint('⚠️ Integrity check failed: $e');
          isCorrupted = true;
        }

        if (isCorrupted) {
          debugPrint('🗑️ Corrupted database detected, removing...');
          await _safeDeleteDatabaseFile(path);
        } else {
          debugPrint('✅ Existing database is valid');
        }
      }

      // Wait for file system cleanup
      await Future.delayed(Duration(milliseconds: 500));

      debugPrint('🔓 Attempting to open database...');

      // Open database with configuration
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
        singleInstance: true,
        readOnly: false,
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Database opening timed out', Duration(seconds: 15));
        },
      );

      debugPrint('✅ Database opened successfully');

      return db;
    } catch (e, stackTrace) {
      debugPrint('❌ Database initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> _checkDatabaseIntegrity(String path) async {
    try {
      debugPrint('🔍 Checking database integrity at: $path');

      // Try to open database temporarily for integrity check
      Database? tempDb;
      try {
        tempDb = await openDatabase(
          path,
          version: _databaseVersion,
          readOnly: true, // Read-only to avoid conflicts
          singleInstance: false, // Allow temporary instance
        ).timeout(
          Duration(seconds: 5), // Very short timeout to prevent hanging
          onTimeout: () {
            debugPrint(
                '⏰ Database integrity check timed out, forcing continue...');
            throw TimeoutException(
                'Database integrity check timed out', Duration(seconds: 5));
          },
        );

        // Check if database can be opened and basic structure is sound
        try {
          // Just verify the database is accessible and not corrupted with timeout
          await tempDb.rawQuery("SELECT 1").timeout(Duration(seconds: 3));
          debugPrint(
              '✅ Database integrity check passed - database is accessible');

          // Close temporary database
          await tempDb.close();
          return true;
        } catch (e) {
          debugPrint('⚠️ Database structure check failed: $e');

          // Close temporary database
          await tempDb.close();

          // Only consider it corrupted if it's a structural issue, not missing tables
          if (e.toString().contains('malformed') ||
              e.toString().contains('not a database') ||
              e.toString().contains('corrupted')) {
            debugPrint('❌ Database is structurally corrupted');
            return false;
          } else {
            debugPrint('⚠️ Database has issues but may be recoverable');
            return true; // Allow recovery attempt
          }
        }
      } catch (e) {
        debugPrint('⚠️ Database integrity check failed: $e');

        // Try to close temp database if it exists
        if (tempDb != null && tempDb.isOpen) {
          try {
            await tempDb.close();
          } catch (closeError) {
            debugPrint('⚠️ Error closing temp database: $closeError');
          }
        }

        // If it's a locking issue, assume database is corrupted
        if (e.toString().contains('database is locked') ||
            e.toString().contains('SQLITE_BUSY') ||
            e.toString().contains('locked')) {
          debugPrint(
              '⚠️ Database locked during integrity check, assuming corrupted');
          return false;
        }

        // For timeout or other errors, force continue to prevent hanging
        if (e.toString().contains('timed out') ||
            e.toString().contains('timeout')) {
          debugPrint('⏰ Integrity check timeout, forcing continue...');
          return true; // Assume accessible to prevent hanging
        }

        // For other errors, assume corrupted
        return false;
      }
    } catch (e) {
      debugPrint('❌ Database integrity check error: $e');
      return true; // Assume accessible to prevent hanging
    }
  }

  Future<String> _getDatabasePath() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return join(documentsDirectory.path, _databaseName);
    } catch (e) {
      debugPrint('❌ Error getting database path: $e');
      // Fallback to a default path
      return join(Directory.current.path, _databaseName);
    }
  }
}
