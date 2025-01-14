import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Returns the currently signed-in user, or null if no user is signed in.
  User? getCurrentUser () {
    return _firebaseAuth.currentUser ;
  }

  /// Signs in a user with the provided email and password.
  /// Throws a [FirebaseAuthException] if the sign-in fails.
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific error codes if needed
      throw Exception('Failed to sign in: ${e.message}');
    }
  }

  /// Signs up a new user with the provided email and password.
  /// Throws a [FirebaseAuthException] if the sign-up fails.
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific error codes if needed
      throw Exception('Failed to sign up: ${e.message}');
    }
  }

  /// Signs out the currently signed-in user.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}