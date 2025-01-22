import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/gate.dart';
import 'package:kantin/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import Firebase App Check

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
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity, // For Android
      appleProvider: AppleProvider.appAttest, // For iOS
    );
  } catch (e) {
    print("Error initializing App Check: $e");
    return; // Exit if App Check initialization fails
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://hmmahzohkafghtdjbkqi.supabase.co',
      anonKey: 'your-supabase-anon-key', // Use a secure method to manage this
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
