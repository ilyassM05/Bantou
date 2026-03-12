import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'biometric_service.dart';
import 'google_sign_in_service.dart';
import 'facebook_sign_in_service.dart';

const _kTimeout = Duration(seconds: 15);

class HttpAuthService implements AuthService {
  // 10.0.2.2 is the special IP to reach the host machine from Android Emulator
  static const String baseUrl = 'http://10.0.2.2:3000/auth';

  /// Holds the signed-in user's name & email after a successful auth call.
  /// Reset to null on sign-out.
  static Map<String, String>? currentUser;

  /// True if the user has NOT yet seen the profile setup screen.
  /// Set from the backend response on every login/signup.
  static bool currentUserNeedsSetup = false;

  /// True if the user has NOT yet completed the onboarding flow.
  /// (Association screen + Profile setup, first-time only)
  static bool currentUserNeedsOnboarding = false;

  /// Role of the currently signed-in user ('SA' for full admin, 'ADMIN' for restricted)
  static String? currentUserRole;

  // ── Deep link / invite state ───────────────────────────────────────────
  /// Invite token extracted from a `bantou://invite?token=...` deep link.
  static String? pendingInviteToken;

  /// Email address decoded from the invite token (to pre-fill signup form).
  static String? pendingInviteEmail;

  /// Association name from the invite (to show invitation banner).
  static String? pendingAssociationName;

  /// Clears all pending invite state (call after successful signup).
  static void clearPendingInvite() {
    pendingInviteToken = null;
    pendingInviteEmail = null;
    pendingAssociationName = null;
  }

  @override
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final user = body['user'];
        final userName = user?['name'] ?? '';
        final userEmail = user?['email'] ?? email;
        final token = body['token'] ?? '';
        currentUser = {'name': userName, 'email': userEmail};
        currentUserNeedsSetup = !(body['profileSetupSeen'] as bool? ?? false);
        currentUserNeedsOnboarding =
            !(body['onboardingSeen'] as bool? ?? false);
        currentUserRole = body['role'] as String?;
        // Save token for biometric login
        if (token.isNotEmpty) {
          await BiometricService.saveToken(
            token: token,
            name: userName,
            email: userEmail,
          );
        }
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Login failed');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  @override
  Future<bool> signUpWithEmail(
    String name,
    String email,
    String password, {
    String? phone,
    String? inviteToken,
  }) async {
    try {
      final bodyData = {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (inviteToken != null) 'inviteToken': inviteToken,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final token = body['token'] ?? '';
        currentUser = {'name': name, 'email': email};
        currentUserNeedsSetup = true; // new user always needs setup
        // onboardingSeen=true means they were an invited admin (already linked)
        // so they do NOT need onboarding. Regular new users get false → needs onboarding.
        final onboardingSeen = body['onboardingSeen'] as bool? ?? false;
        currentUserNeedsOnboarding = !onboardingSeen;
        // role is returned at top-level in the signup response
        currentUserRole = body['role'] as String?;
        clearPendingInvite(); // clear invite state after successful signup
        if (token.isNotEmpty) {
          await BiometricService.saveToken(
            token: token,
            name: name,
            email: email,
          );
        }
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Signup failed');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  /// Validates an invite token from a deep link and stores the email/assoc name.
  /// Returns true if valid, false/throws if expired or already registered.
  Future<bool> validateInvite(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/invite/$token'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        HttpAuthService.pendingInviteToken = token;
        HttpAuthService.pendingInviteEmail = body['email'] as String?;
        HttpAuthService.pendingAssociationName = body['associationName'] as String?;
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Invalid invite link');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(_kTimeout);
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Email not found');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(_kTimeout);
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Invalid code');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'newPassword': newPassword,
            }),
          )
          .timeout(_kTimeout);
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Reset failed');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  @override
  Future<bool> signInWithFacebook() async {
    // 1. Launch native Facebook login dialog and get access token
    final accessToken = await FacebookSignInService.getAccessToken();
    if (accessToken == null) return false; // user cancelled

    // 2. Send the access token to your backend for verification
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/facebook'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'accessToken': accessToken}),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final user = body['user'];
        final name = user?['name'] ?? '';
        final email = user?['email'] ?? '';
        final token = body['token'] ?? '';
        currentUser = {'name': name, 'email': email};
        currentUserNeedsSetup = !(body['profileSetupSeen'] as bool? ?? false);
        currentUserNeedsOnboarding =
            !(body['onboardingSeen'] as bool? ?? false);
        currentUserRole = body['role'] as String?;
        if (token.isNotEmpty) {
          await BiometricService.saveToken(
            token: token,
            name: name,
            email: email,
          );
        }
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Facebook sign-in failed');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    // 1. Launch native Google account picker and get ID token
    final idToken = await GoogleSignInService.getIdToken();
    if (idToken == null) return false; // user cancelled

    // 2. Send the ID token to your backend for verification
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final user = body['user'];
        final name = user?['name'] ?? '';
        final email = user?['email'] ?? '';
        final token = body['token'] ?? '';
        currentUser = {'name': name, 'email': email};
        currentUserNeedsSetup = !(body['profileSetupSeen'] as bool? ?? false);
        currentUserNeedsOnboarding =
            !(body['onboardingSeen'] as bool? ?? false);
        currentUserRole = body['role'] as String?;
        if (token.isNotEmpty) {
          await BiometricService.saveToken(
            token: token,
            name: name,
            email: email,
          );
        }
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Google sign-in failed');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  @override
  Future<bool> signInWithLinkedIn() async {
    // Left as mock
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    currentUserNeedsSetup = false;
    currentUserNeedsOnboarding = false;
    currentUserRole = null;
    await BiometricService.clearToken();
    await GoogleSignInService.signOut();
    await FacebookSignInService.signOut();
  }

  /// Tells the backend the user has seen the setup screen (called on skip).
  Future<void> markSetupSeen() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) return;
      await http
          .post(
            Uri.parse('$baseUrl/mark-setup-seen'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_kTimeout);
    } catch (_) {
      // Non-critical — silently ignore failures
    }
  }

  /// Fetches the current user's profile data from the backend.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please log in again.');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to fetch profile');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  @override
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please log in again.');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/update-profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['upgraded'] == true) {
          currentUserRole = 'SA';
        }
        currentUserNeedsSetup = false;
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Profile update failed');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  /// Saves the association data to the backend and marks onboarding as complete.
  Future<bool> saveAssociation(Map<String, dynamic> data) async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please log in again.');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/association'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        currentUserNeedsOnboarding = false;
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to save association');
      }
    } on TimeoutException {
      throw Exception('Server not responding. Is your backend running?');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error — make sure the backend is running.');
    }
  }

  /// Fetches the current user's association data from the backend.
  Future<Map<String, dynamic>?> getAssociation() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('$baseUrl/association'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
