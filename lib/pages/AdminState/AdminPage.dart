import 'package:flutter/material.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/pages/AdminState/dashboard/AppNavigationBar.dart';
import 'package:kantin/pages/AdminState/dashboard/Homepage.dart';
import 'package:provider/provider.dart';

class MainAdmin extends StatelessWidget {
  const MainAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProviders>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig:
              AppNavigationBar.router, // Use your router configuration
          theme: themeProvider.themeData,
        );
      },
    );
  }
}
