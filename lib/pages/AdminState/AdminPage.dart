import 'package:flutter/material.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/pages/AdminState/dashboard/AppNavigationBar.dart';
import 'package:provider/provider.dart';

class MainAdmin extends StatefulWidget {
  const MainAdmin({super.key, required this.stanId});
  final int stanId;

  @override
  State<MainAdmin> createState() => _MainAdminState();
}

class _MainAdminState extends State<MainAdmin> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProviders>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: AppNavigationBar.configureRouter(
              widget.stanId), // Use widget.stanId
          theme: themeProvider.themeData,
        );
      },
    );
  }

  /// Call this method to refresh the widget manually
  void refresh() {
    setState(() {});
  }
}
