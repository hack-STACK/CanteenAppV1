import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/pages/homepage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.ontap});
  final void Function()? ontap;

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  Color emailHintColor = Colors.grey; // Default hint color for email
  Color passwordHintColor = Colors.grey; // Default hint color for password
  Color confirmPasswordHintColor = Colors.grey; // Default hint color for confirm password
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();

    // Listen for focus changes on the email field
    emailFocusNode.addListener(() {
      setState(() {
        emailHintColor = emailFocusNode.hasFocus
            ? Colors.blue
            : Theme.of(context).colorScheme.inversePrimary; // Change color based on focus
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

    // Listen for focus changes on the confirm password field
    confirmPasswordFocusNode.addListener(() {
      setState(() {
        confirmPasswordHintColor = confirmPasswordFocusNode.hasFocus
            ? Colors.blue
            : Colors.grey; // Change color based on focus
      });
    });
  }

  void register() async {
    final _authService = AuthService();
    if (passwordController.text == confirmPasswordController.text) {
      setState(() {
        isLoading = true; // Set loading state to true
      });
      try {
        await _authService.signUpWithEmailPassword(
            emailController.text, passwordController.text);
        // Navigate to the homepage after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      } catch (e) {
        setState(() {
          isLoading = false; // Reset loading state
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Registration Failed'),
            content: Text(e.toString()), // Show a user-friendly error message
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Passwords don't match!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    emailFocusNode.dispose(); // Dispose the email focus node
    passwordFocusNode.dispose(); // Dispose the password focus node
    confirmPasswordFocusNode.dispose(); // Dispose the confirm password focus node
    emailController.dispose(); // Dispose the email controller
    passwordController.dispose(); // Dispose the password controller
    confirmPasswordController.dispose(); // Dispose the confirm password controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor : Theme.of(context).colorScheme.surface,
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside the text fields
          FocusScope.of(context).unfocus();
        },
        child: Center(
          child: SingleChildScrollView( // Allow scrolling for smaller screens
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.1), // Responsive padding
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
                    "Create an Account",
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
                  const SizedBox(height: 10),
                  MyTextfield(
                    controller: confirmPasswordController,
                    hintText: "Confirm Password",
                    obscureText: true,
                    hintColor: confirmPasswordHintColor, // Use dynamic hint color
                  ),
                  const SizedBox(height: 25),
                  isLoading // Show loading indicator if registering
                      ? CircularProgressIndicator()
                      : MyButton(
                          text: "Register",
                          onTap: register,
                        ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already a member? ',
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      GestureDetector(
                        onTap: widget.ontap,
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
      ),
    );
  }
}