import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../services/http_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/language_picker.dart';

/// Organization Management Screen — Super Admin only.
/// Displays and allows editing of all association-level data.
class OrganizationManagementScreen extends StatefulWidget {
  const OrganizationManagementScreen({super.key});
  static const routeName = '/org-management';

  @override
  State<OrganizationManagementScreen> createState() =>
      _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState
    extends State<OrganizationManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _formKey = GlobalKey<FormState>();

  // Association logo
  File? _logoFile;
  String? _currentLogoUrl;
  bool _uploadingLogo = false;
  bool _deletingLogo = false;

  // Text controllers
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _xCtrl = TextEditingController();

  // Dynamic lists
  final List<TextEditingController> _contactEmailCtrls = [TextEditingController()];
  final List<TextEditingController> _contactPhoneCtrls = [TextEditingController()];
  final List<TextEditingController> _adminEmailCtrls = [TextEditingController()];
  final List<TextEditingController> _memberEmailCtrls = [TextEditingController()];

  bool _loading = false;
  bool _initialFetchDone = false;
  String? _fetchError;

  static const _kBaseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    _fetchData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _fbCtrl.dispose();
    _linkedInCtrl.dispose();
    _xCtrl.dispose();
    for (final c in _contactEmailCtrls) c.dispose();
    for (final c in _contactPhoneCtrls) c.dispose();
    for (final c in _adminEmailCtrls) c.dispose();
    for (final c in _memberEmailCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await HttpAuthService().getAssociation();
      if (!mounted) return;
      if (data == null) {
        setState(() { _initialFetchDone = true; });
        return;
      }
      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _fbCtrl.text = data['facebookUrl'] ?? '';
        _linkedInCtrl.text = data['linkedinUrl'] ?? '';
        _xCtrl.text = data['twitterUrl'] ?? '';
        _currentLogoUrl = (data['logoUrl'] as String?) ?? HttpAuthService.currentAssociationLogoUrl;

        void populate(List<TextEditingController> ctrls, String key) {
          if (data[key] is List) {
            final list = List<String>.from(data[key]);
            if (list.isNotEmpty) {
              for (final c in ctrls) c.dispose();
              ctrls.clear();
              for (final item in list) ctrls.add(TextEditingController(text: item));
            }
          }
        }

        populate(_contactEmailCtrls, 'contactEmails');
        populate(_contactPhoneCtrls, 'contactPhones');
        populate(_adminEmailCtrls, 'adminEmails');
        populate(_memberEmailCtrls, 'memberEmails');
        _initialFetchDone = true;
        _fetchError = null;
      });
    } catch (e) {
      if (mounted) setState(() { _fetchError = e.toString().replaceAll('Exception: ', ''); _initialFetchDone = true; });
    }
  }

  // ─── Logo actions ────────────────────────────────────────────────────────────
  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
      if (picked == null || !mounted) return;
      setState(() { _logoFile = File(picked.path); _uploadingLogo = true; });
      final url = await HttpAuthService().uploadAssociationLogo(File(picked.path));
      if (mounted) setState(() { _currentLogoUrl = url; _uploadingLogo = false; });
      if (mounted) _snack('Association logo updated!', const Color(0xFF34D399));
    } catch (e) {
      if (mounted) { setState(() => _uploadingLogo = false); _snack(e.toString().replaceAll('Exception: ', ''), Colors.redAccent); }
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _deletingLogo = true);
    try {
      await HttpAuthService().deleteAssociationLogo();
      if (mounted) setState(() { _currentLogoUrl = null; _logoFile = null; _deletingLogo = false; });
      if (mounted) _snack('Logo removed.', Colors.grey);
    } catch (e) {
      if (mounted) { setState(() => _deletingLogo = false); _snack(e.toString().replaceAll('Exception: ', ''), Colors.redAccent); }
    }
  }

  // ─── Dynamic list helpers ─────────────────────────────────────────────────────
  void _addCtrl(List<TextEditingController> list) => setState(() => list.add(TextEditingController()));
  void _removeCtrl(List<TextEditingController> list, int i) {
    if (list.length <= 1) return;
    setState(() { list[i].dispose(); list.removeAt(i); });
  }

  // ─── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      List<String> collect(List<TextEditingController> ctrls) =>
          ctrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

      await HttpAuthService().saveAssociation({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'contactEmails': collect(_contactEmailCtrls),
        'contactPhones': collect(_contactPhoneCtrls),
        'adminEmails': collect(_adminEmailCtrls),
        'memberEmails': collect(_memberEmailCtrls),
        'facebookUrl': _fbCtrl.text.trim(),
        'linkedinUrl': _linkedInCtrl.text.trim(),
        'twitterUrl': _xCtrl.text.trim(),
      });
      if (mounted) {
        _snack('Organization updated successfully!', const Color(0xFF34D399));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color bg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));

  // ─── Build ────────────────────────────────────────────────────────────────────
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
          child: Column(
            children: [
              _buildAppBar(),
              if (!_initialFetchDone)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
              else if (_fetchError != null)
                Expanded(child: _buildError())
              else
                Expanded(child: _buildForm(l)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.9),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Organization Management',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Super Admin only', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFC9A84C))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, size: 12, color: Color(0xFFC9A84C)),
                const SizedBox(width: 4),
                Text('SA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFC9A84C))),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const LanguagePicker(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_fetchError!, textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () { setState(() { _initialFetchDone = false; _fetchError = null; }); _fetchData(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Try Again', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFFC9A84C).withValues(alpha: 0.12), const Color(0xFFC9A84C).withValues(alpha: 0.05)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFC9A84C).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.business_rounded, color: Color(0xFFC9A84C), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Association Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFFC9A84C))),
                            Text('Changes affect the entire organization', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Logo card
                _card(icon: Icons.image_outlined, title: l.caLogoLabel, iconColor: const Color(0xFFF472B6),
                  child: _buildLogoPicker(l)),
                const SizedBox(height: 16),

                // Name & Address
                _card(icon: Icons.business_outlined, title: l.caNameLabel, iconColor: const Color(0xFF818CF8),
                  child: Column(children: [
                    AuthTextField(label: l.caNameLabel, hint: l.caNameHint, icon: Icons.badge_outlined,
                        controller: _nameCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.caNameRequired : null),
                    const SizedBox(height: 14),
                    AuthTextField(label: l.caAddressLabel, hint: l.caAddressHint, icon: Icons.location_on_outlined,
                        controller: _addressCtrl),
                  ])),
                const SizedBox(height: 16),

                // Contact Emails
                _card(icon: Icons.email_outlined, title: l.caEmailsSectionTitle, iconColor: const Color(0xFF34D399),
                  child: _dynamicList(
                    ctrls: _contactEmailCtrls, hint: l.caEmailHint, icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress, addLabel: l.caAddEmailBtn,
                    firstValidator: (v) => (v == null || v.trim().isEmpty) ? l.caEmailRequired : null,
                  )),
                const SizedBox(height: 16),

                // Contact Phones
                _card(icon: Icons.phone_outlined, title: l.caPhonesSectionTitle, iconColor: const Color(0xFFFBBF24),
                  child: _dynamicList(
                    ctrls: _contactPhoneCtrls, hint: l.caPhoneHint, icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone, addLabel: l.caAddPhoneBtn,
                    firstValidator: (v) => (v == null || v.trim().isEmpty) ? l.caPhoneRequired : null,
                  )),
                const SizedBox(height: 16),

                // Admin Emails
                _card(icon: Icons.admin_panel_settings_outlined, title: l.caAdminEmailsTitle, iconColor: const Color(0xFFA78BFA),
                  child: _dynamicList(
                    ctrls: _adminEmailCtrls, hint: l.caAdminEmailHint, icon: Icons.shield_outlined,
                    keyboardType: TextInputType.emailAddress, addLabel: l.caAddAdminEmailBtn,
                  )),
                const SizedBox(height: 16),

                // Member Emails
                _card(icon: Icons.group_add_outlined, title: 'Member Emails', iconColor: const Color(0xFF10B981),
                  child: _dynamicList(
                    ctrls: _memberEmailCtrls, hint: 'member@example.com', icon: Icons.person_add_outlined,
                    keyboardType: TextInputType.emailAddress, addLabel: 'Add Member Email',
                  )),
                const SizedBox(height: 16),

                // Social Media
                _card(icon: Icons.share_outlined, title: l.caSocialTitle, iconColor: const Color(0xFF60A5FA),
                  child: Column(children: [
                    AuthTextField(label: 'Facebook', hint: l.caFbHint, icon: Icons.facebook_outlined,
                        controller: _fbCtrl, keyboardType: TextInputType.url),
                    const SizedBox(height: 14),
                    AuthTextField(label: 'LinkedIn', hint: l.caLinkedInHint, icon: Icons.link_rounded,
                        controller: _linkedInCtrl, keyboardType: TextInputType.url),
                    const SizedBox(height: 14),
                    AuthTextField(label: 'X (Twitter)', hint: l.caXHint, icon: Icons.alternate_email_rounded,
                        controller: _xCtrl, keyboardType: TextInputType.url),
                  ])),
                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6, shadowColor: const Color(0xFFC9A84C).withValues(alpha: 0.4),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Save Organization', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          ]),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo picker ──────────────────────────────────────────────────────────────
  Widget _buildLogoPicker(AppLocalizations l) {
    final hasLogo = _currentLogoUrl != null && _currentLogoUrl!.isNotEmpty;
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: (_uploadingLogo || _deletingLogo) ? null : _pickLogo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (hasLogo || _logoFile != null) ? const Color(0xFFC9A84C) : AppColors.borderSoft,
                  width: (hasLogo || _logoFile != null) ? 2 : 1,
                ),
                boxShadow: (hasLogo || _logoFile != null)
                    ? [BoxShadow(color: const Color(0xFFC9A84C).withValues(alpha: 0.2), blurRadius: 12)]
                    : [],
              ),
              child: _uploadingLogo
                  ? const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)))
                  : _logoFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_logoFile!, fit: BoxFit.cover, width: 110, height: 110))
                      : hasLogo
                          ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network('$_kBaseUrl${_currentLogoUrl!}', fit: BoxFit.cover, width: 110, height: 110, errorBuilder: (_, __, ___) => _logoPlaceholder(l)))
                          : _logoPlaceholder(l),
            ),
          ),
        ),
        if (hasLogo || _logoFile != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _deletingLogo ? null : _removeLogo,
              icon: _deletingLogo
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                  : const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              label: Text('Remove Logo', style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _logoPlaceholder(AppLocalizations l) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_rounded, size: 34, color: AppColors.textHint),
        const SizedBox(height: 6),
        Text(l.caLogoBtn, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }

  // ─── Dynamic list ─────────────────────────────────────────────────────────────
  Widget _dynamicList({
    required List<TextEditingController> ctrls,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String addLabel,
    String? Function(String?)? firstValidator,
  }) {
    return Column(
      children: [
        ...ctrls.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(top: e.key == 0 ? 0 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuthTextField(
                  label: '', hint: hint, icon: icon,
                  controller: e.value, keyboardType: keyboardType,
                  validator: e.key == 0 ? firstValidator : null,
                ),
              ),
              if (ctrls.length > 1) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => _removeCtrl(ctrls, e.key),
                    child: Container(
                      width: 40, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Icon(Icons.remove_rounded, color: Colors.red.shade400, size: 20),
                    ),
                  ),
                ),
              ],
            ],
          ),
        )),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _addCtrl(ctrls),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
            ),
            child: Center(child: Text(addLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
          ),
        ),
      ],
    );
  }

  // ─── Card helper ──────────────────────────────────────────────────────────────
  Widget _card({required IconData icon, required String title, required Color iconColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withValues(alpha: 0.2))),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
