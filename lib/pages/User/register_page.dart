import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/pages/User/Identity_ask_REG.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.onTap,
  });
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
  String errorMessage = '';
  String selectedRole = 'student'; // Default role

  void register() async {
    final authService = AuthService();

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
    });

    try {
      // Register user with Firebase Authentication
      final userCredential = await authService.signUpWithEmailPassword(
        emailController.text,
        passwordController.text,
        selectedRole,
      );

      // Check if the user was created successfully
      if (userCredential.user != null) {
        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': emailController.text,
          'role': selectedRole,
          'createdAt': Timestamp.now(),
        });

        // Navigate to the next screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => IdentityAskReg(role: selectedRole),
            ),
          );
        }
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
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
    // Get the screen size
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
                  "Create an Account",
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
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: passwordController,
                  hintText: "Password",
                  obscureText: true,
                  hintColor: Colors.grey,
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: "Confirm Password",
                  obscureText: true,
                  hintColor: Colors.grey,
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedRole,
                  items: <String>['student', 'admin']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
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
