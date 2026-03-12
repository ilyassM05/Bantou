import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../services/circle_service.dart';

/// Screen representing the Circle Dashboard.
/// This matches the UI from the provided design showing a list of circles
/// or defining its main information (Circle Name, Country, City, etc.).
class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  static const routeName = '/create-circle';

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  // Form controls
  final _formKey = GlobalKey<FormState>();
  final _circleNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _viceResponsibleController = TextEditingController();
  final _meetingPlanningController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _circleNameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _responsibleController.dispose();
    _viceResponsibleController.dispose();
    _meetingPlanningController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = CircleService();
      await service.createCircle(
        name: _circleNameController.text.trim(),
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        responsible: _responsibleController.text.trim(),
        viceResponsible: _viceResponsibleController.text.trim(),
        meetingPlanning: _meetingPlanningController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Circle saved successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true); // Go back home and indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        title: Text(
          l.cdTitle,
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('Circle Details'),
                  const SizedBox(height: 16),
                  
                  // Circle Name
                  AuthTextField(
                    label: l.cdCircleNameLabel,
                    hint: l.cdCircleNameHint,
                    icon: Icons.groups_rounded,
                    controller: _circleNameController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Location (Country & City) side by side if possible, or stacked
                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          label: l.cdCountryLabel,
                          hint: l.cdCountryHint,
                          icon: Icons.public_rounded,
                          controller: _countryController,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AuthTextField(
                          label: l.cdCityLabel,
                          hint: l.cdCityHint,
                          icon: Icons.location_city_rounded,
                          controller: _cityController,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Leadership'),
                  const SizedBox(height: 16),
                  
                  // Circle Responsible
                  AuthTextField(
                    label: l.cdResponsibleLabel,
                    hint: l.cdResponsibleHint,
                    icon: Icons.person_rounded,
                    controller: _responsibleController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Vice Responsible
                  AuthTextField(
                    label: l.cdViceResponsibleLabel,
                    hint: l.cdViceResponsibleHint,
                    icon: Icons.person_outline_rounded,
                    controller: _viceResponsibleController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Schedule'),
                  const SizedBox(height: 16),
                  
                  // Meeting Planning
                  AuthTextField(
                    label: l.cdMeetingPlanningLabel,
                    hint: l.cdMeetingPlanningHint,
                    icon: Icons.calendar_month_rounded,
                    controller: _meetingPlanningController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Save Button
                  GestureDetector(
                    onTap: _isLoading ? null : _handleSave,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLoading
                              ? [AppColors.primaryLight, AppColors.primaryLight]
                              : [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                l.cdSaveBtn,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.5,
          width: 40,
          color: AppColors.primary,
        ),
      ],
    );
  }
}
