import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_form.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Models/UsersModels.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/role_provider.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:kantin/pages/User/Identity_ask_REG.dart';
import 'package:kantin/pages/User/PersonalForm.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.onTap});
  final void Function()? onTap;

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false; // Loading state
  String errorMessage = 'error';

  void register() async {
    final authService = AuthService();
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final userService = UserService(); // Initialize UserService
    final supabaseClient =
        Supabase.instance.client; // Initialize Supabase client

    // Validate inputs
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog("Passwords don't match!");
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
      errorMessage = ''; // Reset error message
    });

    try {
      // Register user with Firebase Authentication
      final userCredential = await authService.signUpWithEmailPassword(
        emailController.text,
        passwordController.text,
        roleProvider.role, // Use the role from the provider
      );

      // Check if the user was created successfully
      if (userCredential.user != null) {
        final String firebaseUid = userCredential.user!.uid; // Get Firebase UID

        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUid)
            .set({
          'email': emailController.text,
          'role': roleProvider.role, // Use the role from the provider
          'createdAt': Timestamp.now(),
          'isRegistered': false, // Set to false initially
        });

        // Create a new UserModel instance
        // UserModel newUser = UserModel(
        //   username: emailController.text, // Assuming username is the email
        //   password:
        //       passwordController.text, // Ensure to hash this before storing
        //   role: roleProvider.role,
        //   firebaseUid: firebaseUid, id: 0, // Store Firebase UID
        // );

        // // // Save user data to Supabase using UserService
        // // await userService.createUser(newUser);

        // Navigate based on the user role
        if (roleProvider.role == 'student' ||
            roleProvider.role == 'admin_stalls') {
          // Navigate to the PersonalInfoScreen for both students and admins
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PersonalInfoScreen(role: roleProvider.role, firebaseUid: firebaseUid,),
              ),
            );
          }
        } else {
          // Navigate to the student dashboard for other roles
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StudentPage(), // Replace with your actual dashboard
              ),
            );
          }
        }
      } else {
        _showErrorDialog('User  registration failed: User credential is null.');
      }
    } catch (e) {
      // Handle errors and show an appropriate message
      _showErrorDialog('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
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
                  "Create an Account ",
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
                  hintColor: Colors.grey,
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: passwordController,
                  hintText: "Password",
                  obscureText: true,
                  hintColor: Colors.grey,
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: "Confirm Password",
                  obscureText: true,
                  hintColor: Colors.grey,
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Consumer<RoleProvider>(
                  builder: (context, roleProvider, child) {
                    return DropdownButton<String>(
                      value: roleProvider.role,
                      items: <String>[
                        'student',
                        'admin_stalls'
                      ] // Updated to include 'admin_stalls'
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          roleProvider
                              .setRole(newValue); // Update role in provider
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 25),
                isLoading
                    ? CircularProgressIndicator()
                    : MyButton(onTap: register, text: "Register"),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        "Login now",
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
