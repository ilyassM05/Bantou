import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/post_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/add_friend_button.dart';
import '../../l10n/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String userName; // passed for instant display while loading

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final PostService _postService = PostService();
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _postService.getUserProfile(widget.userId);
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _getRoleBadge(String role, AppLocalizations l10n) {
    switch (role) {
      case 'SA': return l10n.upSuperAdmin;
      case 'admin': return l10n.upAdmin;
      default: return l10n.upMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(l10n)
              : _buildProfile(l10n),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadProfile, child: Text(l10n.upRetry)),
        ],
      ),
    );
  }

  Widget _buildProfile(AppLocalizations l10n) {
    final p = _profile!;
    return CustomScrollView(
      slivers: [
        // ── Hero AppBar ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // Avatar — shows profile picture or initials
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: UserAvatar(
                        profilePictureUrl: p.profilePictureUrl,
                        name: p.name,
                        size: 86,
                        animate: false, // static in profile view
                        fallbackColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.name,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getRoleBadge(p.role, l10n),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Add Friend button ──────────────────────────────
                AddFriendButton(targetUserId: widget.userId),
                const SizedBox(height: 16),
                
                // About / Bio
                _buildSection(
                  icon: Icons.person_outline,
                  title: l10n.upAbout,
                  child: Text(
                    (p.bio != null && p.bio!.isNotEmpty) ? p.bio! : l10n.upNotProvided,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: (p.bio != null && p.bio!.isNotEmpty) ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.7),
                      fontStyle: (p.bio != null && p.bio!.isNotEmpty) ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Professional Info
                _buildSection(
                  icon: Icons.work_outline,
                  title: l10n.upProfInfo,
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.badge_outlined, (p.jobTitle != null && p.jobTitle!.isNotEmpty) ? p.jobTitle! : '${l10n.upJobTitle}: ${l10n.upNotProvided}'),
                      _buildInfoRow(Icons.business_outlined, (p.company != null && p.company!.isNotEmpty) ? p.company! : '${l10n.upCompany}: ${l10n.upNotProvided}'),
                      _buildInfoRow(Icons.group_outlined, (p.communityRole != null && p.communityRole!.isNotEmpty) ? p.communityRole! : '${l10n.upCommunityRole}: ${l10n.upNotProvided}'),
                      _buildInfoRow(Icons.location_on_outlined, (p.city != null && p.city!.isNotEmpty) ? p.city! : '${l10n.upCity}: ${l10n.upNotProvided}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Website
                _buildSection(
                  icon: Icons.link,
                  title: l10n.upLinks,
                  child: (p.website != null && p.website!.isNotEmpty)
                      ? InkWell(
                          onTap: () => _launchUrl(p.website!),
                          child: Text(
                            p.website!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : Text(
                          '${l10n.upWebsite}: ${l10n.upNotProvided}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Contact info
                _buildSection(
                  icon: Icons.contact_mail_outlined,
                  title: l10n.upContact,
                  child: Column(
                    children: [
                      (p.email != null && p.email!.isNotEmpty)
                          ? _buildContactRow(
                              icon: Icons.email_outlined,
                              label: p.email!,
                              onTap: () => _launchEmail(p.email!),
                            )
                          : _buildInfoRow(Icons.email_outlined, '${l10n.upEmail}: ${l10n.upNotProvided}'),
                      (p.phone != null && p.phone!.isNotEmpty)
                          ? _buildContactRow(
                              icon: Icons.phone_outlined,
                              label: p.phone!,
                              onTap: () => _launchPhone(p.phone!),
                            )
                          : _buildInfoRow(Icons.phone_outlined, '${l10n.upPhone}: ${l10n.upNotProvided}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contact CTA button
                if (p.email != null && p.email!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _launchEmail(p.email!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      l10n.upSendMessage,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
