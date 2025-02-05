import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:kantin/pages/User/PersonalForm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onTap});
  final void Function()? onTap;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  Color emailHintColor = Colors.grey;
  Color passwordHintColor = Colors.grey;
  String errorMessage = '';
  bool isLoading = false;

  Future<void> login() async {
    final authService = AuthService();
    final stanService = StanService(); // Create an instance of StanService
    final userService = UserService(); // Create an instance of UserService
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Sign in with Firebase
      UserCredential userCredential = await authService.signInWithEmailPassword(
        emailController.text,
        passwordController.text,
      );

      // Fetch user data from Supabase using Firebase UID
      final user = await _supabaseClient
          .from('users')
          .select()
          .eq('firebase_uid', userCredential.user!.uid)
          .single();

      String role = user['role'] ?? 'student'; // Default to 'student'
      bool hasCompletedProfile = user['has_completed_form'] ?? false;
      int userId = user['id']; // Fetch user ID from Supabase

      // Navigate based on role and profile completion status
      if (hasCompletedProfile) {
        if (role == 'student') {
          // Fetch student data
          final studentResponse = await _supabaseClient
              .from('students')
              .select()
              .eq('id_user', userId)
              .single();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentPage()),
          );
        } else if (role == 'admin') {
          // Fetch stall data
          final stallResponse = await _supabaseClient
              .from('stalls')
              .select()
              .eq('id_user', userId)
              .single();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainAdmin(stanId: stallResponse['id']),
            ),
          );
        }
      } else {
        // Redirect to PersonalInfoScreen if the profile is not completed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalInfoScreen(
              role: role,
              firebaseUid: userCredential.user!.uid,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    emailFocusNode.addListener(() {
      setState(() {
        emailHintColor = emailFocusNode.hasFocus ? Colors.blue : Colors.grey;
      });
    });

    passwordFocusNode.addListener(() {
      setState(() {
        passwordHintColor =
            passwordFocusNode.hasFocus ? Colors.blue : Colors.grey;
      });
    });
  }

  @override
  void dispose() {
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  size: screenSize.width * 0.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 25),
                Text(
                  "Food Delivery App",
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 25),
                MyTextfield(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                  hintColor: emailHintColor,
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: passwordController,
                  hintText: "Password",
                  obscureText: true,
                  hintColor: passwordHintColor,
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 10),
                isLoading
                    ? CircularProgressIndicator()
                    : MyButton(text: "Sign in", onTap: login),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member? ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        "Register now",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
