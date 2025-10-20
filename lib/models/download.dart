class Download {
  final int id;
  final int episodeId;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final DateTime? downloadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Episode? episode;

  Download({
    required this.id,
    required this.episodeId,
    required this.filePath,
    required this.fileName,
    this.fileSize,
    this.downloadedAt,
    required this.createdAt,
    required this.updatedAt,
    this.episode,
  });

  factory Download.fromJson(Map<String, dynamic> json) {
    return Download(
      id: json['id'],
      episodeId: json['podcastindex_episode_id'],
      filePath: json['file_path'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.parse(json['downloaded_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      episode:
          json['episode'] != null ? Episode.fromJson(json['episode']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'podcastindex_episode_id': episodeId,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'downloaded_at': downloadedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'episode': episode?.toJson(),
    };
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';

    final units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize!.toDouble();
    int unit = 0;

    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }

    return '${size.toStringAsFixed(2)} ${units[unit]}';
  }
}

class Episode {
  final int id;
  final String title;
  final String? description;
  final int? duration;
  final DateTime? pubDate;
  final String? image;
  final Podcast? podcast;

  Episode({
    required this.id,
    required this.title,
    this.description,
    this.duration,
    this.pubDate,
    this.image,
    this.podcast,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'],
      pubDate:
          json['pub_date'] != null ? DateTime.parse(json['pub_date']) : null,
      image: json['image'] ?? '',
      podcast:
          json['podcast'] != null ? Podcast.fromJson(json['podcast']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'pub_date': pubDate?.toIso8601String(),
      'image': image,
      'podcast': podcast?.toJson(),
    };
  }

  String get durationFormatted {
    if (duration == null) return 'Unknown';

    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    final seconds = duration! % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class Podcast {
  final int id;
  final String title;
  final String? description;
  final String? author;
  final String? image;
  final int? episodeCount;
  final List<String>? categories;

  Podcast({
    required this.id,
    required this.title,
    this.description,
    this.author,
    this.image,
    this.episodeCount,
    this.categories,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      author: json['author'] ?? '',
      image: json['image'] ?? '',
      episodeCount: json['episode_count'],
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'image': image,
      'episode_count': episodeCount,
      'categories': categories,
    };
  }
}
