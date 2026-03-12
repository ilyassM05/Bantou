/// Abstract interface for authentication operations.
/// Swap [MockAuthService] for a real implementation (REST, Firebase, etc.)
/// without changing any UI code.
abstract class AuthService {
  Future<bool> signInWithEmail(String email, String password);
  Future<bool> signUpWithEmail(String name, String email, String password);
  Future<bool> signInWithGoogle();
  Future<bool> signInWithLinkedIn();
  Future<bool> signInWithFacebook();
  Future<bool> updateProfile(Map<String, dynamic> data);
  Future<void> signOut();
}
