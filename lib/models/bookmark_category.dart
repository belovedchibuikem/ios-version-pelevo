class BookmarkCategory {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final int? parentId;
  final bool isDefault;
  final int sortOrder;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BookmarkCategory>? subcategories;
  final int? bookmarksCount;

  BookmarkCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.parentId,
    required this.isDefault,
    required this.sortOrder,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.subcategories,
    this.bookmarksCount,
  });

  factory BookmarkCategory.fromJson(Map<String, dynamic> json) {
    return BookmarkCategory(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      icon: json['icon'],
      parentId: json['parent_id'],
      isDefault: json['is_default'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      isPublic: json['is_public'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((sub) => BookmarkCategory.fromJson(sub))
              .toList()
          : null,
      bookmarksCount: json['bookmarks_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'parent_id': parentId,
      'is_default': isDefault,
      'sort_order': sortOrder,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'subcategories': subcategories?.map((sub) => sub.toJson()).toList(),
      'bookmarks_count': bookmarksCount,
    };
  }

  BookmarkCategory copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? color,
    String? icon,
    int? parentId,
    bool? isDefault,
    int? sortOrder,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BookmarkCategory>? subcategories,
    int? bookmarksCount,
  }) {
    return BookmarkCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subcategories: subcategories ?? this.subcategories,
      bookmarksCount: bookmarksCount ?? this.bookmarksCount,
    );
  }

  bool get isRoot => parentId == null;
  bool get hasSubcategories =>
      subcategories != null && subcategories!.isNotEmpty;
  bool get hasBookmarks => bookmarksCount != null && bookmarksCount! > 0;

  String get displayName {
    if (isDefault) {
      return '$name (Default)';
    }
    return name;
  }

  String get colorWithDefault => color ?? '#2196F3';
}
