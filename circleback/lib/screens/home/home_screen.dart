import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/http_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_picker.dart';
import '../auth/edit_profile_screen.dart';
import '../circles/circle_dashboard_screen.dart';
import '../circles/member_circles_screen.dart';
import 'organization_management_screen.dart';
import 'sa_dashboard_screen.dart';

/// Static home screen — placeholder after successful authentication.
/// All UI strings resolved via [AppLocalizations] for multi-language support.
///
/// Expects route arguments `Map<String, String>? { 'name': ..., 'email': ... }`
/// passed from the auth screen after successful sign-in.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _associationName = '';

  @override
  void initState() {
    super.initState();
    _loadAssocName();
  }

  Future<void> _loadAssocName() async {
    final role = HttpAuthService.currentUserRole ?? 'SA';
    if (role != 'SA') return;
    try {
      final data = await HttpAuthService().getAssociation();
      if (mounted && data != null) {
        setState(() => _associationName = data['name'] ?? '');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(context),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l.appName,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Edit Profile
          IconButton(
            tooltip: l.profile,
            icon: Icon(
              Icons.manage_accounts_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, EditProfileScreen.routeName),
          ),
          // Language picker
          const LanguagePicker(),
          // Sign out
          IconButton(
            tooltip: l.signOut,
            icon: Icon(
              Icons.logout_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () async {
              await HttpAuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Read user info passed as route arguments from auth_screen
    final user =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final name = user?['name'] ?? '';
    final email = user?['email'] ?? '';
    final role = HttpAuthService.currentUserRole ?? 'SA';
    final isSA = role == 'SA';
    final isMember = role == 'member';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Association name + SA edit icon
          if (_associationName.isNotEmpty || isSA) ...[  
            Row(
              children: [
                if (_associationName.isNotEmpty)
                  Expanded(
                    child: Text(
                      _associationName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC9A84C),
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (isSA)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context, OrganizationManagementScreen.routeName).then((_) => _loadAssocName()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9A84C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded, size: 13, color: Color(0xFFC9A84C)),
                          const SizedBox(width: 4),
                          Text('Edit Org', style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFC9A84C))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            l.welcomeBack,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.communityWaiting,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          // User identity chip
          if (name.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildUserChip(name, email, role),
          ],
          const SizedBox(height: 28),

          // SA Dashboard card — only for Super Admins
          if (isSA) ...[
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, SaDashboardScreen.routeName),
              child: _SectionCard(
                icon: Icons.dashboard_customize_outlined,
                title: 'SA Dashboard',
                subtitle: 'Manage members, admins & circles',
                color: const Color(0xFFC9A84C),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Circles card — role-based target
          GestureDetector(
            onTap: () {
              if (isMember) {
                Navigator.pushNamed(context, MemberCirclesScreen.routeName);
              } else {
                Navigator.pushNamed(context, CircleDashboardScreen.routeName);
              }
            },
            child: _SectionCard(
              icon: Icons.groups_2_outlined,
              title: l.circles,
              subtitle: isMember ? 'View and join circles' : l.circlesSubtitle,
              color: const Color(0xFF818CF8),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.calendar_month_outlined,
            title: l.events,
            subtitle: l.eventsSubtitle,
            color: const Color(0xFF34D399),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.article_outlined,
            title: l.helpPosts,
            subtitle: l.helpPostsSubtitle,
            color: const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: l.profile,
            subtitle: l.profileSubtitle,
            color: const Color(0xFFF472B6),
          ),
        ],
      ),
    );
  }

  /// Compact user identity card showing avatar initials, display name, email and role badge.
  Widget _buildUserChip(String name, String email, String role) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar circle with initials
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + email column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Role badge
          _RoleBadge(role: role),
          const SizedBox(width: 6),
          // Signed-in badge dot
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature preview card for the home screen dashboard.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// Small role pill badge shown in the user identity chip.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (role) {
      case 'SA':
        color = const Color(0xFFC9A84C);
        label = 'Super Admin';
        break;
      case 'admin':
        color = const Color(0xFF34D399);
        label = 'Admin';
        break;
      case 'member':
        color = const Color(0xFF818CF8);
        label = 'Member';
        break;
      default:
        color = AppColors.textSecondary;
        label = role;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
