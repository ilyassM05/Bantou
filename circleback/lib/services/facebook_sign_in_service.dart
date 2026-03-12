import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Thin wrapper around the [flutter_facebook_auth] package.
///
/// Call [getAccessToken] to trigger the native Facebook Login flow.
/// The returned access token is then sent to your backend via
/// `POST /auth/facebook` where it is verified with the Graph API.
class FacebookSignInService {
  FacebookSignInService._();

  /// Launches the Facebook Login dialog and returns the user's
  /// access token string, or `null` if the user dismissed the dialog.
  static Future<String?> getAccessToken() async {
    try {
      // Log out first to always show the account chooser
      await FacebookAuth.instance.logOut();

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        return result.accessToken?.tokenString;
      }

      // User cancelled or failed
      return null;
    } catch (e) {
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  /// Signs the user out of Facebook (clears the cached session).
  static Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }
}
