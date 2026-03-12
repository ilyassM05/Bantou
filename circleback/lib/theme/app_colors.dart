import 'package:flutter/material.dart';

/// App color palette — Bantou gold/amber theme derived from the official logo.
/// All colors centralized here so the team can retheme in one place.
class AppColors {
  AppColors._();

  // ── Gradient background ──────────────────────────────────────────────────
  static const Color gradientStart = Color(0xFFFFF8EC); // Warm cream
  static const Color gradientEnd = Color(0xFFFFF1D6); // Pale amber

  // ── Brand / Accent ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFC8860A); // Logo primary gold
  static const Color primaryDark = Color(0xFFA06205); // Deep gold
  static const Color primaryLight = Color(0xFFE8A020); // Warm amber

  // ── Surface / Card ────────────────────────────────────────────────────────
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFFFF8EE); // Cream input background

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D1A00); // Deep warm brown
  static const Color textSecondary = Color(0xFF7A6040); // Muted gold-brown
  static const Color textHint = Color(0xFFB89860); // Light gold hint

  // ── Borders / Dividers ────────────────────────────────────────────────────
  static const Color borderSoft = Color(0xFFF0C870); // Soft gold border
  static const Color borderFocused = Color(0xFFC8860A); // Gold focused border

  // ── Utility ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);

  // ── Social brand colors ───────────────────────────────────────────────────
  static const Color googleRed = Color(0xFFEA4335);
  static const Color linkedinBlue = Color(0xFF0A66C2);
  static const Color facebookBlue = Color(0xFF1877F2);
}
