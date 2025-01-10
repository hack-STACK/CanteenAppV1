import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Themes/light_mode.dart';

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

  @override
  void initState() {
    super.initState();

    // Listen for focus changes on the email field 
    emailFocusNode.addListener(() {
      setState(() {
        emailHintColor = emailFocusNode.hasFocus ? Colors.blue : Theme.of(context).colorScheme.inversePrimary; // Change color based on focus
      });
    });

    // Listen for focus changes on the password field
    passwordFocusNode.addListener(() {
      setState(() {
        passwordHintColor = passwordFocusNode.hasFocus ? Colors.blue : Colors.grey; // Change color based on focus
      });
    });

    // Listen for focus changes on the confirm password field
    confirmPasswordFocusNode.addListener(() {
      setState(() {
        confirmPasswordHintColor = confirmPasswordFocusNode.hasFocus ? Colors.blue : Colors.grey; // Change color based on focus
      });
    });
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open_rounded,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 25),
            Text(
              "Create an Account",
              style: TextStyle(
                fontSize: 16,
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
            MyButton(
              text: "Register",
              onTap: () {
                // Handle registration logic here
                // You can validate the inputs and call your registration API
              },
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
    );
  }
}