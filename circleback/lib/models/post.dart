class Post {
  final int id;
  final int userId;
  final int associationId;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByUser;
  final DateTime createdAt;
  final String userName;
  final String userRole;
  final int userAvatar;

  Post({
    required this.id,
    required this.userId,
    required this.associationId,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
    required this.createdAt,
    required this.userName,
    required this.userRole,
    required this.userAvatar,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      associationId: json['association_id'],
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      likesCount: (json['likes_count'] ?? 0) is int
          ? json['likes_count']
          : int.tryParse(json['likes_count'].toString()) ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByUser: (json['is_liked_by_user'] == 1 ||
          json['is_liked_by_user'] == true),
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'] ?? 'Unknown User',
      userRole: json['user_role'] ?? 'Member',
      userAvatar: json['user_avatar'] ?? 0,
    );
  }

  Post copyWith({int? likesCount, bool? isLikedByUser}) {
    return Post(
      id: id,
      userId: userId,
      associationId: associationId,
      content: content,
      imageUrl: imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      createdAt: createdAt,
      userName: userName,
      userRole: userRole,
      userAvatar: userAvatar,
    );
  }
}
