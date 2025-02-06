import 'package:supabase_flutter/supabase_flutter.dart';

// Global instance to access Supabase client
final supabase = Supabase.instance.client;

// Initialize Supabase configuration
Future<void> initializeSupabase(
    String supabaseUrl, String supabaseAnonKey) async {
  await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true // Set to false in production
      );
}
