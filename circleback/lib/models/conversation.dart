class ConversationMember {
  final int id;
  final String name;
  final int avatarIndex;
  final String role; // 'admin' | 'member'

  ConversationMember({
    required this.id,
    required this.name,
    required this.avatarIndex,
    required this.role,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> j) =>
      ConversationMember(
        id: j['id'],
        name: j['name'] ?? '',
        avatarIndex: j['avatar_index'] ?? 0,
        role: j['role'] ?? 'member',
      );
}

class Conversation {
  final int id;
  final String type; // 'private' | 'group'
  final String name;
  final String? imageUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final int? otherUserId;
  final int? otherAvatarIndex;
  final List<ConversationMember> members;

  Conversation({
    required this.id,
    required this.type,
    required this.name,
    this.imageUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.otherUserId,
    this.otherAvatarIndex,
    this.members = const [],
  });

  bool get isGroup => type == 'group';

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'],
        type: j['type'] ?? 'private',
        name: j['name'] ?? 'Conversation',
        imageUrl: j['image_url'],
        lastMessage: j['last_message'],
        lastMessageAt: DateTime.tryParse(j['last_message_at'] ?? ''),
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
        otherUserId: j['other_user_id'],
        otherAvatarIndex: j['other_avatar_index'],
        members: (j['members'] as List<dynamic>?)
                ?.map((m) => ConversationMember.fromJson(m))
                .toList() ??
            [],
      );
}
