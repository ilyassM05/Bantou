import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/conversation.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_colors.dart';
import 'chat_screen.dart';
import 'new_group_screen.dart';
import '../posts/friend_requests_screen.dart';
import '../posts/friend_list_screen.dart';
import '../../services/post_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  static const routeName = '/messages';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Conversation> _conversations = [];
  List<dynamic> _friends = [];
  bool _loading = true;
  String _searchQuery = '';
  int _pendingFriendRequests = 0;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _load();
    MessagingService.instance.connect();
    _notifSub = MessagingService.instance.onNotification.listen((_) => _load());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final convs = await MessagingService.instance.getConversations();
      final friends = await PostService().getFriends();
      final pendingRequests = await PostService().getPendingFriendRequests();
      if (mounted) {
        setState(() {
          _conversations = convs;
          _friends = friends;
          _pendingFriendRequests = pendingRequests.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Conversation> get _filtered {
    if (_searchQuery.isEmpty) return _conversations;

    final query = _searchQuery.toLowerCase();

    // Existing conversations matching query
    final matchingConvs = _conversations
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();

    // Friends matching query who do NOT already have a private conversation
    final matchingFriends = _friends.where((f) {
      final name = (f['name'] as String? ?? '').toLowerCase();
      if (!name.contains(query)) return false;

      final friendId = f['id'] as int;
      final hasConversation = _conversations.any((c) =>
        c.type == 'private' && c.otherUserId == friendId
      );
      return !hasConversation;
    }).map((f) => Conversation(
      id: 0,
      type: 'private',
      name: f['name'] ?? 'Unknown',
      imageUrl: f['profile_picture'],
      lastMessage: null,
      lastMessageAt: null,
      unreadCount: 0,
      otherUserId: f['id'],
    )).toList();

    return [...matchingConvs, ...matchingFriends];
  }

  int get _totalUnread => _conversations.fold(0, (s, c) => s + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: Column(
        children: [
          _buildHeader(l10n),
          _buildSearchBar(l10n),
          Expanded(child: _loading ? _buildLoader() : _buildList(l10n)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'messages_screen_fab',
        onPressed: () async {
          await Navigator.pushNamed(context, NewGroupScreen.routeName);
          _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.group_add_rounded, color: Colors.white),
        label: Text(l10n.ngTitle,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.msTitle,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Unread messages chip
          if (_totalUnread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.msUnread(_totalUnread),
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          const SizedBox(width: 10),
          // Friend Requests button with live notification badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_add_outlined,
                      color: AppColors.primary, size: 22),
                  tooltip: l10n.frTitle,
                  onPressed: () async {
                    await Navigator.pushNamed(
                        context, FriendRequestsScreen.routeName);
                    _load(); // Refresh badge after returning
                  },
                ),
              ),
              if (_pendingFriendRequests > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _pendingFriendRequests > 99
                            ? '99+'
                            : '$_pendingFriendRequests',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Friends List button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.people_rounded,
                  color: AppColors.primary, size: 22),
              tooltip: l10n.flTitle,
              onPressed: () {
                Navigator.pushNamed(context, FriendListScreen.routeName);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.msSearchHint,
            hintStyle: GoogleFonts.inter(color: AppColors.textHint),
            prefixIcon: Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );

  Widget _buildList(AppLocalizations l10n) {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty
                  ? l10n.msNoConversations
                  : l10n.msNoResults,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.msStartHint,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ConversationTile(
          conversation: _filtered[i],
          currentUserId: _currentUserId(),
          onTap: () async {
            if (_filtered[i].id == 0 && _filtered[i].otherUserId != null) {
              try {
                final conv = await MessagingService.instance
                    .getOrCreateDirectConversation(_filtered[i].otherUserId!);
                if (!mounted) return;
                await Navigator.pushNamed(context, ChatScreen.routeName,
                    arguments: conv);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not start chat: $e')));
                return;
              }
            } else {
              await Navigator.pushNamed(
                context,
                ChatScreen.routeName,
                arguments: _filtered[i],
              );
            }
            _load();
          },
        ),
      ),
    );
  }

  int _currentUserId() {
    return 0;
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  final Conversation conversation;
  final int currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasUnread = conversation.unreadCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.borderSoft,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt, l10n),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? l10n.msNoConversations,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${conversation.unreadCount}',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (conversation.isGroup) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.group_rounded, color: Colors.white, size: 24),
      );
    }
    // Private: initials avatar
    final initials = conversation.name.trim().isNotEmpty
        ? conversation.name
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _formatTime(DateTime? dt, AppLocalizations l10n) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return l10n.msYesterday;
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}
