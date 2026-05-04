import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/conversation.dart';
import '../../services/messaging_service.dart';
import '../../services/http_auth_service.dart';
import '../../theme/app_colors.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});
  static const routeName = '/messages/group/info';

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late Conversation _conversation;
  int _currentUserId = 0;
  bool _isAdmin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conversation = ModalRoute.of(context)!.settings.arguments as Conversation;
    _initUserId();
  }

  Future<void> _initUserId() async {
    final uid = HttpAuthService.currentUserId ?? 0;
    final isAdmin = _conversation.members
        .any((m) => m.id == uid && m.role == 'admin');
    if (mounted) setState(() { _currentUserId = uid; _isAdmin = isAdmin; });
  }

  Future<void> _removeMember(int memberId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $name from the group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MessagingService.instance.removeMember(_conversation.id, memberId);
      if (mounted) {
        setState(() {
          _conversation = Conversation(
            id: _conversation.id,
            type: _conversation.type,
            name: _conversation.name,
            imageUrl: _conversation.imageUrl,
            lastMessage: _conversation.lastMessage,
            lastMessageAt: _conversation.lastMessageAt,
            unreadCount: _conversation.unreadCount,
            otherUserId: _conversation.otherUserId,
            otherAvatarIndex: _conversation.otherAvatarIndex,
            members: _conversation.members.where((m) => m.id != memberId).toList(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MessagingService.instance.removeMember(_conversation.id, _currentUserId);
      if (mounted) Navigator.popUntil(context, ModalRoute.withName('/messages'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Group Info',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.group_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(_conversation.name,
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${_conversation.members.length} members',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Members section
            Text('Members',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            ...(_conversation.members.map((m) {
              final isMe = m.id == _currentUserId;
              final initials = m.name.trim().isNotEmpty
                  ? m.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
                  : '?';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(initials,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe ? '${m.name} (You)' : m.name,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          if (m.role == 'admin')
                            Text('Admin',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // Admin can remove non-admin members (not themselves)
                    if (_isAdmin && !isMe && m.role != 'admin')
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            color: AppColors.error, size: 20),
                        onPressed: () => _removeMember(m.id, m.name),
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            })),

            const SizedBox(height: 20),

            // Leave group
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _leaveGroup,
                icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.error),
                label: Text('Leave Group',
                    style: GoogleFonts.inter(
                        color: AppColors.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
