import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  /// Role of the currently signed-in user ('SA' for super admin, 'admin' for restricted invited admin, 'member' for member)
  static String? currentUserRole;

  /// Status of the currently signed-in user ('actif', 'en attente', etc.)
  static String? currentUserStatus;

  /// True when the current user is a freshly-invited admin who has not yet
  /// completed their personal profile. Set from the backend `isInvitedAdmin`
  /// field and cleared once the profile is saved.
  static bool currentIsInvitedAdmin = false;

  /// True when the current user is a member (not SA or admin).
  static bool currentIsMember = false;

  /// Cached profile picture URL for the currently signed-in user.
  /// Updated after upload/delete and on getProfile().
  static String? currentUserProfilePicture;

  /// Cached association logo URL for the currently signed-in user's association.
  /// Updated after upload/delete and on getAssociation().
  static String? currentAssociationLogoUrl;


  // ─── SA and Admin Stats ────────────────────────────────────────────────────────

  /// Fetch association members for SA and Admin
  Future<List<dynamic>> getAssociationMembers() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('No token');
      
      final url = Uri.parse('$baseUrl/association/members');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to fetch members');
      }
    } catch (e) {
      throw Exception('Server error: $e');
    }
  }
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
        currentUserStatus = body['status'] as String?;
        currentIsInvitedAdmin = body['isInvitedAdmin'] as bool? ?? false;
        currentIsMember = (body['role'] as String?) == 'member';
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
        currentUserNeedsSetup = true; // new user always needs profile setup
        // onboardingSeen=true means they were an invited admin or member (already linked)
        // so they do NOT need onboarding. Regular new users get false → needs onboarding.
        final onboardingSeen = body['onboardingSeen'] as bool? ?? false;
        currentUserNeedsOnboarding = !onboardingSeen;
        // role is returned at top-level in the signup response
        currentUserRole = body['role'] as String?;
        currentUserStatus = body['status'] as String?;
        // Dedicated flag for invited admins — more reliable than just checking role
        currentIsInvitedAdmin = body['isInvitedAdmin'] as bool? ?? false;
        currentIsMember = (body['role'] as String?) == 'member';
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
        currentUserStatus = body['status'] as String?;
        currentIsInvitedAdmin = body['isInvitedAdmin'] as bool? ?? false;
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
        currentIsInvitedAdmin = body['isInvitedAdmin'] as bool? ?? false;
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
    currentUserStatus = null;
    currentIsInvitedAdmin = false;
    currentIsMember = false;
    currentUserProfilePicture = null;
    currentAssociationLogoUrl = null;
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Cache profile picture for use across the app
        currentUserProfilePicture = data['profilePicture'] as String?;
        return data;
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

  /// Uploads a profile picture image file.
  /// Returns the server-relative URL of the saved image.
  Future<String> uploadProfilePicture(File image) async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('No authentication token found.');

      final uri = Uri.parse('$baseUrl/upload-profile-picture');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamed = await request.send().timeout(_kTimeout);
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final url = body['profilePictureUrl'] as String;
        currentUserProfilePicture = url;
        return url;
      }
      throw Exception(body['error'] ?? 'Upload failed');
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
    }
  }

  /// Removes the current user's profile picture.
  Future<void> deleteProfilePicture() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('No authentication token found.');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/profile-picture'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_kTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to remove picture');
      }
      currentUserProfilePicture = null;
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
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
        // Role is fixed at signup and never mutated client-side.
        // The backend no longer promotes admins to SA on profile save.
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

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please log in again.');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/change-password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(_kTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to update password');
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
  /// Also caches the logo URL in [currentAssociationLogoUrl].
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Cache the association logo URL
        currentAssociationLogoUrl = data['logoUrl'] as String?;
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a logo image file for the current user's association.
  /// Returns the server-relative URL of the saved logo.
  Future<String> uploadAssociationLogo(File image) async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('No authentication token found.');

      final uri = Uri.parse('$baseUrl/association/logo');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'logo',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamed = await request.send().timeout(_kTimeout);
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final url = body['logoUrl'] as String;
        currentAssociationLogoUrl = url;
        return url;
      }
      throw Exception(body['error'] ?? 'Logo upload failed');
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
    }
  }

  /// Removes the current association's logo.
  Future<void> deleteAssociationLogo() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('No authentication token found.');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/association/logo'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_kTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to remove logo');
      }
      currentAssociationLogoUrl = null;
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
    }
  }

  /// Invites a new user as a member (SA invites directly; members create pending request).
  Future<String> inviteMember(String email, {int? circleId}) async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('Not authenticated.');

      final body = <String, dynamic>{'email': email};
      if (circleId != null) body['circleId'] = circleId;

      final response = await http
          .post(
            Uri.parse('$baseUrl/invite-member'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_kTimeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data['message'] as String;
      throw Exception(data['error'] ?? 'Failed to invite member');
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
    }
  }

  /// Fetches SA dashboard data (members, admins, circles).
  Future<Map<String, dynamic>> getSADashboard() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('Not authenticated.');

      final response = await http
          .get(
            Uri.parse('$baseUrl/sa-dashboard'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to load dashboard');
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
    }
  }

  /// Fetches pending member invitations submitted by non-SA users (SA-only).
  Future<List<dynamic>> getPendingMemberInvitations() async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('Not authenticated.');

      final response = await http
          .get(
            Uri.parse('$baseUrl/member-invitations/pending'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['pendingInvitations'] as List<dynamic>;
      }
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to load pending invitations');
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
    }
  }

  /// SA approves or rejects a pending member invitation.
  Future<String> respondToMemberInvitation(int id, String action) async {
    try {
      final token = await BiometricService.getToken();
      if (token == null) throw Exception('Not authenticated.');

      final response = await http
          .put(
            Uri.parse('$baseUrl/member-invitations/$id/respond'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'action': action}),
          )
          .timeout(_kTimeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data['message'] as String;
      throw Exception(data['error'] ?? 'Failed to respond');
    } on TimeoutException {
      throw Exception('Server not responding.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('Network error.');
    }
  }
}
