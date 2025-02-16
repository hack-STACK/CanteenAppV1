import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
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
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final authService = AuthService();
      final userCredential = await authService.signInWithEmailPassword(
        emailController.text,
        passwordController.text,
      );

      // Get user data with all needed fields
      final userData = await _supabaseClient
          .from('users')
          .select('id, role, "has_completed_Profile", "Email"')
          .eq('firebase_uid', userCredential.user!.uid)
          .single();

      print('Full user data: $userData');

      final int userId = userData['id'];
      final String role = userData['role'] ?? 'student';
      final bool hasCompletedProfile =
          userData['has_completed_Profile'] ?? false;

      print(
          'Parsed user data - ID: $userId, Role: $role, Profile completed: $hasCompletedProfile');

      if (!hasCompletedProfile) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalInfoScreen(
              role: role,
              firebaseUid: userCredential.user!.uid,
            ),
          ),
        );
        return;
      }

      // Profile is completed, proceed with role-based navigation
      if (role == 'student') {
        print('Navigating as student');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentPage()),
        );
      } else if (role == 'admin_stalls') {
        // Changed from 'admin' to 'admin_stalls'
        print('Navigating as admin');
        try {
          final stallData = await _supabaseClient
              .from('stalls')
              .select()
              .eq('id_user', userId)
              .single();

          print('Stall data: $stallData'); // Debug log

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainAdmin(stanId: stallData['id']),
            ),
          );
        } catch (e) {
          print('Error fetching stall data: $e');
          throw 'Stall data not found';
        }
      } else {
        throw 'Invalid role: $role';
      }
    } catch (e) {
      print('Login error: $e'); // Debug log
      if (!mounted) return;
      setState(() {
        errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
