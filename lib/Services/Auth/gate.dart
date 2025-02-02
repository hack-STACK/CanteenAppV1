import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/Services/Auth/role_provider.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:kantin/pages/User/PersonalForm.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<firebase_auth.User?>(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final firebaseUser = snapshot.data!;
            return FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(firebaseUser.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError) {
                  return Center(
                    child:
                        Text('Error fetching user data: ${userSnapshot.error}'),
                  );
                }

                final userData = userSnapshot.data;
                if (userData != null) {
                  final String role = userData['role'];
                  final bool hasCompletedProfile =
                      userData['has_completed_Profile'] ?? false;
                  final int? userId = userData['id'];

                  // Set the role in the RoleProvider
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<RoleProvider>(context, listen: false)
                        .setRole(role);
                  });

                  if (hasCompletedProfile) {
                    if (role == 'admin_stalls') {
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchStallData(userId!),
                        builder: (context, stallSnapshot) {
                          if (stallSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (stallSnapshot.hasError) {
                            return Center(
                              child: Text(
                                  'Error fetching stall data: ${stallSnapshot.error}'),
                            );
                          }

                          final stallData = stallSnapshot.data;
                          if (stallData != null) {
                            return MainAdmin(
                              key: ValueKey('admin_${firebaseUser.uid}'),
                              stanId: stallData['id'],
                            );
                          } else {
                            return Center(
                              child: Text(
                                  'Stall data not found for user ID: $userId'),
                            );
                          }
                        },
                      );
                    } else {
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchStudentData(userId!),
                        builder: (context, studentSnapshot) {
                          if (studentSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (studentSnapshot.hasError) {
                            return Center(
                              child: Text(
                                  'Error fetching student data: ${studentSnapshot.error}'),
                            );
                          }

                          final studentData = studentSnapshot.data;
                          if (studentData != null) {
                            return const StudentPage();
                          } else {
                            return Center(
                              child: Text(
                                  'Student data not found for user ID: $userId'),
                            );
                          }
                        },
                      );
                    }
                  } else {
                    return PersonalInfoScreen(
                      role: role,
                      firebaseUid: firebaseUser.uid,
                    );
                  }
                }

                // Important change: Get the role from the provider instead of defaulting to 'student'
                final roleProvider =
                    Provider.of<RoleProvider>(context, listen: false);
                return PersonalInfoScreen(
                  role: roleProvider
                      .role, // Use the role from provider instead of hardcoding 'student'
                  firebaseUid: firebaseUser.uid,
                );
              },
            );
          }

          return const LoginOrRegister();
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchUserData(String firebaseUid) async {
    final userService = UserService();
    try {
      final userExists = await userService.checkFirebaseUidExists(firebaseUid);
      if (userExists) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('firebase_uid', firebaseUid)
            .single();
        return response;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchStallData(int userId) async {
    try {
      final response = await Supabase.instance.client
          .from('stalls')
          .select()
          .eq('id_user', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching stall data: $e');
      throw Exception('Failed to fetch stall data: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchStudentData(int userId) async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select()
          .eq('id_user', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching student data: $e');
      throw Exception('Failed to fetch student data: $e');
    }
  }
}
