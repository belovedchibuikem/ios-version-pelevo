// Database Models for Local Storage
// These models represent the SQLite table structures

class PodcastDatabaseModel {
  final int? id;
  final String title;
  final String description;
  final String coverImage;
  final String feedUrl;
  final String author;
  final String language;
  final String category;
  final bool isExplicit;
  final DateTime lastUpdated;
  final bool isSubscribed;
  final int episodeCount;
  final String? websiteUrl;
  final String? email;

  PodcastDatabaseModel({
    this.id,
    required this.title,
    required this.description,
    required this.coverImage,
    required this.feedUrl,
    required this.author,
    required this.language,
    required this.category,
    required this.isExplicit,
    required this.lastUpdated,
    required this.isSubscribed,
    required this.episodeCount,
    this.websiteUrl,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverImage': coverImage,
      'feedUrl': feedUrl,
      'author': author,
      'language': language,
      'category': category,
      'isExplicit': isExplicit ? 1 : 0,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isSubscribed': isSubscribed ? 1 : 0,
      'episodeCount': episodeCount,
      'websiteUrl': websiteUrl,
      'email': email,
    };
  }

  factory PodcastDatabaseModel.fromMap(Map<String, dynamic> map) {
    return PodcastDatabaseModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      coverImage: map['coverImage'],
      feedUrl: map['feedUrl'],
      author: map['author'],
      language: map['language'],
      category: map['category'],
      isExplicit: map['isExplicit'] == 1,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      isSubscribed: map['isSubscribed'] == 1,
      episodeCount: map['episodeCount'],
      websiteUrl: map['websiteUrl'],
      email: map['email'],
    );
  }
}

class EpisodeDatabaseModel {
  final int? id;
  final int podcastId;
  final String title;
  final String description;
  final String audioUrl;
  final String? localPath;
  final int duration;
  final DateTime releaseDate;
  final bool isDownloaded;
  final bool isPlayed;
  final String? coverImage;
  final String? transcript;
  final String? notes;
  final DateTime lastPlayed;
  final int playCount;
  final double? rating;
  final String? guid;
  final String? enclosureUrl;
  final String? enclosureType;
  final int? enclosureSize;

  EpisodeDatabaseModel({
    this.id,
    required this.podcastId,
    required this.title,
    required this.description,
    required this.audioUrl,
    this.localPath,
    required this.duration,
    required this.releaseDate,
    this.isDownloaded = false,
    this.isPlayed = false,
    this.coverImage,
    this.transcript,
    this.notes,
    required this.lastPlayed,
    this.playCount = 0,
    this.rating,
    this.guid,
    this.enclosureUrl,
    this.enclosureType,
    this.enclosureSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'podcastId': podcastId,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'localPath': localPath,
      'duration': duration,
      'releaseDate': releaseDate.millisecondsSinceEpoch,
      'isDownloaded': isDownloaded ? 1 : 0,
      'isPlayed': isPlayed ? 1 : 0,
      'coverImage': coverImage,
      'transcript': transcript,
      'notes': notes,
      'lastPlayed': lastPlayed.millisecondsSinceEpoch,
      'playCount': playCount,
      'rating': rating,
      'guid': guid,
      'enclosureUrl': enclosureUrl,
      'enclosureType': enclosureType,
      'enclosureSize': enclosureSize,
    };
  }

  factory EpisodeDatabaseModel.fromMap(Map<String, dynamic> map) {
    return EpisodeDatabaseModel(
      id: map['id'],
      podcastId: map['podcastId'],
      title: map['title'],
      description: map['description'],
      audioUrl: map['audioUrl'],
      localPath: map['localPath'],
      duration: map['duration'],
      releaseDate: DateTime.fromMillisecondsSinceEpoch(map['releaseDate']),
      isDownloaded: map['isDownloaded'] == 1,
      isPlayed: map['isPlayed'] == 1,
      coverImage: map['coverImage'],
      transcript: map['transcript'],
      notes: map['notes'],
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(map['lastPlayed']),
      playCount: map['playCount'],
      rating: map['rating'],
      guid: map['guid'],
      enclosureUrl: map['enclosureUrl'],
      enclosureType: map['enclosureType'],
      enclosureSize: map['enclosureSize'],
    );
  }
}

class PlaybackHistoryModel {
  final int? id;
  final int episodeId;
  final int position; // in milliseconds
  final int duration; // in milliseconds
  final DateTime playedAt;
  final bool completed;
  final String? deviceId;
  final String? sessionId;

  PlaybackHistoryModel({
    this.id,
    required this.episodeId,
    required this.position,
    required this.duration,
    required this.playedAt,
    this.completed = false,
    this.deviceId,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'episodeId': episodeId,
      'position': position,
      'duration': duration,
      'playedAt': playedAt.millisecondsSinceEpoch,
      'completed': completed ? 1 : 0,
      'deviceId': deviceId,
      'sessionId': sessionId,
    };
  }

  factory PlaybackHistoryModel.fromMap(Map<String, dynamic> map) {
    return PlaybackHistoryModel(
      id: map['id'],
      episodeId: map['episodeId'],
      position: map['position'],
      duration: map['duration'],
      playedAt: DateTime.fromMillisecondsSinceEpoch(map['playedAt']),
      completed: map['completed'] == 1,
      deviceId: map['deviceId'],
      sessionId: map['sessionId'],
    );
  }
}

class UserBookmarkModel {
  final int? id;
  final int episodeId;
  final int position; // in milliseconds
  final String title;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? color;
  final bool isSynced;

  UserBookmarkModel({
    this.id,
    required this.episodeId,
    required this.position,
    required this.title,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'episodeId': episodeId,
      'position': position,
      'title': title,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'color': color,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory UserBookmarkModel.fromMap(Map<String, dynamic> map) {
    return UserBookmarkModel(
      id: map['id'],
      episodeId: map['episodeId'],
      position: map['position'],
      title: map['title'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      color: map['color'],
      isSynced: map['isSynced'] == 1,
    );
  }
}

class SubscriptionModel {
  final int? id;
  final int podcastId;
  final String userId;
  final DateTime subscribedAt;
  final bool isActive;
  final DateTime? lastSyncAt;
  final String? syncStatus;
  final String? deviceId;

  SubscriptionModel({
    this.id,
    required this.podcastId,
    required this.userId,
    required this.subscribedAt,
    this.isActive = true,
    this.lastSyncAt,
    this.syncStatus,
    this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'podcastId': podcastId,
      'userId': userId,
      'subscribedAt': subscribedAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
      'syncStatus': syncStatus,
      'deviceId': deviceId,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'],
      podcastId: map['podcastId'],
      userId: map['userId'],
      subscribedAt: DateTime.fromMillisecondsSinceEpoch(map['subscribedAt']),
      isActive: map['isActive'] == 1,
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSyncAt'])
          : null,
      syncStatus: map['syncStatus'],
      deviceId: map['deviceId'],
    );
  }
}

class DownloadQueueModel {
  final int? id;
  final int episodeId;
  final String status; // 'pending', 'downloading', 'completed', 'failed'
  final double progress; // 0.0 to 1.0
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int priority; // 1 = high, 2 = normal, 3 = low
  final bool isAutoDownload;

  DownloadQueueModel({
    this.id,
    required this.episodeId,
    required this.status,
    this.progress = 0.0,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.priority = 2,
    this.isAutoDownload = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'episodeId': episodeId,
      'status': status,
      'progress': progress,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
      'priority': priority,
      'isAutoDownload': isAutoDownload ? 1 : 0,
    };
  }

  factory DownloadQueueModel.fromMap(Map<String, dynamic> map) {
    return DownloadQueueModel(
      id: map['id'],
      episodeId: map['episodeId'],
      status: map['status'],
      progress: map['progress'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      errorMessage: map['errorMessage'],
      priority: map['priority'],
      isAutoDownload: map['isAutoDownload'] == 1,
    );
  }
}
