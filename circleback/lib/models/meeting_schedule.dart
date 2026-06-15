import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum RecurrenceType {
  oneTime,
  daily,
  weekly,
  monthly,
  custom,
}

class MeetingSchedule {
  final DateTime date;
  final TimeOfDay time;
  final RecurrenceType recurrenceType;

  // Weekly specific
  final List<int>? weeklyDays; // 1 = Mon, 7 = Sun (following DateTime weekday)

  // Monthly specific
  final String? monthlyType; // 'sameDate', 'firstMonday', 'lastFriday'

  // Custom specific
  final int? customInterval; // e.g. repeat every X
  final String? customIntervalUnit; // 'days', 'weeks', 'months'
  final DateTime? customEndDate;
  final int? customOccurrences;

  MeetingSchedule({
    required this.date,
    required this.time,
    required this.recurrenceType,
    this.weeklyDays,
    this.monthlyType,
    this.customInterval,
    this.customIntervalUnit,
    this.customEndDate,
    this.customOccurrences,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'recurrenceType': recurrenceType.name,
      if (weeklyDays != null) 'weeklyDays': weeklyDays,
      if (monthlyType != null) 'monthlyType': monthlyType,
      if (customInterval != null) 'customInterval': customInterval,
      if (customIntervalUnit != null) 'customIntervalUnit': customIntervalUnit,
      if (customEndDate != null) 'customEndDate': customEndDate?.toIso8601String(),
      if (customOccurrences != null) 'customOccurrences': customOccurrences,
    };
  }

  /// Returns a clean, compact schedule display string.
  ///
  /// Format examples:
  ///   One-time  → "Jun 8, 2026 · 10:15 AM"
  ///   Daily     → "Daily · 10:15 AM"
  ///   Weekly    → "Mon, Wed, Fri · 10:15 AM"
  ///   Monthly   → "Monthly (8th) · 10:15 AM"
  ///   Custom    → "Every 2 weeks · 10:15 AM"
  String toDisplayString() {
    final timeStr = _formatTime(time);

    switch (recurrenceType) {
      case RecurrenceType.oneTime:
        final dateStr = DateFormat('MMM d, yyyy').format(date);
        return '$dateStr · $timeStr';

      case RecurrenceType.daily:
        return 'Daily · $timeStr';

      case RecurrenceType.weekly:
        if (weeklyDays == null || weeklyDays!.isEmpty) {
          final dayStr = DateFormat('EEE').format(date);
          return '$dayStr · $timeStr';
        }
        final daysStr = weeklyDays!.map(_shortDayName).join(', ');
        return '$daysStr · $timeStr';

      case RecurrenceType.monthly:
        if (monthlyType == 'sameDate') {
          return 'Monthly (${date.day}${_getDaySuffix(date.day)}) · $timeStr';
        } else if (monthlyType == 'firstMonday') {
          return 'Monthly (1st Mon) · $timeStr';
        } else if (monthlyType == 'lastFriday') {
          return 'Monthly (last Fri) · $timeStr';
        }
        return 'Monthly · $timeStr';

      case RecurrenceType.custom:
        String base = 'Every $customInterval $customIntervalUnit';
        if (customIntervalUnit == 'weeks' &&
            weeklyDays != null &&
            weeklyDays!.isNotEmpty) {
          final daysStr = weeklyDays!.map(_shortDayName).join(', ');
          base += ' ($daysStr)';
        }
        return '$base · $timeStr';
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Formats a [TimeOfDay] as "10:15 AM" / "02:30 PM".
  static String _formatTime(TimeOfDay t) {
    final hour = t.hour;
    final minute = t.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  static String _shortDayName(int d) {
    switch (d) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// ─── Meeting Time Formatter ───────────────────────────────────────────────────

/// Converts a raw `meetingPlanning` string (JSON or plain text) into a clean,
/// compact display string used consistently across all screens.
///
/// **JSON input** (produced by the scheduler):
///   `'{"recurrenceType":"weekly","weeklyDays":[1,3],"time":"10:5",...}'`
///   → `"Mon, Wed · 10:05 AM"`
///
/// **Plain-text input** (manually typed by admin):
///   `"Every Monday at 10 AM"`
///   → `"Every Monday at 10 AM"` (returned as-is)
class MeetingTimeFormatter {
  MeetingTimeFormatter._();

  /// Parses [raw] and returns a compact display string.
  /// Returns [fallback] (default `'TBD'`) when [raw] is null/empty.
  static String format(String? raw, {String fallback = 'TBD'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final trimmed = raw.trim();

    // ── Attempt JSON parse ──────────────────────────────────────────────────
    try {
      final Map<String, dynamic> json =
          jsonDecode(trimmed) as Map<String, dynamic>;

      // Parse "H:M" time string → TimeOfDay
      final rawTime = json['time'] as String? ?? '0:0';
      final parts = rawTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final time = TimeOfDay(hour: hour, minute: minute);

      // Parse ISO date
      final date = json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now();

      // Parse recurrence type
      RecurrenceType recType = RecurrenceType.oneTime;
      for (final r in RecurrenceType.values) {
        if (r.name == json['recurrenceType']) {
          recType = r;
          break;
        }
      }

      // Parse optional week-days list
      List<int>? weeklyDays;
      if (json['weeklyDays'] is List) {
        weeklyDays =
            (json['weeklyDays'] as List).map((d) => d as int).toList();
      }

      final schedule = MeetingSchedule(
        date: date,
        time: time,
        recurrenceType: recType,
        weeklyDays: weeklyDays,
        monthlyType: json['monthlyType'] as String?,
        customInterval: json['customInterval'] as int?,
        customIntervalUnit: json['customIntervalUnit'] as String?,
        customEndDate: json['customEndDate'] != null
            ? DateTime.tryParse(json['customEndDate'] as String)
            : null,
        customOccurrences: json['customOccurrences'] as int?,
      );

      return schedule.toDisplayString();
    } catch (_) {
      // Not valid JSON — return the plain-text value unchanged.
      return trimmed;
    }
  }
}
