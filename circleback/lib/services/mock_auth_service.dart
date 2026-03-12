import '../services/auth_service.dart';

/// Mock implementation of [AuthService] for MVP/demo purposes.
/// Replace this with a real API or Firebase implementation for production.
class MockAuthService implements AuthService {
  @override
  Future<bool> signInWithEmail(String email, String password) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));
    // Accept any non-empty credentials for demo
    return email.isNotEmpty && password.isNotEmpty;
  }

  @override
  Future<bool> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return name.isNotEmpty && email.isNotEmpty && password.isNotEmpty;
  }

  @override
  Future<bool> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Stub — always succeeds for demo
  }

  @override
  Future<bool> signInWithLinkedIn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> signInWithFacebook() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
