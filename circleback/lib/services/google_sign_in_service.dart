import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the [google_sign_in] package.
///
/// Call [getIdToken] to trigger the Google OAuth 2.0 flow.
/// The returned ID token is a JWT signed by Google that your backend
/// can verify via `POST /auth/google`.
class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Server/Web OAuth client ID — required so Google returns an idToken
    // that your backend can verify.
    serverClientId:
        '744799157092-klp2t0h00bjfg0ps2166k6a4fn7c7ndb.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Launches the native Google account picker and returns the user's
  /// Google ID token, or `null` if the user dismissed the dialog.
  static Future<String?> getIdToken() async {
    try {
      // Sign out first so the account chooser always appears,
      // letting the user pick any of their Google accounts.
      await _googleSignIn.signOut();

      // Trigger the sign-in flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // User cancelled

      // Fetch authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Signs the user out of Google (clears the cached account).
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
