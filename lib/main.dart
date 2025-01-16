import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/gate.dart';
import 'package:kantin/firebase_options.dart';
import 'package:kantin/pages/User/Identity_ask_REG.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/Models/Restaurant.dart'; // Import your Restaurant model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

String role = 'admin'; // Default role

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProviders>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AuthGate(), //const AuthGate(),
          theme: themeProvider.themeData,
        );
      },
    );
  }
}
