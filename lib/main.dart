  import 'package:flutter/material.dart';
import 'package:kantin/Auth/login_or_register.dart';
  import 'package:provider/provider.dart';
  import 'package:kantin/Themes/theme_providers.dart';

  void main() {
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProviders(),
        child: const MainApp(),
      )
    );
  }

  class MainApp extends StatelessWidget {
    const MainApp({super.key});

    @override
    Widget build(BuildContext context) {
      return  MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoginOrRegister(),
        theme: Provider.of<ThemeProviders>(context).themeData,
      );
    }
  }
