import 'package:flutter/material.dart';
import 'package:kantin/pages/AdminState/dashboard/AppNavigationBar.dart';
import 'package:kantin/pages/AdminState/dashboard/Homepage.dart';

class MainAdmin extends StatelessWidget {
  const MainAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppNavigationBar.router,
    );
  }
}
