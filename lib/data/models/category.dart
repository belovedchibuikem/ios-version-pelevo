// lib/data/models/category.dart

class Category {
  final String id;
  final String name;
  final String? icon;
  final int count;
  final String gradientStart;
  final String gradientEnd;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.count = 0,
    required this.gradientStart,
    required this.gradientEnd,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Generate default gradient colors based on category name
    final colors = _getDefaultGradientColors(json['name']?.toString() ?? '');

    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Category',
      icon: _getCategoryIcon(json['name']?.toString() ?? ''),
      count: json['count'] as int? ?? 0,
      gradientStart: json['gradientStart'] as String? ?? colors['start']!,
      gradientEnd: json['gradientEnd'] as String? ?? colors['end']!,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'count': count,
      'gradientStart': gradientStart,
      'gradientEnd': gradientEnd,
    };
  }

  // Generate default gradient colors based on category name
  static Map<String, String> _getDefaultGradientColors(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('comedy') || name.contains('humor')) {
      return {'start': '0xFFFF6B6B', 'end': '0xFFFF8E8E'};
    } else if (name.contains('crime') || name.contains('true crime')) {
      return {'start': '0xFF6B66FF', 'end': '0xFF8E8EFF'};
    } else if (name.contains('education') || name.contains('learn')) {
      return {'start': '0xFF6BFF6B', 'end': '0xFF8EFF8E'};
    } else if (name.contains('news') || name.contains('current events')) {
      return {'start': '0xFF6BFFFF', 'end': '0xFF8EFFFF'};
    } else if (name.contains('business') || name.contains('finance')) {
      return {'start': '0xFFFFB36B', 'end': '0xFFFFD18E'};
    } else if (name.contains('science') || name.contains('technology')) {
      return {'start': '0xFFB36BFF', 'end': '0xFFD18EFF'};
    } else if (name.contains('sport') || name.contains('fitness')) {
      return {'start': '0xFFFF6BB3', 'end': '0xFFFF8ED1'};
    } else if (name.contains('health') || name.contains('medical')) {
      return {'start': '0xFF6BFFB3', 'end': '0xFF8EFFD1'};
    } else if (name.contains('music') || name.contains('audio')) {
      return {'start': '0xFF1DB954', 'end': '0xFF1ED760'};
    } else if (name.contains('art') || name.contains('culture')) {
      return {'start': '0xFFFF6B9E', 'end': '0xFFFF8EC1'};
    } else if (name.contains('politics') || name.contains('government')) {
      return {'start': '0xFF9E6BFF', 'end': '0xFFC18EFF'};
    } else if (name.contains('religion') || name.contains('spiritual')) {
      return {'start': '0xFFFFD700', 'end': '0xFFFFE55C'};
    } else if (name.contains('history')) {
      return {'start': '0xFF8B4513', 'end': '0xFFA0522D'};
    } else if (name.contains('kids') || name.contains('children')) {
      return {'start': '0xFFFFE066', 'end': '0xFFFFB347'};
    } else if (name.contains('games') || name.contains('gaming')) {
      return {'start': '0xFF00C3FF', 'end': '0xFFFFFC00'};
    } else if (name.contains('lifestyle')) {
      return {'start': '0xFFFFA17F', 'end': '0xFFFFE0A3'};
    } else if (name.contains('food') || name.contains('cooking')) {
      return {'start': '0xFFFFC371', 'end': '0xFFFF5F6D'};
    } else if (name.contains('travel')) {
      return {'start': '0xFF43CEA2', 'end': '0xFF185A9D'};
    } else if (name.contains('fiction')) {
      return {'start': '0xFFB993D6', 'end': '0xFF8CA6DB'};
    } else if (name.contains('documentary')) {
      return {'start': '0xFF3A6073', 'end': '0xFF16222A'};
    } else if (name.contains('relationships') || name.contains('dating')) {
      return {'start': '0xFFFFA6C9', 'end': '0xFFFFF6B7'};
    } else if (name.contains('adventure')) {
      return {'start': '0xFF56CCF2', 'end': '0xFF2F80ED'};
    } else if (name.contains('nature') || name.contains('environment')) {
      return {'start': '0xFF11998E', 'end': '0xFF38EF7D'};
    } else if (name.contains('philosophy')) {
      return {'start': '0xFFB06AB3', 'end': '0xFF4568DC'};
    } else if (name.contains('psychology')) {
      return {'start': '0xFFFFE53B', 'end': '0xFFFF2525'};
    } else if (name.contains('language')) {
      return {'start': '0xFF43C6AC', 'end': '0xFF191654'};
    } else if (name.contains('animals') || name.contains('pets')) {
      return {'start': '0xFFFFDEE9', 'end': '0xFFB5FFFC'};
    } else if (name.contains('automotive') || name.contains('cars')) {
      return {'start': '0xFF232526', 'end': '0xFF414345'};
    } else if (name.contains('fashion') || name.contains('style')) {
      return {'start': '0xFFFFDEE9', 'end': '0xFFB5FFFC'};
    } else if (name.contains('hobbies')) {
      return {'start': '0xFF00F2FE', 'end': '0xFF4FACFE'};
    } else if (name.contains('personal journals')) {
      return {'start': '0xFFFFE000', 'end': '0xFF799F0C'};
    } else if (name.contains('society')) {
      return {'start': '0xFFFC5C7D', 'end': '0xFF6A82FB'};
    } else if (name.contains('tv') ||
        name.contains('film') ||
        name.contains('movie')) {
      return {'start': '0xFF0F2027', 'end': '0xFF2C5364'};
    } else if (name.contains('books') || name.contains('literature')) {
      return {'start': '0xFFFFE259', 'end': '0xFFFFA751'};
    } else if (name.contains('non-profit') || name.contains('charity')) {
      return {'start': '0xFF43E97B', 'end': '0xFF38F9D7'};
    } else {
      // Fallback: generate a unique color based on the hash of the category name
      final hash = categoryName.hashCode;
      final color1 = 0xFF000000 | ((hash & 0x00FFFFFF) ^ 0x00555555);
      final color2 = 0xFF000000 | (((hash >> 8) & 0x00FFFFFF) ^ 0x00AAAAAA);
      return {
        'start': '0x${color1.toRadixString(16).toUpperCase()}',
        'end': '0x${color2.toRadixString(16).toUpperCase()}'
      };
    }
  }

  // Get appropriate icon for category
  static String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('comedy') || name.contains('humor')) {
      return 'sentiment_very_satisfied';
    } else if (name.contains('crime') || name.contains('true crime')) {
      return 'gavel';
    } else if (name.contains('education') || name.contains('learn')) {
      return 'school';
    } else if (name.contains('news') || name.contains('current events')) {
      return 'newspaper';
    } else if (name.contains('business') || name.contains('finance')) {
      return 'business';
    } else if (name.contains('science') || name.contains('technology')) {
      return 'science';
    } else if (name.contains('sport') || name.contains('fitness')) {
      return 'sports_soccer';
    } else if (name.contains('health') || name.contains('medical')) {
      return 'favorite';
    } else if (name.contains('music') || name.contains('audio')) {
      return 'music_note';
    } else if (name.contains('art') || name.contains('culture')) {
      return 'palette';
    } else if (name.contains('politics') || name.contains('government')) {
      return 'account_balance';
    } else if (name.contains('religion') || name.contains('spiritual')) {
      return 'auto_awesome';
    } else if (name.contains('history')) {
      return 'auto_stories';
    } else {
      return 'podcasts';
    }
  }
}
