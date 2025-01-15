import 'package:flutter/material.dart';
import 'package:kantin/pages/User/login_page.dart';
import 'package:kantin/pages/User/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage; // Toggle between login and register pages
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showLoginPage
            ? LoginPage(
                key: const ValueKey('LoginPage'),
                onTap: togglePages, // Pass the toggle function
              )
            : RegisterPage(
                key: const ValueKey('RegisterPage'),
                onTap: togglePages, // Ensure consistent naming
              ),
      ),
    );
  }
}