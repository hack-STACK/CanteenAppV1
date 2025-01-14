import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/pages/homepage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Check if the snapshot has data
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting for the authentication state, show a loading indicator
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // User is signed in
            return const Homepage();
          } else {
            // User is not signed in
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}