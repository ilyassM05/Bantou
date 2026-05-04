class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final int senderAvatarIndex;
  final String content;
  final String type; // 'text' | 'image'
  final String? imageUrl;
  final String status; // 'sent' | 'delivered' | 'seen'
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarIndex,
    required this.content,
    required this.type,
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'],
        conversationId: j['conversation_id'],
        senderId: j['sender_id'],
        senderName: j['sender_name'] ?? '',
        senderAvatarIndex: j['sender_avatar_index'] ?? 0,
        content: j['content'] ?? '',
        type: j['type'] ?? 'text',
        imageUrl: j['image_url'],
        status: j['status'] ?? 'sent',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );

  Message copyWith({String? status}) => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarIndex: senderAvatarIndex,
        content: content,
        type: type,
        imageUrl: imageUrl,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
