import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:kantin/pages/User/PersonalForm.dart';
import 'package:provider/provider.dart';
import 'role_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle authentication state
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError) {
                  return Center(
                    child: Text('Error fetching user data: ${userSnapshot.error}'),
                  );
                }

                // Check document existence and role
                if (userSnapshot.data?.exists ?? false) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                  if (userData != null) {
                    final String role = userData['role'] ?? 'student';
                    final bool isRegistered = userData['isRegistered'] ?? false;
                    final bool hasCompletedProfile = userData['hasCompletedProfile'] ?? false;
                    final int? stanId = userData['stanId'];

                    // Set the role in the RoleProvider
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Provider.of<RoleProvider>(context, listen: false).setRole(role);
                    });

                    // Determine which screen to show
                    if (!hasCompletedProfile || (role == 'student' && !isRegistered)) {
                      return PersonalInfoScreen(
                        role: role,
                        firebaseUid: snapshot.data!.uid,
                      );
                    }

                    // Return appropriate page based on role
                    if (role == 'admin_stalls') {
                      return MainAdmin(
                        key: ValueKey('admin_${snapshot.data!.uid}'),
                        stanId: stanId!,
                      );
                    } else {
                      return const StudentPage();
                    }
                  }
                }

                // Handle new user registration
                return PersonalInfoScreen(
                  role: 'student',
                  firebaseUid: snapshot.data!.uid,
                );
              },
            );
          }

          // Handle unauthenticated state
          return const LoginOrRegister();
        },
      ),
    );
  }
}