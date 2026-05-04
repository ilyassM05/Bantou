import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../services/messaging_service.dart';
import '../../services/http_auth_service.dart';
import '../../theme/app_colors.dart';
import 'group_info_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  static const routeName = '/messages/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Conversation _conversation;
  final List<Message> _messages = [];
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _sending = false;
  late int _currentUserId;
  bool _initialized = false;

  StreamSubscription? _msgSub;
  StreamSubscription? _seenSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _conversation =
          ModalRoute.of(context)!.settings.arguments as Conversation;
      _currentUserId = HttpAuthService.currentUserId ?? 0;
      _init();
    }
  }

  Future<void> _init() async {
    MessagingService.instance.joinConversation(_conversation.id);
    await _loadMessages();
    await MessagingService.instance.markSeen(_conversation.id);

    _msgSub = MessagingService.instance.onMessage.listen((msg) {
      if (msg.conversationId == _conversation.id && mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
        MessagingService.instance.markSeen(_conversation.id);
      }
    });

    _seenSub = MessagingService.instance.onSeen.listen((data) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].senderId == _currentUserId) {
              _messages[i] = _messages[i].copyWith(status: 'seen');
            }
          }
        });
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final msgs =
          await MessagingService.instance.getMessages(_conversation.id);
      if (mounted) {
        setState(() {
          _messages.addAll(msgs);
          _loading = false;
        });
        // Set watermark for polling
        if (msgs.isNotEmpty) {
          MessagingService.instance.setLastMessageId(msgs.last.id);
        }
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    try {
      final msg =
          await MessagingService.instance.sendMessage(_conversation.id, text);
      if (mounted) {
        setState(() {
          _messages.add(msg);
          if (msg.id > 0) MessagingService.instance.setLastMessageId(msg.id);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _seenSub?.cancel();
    MessagingService.instance.leaveConversation(_conversation.id);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
              child: _loading ? _buildLoader() : _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.cardSurface,
      elevation: 0,
      leading: IconButton(
        icon:
            Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildConvAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversation.name,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_conversation.isGroup)
                  Text(
                    '${_conversation.members.length} members',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_conversation.isGroup)
          IconButton(
            icon:
                Icon(Icons.info_outline_rounded, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(
              context,
              GroupInfoScreen.routeName,
              arguments: _conversation,
            ),
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppColors.primary),
          onSelected: (v) async {
            if (v == 'block') {
              await MessagingService.instance
                  .blockUser(_conversation.otherUserId ?? 0);
            }
            if (v == 'leave') {
              await MessagingService.instance
                  .removeMember(_conversation.id, _currentUserId);
              if (mounted) Navigator.pop(context);
            }
          },
          itemBuilder: (_) => [
            if (!_conversation.isGroup)
              const PopupMenuItem(value: 'block', child: Text('Block user')),
            if (_conversation.isGroup)
              const PopupMenuItem(value: 'leave', child: Text('Leave group')),
          ],
        ),
      ],
    );
  }

  Widget _buildConvAvatar() {
    if (_conversation.isGroup) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.group_rounded, color: Colors.white, size: 18),
      );
    }
    final initials = _conversation.name.trim().isNotEmpty
        ? _conversation.name
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildLoader() =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waving_hand_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Say hello!',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isMe = msg.senderId == _currentUserId;
        final showName = _conversation.isGroup && !isMe;
        final showDate = i == 0 ||
            _messages[i].createdAt.day != _messages[i - 1].createdAt.day;
        return Column(
          children: [
            if (showDate) _buildDateDivider(msg.createdAt),
            _MessageBubble(msg: msg, isMe: isMe, showName: showName),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (dt.day == now.day) {
      label = 'Today';
    } else if (now.difference(dt).inDays == 1) {
      label = 'Yesterday';
    } else {
      label = '${dt.day}/${dt.month}/${dt.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE8D5A3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500)),
          ),
          const Expanded(child: Divider(color: Color(0xFFE8D5A3))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: TextField(
                controller: _textCtrl,
                maxLines: 4,
                minLines: 1,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _sending
                  ? const Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.showName,
  });

  final Message msg;
  final bool isMe;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showName)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      msg.senderName,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : AppColors.cardSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isMe ? AppColors.primary : AppColors.textHint)
                                .withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border:
                        isMe ? null : Border.all(color: AppColors.borderSoft),
                  ),
                  child: Text(
                    msg.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg.createdAt),
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _StatusIcon(status: msg.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = msg.senderName.isNotEmpty
        ? msg.senderName
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'seen':
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Color(0xFF34D399));
      case 'delivered':
        return Icon(Icons.done_all_rounded,
            size: 14, color: AppColors.textHint);
      default:
        return Icon(Icons.done_rounded, size: 14, color: AppColors.textHint);
    }
  }
}
