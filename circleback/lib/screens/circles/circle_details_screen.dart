import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/user_avatar.dart';
import '../../services/circle_service.dart';
import '../../services/http_auth_service.dart';
import '../posts/user_profile_screen.dart';

/// Screen representing the details of a specific Circle.
class CircleDetailsScreen extends StatefulWidget {
  const CircleDetailsScreen({super.key});

  static const routeName = '/circle-details';

  @override
  State<CircleDetailsScreen> createState() => _CircleDetailsScreenState();
}

class _CircleDetailsScreenState extends State<CircleDetailsScreen> {
  Map<String, dynamic>? _circleData;
  bool _isUploadingPhoto = false;
  List<dynamic> _photos = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_circleData == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _circleData = args;
        _fetchPhotos();
      }
    }
  }

  Future<void> _fetchPhotos() async {
    try {
      final photos = await CircleService().getCirclePhotos(_circleData!['id'] as int);
      if (mounted) {
        setState(() {
          _photos = photos;
        });
      }
    } catch (e) {
      debugPrint('Failed to load photos: $e');
    }
  }

  Future<void> _takeAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    
    try {
      await CircleService().uploadCirclePhoto(_circleData!['id'] as int, image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cdPhotoUploadedSuccess), backgroundColor: AppColors.primary),
        );
        _fetchPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).cdCircleDetailsTitle,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_circleData?['isAdmin'] == true)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.textPrimary),
              onPressed: _showEditModal,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInfo(context),
            const SizedBox(height: 32),
            _buildLeadershipSection(),
            const SizedBox(height: 32),
            _buildMeetingsSection(),
            const SizedBox(height: 32),
            _buildPhotosSection(),
            if (HttpAuthService.currentUserRole == 'SA' || 
                HttpAuthService.currentUserRole == 'admin' || 
                HttpAuthService.currentIsInvitedAdmin ||
                _circleData?['isAdmin'] == true) ...[
              const SizedBox(height: 32),
              _buildParticipantsSection(),
            ],
            const SizedBox(height: 32),
            // Grey box at the bottom as seen in mockup
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context) {
    final title = _circleData?['name'] ?? AppLocalizations.of(context).cdUnknownCircle;
    final location = '${_circleData?['city'] ?? ''}, ${_circleData?['country'] ?? ''}'.trim();
    final status = _circleData?['status'] ?? AppLocalizations.of(context).cdActive;
    final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'actif' || status.toLowerCase() == 'activo' || status == AppLocalizations.of(context).cdActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00BFA5) : const Color(0xFFF1F3F4), // Teal color
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF5F6368),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              location,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _circleData?['description'] ?? AppLocalizations.of(context).cdNoDescriptionProvided,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLeadershipSection() {
    final responsible = _circleData?['responsible'] ?? 'Unknown';
    final viceResponsible = _circleData?['viceResponsible'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).cdCircleLeadership,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLeaderCard(
                name: responsible,
                role: AppLocalizations.of(context).cdResponsibleSmall,
                color: const Color(0xFF2962FF), // Blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLeaderCard(
                name: viceResponsible,
                role: AppLocalizations.of(context).cdViceResponsibleSmall,
                color: const Color(0xFFFF9100), // Orange
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaderCard({
    required String name,
    required String role,
    required Color color,
  }) {
    final initials = name.split(' ').map((e) => e[0]).take(2).join();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsSection() {
    final meetingTime = _circleData?['meetingPlanning'] ?? 'TBD';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).cdUpcomingMeetings,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context).cdViewCalendar,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4285F4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMeetingCard(
          month: 'TBD',
          day: '??',
          title: AppLocalizations.of(context).cdNextSync,
          time: meetingTime,
        ),
      ],
    );
  }

  Widget _buildMeetingCard({
    required String month,
    required String day,
    required String title,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gradientStart,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4285F4),
                  ),
                ),
                Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).cdMeetingGallery,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            if (_isUploadingPhoto)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton.icon(
                onPressed: _takeAndUploadPhoto,
                icon: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF4285F4)),
                label: Text(
                  AppLocalizations.of(context).cdAddPhoto,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF4285F4),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined, size: 32, color: AppColors.textSecondary),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).cdNoPhotosYet,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).cdTakeFirstSnapshot,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photoUrl = 'http://10.0.2.2:3000${_photos[index]['photo_url']}';
                final uploader = _photos[index]['uploader_name'] ?? 'Someone';
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photoUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                        ),
                        child: Text(
                          uploader,
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).cdCircleParticipants,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => _CircleParticipantsModal(circleId: _circleData!['id'] as int),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context).cdViewAll,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4285F4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => _CircleParticipantsModal(circleId: _circleData!['id'] as int),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_alt, color: Color(0xFF3F51B5)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).cdManageParticipation,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).cdSeeWhoJoined,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: _circleData?['name']);
    final descCtrl = TextEditingController(text: _circleData?['description']);
    final countryCtrl = TextEditingController(text: _circleData?['country']);
    final cityCtrl = TextEditingController(text: _circleData?['city']);
    final respCtrl = TextEditingController(text: _circleData?['responsible']);
    final viceRespCtrl = TextEditingController(text: _circleData?['viceResponsible'] ?? _circleData?['vice_responsible']);
    final meetCtrl = TextEditingController(text: _circleData?['meetingPlanning'] ?? _circleData?['meeting_planning']);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context).cdEditCircle,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        label: 'Circle Name',
                        hint: 'e.g. IT Leaders Network',
                        icon: Icons.groups_rounded,
                        controller: nameCtrl,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Description',
                        hint: 'Describe the purpose...',
                        icon: Icons.description_rounded,
                        controller: descCtrl,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              label: 'Country',
                              hint: 'Country',
                              icon: Icons.public_rounded,
                              controller: countryCtrl,
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AuthTextField(
                              label: 'City',
                              hint: 'City',
                              icon: Icons.location_city_rounded,
                              controller: cityCtrl,
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Responsible',
                        hint: 'Name',
                        icon: Icons.person_rounded,
                        controller: respCtrl,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Vice-Responsible',
                        hint: 'Name',
                        icon: Icons.person_outline_rounded,
                        controller: viceRespCtrl,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Meeting Planning',
                        hint: 'e.g. Every Monday at 10 AM',
                        icon: Icons.calendar_month_rounded,
                        controller: meetCtrl,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isLoading = true);
                            try {
                              await CircleService().updateCircle(
                                _circleData!['id'],
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                country: countryCtrl.text.trim(),
                                city: cityCtrl.text.trim(),
                                responsible: respCtrl.text.trim(),
                                viceResponsible: viceRespCtrl.text.trim(),
                                meetingPlanning: meetCtrl.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                setState(() {
                                  _circleData!['name'] = nameCtrl.text.trim();
                                  _circleData!['description'] = descCtrl.text.trim();
                                  _circleData!['country'] = countryCtrl.text.trim();
                                  _circleData!['city'] = cityCtrl.text.trim();
                                  _circleData!['responsible'] = respCtrl.text.trim();
                                  _circleData!['viceResponsible'] = viceRespCtrl.text.trim();
                                  _circleData!['meetingPlanning'] = meetCtrl.text.trim();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppLocalizations.of(context).cdCircleUpdatedSuccess), backgroundColor: AppColors.primary),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                setModalState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          child: isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(AppLocalizations.of(context).cdSaveBtn, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CircleParticipantsModal extends StatefulWidget {
  final int circleId;
  const _CircleParticipantsModal({required this.circleId});

  @override
  State<_CircleParticipantsModal> createState() => _CircleParticipantsModalState();
}

class _CircleParticipantsModalState extends State<_CircleParticipantsModal> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      final participants = await CircleService().getCircleParticipants(widget.circleId);
      if (mounted) {
        setState(() {
          _participants = participants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context).cdCircleParticipants, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null 
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _participants.isEmpty 
                      ? Center(child: Text(AppLocalizations.of(context).cdNoMembersFound))
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(24),
                          itemCount: _participants.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final p = _participants[i];
                            final name = p['name'] ?? 'Unknown';
                            final hasJoined = p['hasJoined'] == true;
                            final joinedAtStr = p['joinedAt'] as String?;
                            final profilePic = p['profilePicture'] as String?;
                            final assocLogo = p['associationLogo'] as String?;
                            
                            String joinedDate = '';
                            if (hasJoined && joinedAtStr != null) {
                              try {
                                final dt = DateTime.parse(joinedAtStr);
                                joinedDate = DateFormat('MMM d, yyyy').format(dt);
                              } catch (_) {}
                            }

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    userId: p['id'] as int,
                                    userName: name,
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.borderSoft),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      profilePictureUrl: profilePic,
                                      associationLogoUrl: assocLogo,
                                      name: name,
                                      size: 44,
                                      animate: true,
                                      fallbackColor: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                          if (hasJoined && joinedDate.isNotEmpty)
                                            Text('Joined $joinedDate', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: hasJoined ? const Color(0xFFE6F4EA) : const Color(0xFFF1F3F4),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: hasJoined ? const Color(0xFFCEEAD6) : const Color(0xFFDADCE0)),
                                      ),
                                      child: Text(
                                        hasJoined ? AppLocalizations.of(context).cdJoined : AppLocalizations.of(context).cdNotJoined,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: hasJoined ? const Color(0xFF137333) : const Color(0xFF5F6368),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

