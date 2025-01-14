import 'package:flutter/material.dart';
import 'package:kantin/Pages/login_page.dart';
import 'package:kantin/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
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
                ontap: togglePages, // Pass the toggle function
              ),
      ),
    );
  }
}