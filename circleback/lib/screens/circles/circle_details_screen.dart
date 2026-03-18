import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../services/circle_service.dart';

/// Screen representing the details of a specific Circle.
class CircleDetailsScreen extends StatefulWidget {
  const CircleDetailsScreen({super.key});

  static const routeName = '/circle-details';

  @override
  State<CircleDetailsScreen> createState() => _CircleDetailsScreenState();
}

class _CircleDetailsScreenState extends State<CircleDetailsScreen> {
  Map<String, dynamic>? _circleData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_circleData == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _circleData = args;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        title: Text(
          'Circle Details',
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
    final title = _circleData?['name'] ?? 'Unknown Circle';
    final location = '${_circleData?['city'] ?? ''}, ${_circleData?['country'] ?? ''}'.trim();
    final status = _circleData?['status'] ?? 'Active';
    final isActive = status.toLowerCase() == 'active';

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
          _circleData?['description'] ?? 'No description provided.',
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
          'Circle Leadership',
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
                role: 'Responsible',
                color: const Color(0xFF2962FF), // Blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLeaderCard(
                name: viceResponsible,
                role: 'Vice-Responsible',
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
              'Upcoming Meetings',
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
                'View Calendar',
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
          title: 'Next Sync',
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
                        'Edit Circle',
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
                                  const SnackBar(content: Text('Circle updated successfully!'), backgroundColor: AppColors.primary),
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
                            : Text('Save Changes', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
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
