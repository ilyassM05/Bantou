import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/http_auth_service.dart';
import '../../widgets/auth_text_field.dart';
import '../../l10n/app_localizations.dart';

/// Forgot Password screen — three steps:
///  1. Enter email  → backend sends OTP via real email
///  2. Enter OTP    → backend verifies the 6-digit code
///  3. New password → backend resets password (OTP consumed)
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = HttpAuthService();

  // ── Step tracking ──────────────────────────────────────────────────────
  // 0 = email, 1 = OTP, 2 = new password, 3 = success
  int _step = 0;

  // Step 1 – email
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _emailLoading = false;
  String? _emailError;

  // Step 2 – OTP
  final _otpCtrl = TextEditingController();
  bool _otpLoading = false;
  String? _otpError;
  int _countdown = 0;
  Timer? _timer;

  // Step 3 – new password
  final _passFormKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _passLoading = false;
  String? _passError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Step 1: send OTP ──────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _emailLoading = true;
      _emailError = null;
    });
    try {
      await _authService.forgotPassword(_emailCtrl.text.trim());
      if (mounted) {
        setState(() {
          _step = 1;
          _emailLoading = false;
        });
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailLoading = false;
          _emailError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── Step 2: verify OTP ────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _otpError = AppLocalizations.of(context).fpOtpInvalid);
      return;
    }
    setState(() {
      _otpLoading = true;
      _otpError = null;
    });
    try {
      await _authService.verifyOtp(_emailCtrl.text.trim(), otp);
      if (mounted)
        setState(() {
          _step = 2;
          _otpLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpLoading = false;
          _otpError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (_countdown > 0) return;
    setState(() {
      _otpError = null;
      _otpCtrl.clear();
    });
    try {
      await _authService.forgotPassword(_emailCtrl.text.trim());
      if (mounted) _startCountdown();
    } catch (e) {
      if (mounted) {
        setState(() => _otpError = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) setState(() => _countdown = 0);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  // ── Step 3: reset password ────────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() {
      _passLoading = true;
      _passError = null;
    });
    try {
      await _authService.resetPassword(
        _emailCtrl.text.trim(),
        _otpCtrl.text.trim(),
        _newPassCtrl.text,
      );
      if (mounted)
        setState(() {
          _step = 3;
          _passLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _passLoading = false;
          _passError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final subtitles = [
      l.fpSubtitleStep1,
      l.fpOtpSubtitle,
      l.fpSubtitleStep3,
      '',
    ];

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryDark,
          ),
          onPressed: () {
            if (_step > 0 && _step < 3) {
              setState(() {
                _step--;
                _otpError = null;
                _passError = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          l.fpTitle,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator (hidden on success)
                if (_step < 3) _buildStepIndicator(),
                const SizedBox(height: 12),
                if (_step < 3)
                  Text(
                    subtitles[_step],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderSoft, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentStep(l),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (i) {
        final active = i == _step;
        final done = i < _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: done || active
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(AppLocalizations l) {
    switch (_step) {
      case 0:
        return _buildEmailForm(l);
      case 1:
        return _buildOtpForm(l);
      case 2:
        return _buildPasswordForm(l);
      case 3:
        return _buildSuccessView(l);
      default:
        return _buildEmailForm(l);
    }
  }

  // ── Step 1: email form ────────────────────────────────────────────────
  Widget _buildEmailForm(AppLocalizations l) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            label: l.fpEmailLabel,
            hint: l.fpEmailHint,
            icon: Icons.email_outlined,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.isEmpty) ? l.fpEmailRequired : null,
          ),
          if (_emailError != null) ...[
            const SizedBox(height: 10),
            _buildError(_emailError!),
          ],
          const SizedBox(height: 24),
          _buildButton(
            label: l.fpVerifyButton,
            loading: _emailLoading,
            onTap: _sendOtp,
          ),
        ],
      ),
    );
  }

  // ── Step 2: OTP form ──────────────────────────────────────────────────
  Widget _buildOtpForm(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _emailCtrl.text.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 6-digit OTP input
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 16,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            hintText: '······',
            hintStyle: GoogleFonts.inter(
              fontSize: 28,
              letterSpacing: 16,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: AppColors.primary.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
          ),
          onChanged: (v) {
            if (_otpError != null) setState(() => _otpError = null);
          },
        ),
        if (_otpError != null) ...[
          const SizedBox(height: 10),
          _buildError(_otpError!),
        ],
        const SizedBox(height: 24),
        _buildButton(
          label: l.fpOtpButton,
          loading: _otpLoading,
          onTap: _verifyOtp,
        ),
        const SizedBox(height: 16),
        // Resend
        GestureDetector(
          onTap: _countdown == 0 ? _resendOtp : null,
          child: Text(
            _countdown > 0 ? '${l.fpOtpResendIn} $_countdown s' : l.fpOtpResend,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _countdown > 0
                  ? AppColors.textSecondary
                  : AppColors.primary,
              fontWeight: FontWeight.w600,
              decoration: _countdown == 0
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: new password form ─────────────────────────────────────────
  Widget _buildPasswordForm(AppLocalizations l) {
    return Form(
      key: _passFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            label: l.fpNewPasswordLabel,
            hint: l.fpNewPasswordHint,
            icon: Icons.lock_outline,
            controller: _newPassCtrl,
            isPassword: true,
            validator: (v) => (v == null || v.length < 6) ? l.fpMinChars : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: l.fpConfirmLabel,
            hint: l.fpConfirmHint,
            icon: Icons.lock_outline,
            controller: _confirmPassCtrl,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                v != _newPassCtrl.text ? l.fpPasswordsMismatch : null,
          ),
          if (_passError != null) ...[
            const SizedBox(height: 10),
            _buildError(_passError!),
          ],
          const SizedBox(height: 24),
          _buildButton(
            label: l.fpResetButton,
            loading: _passLoading,
            onTap: _resetPassword,
          ),
        ],
      ),
    );
  }

  // ── Success view ──────────────────────────────────────────────────────
  Widget _buildSuccessView(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l.fpSuccessTitle,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          l.fpSuccessSubtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        _buildButton(
          label: l.fpGoToLogin,
          loading: false,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Text(
      message,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.red.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: loading
                ? [AppColors.primaryLight, AppColors.primaryLight]
                : [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading
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
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
