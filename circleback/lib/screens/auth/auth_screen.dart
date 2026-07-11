import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/http_auth_service.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/create_association_screen.dart';
import '../auth/pending_approval_screen.dart';
import '../main_shell_screen.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/social_button.dart';

/// Main authentication screen with Login / Sign Up tab switcher.
/// All UI strings resolved via [AppLocalizations] for multi-language support.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routeName = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Service — use HttpAuthService for live backend requests
  final AuthService _authService = HttpAuthService();

  // Biometric
  bool _biometricAvailable = false;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _loginLoading = false;
  String? _loginErrorMessage;

  // Sign-up form
  final _signupFormKey = GlobalKey<FormState>();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPhone = TextEditingController();
  final _signupPassword = TextEditingController();
  final _signupConfirm = TextEditingController();
  bool _signupLoading = false;
  String? _signupErrorMessage;
  String? _inviteToken; // captured via intent/deep link or parameter

  bool _inviteHandled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _checkBiometric();
    _applyInviteStateIfPending();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle navigation argument from main.dart deep link handler
    if (!_inviteHandled) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['openSignUp'] == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tabController.animateTo(1);
          _applyInviteStateIfPending();
        });
      }
    }
  }

  /// If there's a pending invite (from deep link), prefill email and switch to sign-up tab.
  void _applyInviteStateIfPending() {
    if (_inviteHandled) return;
    final email = HttpAuthService.pendingInviteEmail;
    final token = HttpAuthService.pendingInviteToken;
    if (token != null) {
      _inviteHandled = true;
      _inviteToken = token;
      if (email != null && email.isNotEmpty) {
        _signupEmail.text = email;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(1);
      });
    }
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final hasToken = await BiometricService.hasStoredToken();
    if (mounted) setState(() => _biometricAvailable = available && hasToken);
    // Auto-prompt on first load if everything is ready
    if (available && hasToken) _handleBiometric();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPhone.dispose();
    _signupPassword.dispose();
    _signupConfirm.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  /// All post-auth paths converge here.
  /// - Invited admin (isInvitedAdmin flag OR role == 'admin') → Dashboard (limited access)
  /// - First-time creator → Association setup → Profile setup → Dashboard
  /// - Returning user → Dashboard directly
  void _goToCorrectScreen() {
    if (HttpAuthService.currentUserStatus == 'en attente') {
      Navigator.pushReplacementNamed(context, PendingApprovalScreen.routeName);
      return;
    }

    // Both signals must agree before sending someone to the association form.
    final isInvitedAdmin = HttpAuthService.currentIsInvitedAdmin ||
        HttpAuthService.currentUserRole == 'admin';
    final isMember = HttpAuthService.currentIsMember ||
        HttpAuthService.currentUserRole == 'member';

    // Only force association creation for SAs who haven't done it yet
    if (!isInvitedAdmin && !isMember && HttpAuthService.currentUserNeedsOnboarding) {
      Navigator.pushReplacementNamed(
        context,
        CreateAssociationScreen.routeName,
      );
    } else {
      // Everyone else goes directly to the main shell (tab bar)
      Navigator.pushReplacementNamed(context, MainShellScreen.routeName);
    }
  }

  // _goHome / _goSetup are kept as aliases so existing call-sites compile
  void _goHome() => _goToCorrectScreen();
  void _goSetup() => _goToCorrectScreen();

  // ── Login ──────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    setState(() => _loginErrorMessage = null);
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);
    try {
      final ok = await _authService.signInWithEmail(
        _loginEmail.text.trim(),
        _loginPassword.text,
      );
      if (mounted) {
        setState(() => _loginLoading = false);
        if (ok) _goToCorrectScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginLoading = false;
          _loginErrorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── Sign up ────────────────────────────────────────────────────────────
  Future<void> _handleSignup() async {
    setState(() => _signupErrorMessage = null);
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _signupLoading = true);
    try {
      final ok = await (_authService as HttpAuthService).signUpWithEmail(
        _signupName.text.trim(),
        _signupEmail.text.trim(),
        _signupPassword.text,
        phone: _signupPhone.text.trim().isNotEmpty
            ? _signupPhone.text.trim()
            : null,
        inviteToken: _inviteToken, // Pass token if we have one
      );
      if (mounted) {
        setState(() => _signupLoading = false);
        if (ok) _goSetup();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signupLoading = false;
          _signupErrorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── Biometric login ────────────────────────────────────────────────────
  Future<void> _handleBiometric() async {
    final result = await BiometricService.authenticate();
    if (!mounted || result == null) return;
    HttpAuthService.currentUser = {
      'name': result['name'] ?? '',
      'email': result['email'] ?? '',
    };
    _goHome();
  }

  // ── Social ─────────────────────────────────────────────────────────────
  /// Social sign-ins check the flag: only go to setup if it's the first time.
  Future<void> _handleSocial(Future<bool> Function() call) async {
    final ok = await call();
    if (mounted && ok) _goToCorrectScreen();
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  _buildCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header (logo + language picker) ──────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Language picker row
        Align(alignment: Alignment.centerRight, child: const LanguagePicker()),
        const SizedBox(height: 8),
        // Bantou logo — transparent PNG (globe + name + slogan)
        Center(
          child: Image.asset(
            'assets/images/bantou.png',
            width: 160,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  // ── Glass card ───────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.borderSoft, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabBar(context),
          // Show invite banner when opened from a deep link
          if (_tabController.index == 1 && HttpAuthService.pendingAssociationName != null)
            _buildInviteBanner(),
          const SizedBox(height: 24),
          _tabController.index == 0
              ? _buildLoginForm(context)
              : _buildSignupForm(context),
        ],
      ),
    );
  }

  // ── Invite banner ────────────────────────────────────────────────────
  /// Shown above the sign-up form when the user opened the app via an invite link.
  Widget _buildInviteBanner() {
    final assocName = HttpAuthService.pendingAssociationName ?? 'an association';
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC9A84C), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: Color(0xFFC9A84C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'ve been invited to join $assocName. Create your account below.',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B5020),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pill tab bar ─────────────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: l.loginTab),
          Tab(text: l.signUpTab),
        ],
      ),
    );
  }

  // ── Divider "OR" ──────────────────────────────────────────────────────
  Widget _buildOrDivider(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.borderSoft, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            l.orDivider,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.borderSoft, thickness: 1)),
      ],
    );
  }

  // ── Social buttons ────────────────────────────────────────────────────
  Widget _buildSocialButtons(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SocialButton(
          provider: SocialProvider.google,
          onTap: () => _handleSocial(_authService.signInWithGoogle),
        ),
        const SizedBox(height: 12),
        SocialButton(
          provider: SocialProvider.facebook,
          label: l.continueWithFacebook,
          onTap: () => _handleSocial(_authService.signInWithFacebook),
        ),
      ],
    );
  }

  // ── Login form ────────────────────────────────────────────────────────
  Widget _buildLoginForm(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            label: l.emailLabel,
            hint: l.emailHint,
            icon: Icons.email_outlined,
            controller: _loginEmail,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? l.enterEmail : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: l.passwordLabel,
            hint: l.passwordHint,
            icon: Icons.lock_outline,
            controller: _loginPassword,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                (v == null || v.length < 4) ? l.enterPassword : null,
          ),
          if (_loginErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _loginErrorMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                ForgotPasswordScreen.routeName,
              ), // Navigate to forgot-password screen
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l.forgotPassword,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildGradientButton(
            label: l.signIn,
            loading: _loginLoading,
            onTap: _handleLogin,
          ),
          // ── Fingerprint button ──────────────────────────────────────
          if (_biometricAvailable) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _handleBiometric,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Fingerprint',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildOrDivider(context),
          const SizedBox(height: 20),
          _buildSocialButtons(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l.newToBantou,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: Text(
                  l.createAnAccount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCopyright(context),
        ],
      ),
    );
  }

  // ── Sign-up form ─────────────────────────────────────────────────────
  Widget _buildSignupForm(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            label: l.fullNameLabel,
            hint: l.fullNameHint,
            icon: Icons.person_outline,
            controller: _signupName,
            validator: (v) => (v == null || v.isEmpty) ? l.enterName : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: l.phoneLabel,
            hint: l.phoneHint,
            icon: Icons.phone_outlined,
            controller: _signupPhone,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return l.enterPhone;
              final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length < 8) return l.invalidPhone;
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: l.emailLabel,
            hint: l.emailHint,
            icon: Icons.email_outlined,
            controller: _signupEmail,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? l.enterEmail : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: l.passwordLabel,
            hint: l.passwordHint,
            icon: Icons.lock_outline,
            controller: _signupPassword,
            isPassword: true,
            validator: (v) =>
                (v == null || v.length < 6) ? l.passwordTooShort : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: l.confirmPasswordLabel,
            hint: l.passwordHint,
            icon: Icons.lock_outline,
            controller: _signupConfirm,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                v != _signupPassword.text ? l.passwordsDoNotMatch : null,
          ),
          if (_signupErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _signupErrorMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          _buildGradientButton(
            label: l.createAccount,
            loading: _signupLoading,
            onTap: _handleSignup,
          ),
          const SizedBox(height: 20),
          _buildOrDivider(context),
          const SizedBox(height: 20),
          _buildSocialButtons(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l.alreadyHaveAccount,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: Text(
                  l.signInLink,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCopyright(context),
        ],
      ),
    );
  }

  // ── Copyright footer ─────────────────────────────────────────────────
  Widget _buildCopyright(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Text(
      l.copyright,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 11,
        color: AppColors.textSecondary.withValues(alpha: 0.7),
      ),
    );
  }

  // ── Gradient primary button ───────────────────────────────────────────
  Widget _buildGradientButton({
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
