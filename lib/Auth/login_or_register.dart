import 'package:flutter/material.dart';
import 'package:kantin/Pages/login_page.dart';
import 'package:kantin/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showloginpage = true;

  void tooglePages() {
    setState(() {
      showloginpage = !showloginpage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showloginpage) {
      return LoginPage(
        ontap: tooglePages,
      );
    } else {
      return RegisterPage(
        ontap: tooglePages,
      );
    }
  }
}
