import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onTap});
  final void Function()? onTap;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  Color emailHintColor = Colors.grey; // Default hint color for email
  Color passwordHintColor = Colors.grey; // Default hint color for password
  String errorMessage = ''; // To hold error messages
  bool isLoading = false; // Loading state

  Future<void> login() async {
  final authService = AuthService();
  setState(() {
    isLoading = true; // Set loading state to true
    errorMessage = ''; // Reset error message
  });

  try {
    UserCredential userCredential = await authService.signInWithEmailPassword(
      emailController.text,
      passwordController.text,
    );

    // Fetch user role from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    // Check if the document exists and contains the 'role' field
    if (userDoc.exists && userDoc.data() != null) {
      String role = userDoc['role'] ?? 'student'; // Default to 'student' if role is null

      // Navigate based on role
      if (role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentPage()),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard(canteenName: '',)),
        );
      }
    } else {
      setState(() {
        errorMessage = 'User  document does not exist or is empty';
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Login failed: ${e.toString()}'; // Show error message
    });
  } finally {
    setState(() {
      isLoading = false; // Reset loading state
    });
  }
}

  @override
  void initState() {
    super.initState();

    // Listen for focus changes on the email field
    emailFocusNode.addListener(() {
      setState(() {
        emailHintColor = emailFocusNode.hasFocus
            ? Colors.blue
            : Theme.of(context)
                .colorScheme
                .inversePrimary; // Change color based on focus
      });
    });

    // Listen for focus changes on the password field
    passwordFocusNode.addListener(() {
      setState(() {
        passwordHintColor = passwordFocusNode.hasFocus
            ? Colors.blue
            : Colors.grey; // Change color based on focus
      });
    });
  }

  @override
  void dispose() {
    emailFocusNode.dispose(); // Dispose the email focus node
    passwordFocusNode.dispose(); // Dispose the password focus node
    emailController.dispose(); // Dispose the email controller
    passwordController.dispose(); // Dispose the password controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside the text fields
          FocusScope.of(context).unfocus();
        },
        child: Center(
          child: SingleChildScrollView(
            // Allow scrolling for smaller screens
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.1), // Responsive padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    size: screenSize.width * 0.2, // Responsive icon size
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Food Delivery App",
                    style: TextStyle(
                      fontSize: 20, // Increased font size for better visibility
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 25),
                  MyTextfield(
                    controller: emailController,
                    hintText: "Email",
                    obscureText: false,
                    hintColor: emailHintColor, // Use dynamic hint color
                  ),
                  const SizedBox(height: 10),
                  MyTextfield(
                    controller: passwordController,
                    hintText: "Password",
                    obscureText: true,
                    hintColor: passwordHintColor, // Use dynamic hint color
                  ),
                  const SizedBox(height: 25),
                  if (errorMessage
                      .isNotEmpty) // Display error message if exists
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),
                  isLoading // Show loading indicator while logging in
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
                        onTap:
                            widget.onTap, // Call the onTap function to navigate
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
      ),
    );
  }
}
