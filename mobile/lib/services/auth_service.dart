import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication so the rest of the app never imports the SDK
/// directly. Two things this buys: screens depend on a small surface that is
/// easy to reason about, and every Firebase error is translated once, here,
/// into a message that can be shown to a user.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Emits on sign-in, sign-out and token refresh.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  /// The current ID token, or null when nobody is signed in.
  ///
  /// The SDK caches this and refreshes it automatically when it is close to
  /// expiring, so calling it per request is cheap and always yields a token the
  /// backend will accept.
  Future<String?> idToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    return _run(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _run(() => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
    }
    return credential;
  }

  Future<void> sendPasswordReset(String email) {
    return _run(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _auth.signOut();

  /// Runs a Firebase call and rethrows failures as [AuthFailure].
  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    } catch (_) {
      throw AuthFailure('Something went wrong. Please try again.');
    }
  }

  /// Firebase codes are precise but not for end users. Note that sign-in
  /// failures deliberately collapse to one message: telling an attacker
  /// whether an email is registered is an account-enumeration leak.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address does not look right.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password of at least 6 characters.';
      case 'network-request-failed':
        return 'No connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this project yet.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      default:
        return 'Incorrect email or password.';
    }
  }
}

/// A sign-in problem with a message safe to show to the user.
class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);
  @override
  String toString() => message;
}
