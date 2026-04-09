import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_scope.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/auth/create_association_screen.dart';
import 'screens/auth/edit_profile_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/sa_dashboard_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/circles/circle_dashboard_screen.dart';
import 'screens/circles/create_circle_screen.dart';
import 'screens/circles/circle_details_screen.dart';
import 'screens/circles/member_circles_screen.dart';
import 'services/http_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait for MVP mobile demo
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Load persisted locale before first frame
  final savedLocale = await loadSavedLocale();
  runApp(BantouApp(initialLocale: savedLocale));
}

/// Root widget — now [StatefulWidget] so it can manage the active [Locale].
class BantouApp extends StatefulWidget {
  const BantouApp({super.key, this.initialLocale = const Locale('en')});

  final Locale initialLocale;

  @override
  State<BantouApp> createState() => _BantouAppState();
}

class _BantouAppState extends State<BantouApp> {
  late Locale _locale;
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _initDeepLinks();
  }

  /// Initialise deep-link listener.
  /// Handles both the "cold start" URI (app was closed when link was tapped)
  /// and the "warm start" stream (app already running in background).
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Cold-start: was the app launched from a deep link?
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (_) {
      // Ignore — not launched from a link
    }

    // Warm-start: listen for future link events
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (_) {}, // silently ignore errors
    );
  }

  /// Process an incoming `bantou://invite?token=...` URI.
  void _handleIncomingLink(Uri uri) async {
    if (uri.scheme != 'bantou' || uri.host != 'invite') return;
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    // Validate the token with the backend and store invite state
    try {
      await HttpAuthService().validateInvite(token);
    } catch (_) {
      // If validation fails (expired / already registered), keep token
      // so AuthScreen can show an appropriate error banner.
      HttpAuthService.pendingInviteToken = token;
    }

    // Navigate to AuthScreen — it will detect pendingInviteToken and act accordingly
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AuthScreen.routeName,
      (route) => false,
      arguments: {'openSignUp': true},
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      locale: _locale,
      onLocaleChanged: _setLocale,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Bantou',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Localization wiring
        locale: _locale,
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
          Locale('es'),
          Locale('ar'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (deviceLocale, supported) {
          for (final s in supported) {
            if (s.languageCode == deviceLocale?.languageCode) return s;
          }
          return const Locale('en');
        },
        initialRoute: AuthScreen.routeName,
        routes: {
          AuthScreen.routeName: (_) => const AuthScreen(),
          ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
          CreateAssociationScreen.routeName: (_) =>
              const CreateAssociationScreen(),
          ProfileSetupScreen.routeName: (_) => const ProfileSetupScreen(),
          EditProfileScreen.routeName: (_) => const EditProfileScreen(),
          PendingApprovalScreen.routeName: (_) => const PendingApprovalScreen(),
          HomeScreen.routeName: (_) => const HomeScreen(),
          SaDashboardScreen.routeName: (_) => const SaDashboardScreen(),
          MainShellScreen.routeName: (_) => const MainShellScreen(),
          CircleDashboardScreen.routeName: (_) => const CircleDashboardScreen(),
          CreateCircleScreen.routeName: (_) => const CreateCircleScreen(),
          CircleDetailsScreen.routeName: (_) => const CircleDetailsScreen(),
          MemberCirclesScreen.routeName: (_) => const MemberCirclesScreen(),
        },
      ),
    );
  }
}
