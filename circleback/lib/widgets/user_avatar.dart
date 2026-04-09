import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Base URL for the backend (Android emulator loopback).
const _kBaseUrl = 'http://10.0.2.2:3000';

/// Reusable avatar widget that:
/// 1. Shows the user's profile picture when available.
/// 2. Fades smoothly to the association logo every 2 seconds if both are present.
/// 3. Falls back to an initials-based coloured circle when no photo is set.
/// 4. Respects `MediaQuery.disableAnimations` for reduced-motion accessibility.
class UserAvatar extends StatefulWidget {
  /// Server-relative URL of the user's profile picture (e.g. '/uploads/profiles/...').
  final String? profilePictureUrl;

  /// Server-relative URL of the association logo (e.g. '/uploads/...').
  final String? associationLogoUrl;

  /// Full name — used to generate two-letter initials as a fallback.
  final String name;

  /// Diameter of the avatar circle in logical pixels.
  final double size;

  /// Whether to enable the 2-second profile ↔ logo alternating animation.
  /// Set to false for static avatar display.
  final bool animate;

  /// Background colour for the initials fallback avatar.
  final Color? fallbackColor;

  const UserAvatar({
    super.key,
    this.profilePictureUrl,
    this.associationLogoUrl,
    required this.name,
    this.size = 40,
    this.animate = true,
    this.fallbackColor,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  /// true  → show profile picture  |  false → show association logo
  bool _showingProfile = true;
  Timer? _timer;

  bool get _hasProfilePic =>
      widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty;

  bool get _hasLogo =>
      widget.associationLogoUrl != null && widget.associationLogoUrl!.isNotEmpty;

  bool get _shouldAnimate =>
      widget.animate && _hasProfilePic && _hasLogo;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(UserAvatar old) {
    super.didUpdateWidget(old);
    if (_shouldAnimate && _timer == null) {
      _startTimerIfNeeded();
    } else if (!_shouldAnimate) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimerIfNeeded() {
    if (!_shouldAnimate) return;
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _showingProfile = !_showingProfile);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fullUrl(String relative) {
    if (relative.startsWith('http')) return relative;
    return '$_kBaseUrl$relative';
  }

  /// Two initials derived from the first letters of the name's words.
  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _networkImage(String relativeUrl, {required double size}) {
    return Image.network(
      _fullUrl(relativeUrl),
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _fallbackCircle(size),
      errorBuilder: (_, __, ___) => _fallbackCircle(size),
    );
  }

  Widget _fallbackCircle(double size) {
    final bg = widget.fallbackColor ??
        HSLColor.fromAHSL(1, (widget.name.hashCode % 360).toDouble(), 0.55, 0.45)
            .toColor();
    return Container(
      width: size,
      height: size,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.inter(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Respect system-level reduced-motion setting
    final disableAnim = MediaQuery.of(context).disableAnimations;
    final doAnimate = _shouldAnimate && !disableAnim;

    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: _buildContent(doAnimate),
      ),
    );
  }

  Widget _buildContent(bool doAnimate) {
    final size = widget.size;

    if (!_hasProfilePic && !_hasLogo) {
      // Pure initials fallback
      return _fallbackCircle(size);
    }

    if (!doAnimate) {
      // Static — show profile picture if available, else logo, else initials
      final url = _hasProfilePic
          ? widget.profilePictureUrl!
          : (_hasLogo ? widget.associationLogoUrl! : null);
      if (url == null) return _fallbackCircle(size);
      return _networkImage(url, size: size);
    }

    // Animated crossfade between profile pic and association logo
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 400),
      crossFadeState: _showingProfile
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: _hasProfilePic
          ? _networkImage(widget.profilePictureUrl!, size: size)
          : _fallbackCircle(size),
      secondChild: _hasLogo
          ? _networkImage(widget.associationLogoUrl!, size: size)
          : _fallbackCircle(size),
    );
  }
}
