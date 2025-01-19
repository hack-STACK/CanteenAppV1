import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/gate.dart';
import 'package:kantin/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import your Restaurant model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
      url: 'https://hmmahzohkafghtdjbkqi.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtbWFoem9oa2FmZ2h0ZGpia3FpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwOTk4NjMsImV4cCI6MjA1MjY3NTg2M30.mbmgey9hVH4l2f_NpnFv5sgC8mo5dp70qX5avlJ8Jgw');
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
