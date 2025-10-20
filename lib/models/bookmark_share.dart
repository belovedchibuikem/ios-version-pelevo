class BookmarkShare {
  final int id;
  final int bookmarkId;
  final int sharedByUserId;
  final int? sharedWithUserId;
  final String shareType;
  final String? shareMessage;
  final bool isActive;
  final DateTime? expiresAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookmarkShare({
    required this.id,
    required this.bookmarkId,
    required this.sharedByUserId,
    this.sharedWithUserId,
    required this.shareType,
    this.shareMessage,
    required this.isActive,
    this.expiresAt,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookmarkShare.fromJson(Map<String, dynamic> json) {
    return BookmarkShare(
      id: json['id'],
      bookmarkId: json['bookmark_id'],
      sharedByUserId: json['shared_by_user_id'],
      sharedWithUserId: json['shared_with_user_id'],
      shareType: json['share_type'],
      shareMessage: json['share_message'],
      isActive: json['is_active'] ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookmark_id': bookmarkId,
      'shared_by_user_id': sharedByUserId,
      'shared_with_user_id': sharedWithUserId,
      'share_type': shareType,
      'share_message': shareMessage,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'view_count': viewCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BookmarkShare copyWith({
    int? id,
    int? bookmarkId,
    int? sharedByUserId,
    int? sharedWithUserId,
    String? shareType,
    String? shareMessage,
    bool? isActive,
    DateTime? expiresAt,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookmarkShare(
      id: id ?? this.id,
      bookmarkId: bookmarkId ?? this.bookmarkId,
      sharedByUserId: sharedByUserId ?? this.sharedByUserId,
      sharedWithUserId: sharedWithUserId ?? this.sharedWithUserId,
      shareType: shareType ?? this.shareType,
      shareMessage: shareMessage ?? this.shareMessage,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isPublic => shareType == 'public';
  bool get isUserShare => shareType == 'user';
  bool get isLinkShare => shareType == 'link';

  String get shareTypeLabel {
    switch (shareType) {
      case 'public':
        return 'Public';
      case 'user':
        return 'User';
      case 'link':
        return 'Link';
      default:
        return 'Unknown';
    }
  }

  String get statusLabel {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    return 'Active';
  }

  bool get canView => isActive && !isExpired;
}
