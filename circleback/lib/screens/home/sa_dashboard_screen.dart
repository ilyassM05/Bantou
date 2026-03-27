import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/http_auth_service.dart';
import '../../theme/app_colors.dart';

/// Super Admin Dashboard — shows Members, Admins, Circles, and pending invitations.
/// Only accessible to users with role 'SA'.
class SaDashboardScreen extends StatefulWidget {
  const SaDashboardScreen({super.key});
  static const routeName = '/sa-dashboard';

  @override
  State<SaDashboardScreen> createState() => _SaDashboardScreenState();
}

class _SaDashboardScreenState extends State<SaDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = HttpAuthService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _pendingInvitations = [];

  // Invite member dialog state
  final _inviteEmailCtrl = TextEditingController();
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inviteEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dash = await _authService.getSADashboard();
      final pending = await _authService.getPendingMemberInvitations();
      if (mounted) {
        setState(() {
          _dashboardData = dash;
          _pendingInvitations = pending;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _inviteMember() async {
    final email = _inviteEmailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _inviting = true);
    try {
      final msg = await _authService.inviteMember(email);
      _inviteEmailCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFF34D399)),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _respond(int id, String action) async {
    try {
      final msg = await _authService.respondToMemberInvitation(id, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: action == 'approve' ? const Color(0xFF34D399) : Colors.orange),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Invite Member', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: _inviteEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _inviting ? null : _inviteMember,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: _inviting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Invite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assocName = _dashboardData?['associationName'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SA Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
            if (assocName.isNotEmpty)
              Text(assocName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Members (${(_dashboardData?['members'] as List?)?.length ?? 0})'),
            Tab(text: 'Admins (${(_dashboardData?['admins'] as List?)?.length ?? 0})'),
            Tab(text: 'Circles (${(_dashboardData?['circles'] as List?)?.length ?? 0})'),
            Tab(text: 'Pending (${_pendingInvitations.length})'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Invite Member',
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFF34D399)),
            onPressed: _showInviteDialog,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: _ErrorView(message: _error!, onRetry: _loadData))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _MembersTab(members: (_dashboardData?['members'] as List?) ?? []),
                    _AdminsTab(admins: (_dashboardData?['admins'] as List?) ?? []),
                    _CirclesTab(circles: (_dashboardData?['circles'] as List?) ?? []),
                    _PendingTab(
                      invitations: _pendingInvitations,
                      onRespond: _respond,
                    ),
                  ],
                ),
    );
  }
}

// ─── Members Tab ─────────────────────────────────────────────────────────────

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.members});
  final List<dynamic> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return _EmptyState(icon: Icons.people_outline, label: 'No members yet.\nUse the + button to invite someone.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = members[i] as Map<String, dynamic>;
        return _UserCard(
          name: m['name'] ?? '',
          email: m['email'] ?? '',
          role: 'Member',
          roleColor: const Color(0xFF818CF8),
          status: m['status'] ?? '',
        );
      },
    );
  }
}

// ─── Admins Tab ───────────────────────────────────────────────────────────────

class _AdminsTab extends StatelessWidget {
  const _AdminsTab({required this.admins});
  final List<dynamic> admins;

  @override
  Widget build(BuildContext context) {
    if (admins.isEmpty) {
      return _EmptyState(icon: Icons.admin_panel_settings_outlined, label: 'No admins found.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: admins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = admins[i] as Map<String, dynamic>;
        final role = a['role'] ?? 'admin';
        return _UserCard(
          name: a['name'] ?? '',
          email: a['email'] ?? '',
          role: role == 'SA' ? 'Super Admin' : 'Admin',
          roleColor: role == 'SA' ? const Color(0xFFC9A84C) : const Color(0xFF34D399),
          status: a['status'] ?? '',
        );
      },
    );
  }
}

// ─── Circles Tab ──────────────────────────────────────────────────────────────

class _CirclesTab extends StatelessWidget {
  const _CirclesTab({required this.circles});
  final List<dynamic> circles;

  @override
  Widget build(BuildContext context) {
    if (circles.isEmpty) {
      return _EmptyState(icon: Icons.groups_2_outlined, label: 'No circles created yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: circles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = circles[i] as Map<String, dynamic>;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF818CF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups_2_outlined, color: Color(0xFF818CF8), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('${c['city'] ?? ''}, ${c['country'] ?? ''}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c['status'] == 'Active' ? const Color(0xFF34D399).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(c['status'] ?? '', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: c['status'] == 'Active' ? const Color(0xFF34D399) : Colors.grey,
                    )),
                  ),
                ],
              ),
              if ((c['creator_name'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFFC9A84C)),
                    const SizedBox(width: 4),
                    Text('Responsible: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    Text(c['responsible'] ?? c['creator_name'] ?? '',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.manage_accounts_outlined, size: 14, color: Color(0xFF818CF8)),
                    const SizedBox(width: 4),
                    Text('Created by: ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    Text(c['creator_name'] ?? '',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Pending Invitations Tab ──────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.invitations, required this.onRespond});
  final List<dynamic> invitations;
  final void Function(int id, String action) onRespond;

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return _EmptyState(icon: Icons.mark_email_read_outlined, label: 'No pending invitations from members.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invitations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final inv = invitations[i] as Map<String, dynamic>;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined, color: Color(0xFFC9A84C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(inv['invitee_email'] ?? '',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Invited by: ${inv['inviter_name'] ?? ''}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              if ((inv['circle_name'] ?? '').isNotEmpty)
                Text('Circle: ${inv['circle_name']}',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF818CF8))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onRespond(inv['id'], 'reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onRespond(inv['id'], 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34D399),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Approve & Send', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.name,
    required this.email,
    required this.role,
    required this.roleColor,
    required this.status,
  });
  final String name, email, role, status;
  final Color roleColor;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withValues(alpha: 0.2),
            child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: roleColor, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(email, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(role, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
