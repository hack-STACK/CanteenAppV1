import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/gate.dart';
import 'package:kantin/Services/Auth/role_provider.dart';
import 'package:kantin/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print("Error initializing Firebase: $e");
    return; // Exit if Firebase initialization fails
  }
    // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity, // For Android
    appleProvider: AppleProvider.appAttest, // For iOS
  );

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://hmmahzohkafghtdjbkqi.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtbWFoem9oa2FmZ2h0ZGpia3FpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwOTk4NjMsImV4cCI6MjA1MjY3NTg2M30.mbmgey9hVH4l2f_NpnFv5sgC8mo5dp70qX5avlJ8Jgw', // Use a secure method to manage this
    );
  } catch (e) {
    print("Error initializing Supabase: $e");
    return; // Exit if Supabase initialization fails
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProviders()),
        ChangeNotifierProvider(create: (context) => Restaurant()),
        ChangeNotifierProvider(
          create: (context) => RoleProvider(
              initialRole: 'student'), // Set default role to 'student'
        ),
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
          home: const AuthGate(), // Ensure AuthGate is properly defined
          theme: themeProvider.themeData,
        );
      },
    );
  }
}
