import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_invitation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'biometric_service.dart';

const _kBase = 'http://10.0.2.2:3000';
const _kTimeout = Duration(seconds: 15);

/// HTTP-polling based messaging service (no WebSocket dependency).
/// Polls conversations every 8 s and messages every 3 s when in a chat.
class MessagingService {
  static final MessagingService instance = MessagingService._();
  MessagingService._();

  // ── Streams ───────────────────────────────────────────────────────────────
  final _messageCtrl = StreamController<Message>.broadcast();
  final _notificationCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _seenCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Message> get onMessage => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationCtrl.stream;
  Stream<Map<String, dynamic>> get onSeen => _seenCtrl.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingCtrl.stream;
  // Alias so MessagesScreen/main_shell can subscribe
  Stream<Map<String, dynamic>> get onInvitation => _notificationCtrl.stream
      .where((d) => d['type'] == 'invitation');

  Timer? _convPoller;
  Timer? _msgPoller;
  int? _pollingConvId;
  int _lastPolledMessageId = 0;

  bool get isConnected => _convPoller != null;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (_convPoller != null) return;
    // Poll conversations & invitations every 8 seconds
    _convPoller = Timer.periodic(const Duration(seconds: 8), (_) async {
      _notificationCtrl.add({'type': 'refresh'});
    });
  }

  void disconnect() {
    _convPoller?.cancel();
    _convPoller = null;
    _stopMessagePolling();
  }

  void joinConversation(int conversationId) {
    _pollingConvId = conversationId;
    _lastPolledMessageId = 0;
    _stopMessagePolling();
    _msgPoller = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollNewMessages(conversationId);
    });
  }

  void leaveConversation(int conversationId) {
    if (_pollingConvId == conversationId) {
      _pollingConvId = null;
      _stopMessagePolling();
    }
  }

  void _stopMessagePolling() {
    _msgPoller?.cancel();
    _msgPoller = null;
  }

  Future<void> _pollNewMessages(int convId) async {
    if (_lastPolledMessageId == 0) return; // first load handled by getMessages()
    try {
      final data = await _get('/conversations/$convId/messages?after=$_lastPolledMessageId') as List;
      for (final j in data) {
        final msg = Message.fromJson(j);
        if (msg.id > _lastPolledMessageId) {
          _lastPolledMessageId = msg.id;
          _messageCtrl.add(msg);
        }
      }
    } catch (_) {}
  }

  /// Called by ChatScreen after initial load to set the watermark for polling.
  void setLastMessageId(int id) => _lastPolledMessageId = id;

  // Typing indicators — no-op with polling (not real-time)
  void sendTyping(int conversationId) {}
  void sendStopTyping(int conversationId) {}
  void emitMarkSeen(int conversationId) => markSeen(conversationId);

  // ── HTTP helpers ──────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final token = await BiometricService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _get(String path) async {
    final res = await http
        .get(Uri.parse('$_kBase/api/messages$path'), headers: await _headers())
        .timeout(_kTimeout);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(body['error'] ?? 'Request failed');
    return body;
  }

  Future<dynamic> _post(String path, Map<String, dynamic> data) async {
    final res = await http
        .post(Uri.parse('$_kBase/api/messages$path'),
            headers: await _headers(), body: jsonEncode(data))
        .timeout(_kTimeout);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(body['error'] ?? 'Request failed');
    return body;
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> data) async {
    final res = await http
        .patch(Uri.parse('$_kBase/api/messages$path'),
            headers: await _headers(), body: jsonEncode(data))
        .timeout(_kTimeout);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(body['error'] ?? 'Request failed');
    return body;
  }

  Future<dynamic> _delete(String path) async {
    final res = await http
        .delete(Uri.parse('$_kBase/api/messages$path'), headers: await _headers())
        .timeout(_kTimeout);
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) throw Exception(body['error'] ?? 'Request failed');
    return body;
  }

  // ── Invitations ───────────────────────────────────────────────────────────
  Future<void> sendInvitation(int receiverId) async =>
      _post('/invitations', {'receiverId': receiverId});

  Future<List<ChatInvitation>> getInvitations() async {
    final data = await _get('/invitations') as List;
    return data.map((j) => ChatInvitation.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> respondToInvitation(int id, String action) async =>
      (await _patch('/invitations/$id', {'action': action})) as Map<String, dynamic>;

  // ── Conversations ─────────────────────────────────────────────────────────
  Future<List<Conversation>> getConversations() async {
    final data = await _get('/conversations') as List;
    return data.map((j) => Conversation.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> createGroup(String name, List<int> memberIds) async =>
      (await _post('/conversations', {'name': name, 'memberIds': memberIds}))
          as Map<String, dynamic>;

  Future<Conversation> getOrCreateDirectConversation(int targetUserId) async {
    final data = await _post('/conversations/direct', {'targetUserId': targetUserId});
    return Conversation.fromJson(data);
  }

  // ── Messages ──────────────────────────────────────────────────────────────
  Future<List<Message>> getMessages(int conversationId, {int? before}) async {
    final q = before != null ? '?before=$before' : '';
    final data = await _get('/conversations/$conversationId/messages$q') as List;
    return data.map((j) => Message.fromJson(j)).toList();
  }

  Future<Message> sendMessage(int conversationId, String content) async {
    final data = await _post(
        '/conversations/$conversationId/messages', {'content': content, 'type': 'text'});
    return Message.fromJson(data);
  }

  Future<void> markSeen(int conversationId) async =>
      _post('/conversations/$conversationId/seen', {});

  // ── Group management ──────────────────────────────────────────────────────
  Future<void> addMember(int conversationId, int memberId) async =>
      _post('/conversations/$conversationId/members', {'memberId': memberId});

  Future<void> removeMember(int conversationId, int userId) async =>
      _delete('/conversations/$conversationId/members/$userId');

  // ── User search ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final data =
        await _get('/users/search?q=${Uri.encodeComponent(query)}') as List;
    return data.map((j) => Map<String, dynamic>.from(j)).toList();
  }

  // ── Block ─────────────────────────────────────────────────────────────────
  Future<void> blockUser(int uid) async => _post('/block/$uid', {});
  Future<void> unblockUser(int uid) async => _delete('/block/$uid');

  void dispose() {
    disconnect();
    _messageCtrl.close();
    _notificationCtrl.close();
    _seenCtrl.close();
    _typingCtrl.close();
  }
}
