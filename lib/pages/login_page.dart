import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/pages/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.ontap});
  final void Function()? ontap;
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  Color emailHintColor = Colors.grey; // Default hint color for email
  Color passwordHintColor = Colors.grey;
  // Default hint color for password
  void login() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => Homepage()));
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
              "Food Delivery App",
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
            const SizedBox(
              height: 25,
            ),
            MyButton(text: "Sign in", onTap: login),
            const SizedBox(
              height: 25,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Not a member? ',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                GestureDetector(
                  onTap: widget.ontap,
                  child: Text(
                    "Register now",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
