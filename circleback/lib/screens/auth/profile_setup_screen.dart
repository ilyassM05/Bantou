import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/language_picker.dart';
import '../main_shell_screen.dart';
import '../../services/http_auth_service.dart';

/// Profile setup screen shown once after a user creates their account.
/// Collects complementary profile information for the community context.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const routeName = '/profile-setup';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _selectedAvatar = 0;
  int? _hoveredAvatar;
  File? _companyLogoFile;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  String? _selectedRole;
  bool _loading = false;

  // Community role options
  static const _roles = [
    'Community Leader',
    'Event Organizer',
    'Member',
    'Volunteer',
    'Sponsor',
    'Partner',
    'Advisor',
  ];

  // Distinct professional avatar options representing different fields/roles
  static const List<IconData> _avatars = [
    Icons.work_rounded, // Corporate / Business
    Icons.account_balance_rounded, // Finance / Institution
    Icons.school_rounded, // Education
    Icons.engineering_rounded, // Engineering / Technical
    Icons.code_rounded, // Software / Tech
    Icons.palette_rounded, // Design / Creative
    Icons.campaign_rounded, // Marketing / Comms
    Icons.gavel_rounded, // Legal
    Icons.medical_services_rounded, // Health / Medical
    Icons.restaurant_rounded, // Food / Hospitality
    Icons.support_agent_rounded, // Customer Support
    Icons.biotech_rounded, // Science / Research
    Icons.architecture_rounded, // Architecture / Planning
    Icons.camera_alt_rounded, // Media / Photography
    Icons.music_note_rounded, // Audio / Entertainment
    Icons.public_rounded, // International / NGO
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _companyCtrl.dispose();
    _jobTitleCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.pushReplacementNamed(
      context,
      MainShellScreen.routeName,
    );
  }

  /// Silently mark setup as seen, then go Home (used by Skip button).
  Future<void> _skipAndGoHome() async {
    // Fire and forget — not critical if it fails
    HttpAuthService().markSetupSeen();
    _goHome();
  }

  Future<void> _pickCompanyLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() => _companyLogoFile = File(picked.path));
      }
    } catch (_) {
      // image_picker failing
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final success = await HttpAuthService().updateProfile({
        'company': _companyCtrl.text,
        'jobTitle': _jobTitleCtrl.text,
        'communityRole': _selectedRole ?? 'Member',
        'city': _cityCtrl.text,
        'bio': _bioCtrl.text,
        'website': _websiteCtrl.text,
        'avatarIndex': _selectedAvatar,
      });

      if (success) {
        if (mounted) _goHome();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildTopBar(l),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroSection(l),
                            const SizedBox(height: 28),
                            _buildAvatarSection(l),
                            const SizedBox(height: 28),
                            _buildCard(
                              icon: Icons.business_center_outlined,
                              title: l.psProfInfoTitle,
                              iconColor: const Color(0xFF818CF8),
                              children: [
                                _buildCompanyLogoPicker(l),
                                const SizedBox(height: 24),
                                AuthTextField(
                                  label: l.psCompanyLabel,
                                  hint: l.psCompanyHint,
                                  icon: Icons.business_outlined,
                                  controller: _companyCtrl,
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: l.psJobLabel,
                                  hint: l.psJobHint,
                                  icon: Icons.badge_outlined,
                                  controller: _jobTitleCtrl,
                                ),
                                const SizedBox(height: 16),
                                _buildRoleDropdown(l),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCard(
                              icon: Icons.person_outline_rounded,
                              title: l.psAboutTitle,
                              iconColor: const Color(0xFF34D399),
                              children: [
                                AuthTextField(
                                  label: l.psCityLabel,
                                  hint: l.psCityHint,
                                  icon: Icons.location_on_outlined,
                                  controller: _cityCtrl,
                                ),
                                const SizedBox(height: 16),
                                _buildBioField(l),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildCard(
                              icon: Icons.link_rounded,
                              title: l.psOnlineTitle,
                              iconColor: const Color(0xFFFBBF24),
                              children: [
                                AuthTextField(
                                  label: l.psWebLabel,
                                  hint: l.psWebHint,
                                  icon: Icons.language_outlined,
                                  controller: _websiteCtrl,
                                  keyboardType: TextInputType.url,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildSaveButton(l),
                            const SizedBox(height: 12),
                            _buildSkipButton(l),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
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

  // ── Top progress bar ───────────────────────────────────────────────────
  Widget _buildTopBar(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.psStepTitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                l.psHeaderTitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const LanguagePicker(),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1.0,
              backgroundColor: AppColors.borderSoft.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero section ────────────────────────────────────────────────────────
  Widget _buildHeroSection(AppLocalizations l) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.psHeroTitle,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.psHeroSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Avatar picker ────────────────────────────────────────────────────────
  Widget _buildAvatarSection(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(const Color(0xFFF472B6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            Icons.face_retouching_natural_outlined,
            l.psAvatarTitle,
            const Color(0xFFF472B6),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _avatars.length,
            itemBuilder: (context, i) {
              final selected = _selectedAvatar == i + 1;
              return Tooltip(
                message: l.psAvatarTooltips.length > i
                    ? l.psAvatarTooltips[i]
                    : '',
                preferBelow: false,
                verticalOffset: 24,
                waitDuration: Duration.zero,
                textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredAvatar = i + 1),
                  onExit: (_) => setState(() => _hoveredAvatar = null),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.borderSoft,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          _avatars[i],
                          size: selected ? 26 : 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ), // closes Center
                    ), // closes AnimatedContainer
                  ), // closes GestureDetector
                ), // closes MouseRegion
              ); // closes Tooltip
            },
          ),
          Builder(
            builder: (context) {
              final targetAvatar = _hoveredAvatar ?? _selectedAvatar;
              if (targetAvatar > 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _avatars[targetAvatar - 1],
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.psAvatarTooltips.length >= targetAvatar
                                  ? l.psAvatarTooltips[targetAvatar - 1]
                                  : l.psAvatarSelected,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ), // closes Row
                      ), // closes Container
                    ],
                  ), // closes Row
                ); // closes Padding
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ── Role dropdown ────────────────────────────────────────────────────────
  Widget _buildRoleDropdown(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedRole,
          hint: Row(
            children: [
              Icon(
                Icons.groups_2_outlined,
                size: 18,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 10),
              Text(
                l.psRoleHint,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          dropdownColor: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: _roles
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(
                    r,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedRole = v),
        ),
      ),
    );
  }

  // ── Bio text area ────────────────────────────────────────────────────────
  Widget _buildBioField(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 16),
            child: Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 160,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: l.psBioHint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
                counterStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Company Logo picker ──────────────────────────────────────────────────
  Widget _buildCompanyLogoPicker(AppLocalizations l) {
    return Center(
      child: GestureDetector(
        onTap: _pickCompanyLogo,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _companyLogoFile != null
                  ? AppColors.primary
                  : AppColors.borderSoft,
              width: _companyLogoFile != null ? 2 : 1,
            ),
            boxShadow: _companyLogoFile != null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: _companyLogoFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _companyLogoFile!,
                    fit: BoxFit.cover,
                    width: 90,
                    height: 90,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 28,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Company Logo', // You may want to translate this later
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Save button ─────────────────────────────────────────────────────────
  Widget _buildSaveButton(AppLocalizations l) {
    return GestureDetector(
      onTap: _loading ? null : _handleSave,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _loading
                ? [AppColors.primaryLight, AppColors.primaryLight]
                : [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.psSaveBtn,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Skip button ─────────────────────────────────────────────────────────
  Widget _buildSkipButton(AppLocalizations l) {
    return GestureDetector(
      onTap: _skipAndGoHome,
      child: Center(
        child: Text(
          l.psSkipBtn,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Helpers: card ─────────────────────────────────────────────────────
  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(iconColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(icon, title, iconColor),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(Color accentColor) => BoxDecoration(
    color: AppColors.cardSurface.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.borderSoft),
    boxShadow: [
      BoxShadow(
        color: accentColor.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _cardHeader(IconData icon, String title, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
