import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles biometric authentication and secure JWT token storage.
class BiometricService {
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'biometric_token';
  static const _nameKey = 'biometric_name';
  static const _emailKey = 'biometric_email';

  // ── Availability ────────────────────────────────────────────────────────

  /// Returns true if the device supports and has biometrics enrolled.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if a saved token exists (biometric login has been enabled).
  static Future<bool> hasStoredToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Read the stored JWT token.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // ── Store / clear token ─────────────────────────────────────────────────

  /// Save a JWT token + user info for biometric login after a successful
  /// email/password or Google sign-in.
  static Future<void> saveToken({
    required String token,
    required String name,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _nameKey, value: name),
      _storage.write(key: _emailKey, value: email),
    ]);
  }

  /// Remove all saved biometric credentials (on sign-out).
  static Future<void> clearToken() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _nameKey),
      _storage.delete(key: _emailKey),
    ]);
  }

  // ── Authenticate ────────────────────────────────────────────────────────

  /// Prompt the user for biometric authentication.
  /// Returns the stored user map on success, or null if cancelled / failed.
  static Future<Map<String, String>?> authenticate() async {
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Use your fingerprint or face to sign in to Bantou',
        options: const AuthenticationOptions(
          stickyAuth: true, // keep prompt if user moves away
          biometricOnly: false, // allow device PIN as fallback
        ),
      );

      if (!didAuth) return null;

      final token = await _storage.read(key: _tokenKey);
      final name = await _storage.read(key: _nameKey);
      final email = await _storage.read(key: _emailKey);

      if (token == null || name == null || email == null) return null;

      return {'token': token, 'name': name, 'email': email};
    } catch (_) {
      return null;
    }
  }
}
