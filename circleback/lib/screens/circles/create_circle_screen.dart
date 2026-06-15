import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_text_field.dart';
import '../../services/circle_service.dart';
import '../../models/meeting_schedule.dart';
import '../../models/location_data.dart';
import '../../widgets/location_picker_field.dart';
import 'widgets/meeting_scheduler_sheet.dart';
import 'dart:convert';

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
  final _descriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _viceResponsibleController = TextEditingController();
  final _meetingPlanningController = TextEditingController();

  String _visibilityType = 'Public';
  List<Map<String, dynamic>> _selectedMembers = [];
  MeetingSchedule? _meetingSchedule;
  LocationData? _meetingLocation;

  bool _isLoading = false;

  @override
  void dispose() {
    _circleNameController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _responsibleController.dispose();
    _viceResponsibleController.dispose();
    _meetingPlanningController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const _AddMemberDialog();
      },
    ).then((selectedUser) {
      if (selectedUser != null) {
        setState(() {
          if (!_selectedMembers.any((m) => m['id'] == selectedUser['id'])) {
            _selectedMembers.add(Map<String, dynamic>.from(selectedUser));
          }
        });
      }
    });
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        final schedule = await showModalBottomSheet<MeetingSchedule>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MeetingSchedulerSheet(
            pickedDate: pickedDate,
            pickedTime: pickedTime,
          ),
        );

        if (schedule != null) {
          setState(() {
            _meetingSchedule = schedule;
            // Update controller with the smart summary so the user sees the human-readable text
            _meetingPlanningController.text = schedule.toDisplayString().replaceAll('\n', ' - ');
          });
        }
      }
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = CircleService();
      
      // Serialize the structured recurrence data for the backend
      final meetingPlanningData = _meetingSchedule != null 
          ? jsonEncode(_meetingSchedule!.toJson())
          : _meetingPlanningController.text.trim();

      await service.createCircle(
        name: _circleNameController.text.trim(),
        description: _descriptionController.text.trim(),
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        responsible: _responsibleController.text.trim(),
        viceResponsible: _viceResponsibleController.text.trim(),
        meetingPlanning: meetingPlanningData,
        visibilityType: _visibilityType,
        initialMembers: _selectedMembers.map((m) => m['id'] as int).toList(),
        meetingLat: _meetingLocation?.lat,
        meetingLng: _meetingLocation?.lng,
        meetingAddress: _meetingLocation?.address,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).cdCircleSavedSuccess),
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
          l.cdCreateCircleTitle,
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
                  _buildSectionTitle(l.cdCircleDetailsTitle),
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

                  // Circle Description
                  AuthTextField(
                    label: l.cdDescriptionOptional,
                    hint: l.cdDescriptionHintText,
                    icon: Icons.description_rounded,
                    controller: _descriptionController,
                    maxLines: 4,
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

                  _buildSectionTitle(l.cdVisibilityAccess),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(l.cdPublic, style: GoogleFonts.inter(fontSize: 14)),
                          value: 'Public',
                          groupValue: _visibilityType,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _visibilityType = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(l.cdPrivate, style: GoogleFonts.inter(fontSize: 14)),
                          value: 'Private',
                          groupValue: _visibilityType,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _visibilityType = val!),
                        ),
                      ),
                    ],
                  ),
                  if (_visibilityType == 'Private') ...[
                    const SizedBox(height: 16),
                    Text(
                      l.cdInviteMembers,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showAddMemberDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_add_rounded, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(l.cdSearchAddMembers, style: GoogleFonts.inter(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedMembers.map((m) {
                        return Chip(
                          label: Text(m['name'] ?? m['email'], style: GoogleFonts.inter(fontSize: 12)),
                          onDeleted: () {
                            setState(() => _selectedMembers.remove(m));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),

                  _buildSectionTitle(l.cdLeadership),
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

                  _buildSectionTitle(l.cdSchedule),
                  const SizedBox(height: 16),
                  
                  // Meeting Planning
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cdMeetingPlanningLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _meetingPlanningController,
                        readOnly: true,
                        maxLines: null,
                        onTap: _pickDateTime,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: l.cdMeetingPlanningHint,
                          prefixIcon: const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // ── Meeting Location ──────────────────────────────────────
                  _buildSectionTitle(AppLocalizations.of(context).cdMeetingLocation),
                  const SizedBox(height: 16),
                  LocationPickerField(
                    selectedLocation: _meetingLocation,
                    onLocationSelected: (loc) {
                      setState(() => _meetingLocation = loc);
                    },
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

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _error = '';

  void _search() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await CircleService().searchAssociationMembers(_searchController.text.trim());
      setState(() {
        _results = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).cdAddMember, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).cdSearchNameEmail,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
            if (!_isLoading && _results.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      title: Text(user['name'] ?? 'Unknown', style: GoogleFonts.inter()),
                      subtitle: Text(user['email'] ?? '', style: GoogleFonts.inter(fontSize: 12)),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                ),
              ),
            if (!_isLoading && _results.isEmpty && _searchController.text.isNotEmpty && _error.isEmpty)
              Text(AppLocalizations.of(context).cdNoMembersFound),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cdCancel),
        ),
      ],
    );
  }
}
