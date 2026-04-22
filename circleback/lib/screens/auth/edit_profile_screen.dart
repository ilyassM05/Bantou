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
  int? _hoveredAvatar;

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

  // Association fields
  File? _associationLogoFile;           // locally picked file (before/during upload)
  String? _currentAssociationLogoUrl;   // URL from server after successful upload
  bool _uploadingLogo = false;
  bool _deletingLogo = false;
  File? _companyLogoFile; // Company/personal logo
  final _assocNameCtrl = TextEditingController();
  final _assocAddressCtrl = TextEditingController();
  final List<TextEditingController> _contactEmailCtrls = [
    TextEditingController(),
  ];
  final List<TextEditingController> _contactPhoneCtrls = [
    TextEditingController(),
  ];
  final List<TextEditingController> _adminEmailCtrls = [
    TextEditingController(),
  ];
  final List<TextEditingController> _memberEmailCtrls = [
    TextEditingController(),
  ];
  final _fbCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _xCtrl = TextEditingController();

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
      final assocData = await HttpAuthService().getAssociation();

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

          // Association Fields
          if (assocData != null) {
            _assocNameCtrl.text = assocData['name'] ?? '';
            _assocAddressCtrl.text = assocData['address'] ?? '';
            _fbCtrl.text = assocData['facebookUrl'] ?? '';
            _linkedInCtrl.text = assocData['linkedinUrl'] ?? '';
            _xCtrl.text = assocData['twitterUrl'] ?? '';
            // Load existing logo URL from server
            _currentAssociationLogoUrl =
                (assocData['logoUrl'] as String?) ??
                HttpAuthService.currentAssociationLogoUrl;

            // Dynamic lists
            void populateList(List<TextEditingController> ctrls, String key) {
              if (assocData[key] != null && assocData[key] is List) {
                final list = List<String>.from(assocData[key]);
                if (list.isNotEmpty) {
                  // Clear dummy first controller and recreate as many as needed
                  for (final c in ctrls) {
                    c.dispose();
                  }
                  ctrls.clear();
                  for (final item in list) {
                    ctrls.add(TextEditingController(text: item));
                  }
                }
              }
            }

            populateList(_contactEmailCtrls, 'contactEmails');
            populateList(_contactPhoneCtrls, 'contactPhones');
            populateList(_adminEmailCtrls, 'adminEmails');
            populateList(_memberEmailCtrls, 'memberEmails');
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
    _assocNameCtrl.dispose();
    _assocAddressCtrl.dispose();
    _fbCtrl.dispose();
    _linkedInCtrl.dispose();
    _xCtrl.dispose();
    for (var c in _contactEmailCtrls) {
      c.dispose();
    }
    for (var c in _contactPhoneCtrls) {
      c.dispose();
    }
    for (var c in _adminEmailCtrls) {
      c.dispose();
    }
    for (var c in _memberEmailCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAssociationLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null || !mounted) return;

      setState(() {
        _associationLogoFile = File(picked.path);
        _uploadingLogo = true;
      });

      final url = await HttpAuthService().uploadAssociationLogo(File(picked.path));
      if (mounted) {
        setState(() {
          _currentAssociationLogoUrl = url;
          _uploadingLogo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Association logo updated!'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _removeAssociationLogo() async {
    setState(() => _deletingLogo = true);
    try {
      await HttpAuthService().deleteAssociationLogo();
      if (mounted) {
        setState(() {
          _currentAssociationLogoUrl = null;
          _associationLogoFile = null;
          _deletingLogo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Association logo removed.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deletingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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

  Future<void> _pickCompanyLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() => _companyLogoFile = File(picked.path));
      }
    } catch (_) {}
  }

  void _addEmail() =>
      setState(() => _contactEmailCtrls.add(TextEditingController()));
  void _removeEmail(int i) {
    if (_contactEmailCtrls.length <= 1) return;
    setState(() {
      _contactEmailCtrls[i].dispose();
      _contactEmailCtrls.removeAt(i);
    });
  }

  void _addPhone() =>
      setState(() => _contactPhoneCtrls.add(TextEditingController()));
  void _removePhone(int i) {
    if (_contactPhoneCtrls.length <= 1) return;
    setState(() {
      _contactPhoneCtrls[i].dispose();
      _contactPhoneCtrls.removeAt(i);
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

      final isSA = HttpAuthService.currentUserRole == 'SA';
      // Only Super Admins can modify association information.
      // Admins and Members always have read-only access to association data.
      final canEditAssociation = isSA;

      // 2. Save Association (only if can edit)
      bool assocSuccess = true;
      if (canEditAssociation) {
        final emails = _contactEmailCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final phones = _contactPhoneCtrls
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

        assocSuccess = await HttpAuthService().saveAssociation({
          'name': _assocNameCtrl.text.trim(),
          'address': _assocAddressCtrl.text.trim(),
          'contactEmails': emails,
          'contactPhones': phones,
          'adminEmails': adminEmails,
          'memberEmails': memberEmails,
          'facebookUrl': _fbCtrl.text.trim(),
          'linkedinUrl': _linkedInCtrl.text.trim(),
          'twitterUrl': _xCtrl.text.trim(),
        });
      }

      if (profileSuccess && assocSuccess) {
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
    final isSA = HttpAuthService.currentUserRole == 'SA';
    // Only Super Admins can modify association information.
    // Admins and Members always see the section as read-only.
    final canEditAssociation = isSA;
    final isRestrictedAdmin = !canEditAssociation;

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
                          const SizedBox(height: 16),
                          // ── Association Cards ──
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Column(
                                children: [
                                  // Association Section Header / Banner
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isRestrictedAdmin
                                          ? Colors.blueAccent.withValues(alpha: 0.1)
                                          : AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isRestrictedAdmin
                                            ? Colors.blueAccent.withValues(alpha: 0.3)
                                            : AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isRestrictedAdmin ? Icons.info_outline : Icons.business_outlined,
                                          color: isRestrictedAdmin ? Colors.blueAccent : AppColors.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            isRestrictedAdmin
                                                ? 'Association Information (Read-Only)'
                                                : 'Association Information',
                                            style: GoogleFonts.inter(
                                              color: isRestrictedAdmin ? Colors.blueAccent : AppColors.primary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Logo
                                  _buildCard(
                                    icon: Icons.image_outlined,
                                    title: l.caLogoLabel,
                                    iconColor: const Color(0xFFF472B6),
                                    children: [_buildLogoPicker(l, isRestrictedAdmin)],
                                  ),
                                  const SizedBox(height: 16),

                                  // Basic info
                                  _buildCard(
                                    icon: Icons.business_outlined,
                                    title: l.caNameLabel,
                                    iconColor: const Color(0xFF818CF8),
                                    children: [
                                      AuthTextField(
                                        label: l.caNameLabel,
                                        hint: l.caNameHint,
                                        icon: Icons.badge_outlined,
                                        controller: _assocNameCtrl,
                                        enabled: !isRestrictedAdmin,
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
                                        controller: _assocAddressCtrl,
                                        enabled: !isRestrictedAdmin,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Emails
                                  _buildCard(
                                    icon: Icons.email_outlined,
                                    title: l.caEmailsSectionTitle,
                                    iconColor: const Color(0xFF34D399),
                                    children: [
                                      ..._contactEmailCtrls.asMap().entries.map(
                                        (e) => _buildDynamicRow(
                                          index: e.key,
                                          ctrl: e.value,
                                          hint: l.caEmailHint,
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          removeLabel: l.caRemoveBtn,
                                          canRemove:
                                              !isRestrictedAdmin && _contactEmailCtrls.length > 1,
                                          onRemove: () => _removeEmail(e.key),
                                          isFirst: e.key == 0,
                                          enabled: !isRestrictedAdmin,
                                          validator: e.key == 0
                                              ? (v) =>
                                                    (v == null ||
                                                        v.trim().isEmpty)
                                                    ? l.caEmailRequired
                                                    : null
                                              : null,
                                        ),
                                      ),
                                      if (!isRestrictedAdmin) ...[
                                        const SizedBox(height: 8),
                                        _buildAddButton(
                                          l.caAddEmailBtn,
                                          _addEmail,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Phones
                                  _buildCard(
                                    icon: Icons.phone_outlined,
                                    title: l.caPhonesSectionTitle,
                                    iconColor: const Color(0xFFFBBF24),
                                    children: [
                                      ..._contactPhoneCtrls.asMap().entries.map(
                                        (e) => _buildDynamicRow(
                                          index: e.key,
                                          ctrl: e.value,
                                          hint: l.caPhoneHint,
                                          icon: Icons.phone_outlined,
                                          keyboardType: TextInputType.phone,
                                          removeLabel: l.caRemoveBtn,
                                          canRemove:
                                              !isRestrictedAdmin && _contactPhoneCtrls.length > 1,
                                          onRemove: () => _removePhone(e.key),
                                          isFirst: e.key == 0,
                                          enabled: !isRestrictedAdmin,
                                          validator: e.key == 0
                                              ? (v) =>
                                                    (v == null ||
                                                        v.trim().isEmpty)
                                                    ? l.caPhoneRequired
                                                    : null
                                              : null,
                                        ),
                                      ),
                                      if (!isRestrictedAdmin) ...[
                                        const SizedBox(height: 8),
                                        _buildAddButton(
                                          l.caAddPhoneBtn,
                                          _addPhone,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Admin Emails
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
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          removeLabel: l.caRemoveBtn,
                                          canRemove:
                                              !isRestrictedAdmin && (_adminEmailCtrls.length > 1 ||
                                              (e.key == 0 &&
                                                  _adminEmailCtrls[0]
                                                      .text
                                                      .isNotEmpty)),
                                          onRemove: () {
                                            if (_adminEmailCtrls.length == 1) {
                                              _adminEmailCtrls[0].clear();
                                            } else {
                                              _removeAdminEmail(e.key);
                                            }
                                          },
                                          isFirst: e.key == 0,
                                          enabled: !isRestrictedAdmin,
                                          // Validate if not empty
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
                                      if (!isRestrictedAdmin) ...[
                                        const SizedBox(height: 8),
                                        _buildAddButton(
                                          l.caAddAdminEmailBtn,
                                          _addAdminEmail,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Member Emails
                                  _buildCard(
                                    icon: Icons.group_add_outlined,
                                    title: 'Member Emails', // l.caMemberEmailsTitle
                                    iconColor: const Color(0xFF10B981),
                                    children: [
                                      ..._memberEmailCtrls.asMap().entries.map(
                                        (e) => _buildDynamicRow(
                                          index: e.key,
                                          ctrl: e.value,
                                          hint: 'member@example.com', // l.caMemberEmailHint
                                          icon: Icons.person_add_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          removeLabel: l.caRemoveBtn,
                                          canRemove:
                                              !isRestrictedAdmin && (_memberEmailCtrls.length > 1 ||
                                              (e.key == 0 &&
                                                  _memberEmailCtrls[0]
                                                      .text
                                                      .isNotEmpty)),
                                          onRemove: () {
                                            if (_memberEmailCtrls.length == 1) {
                                              _memberEmailCtrls[0].clear();
                                            } else {
                                              _removeMemberEmail(e.key);
                                            }
                                          },
                                          isFirst: e.key == 0,
                                          enabled: !isRestrictedAdmin,
                                          // Validate if not empty
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
                                      if (!isRestrictedAdmin) ...[
                                        const SizedBox(height: 8),
                                        _buildAddButton(
                                          'Add Member Email', // l.caAddMemberEmailBtn
                                          _addMemberEmail,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Socials
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
                                        enabled: !isRestrictedAdmin,
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        label: 'LinkedIn',
                                        hint: l.caLinkedInHint,
                                        icon: Icons.link_rounded,
                                        controller: _linkedInCtrl,
                                        keyboardType: TextInputType.url,
                                        enabled: !isRestrictedAdmin,
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        label: 'X (Twitter)',
                                        hint: l.caXHint,
                                        icon: Icons.alternate_email_rounded,
                                        controller: _xCtrl,
                                        keyboardType: TextInputType.url,
                                        enabled: !isRestrictedAdmin,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
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
                                  // Company logo picker
                                  _buildCompanyLogoPicker(),
                                  const SizedBox(height: 16),
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

  // ── Company logo picker ──────────────────────────────────────────────
  Widget _buildCompanyLogoPicker() {
    const accent = Color(0xFF818CF8);
    return GestureDetector(
      onTap: _pickCompanyLogo,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _companyLogoFile != null
                  ? Image.file(_companyLogoFile!, fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, color: accent, size: 26),
                        const SizedBox(height: 4),
                        Text(
                          'Logo',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company / Organization Logo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to upload a logo or photo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_companyLogoFile != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _companyLogoFile = null),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
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

  // ── Logo picker widget ───────────────────────────────────────────────────
  Widget _buildLogoPicker(AppLocalizations l, bool isRestrictedAdmin) {
    const kBaseUrl = 'http://10.0.2.2:3000';
    final hasServerLogo = _currentAssociationLogoUrl != null &&
        _currentAssociationLogoUrl!.isNotEmpty;
    final hasLocalFile = _associationLogoFile != null;
    final hasAny = hasServerLogo || hasLocalFile;

    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: (isRestrictedAdmin || _uploadingLogo || _deletingLogo)
                ? null
                : _pickAssociationLogo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasAny ? AppColors.primary : AppColors.borderSoft,
                  width: hasAny ? 2 : 1,
                ),
                boxShadow: hasAny
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: _uploadingLogo
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : hasLocalFile
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _associationLogoFile!,
                            fit: BoxFit.cover,
                            width: 110,
                            height: 110,
                          ),
                        )
                      : hasServerLogo
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                '$kBaseUrl${_currentAssociationLogoUrl!}',
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                                errorBuilder: (_, __, ___) => _logoPlaceholder(l),
                              ),
                            )
                          : _logoPlaceholder(l),
            ),
          ),
        ),
        if (hasAny && !isRestrictedAdmin) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _deletingLogo ? null : _removeAssociationLogo,
              icon: _deletingLogo
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.redAccent),
                    )
                  : const Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent),
              label: Text(
                'Remove Logo',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        const Icon(Icons.add_photo_alternate_rounded,
            size: 36, color: AppColors.textHint),
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
    bool enabled = true,
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
              enabled: enabled,
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
}
