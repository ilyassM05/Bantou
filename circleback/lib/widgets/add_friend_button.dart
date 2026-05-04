import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/post_service.dart';
import '../services/http_auth_service.dart';
import '../l10n/app_localizations.dart';

/// Reusable "Add Friend" button used on UserProfileScreen and Circle participant cards.
///
/// Self-contained: loads its own friend status on mount and manages all
/// state transitions internally. Pass [targetUserId]; the widget automatically
/// hides itself when [targetUserId] equals the currently signed-in user.
class AddFriendButton extends StatefulWidget {
  final int targetUserId;

  const AddFriendButton({super.key, required this.targetUserId});

  @override
  State<AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<AddFriendButton> {
  final PostService _service = PostService();

  /// Current relationship status:
  /// 'loading' | 'none' | 'pending_sent' | 'pending_received' | 'friends' | 'self' | 'error'
  String _status = 'loading';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final s = await _service.getFriendStatus(widget.targetUserId);
      if (mounted) setState(() => _status = s);
    } catch (_) {
      if (mounted) setState(() => _status = 'error');
    }
  }

  Future<void> _sendRequest() async {
    if (_isSending) return;
    final wasPendingReceived = _status == 'pending_received';
    setState(() => _isSending = true);
    
    try {
      await _service.sendFriendRequest(widget.targetUserId);
      if (mounted) {
        setState(() {
          _status = wasPendingReceived ? 'friends' : 'pending_sent';
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasPendingReceived 
                ? AppLocalizations.of(context).afFriendRequestAccepted 
                : AppLocalizations.of(context).afFriendRequestSentSuccess,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToChat() {
    // In a full implementation, you would look up the conversation ID or create a new one.
    // For now, we route to MessagesScreen to let the user find the chat or use standard routing.
    Navigator.pushNamed(context, '/messages');
  }

  @override
  Widget build(BuildContext context) {
    // Don't render for self or while checking
    if (_status == 'self') return const SizedBox.shrink();
    if (HttpAuthService.currentUserId == widget.targetUserId) return const SizedBox.shrink();

    return _buildButton();
  }

  Widget _buildButton() {
    final l10n = AppLocalizations.of(context);

    switch (_status) {
      case 'loading':
        return _buttonShell(
          label: l10n.afAddFriend,
          icon: Icons.person_add_outlined,
          bgColor: AppColors.primary.withValues(alpha: 0.12),
          textColor: AppColors.primary,
          enabled: false,
          isLoading: true,
        );

      case 'none':
      case 'pending_received': // they sent to us — we can "accept" by sending back
        return _buttonShell(
          label: _status == 'pending_received' ? l10n.afAcceptRequest : l10n.afAddFriend,
          icon: _status == 'pending_received' ? Icons.check_circle_outline : Icons.person_add_outlined,
          bgColor: AppColors.primary,
          textColor: Colors.white,
          enabled: !_isSending,
          isLoading: _isSending,
          onTap: _sendRequest,
        );

      case 'pending_sent':
        return _buttonShell(
          label: l10n.afRequestSent,
          icon: Icons.schedule_outlined,
          bgColor: const Color(0xFFF1F3F4),
          textColor: const Color(0xFF5F6368),
          enabled: false,
        );

      case 'friends':
        return _buttonShell(
          label: l10n.afMessage,
          icon: Icons.chat_bubble_outline,
          bgColor: AppColors.primary,
          textColor: Colors.white,
          enabled: true,
          onTap: _navigateToChat,
        );

      case 'error':
        return _buttonShell(
          label: l10n.afAddFriend,
          icon: Icons.person_add_outlined,
          bgColor: AppColors.primary.withValues(alpha: 0.12),
          textColor: AppColors.primary,
          enabled: true,
          onTap: _loadStatus, // retry on tap
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buttonShell({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required bool enabled,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8), // Ensure spacing around it
        constraints: const BoxConstraints(minHeight: 44), // Minimum height 44px
        child: Material(
          key: ValueKey(_status),
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  else
                    Icon(icon, size: 20, color: textColor),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
