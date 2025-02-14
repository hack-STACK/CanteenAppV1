import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get SUPABASE_URL => dotenv.env['SUPABASE_URL'] ?? '';
  static String get SUPABASE_ANON_KEY => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}