import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../services/http_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/language_picker.dart';
import '../auth/profile_setup_screen.dart';

/// Screen shown right after login, before profile setup.
/// Collects the association's basic information.
class CreateAssociationScreen extends StatefulWidget {
  const CreateAssociationScreen({super.key});

  static const routeName = '/create-association';

  @override
  State<CreateAssociationScreen> createState() =>
      _CreateAssociationScreenState();
}

class _CreateAssociationScreenState extends State<CreateAssociationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Logo
  File? _logoFile;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Dynamic emails & phones
  final List<TextEditingController> _emailCtrls = [TextEditingController()];
  final List<TextEditingController> _phoneCtrls = [TextEditingController()];
  final List<TextEditingController> _adminEmailCtrls = [
    TextEditingController(),
  ];
  final List<TextEditingController> _memberEmailCtrls = [
    TextEditingController(),
  ];

  // Social
  final _fbCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _xCtrl = TextEditingController();

  bool _loading = false;

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
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    for (final c in _emailCtrls) c.dispose();
    for (final c in _phoneCtrls) c.dispose();
    for (final c in _adminEmailCtrls) c.dispose();
    for (final c in _memberEmailCtrls) c.dispose();
    _fbCtrl.dispose();
    _linkedInCtrl.dispose();
    _xCtrl.dispose();
    super.dispose();
  }

  // ── Logo picker ──────────────────────────────────────────────────────────
  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() => _logoFile = File(picked.path));
      }
    } catch (_) {
      // image_picker not available in all environments — silently skip
    }
  }

  // ── Dynamic list helpers ─────────────────────────────────────────────────
  void _addEmail() => setState(() => _emailCtrls.add(TextEditingController()));
  void _removeEmail(int i) {
    if (_emailCtrls.length <= 1) return;
    setState(() {
      _emailCtrls[i].dispose();
      _emailCtrls.removeAt(i);
    });
  }

  void _addPhone() => setState(() => _phoneCtrls.add(TextEditingController()));
  void _removePhone(int i) {
    if (_phoneCtrls.length <= 1) return;
    setState(() {
      _phoneCtrls[i].dispose();
      _phoneCtrls.removeAt(i);
    });
  }

  void _addAdminEmail() =>
      setState(() => _adminEmailCtrls.add(TextEditingController()));
  void _removeAdminEmail(int i) {
    if (_adminEmailCtrls.length <= 1) return;
    setState(() {
      _adminEmailCtrls[i].dispose();
      _adminEmailCtrls.removeAt(i);
    });
  }

  void _addMemberEmail() =>
      setState(() => _memberEmailCtrls.add(TextEditingController()));
  void _removeMemberEmail(int i) {
    if (_memberEmailCtrls.length <= 1) return;
    setState(() {
      _memberEmailCtrls[i].dispose();
      _memberEmailCtrls.removeAt(i);
    });
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Collect all non-empty values from dynamic lists
      final emails = _emailCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final phones = _phoneCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final adminEmails = _adminEmailCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final memberEmails = _memberEmailCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await HttpAuthService().saveAssociation({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'contactEmails': emails,
        'contactPhones': phones,
        'adminEmails': adminEmails,
        'memberEmails': memberEmails,
        'facebookUrl': _fbCtrl.text.trim(),
        'linkedinUrl': _linkedInCtrl.text.trim(),
        'twitterUrl': _xCtrl.text.trim(),
      });

      if (mounted) {
        setState(() => _loading = false);
        Navigator.pushReplacementNamed(context, ProfileSetupScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
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
                            const SizedBox(height: 24),
                            // ── Logo picker ────────────────────────────
                            _buildCard(
                              icon: Icons.image_outlined,
                              title: l.caLogoLabel,
                              iconColor: const Color(0xFFF472B6),
                              children: [_buildLogoPicker(l)],
                            ),
                            const SizedBox(height: 16),
                            // ── Basic info ─────────────────────────────
                            _buildCard(
                              icon: Icons.business_outlined,
                              title: l.caNameLabel,
                              iconColor: const Color(0xFF818CF8),
                              children: [
                                AuthTextField(
                                  label: l.caNameLabel,
                                  hint: l.caNameHint,
                                  icon: Icons.badge_outlined,
                                  controller: _nameCtrl,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? l.caNameRequired
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: l.caAddressLabel,
                                  hint: l.caAddressHint,
                                  icon: Icons.location_on_outlined,
                                  controller: _addressCtrl,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Emails ─────────────────────────────────
                            _buildCard(
                              icon: Icons.email_outlined,
                              title: l.caEmailsSectionTitle,
                              iconColor: const Color(0xFF34D399),
                              children: [
                                ..._emailCtrls.asMap().entries.map(
                                  (e) => _buildDynamicRow(
                                    index: e.key,
                                    ctrl: e.value,
                                    hint: l.caEmailHint,
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    removeLabel: l.caRemoveBtn,
                                    canRemove: _emailCtrls.length > 1,
                                    onRemove: () => _removeEmail(e.key),
                                    isFirst: e.key == 0,
                                    validator: e.key == 0
                                        ? (v) => (v == null || v.trim().isEmpty)
                                              ? l.caEmailRequired
                                              : null
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildAddButton(l.caAddEmailBtn, _addEmail),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Phones ─────────────────────────────────
                            _buildCard(
                              icon: Icons.phone_outlined,
                              title: l.caPhonesSectionTitle,
                              iconColor: const Color(0xFFFBBF24),
                              children: [
                                ..._phoneCtrls.asMap().entries.map(
                                  (e) => _buildDynamicRow(
                                    index: e.key,
                                    ctrl: e.value,
                                    hint: l.caPhoneHint,
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    removeLabel: l.caRemoveBtn,
                                    canRemove: _phoneCtrls.length > 1,
                                    onRemove: () => _removePhone(e.key),
                                    isFirst: e.key == 0,
                                    validator: e.key == 0
                                        ? (v) => (v == null || v.trim().isEmpty)
                                              ? l.caPhoneRequired
                                              : null
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildAddButton(l.caAddPhoneBtn, _addPhone),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Admin Emails ───────────────────────────
                            _buildCard(
                              icon: Icons.admin_panel_settings_outlined,
                              title: l.caAdminEmailsTitle,
                              iconColor: const Color(0xFFA78BFA),
                              children: [
                                ..._adminEmailCtrls.asMap().entries.map(
                                  (e) => _buildDynamicRow(
                                    index: e.key,
                                    ctrl: e.value,
                                    hint: l.caAdminEmailHint,
                                    icon: Icons.shield_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    removeLabel: l.caRemoveBtn,
                                    // Let users remove all if they don't want admins
                                    canRemove:
                                        _adminEmailCtrls.length > 1 ||
                                        (e.key == 0 &&
                                            _adminEmailCtrls[0]
                                                .text
                                                .isNotEmpty),
                                    onRemove: () {
                                      if (_adminEmailCtrls.length == 1) {
                                        _adminEmailCtrls[0].clear();
                                      } else {
                                        _removeAdminEmail(e.key);
                                      }
                                    },
                                    isFirst: e.key == 0,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return null;
                                      final RegExp emailExp = RegExp(
                                        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                                      );
                                      if (!emailExp.hasMatch(v.trim())) {
                                        return 'Invalid email format';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildAddButton(
                                  l.caAddAdminEmailBtn,
                                  _addAdminEmail,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Member Emails ───────────────────────────
                            _buildCard(
                              icon: Icons.group_add_outlined,
                              title: 'Member Emails', // Or l.caMemberEmailsTitle if localized
                              iconColor: const Color(0xFF10B981),
                              children: [
                                ..._memberEmailCtrls.asMap().entries.map(
                                  (e) => _buildDynamicRow(
                                    index: e.key,
                                    ctrl: e.value,
                                    hint: 'member@example.com', // Or l.caMemberEmailHint
                                    icon: Icons.person_add_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    removeLabel: l.caRemoveBtn,
                                    canRemove:
                                        _memberEmailCtrls.length > 1 ||
                                        (e.key == 0 &&
                                            _memberEmailCtrls[0]
                                                .text
                                                .isNotEmpty),
                                    onRemove: () {
                                      if (_memberEmailCtrls.length == 1) {
                                        _memberEmailCtrls[0].clear();
                                      } else {
                                        _removeMemberEmail(e.key);
                                      }
                                    },
                                    isFirst: e.key == 0,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return null;
                                      final RegExp emailExp = RegExp(
                                        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                                      );
                                      if (!emailExp.hasMatch(v.trim())) {
                                        return 'Invalid email format';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildAddButton(
                                  'Add Member Email', // Or l.caAddMemberEmailBtn
                                  _addMemberEmail,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Social ─────────────────────────────────
                            _buildCard(
                              icon: Icons.share_outlined,
                              title: l.caSocialTitle,
                              iconColor: const Color(0xFF60A5FA),
                              children: [
                                AuthTextField(
                                  label: 'Facebook',
                                  hint: l.caFbHint,
                                  icon: Icons.facebook_outlined,
                                  controller: _fbCtrl,
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: 'LinkedIn',
                                  hint: l.caLinkedInHint,
                                  icon: Icons.link_rounded,
                                  controller: _linkedInCtrl,
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: 'X (Twitter)',
                                  hint: l.caXHint,
                                  icon: Icons.alternate_email_rounded,
                                  controller: _xCtrl,
                                  keyboardType: TextInputType.url,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildSubmitButton(l),
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

  // ── Top bar ──────────────────────────────────────────────────────────────
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
                'Step 1 of 2',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                l.caTitle,
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
              value: 0.5,
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

  // ── Hero section ─────────────────────────────────────────────────────────
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
            Icons.groups_2_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.caTitle,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.caSubtitle,
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

  // ── Logo picker widget ───────────────────────────────────────────────────
  Widget _buildLogoPicker(AppLocalizations l) {
    return Center(
      child: GestureDetector(
        onTap: _pickLogo,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _logoFile != null
                  ? AppColors.primary
                  : AppColors.borderSoft,
              width: _logoFile != null ? 2 : 1,
            ),
            boxShadow: _logoFile != null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: _logoFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    _logoFile!,
                    fit: BoxFit.cover,
                    width: 110,
                    height: 110,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 36,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.caLogoBtn,
                      style: GoogleFonts.inter(
                        fontSize: 11,
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

  // ── Dynamic row (email / phone) ──────────────────────────────────────────
  Widget _buildDynamicRow({
    required int index,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String removeLabel,
    required bool canRemove,
    required VoidCallback onRemove,
    required bool isFirst,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AuthTextField(
              label: '',
              hint: hint,
              icon: icon,
              controller: ctrl,
              keyboardType: keyboardType,
              validator: validator,
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Tooltip(
                message: removeLabel,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 40,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Add button ────────────────────────────────────────────────────────────
  Widget _buildAddButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton(AppLocalizations l) {
    return GestureDetector(
      onTap: _loading ? null : _handleSubmit,
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
                      l.caSubmitBtn,
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

  // ── Card helper ───────────────────────────────────────────────────────────
  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
