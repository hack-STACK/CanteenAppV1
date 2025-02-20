import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { student, admin }

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      // Attempt to sign in the user with email and password
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Check if the user document exists
      if (!userDoc.exists) {
        throw Exception(
            'User  document does not exist. Please register first.');
      }

      // Cast the data to Map<String, dynamic>
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Retrieve the role, defaulting to 'student' if not found
      String roleString = userData['role'] ?? 'student';
      UserRole role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == roleString,
          orElse: () => UserRole.student);

      // Optionally, you can return the role or store it in a variable for later use
      return userCredential; // You can also return role if needed
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email. Please register.');
        case 'wrong-password':
          throw Exception('Incorrect password provided. Please try again.');
        default:
          throw Exception('Failed to sign in: ${e.message}');
      }
    } catch (e) {
      // Handle any other errors
      throw Exception('Error fetching user role: ${e.toString()}');
    }
  }

  Future<UserCredential> signUpWithEmailPassword(
      String email, String password, String role) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user role in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role, // Save role directly as string
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
              'The email address is already in use by another account. Please use a different email.');
        case 'invalid-email':
          throw Exception(
              'The email address is not valid. Please enter a valid email.');
        case 'weak-password':
          throw Exception(
              'The password provided is too weak. Please choose a stronger password.');
        default:
          throw Exception('Failed to sign up: ${e.message}');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  Future<void> deleteUserAccount(String password) async {
    try {
      // Reauthenticate the user before deleting the account
      await _reauthenticateAndDelete(password);
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        // If reauthentication is required, prompt the user to sign in again
        throw Exception('Please sign in again to delete your account.');
      } else {
        // Handle other Firebase exceptions
        throw Exception('Failed to delete account: ${e.message}');
      }
    } catch (e) {
      // Handle general exceptions
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  Future<void> _reauthenticateAndDelete(String password) async {
    try {
      User? user = _firebaseAuth.currentUser;

      if (user != null && user.email != null) {
        // Create an AuthCredential using the user's email and password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        // Reauthenticate the user
        await user.reauthenticateWithCredential(credential);

        // Delete the user account
        await user.delete();
      } else {
        throw Exception('No user is currently signed in.');
      }
    } catch (e) {
      // Handle exceptions during reauthentication or deletion
      throw Exception(
          'Failed to reauthenticate and delete account: ${e.toString()}');
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  String? get currentUserId => _firebaseAuth.currentUser?.uid;
}
