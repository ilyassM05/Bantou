import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/circle_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Member-facing circles screen.
/// Shows all circles in the association with Join/Leave toggle and Invite-to-Circle action.
class MemberCirclesScreen extends StatefulWidget {
  const MemberCirclesScreen({super.key});
  static const routeName = '/member-circles';

  @override
  State<MemberCirclesScreen> createState() => _MemberCirclesScreenState();
}

class _MemberCirclesScreenState extends State<MemberCirclesScreen> {
  final _circleService = CircleService();
  bool _loading = true;
  String? _error;
  List<dynamic> _circles = [];
  String? _assocName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _circleService.getCircles();
      if (mounted) {
        setState(() {
          _circles = (data['circles'] as List?) ?? [];
          _assocName = data['associationName'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _toggleJoin(Map<String, dynamic> circle) async {
    final id = circle['id'] as int;
    final joined = circle['joinStatus'] == 'Joined';
    try {
      if (joined) {
        await _circleService.leaveCircle(id);
      } else {
        await _circleService.joinCircle(id);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInviteDialog(Map<String, dynamic> circle) {
    final emailCtrl = TextEditingController();
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: Text(AppLocalizations.of(context).cdInviteToCircle(circle['name'] ?? ''),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the email of someone you\'d like to invite to this circle.\nThe Super Admin will review your request.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).cdEmailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).cdCancel)),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;
                      setInnerState(() => sending = true);
                      try {
                        final msg = await _circleService.inviteToCircle(circle['id'] as int, email);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: const Color(0xFF34D399)),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setInnerState(() => sending = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context).cdSend, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).circles, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
            if (_assocName != null)
              Text(_assocName!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _circles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_2_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('No circles available yet.',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _circles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _CircleCard(
                          circle: _circles[i] as Map<String, dynamic>,
                          onToggleJoin: () => _toggleJoin(_circles[i] as Map<String, dynamic>),
                          onInvite: () => _showInviteDialog(_circles[i] as Map<String, dynamic>),
                        ),
                      ),
                    ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    required this.circle,
    required this.onToggleJoin,
    required this.onInvite,
  });
  final Map<String, dynamic> circle;
  final VoidCallback onToggleJoin;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final joined = circle['joinStatus'] == 'Joined';
    final name = circle['name'] ?? '';
    final description = circle['description'] ?? '';
    final city = circle['city'] ?? '';
    final country = circle['country'] ?? '';
    final responsible = circle['responsible'] ?? '';
    final status = circle['status'] ?? 'Active';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: joined
              ? const Color(0xFF34D399).withValues(alpha: 0.4)
              : AppColors.borderSoft,
          width: joined ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF818CF8).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF818CF8).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.groups_2_outlined, color: Color(0xFF818CF8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                      Text('$city, $country', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'Active'
                        ? const Color(0xFF34D399).withValues(alpha: 0.13)
                        : Colors.grey.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(AppLocalizations.of(context).translateStatus(status),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                          color: status == 'Active' ? const Color(0xFF34D399) : Colors.grey)),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(description, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (responsible.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 13, color: Color(0xFFC9A84C)),
                  const SizedBox(width: 4),
                  Text('${AppLocalizations.of(context).cdResponsibleSmall}: $responsible', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onInvite,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                    label: Text(AppLocalizations.of(context).cdInviteBtn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onToggleJoin,
                    icon: Icon(joined ? Icons.exit_to_app_rounded : Icons.login_rounded, size: 16),
                    label: Text(joined ? AppLocalizations.of(context).cdLeaveBtn : AppLocalizations.of(context).cdJoinBtn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: joined ? Colors.red.shade400 : const Color(0xFF34D399),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            // Joined badge
            if (joined) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF34D399)),
                  const SizedBox(width: 4),
                  Text(AppLocalizations.of(context).cdMemberOfCircle,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF34D399), fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
