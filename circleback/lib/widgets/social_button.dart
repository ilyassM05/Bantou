import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';

/// Social sign-in button variant.
enum SocialProvider { google, facebook }

/// Outlined social authentication button with real brand icon and label.
/// Pass [label] to override the default provider label (useful for localization).
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.provider,
    required this.onTap,
    this.label,
  });

  final SocialProvider provider;
  final VoidCallback onTap;

  /// Optional label override (use for localized strings). Falls back to the
  /// default English provider name if null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: AppColors.borderSoft, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: AppColors.cardSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label ?? _defaultLabel,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (provider) {
      case SocialProvider.google:
        return const FaIcon(
          FontAwesomeIcons.google,
          color: Color(0xFFEA4335), // Official Google red
          size: 20,
        );
      case SocialProvider.facebook:
        return const FaIcon(
          FontAwesomeIcons.facebook,
          color: Color(0xFF1877F2), // Official Facebook blue
          size: 22,
        );
    }
  }

  String get _defaultLabel {
    switch (provider) {
      case SocialProvider.google:
        return 'Google';
      case SocialProvider.facebook:
        return 'Continue with Facebook';
    }
  }
}
