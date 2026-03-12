import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_scope.dart';
import '../theme/app_colors.dart';

/// Compact globe button that opens a bottom sheet with 4 language options.
/// Place it anywhere in the widget tree where [LocaleScope] is an ancestor.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  static const _languages = [
    (code: 'en', label: 'English', flag: '🇺🇸'),
    (code: 'fr', label: 'Français', flag: '🇫🇷'),
    (code: 'es', label: 'Español', flag: '🇪🇸'),
    (code: 'ar', label: 'العربية', flag: '🇸🇦'),
  ];

  @override
  Widget build(BuildContext context) {
    final scope = LocaleScope.of(context);
    return IconButton(
      tooltip: AppLocalizations.of(context).changeLanguage,
      icon: const Icon(Icons.language_rounded),
      color: AppColors.primary,
      onPressed: () => _showPicker(context, scope),
    );
  }

  void _showPicker(BuildContext context, LocaleScope scope) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LanguageSheet(
        currentCode: scope.locale.languageCode,
        onSelected: (code) {
          final newLocale = Locale(code);
          scope.onLocaleChanged(newLocale);
          saveLocale(newLocale);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.currentCode, required this.onSelected});

  final String currentCode;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              l.changeLanguage,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          for (final lang in LanguagePicker._languages)
            _LangTile(
              flag: lang.flag,
              label: lang.label,
              code: lang.code,
              selected: lang.code == currentCode,
              onTap: () => onSelected(lang.code),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.flag,
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: selected
            ? BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08))
            : null,
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              code.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
