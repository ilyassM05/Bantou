import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/meeting_schedule.dart';
import '../../../theme/app_colors.dart';

class MeetingSchedulerSheet extends StatefulWidget {
  final DateTime pickedDate;
  final TimeOfDay pickedTime;

  const MeetingSchedulerSheet({
    super.key,
    required this.pickedDate,
    required this.pickedTime,
  });

  @override
  State<MeetingSchedulerSheet> createState() => _MeetingSchedulerSheetState();
}

class _MeetingSchedulerSheetState extends State<MeetingSchedulerSheet> {
  RecurrenceType _recurrenceType = RecurrenceType.oneTime;
  List<int> _selectedDays = [];
  String _monthlyType = 'sameDate';

  // Custom Recurrence State
  int _customInterval = 1;
  String _customIntervalUnit = 'weeks'; // 'days', 'weeks', 'months'
  List<int> _customWeeklyDays = [];
  String _customEndType = 'never'; // 'never', 'date', 'occurrences'
  DateTime? _customEndDate;
  int _customOccurrences = 10;

  @override
  void initState() {
    super.initState();
    // Default to the picked date's day of week if weekly is selected later
    _selectedDays = [widget.pickedDate.weekday];
    _customWeeklyDays = [widget.pickedDate.weekday];
  }

  void _save() {
    final schedule = MeetingSchedule(
      date: widget.pickedDate,
      time: widget.pickedTime,
      recurrenceType: _recurrenceType,
      weeklyDays: _recurrenceType == RecurrenceType.weekly ? _selectedDays : (_recurrenceType == RecurrenceType.custom && _customIntervalUnit == 'weeks' ? _customWeeklyDays : null),
      monthlyType: _recurrenceType == RecurrenceType.monthly ? _monthlyType : null,
      customInterval: _recurrenceType == RecurrenceType.custom ? _customInterval : null,
      customIntervalUnit: _recurrenceType == RecurrenceType.custom ? _customIntervalUnit : null,
      customEndDate: _recurrenceType == RecurrenceType.custom && _customEndType == 'date' ? _customEndDate : null,
      customOccurrences: _recurrenceType == RecurrenceType.custom && _customEndType == 'occurrences' ? _customOccurrences : null,
    );
    Navigator.pop(context, schedule);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Meeting Recurrence',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildRecurrenceDropdown(),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildDynamicOptions(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Confirm Schedule',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RecurrenceType>(
          value: _recurrenceType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: RecurrenceType.oneTime, child: Text('Does not repeat')),
            DropdownMenuItem(value: RecurrenceType.daily, child: Text('Every day')),
            DropdownMenuItem(value: RecurrenceType.weekly, child: Text('Every week')),
            DropdownMenuItem(value: RecurrenceType.monthly, child: Text('Every month')),
            DropdownMenuItem(value: RecurrenceType.custom, child: Text('Custom...')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _recurrenceType = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDynamicOptions() {
    if (_recurrenceType == RecurrenceType.weekly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat on',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final dayNum = index + 1; // 1=Mon, 7=Sun
              final isSelected = _selectedDays.contains(dayNum);
              final dayLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
              return ChoiceChip(
                label: Text(dayLabel),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey.shade100,
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(dayNum);
                      _selectedDays.sort();
                    } else {
                      if (_selectedDays.length > 1) { // Keep at least one
                        _selectedDays.remove(dayNum);
                      }
                    }
                  });
                },
              );
            }),
          ),
        ],
      );
    } else if (_recurrenceType == RecurrenceType.monthly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly rule',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _monthlyType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                items: [
                  DropdownMenuItem(value: 'sameDate', child: Text('Monthly on day ${widget.pickedDate.day}')),
                  const DropdownMenuItem(value: 'firstMonday', child: Text('Monthly on the first Monday')),
                  const DropdownMenuItem(value: 'lastFriday', child: Text('Monthly on the last Friday')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _monthlyType = val);
                  }
                },
              ),
            ),
          ),
        ],
      );
    } else if (_recurrenceType == RecurrenceType.custom) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repeat every', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _customInterval,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    items: List.generate(30, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                    onChanged: (val) {
                      if (val != null) setState(() => _customInterval = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _customIntervalUnit,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                      style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      items: const [
                        DropdownMenuItem(value: 'days', child: Text('Day(s)')),
                        DropdownMenuItem(value: 'weeks', child: Text('Week(s)')),
                        DropdownMenuItem(value: 'months', child: Text('Month(s)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _customIntervalUnit = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_customIntervalUnit == 'weeks') ...[
            const SizedBox(height: 24),
            Text('Repeat on', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final dayNum = index + 1;
                final isSelected = _customWeeklyDays.contains(dayNum);
                final dayLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
                return ChoiceChip(
                  label: Text(dayLabel),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _customWeeklyDays.add(dayNum);
                        _customWeeklyDays.sort();
                      } else if (_customWeeklyDays.length > 1) {
                        _customWeeklyDays.remove(dayNum);
                      }
                    });
                  },
                );
              }),
            ),
          ],
          const SizedBox(height: 24),
          Text('Ends', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Column(
            children: [
              RadioListTile<String>(
                title: Text('Never', style: GoogleFonts.inter(fontSize: 14)),
                value: 'never',
                groupValue: _customEndType,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _customEndType = val!),
              ),
              RadioListTile<String>(
                title: Row(
                  children: [
                    Text('On ', style: GoogleFonts.inter(fontSize: 14)),
                    TextButton(
                      onPressed: () async {
                        setState(() => _customEndType = 'date');
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _customEndDate ?? widget.pickedDate.add(const Duration(days: 30)),
                          firstDate: widget.pickedDate,
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _customEndDate = date);
                        }
                      },
                      child: Text(
                        _customEndDate != null ? '${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}' : 'Select Date',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                value: 'date',
                groupValue: _customEndType,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _customEndType = val!),
              ),
              RadioListTile<String>(
                title: Row(
                  children: [
                    Text('After ', style: GoogleFonts.inter(fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      width: 60,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _customOccurrences,
                          icon: const SizedBox.shrink(),
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          items: List.generate(50, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _customEndType = 'occurrences';
                                _customOccurrences = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('occurrences', style: GoogleFonts.inter(fontSize: 14)),
                  ],
                ),
                value: 'occurrences',
                groupValue: _customEndType,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _customEndType = val!),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
