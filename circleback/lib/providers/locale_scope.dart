import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// InheritedWidget providing the current [Locale] and a callback to change it.
/// Wrap MaterialApp with [LocaleScope] to enable app-wide language switching.
class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  final Locale locale;
  final void Function(Locale) onLocaleChanged;

  static LocaleScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()!;

  @override
  bool updateShouldNotify(LocaleScope old) => locale != old.locale;
}

/// Loads and saves the persisted language code from [SharedPreferences].
Future<Locale> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('language_code') ?? 'en';
  return Locale(code);
}

Future<void> saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language_code', locale.languageCode);
}
