class PostComment {
  final int id;
  final int postId;
  final int userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
