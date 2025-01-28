import 'package:flutter/material.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/pages/AdminState/dashboard/AppNavigationBar.dart';
import 'package:provider/provider.dart';

class MainAdmin extends StatelessWidget {
  const MainAdmin({super.key, required this.stanId});
  final int stanId; // Make it non-nullable

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProviders>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig:
              AppNavigationBar.configureRouter(stanId), // Pass stanId directly
          theme: themeProvider.themeData,
        );
      },
    );
  }
}
