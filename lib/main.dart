import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Auth/login_or_register.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/Models/Restaurant.dart'; // Import your Restaurant model

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProviders()),
        ChangeNotifierProvider(
            create: (context) => Restaurant()), // Add Restaurant provider
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProviders>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const LoginOrRegister(),
          theme: themeProvider.themeData,
        );
      },
    );
  }
}
