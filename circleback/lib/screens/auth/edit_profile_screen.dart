import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/language_picker.dart';
import '../../services/http_auth_service.dart';

/// Screen allowing the user to edit their profile information from the Home tab.
/// Fetches existing data on load, populates the form, and saves via the same endpoint.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _selectedAvatar = 0;

  final _formKey = GlobalKey<FormState>();

  // Profile Setup fields
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  // Password fields
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _savingPassword = false;


  String? _selectedRole;
  bool _loading = false;
  bool _initialFetchDone = false;
  String? _fetchError;

  // Profile picture state
  File? _pickedProfileImage;           // local file picked by user
  String? _currentProfilePictureUrl;   // URL from server (or local cache)
  bool _uploadingPic = false;
  bool _deletingPic = false;

  static const _roles = [
    'Community Leader',
    'Event Organizer',
    'Member',
    'Volunteer',
    'Sponsor',
    'Partner',
    'Advisor',
  ];

  static const List<IconData> _avatars = [
    Icons.work_rounded,
    Icons.account_balance_rounded,
    Icons.school_rounded,
    Icons.engineering_rounded,
    Icons.code_rounded,
    Icons.palette_rounded,
    Icons.campaign_rounded,
    Icons.gavel_rounded,
    Icons.medical_services_rounded,
    Icons.restaurant_rounded,
    Icons.support_agent_rounded,
    Icons.biotech_rounded,
    Icons.architecture_rounded,
    Icons.camera_alt_rounded,
    Icons.music_note_rounded,
    Icons.public_rounded,
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

    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await HttpAuthService().getProfile();

      if (mounted) {
        setState(() {
          // Profile Setup Fields
          _nameCtrl.text = data['name'] ?? '';
          _companyCtrl.text = data['company'] ?? '';
          _jobTitleCtrl.text = data['jobTitle'] ?? '';
          _cityCtrl.text = data['city'] ?? '';
          _bioCtrl.text = data['bio'] ?? '';
          _websiteCtrl.text = data['website'] ?? '';
          _selectedAvatar = data['avatarIndex'] ?? 0;
          // Populate profile picture from server or cache
          _currentProfilePictureUrl =
              (data['profilePicture'] as String?) ??
              HttpAuthService.currentUserProfilePicture;

          final role = data['communityRole'];
          if (role != null && _roles.contains(role)) {
            _selectedRole = role;
          }

          _initialFetchDone = true;
          _fetchError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString().replaceAll('Exception: ', '');
          _initialFetchDone = true;
        });
      }
    }
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



  /// Picks a photo from gallery and immediately uploads it as the profile picture.
  Future<void> _pickAndUploadProfilePicture() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null || !mounted) return;

      setState(() {
        _pickedProfileImage = File(picked.path);
        _uploadingPic = true;
      });

      final url = await HttpAuthService().uploadProfilePicture(File(picked.path));
      if (mounted) {
        setState(() {
          _currentProfilePictureUrl = url;
          _uploadingPic = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPic = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Removes the profile picture from the server and clears local state.
  Future<void> _removeProfilePicture() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingPic = true);
    try {
      await HttpAuthService().deleteProfilePicture();
      if (mounted) {
        setState(() {
          _currentProfilePictureUrl = null;
          _pickedProfileImage = null;
          _deletingPic = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deletingPic = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }



  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Save Profile
      final profileSuccess = await HttpAuthService().updateProfile({
        'name': _nameCtrl.text,
        'company': _companyCtrl.text,
        'jobTitle': _jobTitleCtrl.text,
        'communityRole': _selectedRole ?? 'Member',
        'city': _cityCtrl.text,
        'bio': _bioCtrl.text,
        'website': _websiteCtrl.text,
        'avatarIndex': _selectedAvatar,
      });

      if (profileSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFF34D399), // Green
            ),
          );
          Navigator.pop(context); // Go back to Home
        }
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (_currentPwdCtrl.text.isEmpty || _newPwdCtrl.text.isEmpty || _confirmPwdCtrl.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all password fields', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
      return;
    }
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
      return;
    }
    if (_newPwdCtrl.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await HttpAuthService().changePassword(_currentPwdCtrl.text, _newPwdCtrl.text);
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF34D399)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const screenTitle = 'Edit Profile';

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
              _buildAppBar(screenTitle),
              if (!_initialFetchDone)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_fetchError != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _fetchError!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _initialFetchDone = false;
                                _fetchError = null;
                              });
                              _fetchProfile();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: Text(
                              'Try Again',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
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
                          const SizedBox(height: 16),
                          // ── Profile Picture Card ──
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildProfilePictureCard(),
                            ),
                          ),
                          const SizedBox(height: 28),

                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildAvatarSection(l),
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildCard(
                                icon: Icons.business_center_outlined,
                                title: l.psProfInfoTitle,
                                iconColor: const Color(0xFF818CF8),
                                children: [
                                  AuthTextField(
                                    label: l.fullNameLabel,
                                    hint: l.fullNameHint,
                                    icon: Icons.person_outline,
                                    controller: _nameCtrl,
                                  ),
                                  const SizedBox(height: 16),
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
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildCard(
                                icon: Icons.security_outlined,
                                title: 'Password & Security',
                                iconColor: Colors.deepOrangeAccent,
                                children: [
                                  AuthTextField(
                                    label: 'Current Password',
                                    hint: 'Enter your current password',
                                    icon: Icons.lock_outline,
                                    controller: _currentPwdCtrl,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 16),
                                  AuthTextField(
                                    label: 'New Password',
                                    hint: 'Enter your new password',
                                    icon: Icons.lock_reset_outlined,
                                    controller: _newPwdCtrl,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 16),
                                  AuthTextField(
                                    label: 'Confirm New Password',
                                    hint: 'Re-enter your new password',
                                    icon: Icons.check_circle_outline,
                                    controller: _confirmPwdCtrl,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _savingPassword ? null : _handleChangePassword,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: Colors.deepOrangeAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: _savingPassword
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text('Change Password', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildCard(
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
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildCard(
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
                            ),
                          ),
                          const SizedBox(height: 32),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: _buildSaveButton(l),
                            ),
                          ),
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
    );
  }

  /// Premium profile picture card with upload/remove capability.
  Widget _buildProfilePictureCard() {
    const kBaseUrl = 'http://10.0.2.2:3000';
    final hasPhoto =
        _currentProfilePictureUrl != null && _currentProfilePictureUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            const Color(0xFF818CF8).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Photo preview
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _uploadingPic
                      ? Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : hasPhoto
                          ? Image.network(
                              '$kBaseUrl${_currentProfilePictureUrl!}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildInitialsAvatar(84),
                            )
                          : _pickedProfileImage != null
                              ? Image.file(
                                  _pickedProfileImage!,
                                  fit: BoxFit.cover,
                                )
                              : _buildInitialsAvatar(84),
                ),
              ),
              if (hasPhoto)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _uploadingPic || _deletingPic
                        ? null
                        : _pickAndUploadProfilePicture,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Photo',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto
                      ? 'Your profile picture is set'
                      : 'Add a photo so people can recognise you',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _uploadingPic || _deletingPic
                            ? null
                            : _pickAndUploadProfilePicture,
                        icon: _uploadingPic
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_rounded, size: 16),
                        label: Text(
                          hasPhoto ? 'Change' : 'Upload',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (hasPhoto) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _uploadingPic || _deletingPic
                              ? null
                              : _removeProfilePicture,
                          icon: _deletingPic
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.redAccent,
                                  ),
                                )
                              : const Icon(Icons.delete_outline, size: 16),
                          label: Text(
                            'Remove',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Initials fallback avatar used inside the profile picture card.
  Widget _buildInitialsAvatar(double size) {
    final name = _nameCtrl.text.trim();
    final parts = name.split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAppBar(String title) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const LanguagePicker(),
        ],
      ),
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
                      ),
                    ),
                  ),
              );
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
              const Icon(
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
          icon: const Icon(
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
          const Padding(
            padding: EdgeInsets.only(left: 14, top: 16),
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


  // ── Save button ─────────────────────────────────────────────────────────
  Widget _buildSaveButton(AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  // ── Helpers: card ─────────────────────────────────────────────────────
  BoxDecoration _cardDecoration(Color iconColor) {
    return BoxDecoration(
      color: AppColors.cardSurface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.borderSoft),
      boxShadow: [
        BoxShadow(
          color: iconColor.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  Widget _cardHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

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

}

