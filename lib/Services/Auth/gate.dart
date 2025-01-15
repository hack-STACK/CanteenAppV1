import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // User is signed in
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                String role = userSnapshot.data!['role'];
                if (role == 'student') {
                  return const StudentPage();
                } else if (role == 'admin') {
                  return const AdminDashboard();
                }
                return const LoginOrRegister();
              },
            );
          } else {
            // User is not signed in
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}