class ChatInvitation {
  final int id;
  final int senderId;
  final String senderName;
  final int senderAvatarIndex;
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime createdAt;

  ChatInvitation({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarIndex,
    required this.status,
    required this.createdAt,
  });

  factory ChatInvitation.fromJson(Map<String, dynamic> j) => ChatInvitation(
        id: j['id'],
        senderId: j['sender_id'],
        senderName: j['sender_name'] ?? 'Unknown',
        senderAvatarIndex: j['sender_avatar_index'] ?? 0,
        status: j['status'] ?? 'pending',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}
