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
import '../../widgets/add_friend_button.dart';
import '../../widgets/location_picker_field.dart';
import '../../widgets/meeting_location_card.dart';
import '../../models/location_data.dart';
import '../../models/meeting_schedule.dart';
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

  /// Shows a bottom sheet so the user can choose between camera and gallery.
  void _showPhotoSourceSheet() {
    if (_isUploadingPhoto) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add Photo',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you would like to add a photo',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Take Photo option
              _PhotoSourceTile(
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFF4285F4),
                iconBgColor: const Color(0xFFE8F0FE),
                title: 'Take Photo',
                subtitle: 'Open the camera to capture a new photo',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              // Choose from Gallery option
              _PhotoSourceTile(
                icon: Icons.photo_library_rounded,
                iconColor: const Color(0xFF34A853),
                iconBgColor: const Color(0xFFE6F4EA),
                title: 'Choose from Gallery',
                subtitle: 'Select an existing photo from your device',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              // Cancel
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Picks an image from [source] and uploads it to the circle.
  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (_isUploadingPhoto) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      // Use high quality; gallery images are already compressed by the OS.
      imageQuality: source == ImageSource.camera ? 85 : null,
    );

    if (image == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final result = await CircleService().uploadCirclePhoto(
        _circleData!['id'] as int,
        image.path,
      );
      if (mounted) {
        final isPending = result['status'] == 'pending';
        final msg = isPending
            ? AppLocalizations.of(context).cdPhotoSubmittedForReview
            : AppLocalizations.of(context).cdPhotoUploadedSuccess;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isPending ? const Color(0xFFF9A825) : AppColors.primary,
          ),
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

  /// True when the current user has moderation privileges (Admin or Super Admin).
  bool get _isAdminUser =>
      HttpAuthService.currentUserRole == 'SA' ||
      HttpAuthService.currentUserRole == 'admin' ||
      HttpAuthService.currentIsInvitedAdmin ||
      _circleData?['isAdmin'] == true;

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
          if (_circleData?['isAdmin'] == true) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.textPrimary),
              onPressed: _showEditModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInfo(context),
            const SizedBox(height: 28),
            _buildLeadershipSection(),
            const SizedBox(height: 28),
            _buildPhotosSection(),
            // ── Admin/SA: existing Manage Participants ────────────
            if (HttpAuthService.currentUserRole == 'SA' || 
                HttpAuthService.currentUserRole == 'admin' || 
                HttpAuthService.currentIsInvitedAdmin ||
                _circleData?['isAdmin'] == true) ...[
              const SizedBox(height: 28),
              _buildParticipantsSection(),
            ],
            // ── Member: read-only Participants section ───────────
            if (!_isAdminUser) ...[
              const SizedBox(height: 28),
              _buildMemberParticipantsSection(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Circle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this circle? This action cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCircle();
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCircle() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      await CircleService().deleteCircle(_circleData!['id'] as int);
      if (mounted) {
        Navigator.pop(context); // pop loading dialog
        Navigator.pop(context, true); // pop screen, return true to refresh
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Returns true when the circle has a saved meeting location.
  bool _hasMeetingLocation() {
    final lat = _circleData?['meetingLat'];
    final lng = _circleData?['meetingLng'];
    return lat != null && lng != null;
  }

  Widget _buildHeaderInfo(BuildContext context) {
    final title = _circleData?['name'] ?? AppLocalizations.of(context).cdUnknownCircle;
    final cityCountry = '${_circleData?['city'] ?? ''}, ${_circleData?['country'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '');
    final status = _circleData?['status'] ?? AppLocalizations.of(context).cdActive;
    final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'actif' || status.toLowerCase() == 'activo' || status == AppLocalizations.of(context).cdActive;
    final meetingPlanning = _circleData?['meetingPlanning'] as String?;
    final formattedSchedule = meetingPlanning != null && meetingPlanning.isNotEmpty
        ? MeetingTimeFormatter.format(meetingPlanning)
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + status badge ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF00BFA5).withValues(alpha: 0.12)
                      : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF00BFA5).withValues(alpha: 0.4)
                        : const Color(0xFFDADCE0),
                  ),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF00897B) : const Color(0xFF5F6368),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          // ── City / Country info row ──────────────────────────────────────
          if (cityCountry.isNotEmpty && cityCountry != ',') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.apartment_rounded, size: 13, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  cityCountry,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // ── Meeting schedule info ────────────────────────────────────────
          if (formattedSchedule != null && formattedSchedule.isNotEmpty && formattedSchedule != 'TBD') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schedule_rounded, size: 13, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedSchedule,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // ── Description ─────────────────────────────────────────────────
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF5ECD8)),
          const SizedBox(height: 14),
          Text(
            _circleData?['description'] ?? AppLocalizations.of(context).cdNoDescriptionProvided,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),

          // ── Interactive Meeting Location chip ────────────────────────────
          if (_hasMeetingLocation()) ...[
            const SizedBox(height: 16),
            _buildMapChip(context),
          ],
        ],
      ),
    );
  }

  /// A tappable map chip that opens Google Maps when pressed.
  Widget _buildMapChip(BuildContext context) {
    final address = _circleData?['meetingAddress'] as String? ?? '';
    final lat = (_circleData!['meetingLat'] as num).toDouble();
    final lng = (_circleData!['meetingLng'] as num).toDouble();
    final location = LocationData(lat: lat, lng: lng, address: address);

    return GestureDetector(
      onTap: () {
        // Open using the MeetingLocationCard logic via bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _MapBottomSheet(location: location),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Map pin icon with pulsing indicator
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).cdMeetingLocation,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.isNotEmpty ? address : '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'View',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadershipSection() {
    final responsible = _circleData?['responsible'] ?? 'Unknown';
    final viceResponsible = _circleData?['viceResponsible'] ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.star_rounded,
          label: AppLocalizations.of(context).cdCircleLeadership,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildLeaderCard(
                name: responsible,
                role: AppLocalizations.of(context).cdResponsibleSmall,
                color: const Color(0xFF2962FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLeaderCard(
                name: viceResponsible,
                role: AppLocalizations.of(context).cdViceResponsibleSmall,
                color: const Color(0xFFFF9100),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Reusable section header with icon accent.
  Widget _buildSectionHeader({required IconData icon, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderCard({
    required String name,
    required String role,
    required Color color,
  }) {
    final nameParts = name.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'
        : (name.isNotEmpty ? name[0] : '?');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            role.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPhotosSection() {
    final pendingPhotos = _photos.where((p) => p['status'] == 'pending').toList();
    final approvedPhotos = _photos.where((p) => p['status'] != 'pending').toList();
    final circleId = _circleData!['id'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              icon: Icons.photo_library_rounded,
              label: AppLocalizations.of(context).cdMeetingGallery,
            ),
            if (_isUploadingPhoto)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              GestureDetector(
                onTap: _showPhotoSourceSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_a_photo_rounded, size: 14, color: Color(0xFF4285F4)),
                      const SizedBox(width: 5),
                      Text(
                        AppLocalizations.of(context).cdAddPhoto,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4285F4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Pending-photos moderation panel (Admin / SA only) ─────────
        if (_isAdminUser && pendingPhotos.isNotEmpty) ...[
          _buildModerationPanel(pendingPhotos, circleId),
          const SizedBox(height: 20),
        ],

        // ── Approved gallery ──────────────────────────────────────────
        if (approvedPhotos.isEmpty)
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
              itemCount: approvedPhotos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = approvedPhotos[index];
                final photoUrl = 'http://10.0.2.2:3000${photo['photo_url']}';
                final uploader = photo['uploader_name'] ?? 'Someone';
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
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          uploader,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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

  // ── Moderation panel widget ───────────────────────────────────────────────
  Widget _buildModerationPanel(List<dynamic> pendingPhotos, int circleId) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: Color(0xFFF9A825), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).cdPendingPhotos(
                      pendingPhotos.length,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9A825),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pendingPhotos.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFFE082)),

          // List of pending photo cards
          ...pendingPhotos.map((photo) {
            final photoId = photo['id'] as int;
            final photoUrl = 'http://10.0.2.2:3000${photo['photo_url']}';
            final uploader = photo['uploader_name'] ?? 'Someone';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Thumbnail with "PENDING" badge
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Image.network(
                            photoUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9A825),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppLocalizations.of(context).cdPendingBadge,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Uploader name
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).cdUploadedBy,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              uploader,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context).cdAwaitingApproval,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFFF9A825),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Approve
                          _ModerationActionButton(
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF2E7D32),
                            backgroundColor: const Color(0xFFE8F5E9),
                            tooltip: AppLocalizations.of(context).cdApprovePhoto,
                            onTap: () => _handleApprove(circleId, photoId),
                          ),
                          const SizedBox(height: 8),
                          // Reject
                          _ModerationActionButton(
                            icon: Icons.cancel_rounded,
                            color: const Color(0xFFC62828),
                            backgroundColor: const Color(0xFFFFEBEE),
                            tooltip: AppLocalizations.of(context).cdRejectPhoto,
                            onTap: () => _handleReject(circleId, photoId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _handleApprove(int circleId, int photoId) async {
    try {
      await CircleService().approveCirclePhoto(circleId, photoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).cdPhotoApproved),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        _fetchPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(int circleId, int photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).cdRejectPhotoTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context).cdRejectPhotoMessage,
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of(context).cdCancelBtn,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context).cdRejectBtn,
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CircleService().rejectCirclePhoto(circleId, photoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).cdPhotoRejected),
            backgroundColor: Colors.red,
          ),
        );
        _fetchPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildParticipantsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              icon: Icons.people_alt_rounded,
              label: AppLocalizations.of(context).cdCircleParticipants,
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => _CircleParticipantsModal(circleId: _circleData!['id'] as int),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).cdViewAll,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4285F4),
                  ),
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

  /// Read-only participants section shown to Members (no admin controls).
  Widget _buildMemberParticipantsSection() {
    final circleId = _circleData!['id'] as int;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.people_outline_rounded,
          label: AppLocalizations.of(context).cdParticipantsTitle,
        ),
        const SizedBox(height: 14),
        _MemberParticipantsList(circleId: circleId),
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

    // Pre-fill existing location if available
    LocationData? editLocation = _hasMeetingLocation()
        ? LocationData(
            lat: (_circleData!['meetingLat'] as num).toDouble(),
            lng: (_circleData!['meetingLng'] as num).toDouble(),
            address: _circleData!['meetingAddress'] as String? ?? '',
          )
        : null;

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
                      // ── Meeting Location ─────────────────────────────
                      Text(
                        AppLocalizations.of(context).cdMeetingLocation,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 1.5,
                        width: 40,
                        color: AppColors.primary,
                        margin: const EdgeInsets.only(bottom: 12),
                      ),
                      StatefulBuilder(
                        builder: (_, setLocState) {
                          return LocationPickerField(
                            selectedLocation: editLocation,
                            onLocationSelected: (loc) {
                              setLocState(() => editLocation = loc);
                            },
                          );
                        },
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
                                meetingLat: editLocation?.lat,
                                meetingLng: editLocation?.lng,
                                meetingAddress: editLocation?.address,
                                clearLocation: editLocation == null && _hasMeetingLocation(),
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
                                  _circleData!['meetingLat'] = editLocation?.lat;
                                  _circleData!['meetingLng'] = editLocation?.lng;
                                  _circleData!['meetingAddress'] = editLocation?.address;
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

/// Bottom sheet that wraps the MeetingLocationCard for the map chip tap interaction.
class _MapBottomSheet extends StatelessWidget {
  final LocationData location;
  const _MapBottomSheet({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Meeting Location',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MeetingLocationCard(location: location),
        ],
      ),
    );
  }
}

/// Read-only list of circle participants shown to Member-role users.
/// Each card is tappable (opens UserProfileScreen) and includes an AddFriendButton.
class _MemberParticipantsList extends StatefulWidget {
  final int circleId;
  const _MemberParticipantsList({required this.circleId});

  @override
  State<_MemberParticipantsList> createState() => _MemberParticipantsListState();
}

class _MemberParticipantsListState extends State<_MemberParticipantsList> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final list = await CircleService().getCircleParticipants(widget.circleId);
      // Only show members who have actually joined
      final joined = list.where((p) => p['hasJoined'] == true).toList();
      if (mounted) setState(() { _participants = joined; _isLoading = false; });
    } catch (e) {
      debugPrint('Fetch participants error: $e');
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).cdLoadParticipantsError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (_participants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).cdNoParticipantsYet,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: _participants.map<Widget>((p) {
        final name         = p['name'] as String? ?? 'Unknown';
        final profilePic   = p['profilePicture'] as String?;
        final assocLogo    = p['associationLogo'] as String?;
        final userId       = p['id'] as int;
        final joinedAtStr  = p['joinedAt'] as String?;

        String joinedDate = '';
        if (joinedAtStr != null) {
          try {
            final dt = DateTime.parse(joinedAtStr);
            joinedDate = AppLocalizations.of(context).cdJoinedOn(DateFormat('MMM d, yyyy').format(dt));
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: userId, userName: name),
                ),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderSoft),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    // Avatar
                    UserAvatar(
                      profilePictureUrl: profilePic,
                      associationLogoUrl: assocLogo,
                      name: name,
                      size: 46,
                      animate: true,
                      fallbackColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    // Name + joined date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (joinedDate.isNotEmpty)
                            Text(
                              joinedDate,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Add Friend button (compact)
                    AddFriendButton(targetUserId: userId),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
      debugPrint('Fetch participants error: $e');
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).cdLoadParticipantsError;
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
                          separatorBuilder: (context2, i2) => const SizedBox(height: 12),
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
                                final formattedDate = DateFormat('MMM d, yyyy').format(dt);
                                joinedDate = AppLocalizations.of(context).cdJoinedOn(formattedDate);
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
                                            Text(joinedDate, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
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

/// Small circular action button used in the photo moderation panel.
class _ModerationActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ModerationActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

/// A tappable option tile used inside the "Add Photo" source-selection sheet.
class _PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoSourceTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8EAED)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
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
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
